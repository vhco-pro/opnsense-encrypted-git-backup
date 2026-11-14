import assert from "node:assert/strict";
import { execFile, spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdtemp, rm, writeFile, readFile, readdir } from "node:fs/promises";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";

const execute = promisify(execFile);
const publisher = fileURLToPath(new URL("../../scripts/publish-feed.sh", import.meta.url));

test("publisher holds ambiguous responses and reconciles one live deployment", async () => {
    const native = process.env.NATIVE_FEED_DIRECTORY && resolve(process.env.NATIVE_FEED_DIRECTORY);
    const journal = [];
    const pages = [];
    const digest = createHash("sha256").update("fixture generation").digest("hex");
    const assets = new Map();
    const key = "a".repeat(32);
    const site = new Map([["/generation.json", key]]);
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
            if (path.startsWith("/feed/") && pages.length && site.has(path.slice(5))) {
                return response.writeHead(200).end(assets.get(site.get(path.slice(5))));
            }
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
                for (const item of payload) assets.set(item.key, Buffer.from(item.value, "base64"));
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
    let forward;
    try {
        const url = `http://127.0.0.1:${server.address().port}`;
        const manifest = join(directory, "manifest.json");
        let nativeManifest;
        let effectiveMarker = digest;
        if (native) {
            const files = await readdir(join(native, "site"));
            for (const file of files) {
                if (!/^[a-zA-Z0-9_.-]+$/.test(file)) continue;
                const bytes = await readFile(join(native, "site", file));
                const hash = createHash("sha256").update(bytes).digest("hex").slice(0, 32);
                site.set("/" + file, hash);
                await writeFile(join(directory, file), bytes);
            }
            const name = "os-encrypted-git-backup-0.0.1.pkg";
            const hashFile = async (file) => createHash("sha256").update(await readFile(join(directory, file))).digest("hex");
            nativeManifest = join(directory, "release.json");
            await writeFile(nativeManifest, JSON.stringify({
                version: "0.0.1", package: name,
                packageSha256: await hashFile(name),
                catalogueSha256: await hashFile("packagesite.pkg"),
            }));
            effectiveMarker = await hashFile("release.json");
            forward = spawn("bash", [
                fileURLToPath(new URL("./hosted-native-feed.sh", import.meta.url)),
                String(server.address().port),
            ], { stdio: "inherit" });
            await new Promise((resolve, reject) => {
                forward.once("error", reject);
                forward.once("exit", (code) => reject(new Error(`VM forward exited ${code}`)));
                setTimeout(resolve, 750);
            });
        }
        await writeFile(manifest, JSON.stringify(Object.fromEntries(site)));
        await writeFile(join(directory, "generation.json"), JSON.stringify({ digest: effectiveMarker }));
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
            ...(native ? {
                FEED_NATIVE_MANIFEST: nativeManifest,
                FEED_HISTORY: join(directory, "history.json"),
                FEED_PUBLIC_KEY: join(native, "key.pem"),
                FEED_ABI: "FreeBSD:15:amd64",
                FEED_NATIVE_SSH: "freebsd",
            } : {}),
        };
        if (native) await writeFile(env.FEED_HISTORY, "{}");
        const run = (mode = "fixture") => execute("bash", [publisher, mode], { env });

        await assert.rejects(run("production"), /Production publication requires the approved protected workflow/);
        assert.equal(journal.length, 0);
        await assert.rejects(run());
        assert.equal(journal.length, 1);
        assert.equal(assets.get(key).toString(), JSON.stringify({ digest: effectiveMarker }));
        assert.equal(pages.length, 1);
        const result = await run();
        if (native) {
            assert.match(result.stdout, /Native client verification passed and closure is recorded/);
            assert.equal(journal[1].payload.phase, "verified-closure");
            await run();
            assert.equal(journal.length, 2);
        } else {
            assert.match(result.stdout, /native client verification remains required/);
        }
        assert.equal(pages.length, 1);
        pages.push(pages[0]);
        await assert.rejects(run(), /unresolved Pages create/);
        assert.equal(journal.length, native ? 2 : 1);

        journal.length = 0;
        pages.length = 0;
        loseJournalReply = true;
        await assert.rejects(run());
        await assert.rejects(run(), /unresolved Pages create/);
        assert.equal(journal.length, 1);
        assert.equal(pages.length, 0);
    } finally {
        if (forward) forward.kill();
        await new Promise((resolve) => server.close(resolve));
        await rm(directory, { recursive: true, force: true });
    }
});
