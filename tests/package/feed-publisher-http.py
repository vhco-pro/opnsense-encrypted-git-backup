"""Exercise the documented GitHub and Pages HTTP shapes with no external requests."""
import hashlib
import json
import os
from pathlib import Path
import re
import socket
import subprocess
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class Fixture(BaseHTTPRequestHandler):
    journal = []
    pages = []
    live = None
    digest = hashlib.sha256(b"fixture generation").hexdigest()
    lose_pages_reply = True
    lose_journal_reply = False

    def log_message(self, *_args):
        pass

    def respond(self, value, status=200):
        payload = json.dumps(value).encode()
        self.send_response(status)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        if self.path.startswith("/repos/fixture/plugin/deployments?"):
            self.respond(self.journal)
        elif self.path.startswith("/pages/deployments?"):
            self.respond({"success": True, "result": self.pages})
        elif self.path == "/pages":
            self.respond({"success": True, "result": {"canonical_deployment": self.live}})
        elif self.path == "/feed/generation.json" and self.live:
            self.respond({"digest": self.digest})
        else:
            self.respond({}, 404)

    def do_POST(self):
        body = self.rfile.read(int(self.headers["Content-Length"]))
        if self.path == "/repos/fixture/plugin/deployments":
            record = json.loads(body)
            if record["auto_merge"] is not False or record["environment"] != "feed-fixture":
                self.respond({}, 422)
                return
            entry = {"sha": record["ref"], "payload": record["payload"]}
            self.journal.append(entry)
            if self.lose_journal_reply:
                self.connection.shutdown(socket.SHUT_RDWR)
                return
            self.respond(entry, 201)
        elif self.path == "/pages/deployments":
            attempt = re.search(rb"feed-attempt:[a-f0-9]{32}", body)
            if not attempt or not self.journal:
                self.respond({}, 422)
                return
            item = {
                "id": "fixture-deployment",
                "environment": "production",
                "deployment_trigger": {"metadata": {"commit_message": attempt[0].decode()}},
                "latest_stage": {"name": "deploy", "status": "success", "ended_on": "2026-01-01"},
            }
            self.pages.append(item)
            type(self).live = item
            if self.lose_pages_reply:
                self.connection.shutdown(socket.SHUT_RDWR)
                return
            self.respond({"success": True, "result": item})
        else:
            self.respond({}, 404)


class PublisherTest(unittest.TestCase):
    def setUp(self):
        Fixture.journal = []
        Fixture.pages = []
        Fixture.live = None
        Fixture.lose_journal_reply = False

    def test_lost_create_replay_and_conflict(self):
        with ThreadingHTTPServer(("127.0.0.1", 0), Fixture) as server, tempfile.TemporaryDirectory() as directory:
            worker = threading.Thread(target=server.serve_forever, daemon=True)
            worker.start()
            try:
                url = f"http://127.0.0.1:{server.server_port}"
                manifest = Path(directory) / "manifest.json"
                manifest.write_text(json.dumps({"/generation.json": "fixture-hash"}))
                env = os.environ | {
                    "GITHUB_API_URL": url, "PAGES_API": url + "/pages", "FEED_URL": url + "/feed",
                    "GITHUB_REPOSITORY": "fixture/plugin", "GITHUB_SHA": "a" * 40,
                    "FEED_MANIFEST": str(manifest), "FEED_DIGEST": Fixture.digest, "PAGES_BRANCH": "main",
                }
                publisher = Path(__file__).resolve().parents[2] / "scripts/publish-feed.sh"

                def run(mode="fixture"):
                    return subprocess.run(["bash", publisher, mode], env=env, capture_output=True, check=False)

                self.assertNotEqual(run("production").returncode, 0)
                self.assertEqual(len(Fixture.journal), 0)
                self.assertNotEqual(run().returncode, 0)
                self.assertEqual(len(Fixture.journal), 1)
                self.assertEqual(len(Fixture.pages), 1)
                result = run()
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn(b"native client verification remains required", result.stdout)
                self.assertEqual(len(Fixture.pages), 1)
                Fixture.pages.append(Fixture.pages[0])
                self.assertNotEqual(run().returncode, 0)
                self.assertEqual(len(Fixture.journal), 1)

                # Lose the durable-intent response before any Pages create.
                self.setUp()
                Fixture.lose_journal_reply = True
                self.assertNotEqual(run().returncode, 0)
                self.assertEqual(len(Fixture.journal), 1)
                self.assertEqual(len(Fixture.pages), 0)
                self.assertNotEqual(run().returncode, 0)
                self.assertEqual(len(Fixture.journal), 1)
                self.assertEqual(len(Fixture.pages), 0)
            finally:
                server.shutdown()
                worker.join()


if __name__ == "__main__":
    unittest.main()
