import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";

const execute = promisify(execFile);
const publisher = fileURLToPath(new URL("../../scripts/publish-feed.sh", import.meta.url));

test("publisher holds ambiguous responses and reconciles one live deployment", async () => {
    const journal = [];
    const pages = [];
    const digest = createHash("sha256").update("fixture generation").digest("hex");
    const assets = new Map();
    const key = "a".repeat(32);
    let loseJournalReply = false;

    const server = createServer(async (request, response) => {
        const path = new URL(request.url, "http://localhost").pathname;
        const reply = (status, value) => response.writeHead(status, {
            "Content-Type": "application/json",
        }).end(JSON.stringify(value));

        if (request.method === "GET") {
            if (path === "/repos/fixture/plugin/deployments") return reply(200, journal);
            if (path === "/pages/upload-token") return reply(200, { success: true, result: { jwt: "fixture-jwt" } });
            if (path === "/pages/deployments") return reply(200, { success: true, result: pages });
            if (path === "/pages") {
                return reply(200, { success: true, result: { canonical_deployment: pages[0] ?? null } });
            }
            if (path === "/feed/generation.json" && pages.length) return reply(200, JSON.parse(assets.get(key)));
            return reply(404, {});
        }

        const chunks = [];
        for await (const chunk of request) chunks.push(chunk);
        const body = Buffer.concat(chunks).toString();
        if (path === "/repos/fixture/plugin/deployments") {
            const record = JSON.parse(body);
            if (record.auto_merge !== false || record.environment !== "feed-fixture") return reply(422, {});
            const entry = { sha: record.ref, payload: record.payload };
            journal.push(entry);
            if (loseJournalReply) return request.socket.destroy();
            return reply(201, entry);
        }

        if (path === "/assets/upload" || path === "/assets/upsert-hashes") {
            if (request.headers.authorization !== "Bearer fixture-jwt") return reply(403, {});
            const payload = JSON.parse(body);
            if (path.endsWith("/upload")) {
                for (const item of payload) assets.set(item.key, Buffer.from(item.value, "base64").toString());
            } else if (!payload.hashes.every((hash) => assets.has(hash))) {
                return reply(422, {});
            }
            return reply(200, { success: true });
        }

        const attempt = body.match(/feed-attempt:[a-f0-9]{32}/)?.[0];
        if (path !== "/pages/deployments" || !attempt || journal.length !== 1 || !assets.has(key) || !body.includes(key)) return reply(422, {});
        pages.push({
            id: "fixture-deployment",
            environment: "production",
            deployment_trigger: { metadata: { commit_message: attempt } },
            latest_stage: { name: "deploy", status: "success", ended_on: "2026-01-01" },
        });
        request.socket.destroy();
    });
    await new Promise((resolve, reject) => {
        server.once("error", reject);
        server.listen(0, "127.0.0.1", resolve);
    });
    const directory = await mkdtemp(join(tmpdir(), "feed-http-"));
    try {
        const url = `http://127.0.0.1:${server.address().port}`;
        const manifest = join(directory, "manifest.json");
        await writeFile(manifest, JSON.stringify({ "/generation.json": key }));
        await writeFile(join(directory, "generation.json"), JSON.stringify({ digest }));
        const env = {
            ...process.env,
            GITHUB_API_URL: url,
            PAGES_ASSET_API: url + "/assets",
            FEED_DIRECTORY: directory,
            PAGES_API: url + "/pages",
            FEED_URL: url + "/feed",
            GITHUB_REPOSITORY: "fixture/plugin",
            GITHUB_SHA: "a".repeat(40),
            FEED_MANIFEST: manifest,
            FEED_DIGEST: digest,
            PAGES_BRANCH: "main",
        };
        const run = (mode = "fixture") => execute("bash", [publisher, mode], { env });

        await assert.rejects(run("production"), /Production publication is disabled/);
        assert.equal(journal.length, 0);
        await assert.rejects(run());
        assert.equal(journal.length, 1);
        assert.equal(assets.get(key), JSON.stringify({ digest }));
        assert.equal(pages.length, 1);
        assert.match((await run()).stdout, /native client verification remains required/);
        assert.equal(pages.length, 1);
        pages.push(pages[0]);
        await assert.rejects(run(), /unresolved Pages create/);
        assert.equal(journal.length, 1);

        journal.length = 0;
        pages.length = 0;
        loseJournalReply = true;
        await assert.rejects(run());
        await assert.rejects(run(), /unresolved Pages create/);
        assert.equal(journal.length, 1);
        assert.equal(pages.length, 0);
    } finally {
        await new Promise((resolve) => server.close(resolve));
        await rm(directory, { recursive: true, force: true });
    }
});
