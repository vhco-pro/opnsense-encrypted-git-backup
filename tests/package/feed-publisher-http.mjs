import assert from "node:assert/strict";
import { execFile, spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdir, mkdtemp, rm, writeFile, readFile, readdir } from "node:fs/promises";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";
import { retainFixture } from "./feed-http-inputs.mjs";

const execute = promisify(execFile);
const dispatch = fileURLToPath(new URL("../../scripts/feed-dispatch.sh", import.meta.url));
const publisher = fileURLToPath(new URL("../../scripts/publish-feed.sh", import.meta.url));

test("publisher holds ambiguous responses and reconciles one live deployment", async () => {
    const native = process.env.NATIVE_FEED_DIRECTORY && resolve(process.env.NATIVE_FEED_DIRECTORY);
    const journal = [];
    const pages = [];
    let historyAnchor;
    const digest = createHash("sha256").update("fixture generation").digest("hex");
    const assets = new Map();
    const bundles = new Map();
    const downloaded = [];
    const key = "a".repeat(32);
    const sites = [];
    const site = new Map([["/generation.json", key]]);
    let loseJournalReply = false;
    let truncatedJournal = false;
    let nextOutcome = "success";
    let dropBeforeCreate = false;
    let createRequests = 0;
    let loseClosureReply = false;
    let loseHistoryReply = false;

    const server = createServer(async (request, response) => {
        const path = new URL(request.url, "http://localhost").pathname;
        const reply = (status, value) => response.writeHead(status, {
            "Content-Type": "application/json",
        }).end(JSON.stringify(value));

        if (request.method === "GET") {
            if (bundles.has(path)) {
                downloaded.push(path);
                return response.writeHead(200).end(bundles.get(path));
            }
            if (path === "/repos/fixture/plugin/deployments") {
                if (truncatedJournal) response.setHeader("Link", '<http://127.0.0.1/next>; rel="next"');
                return reply(200, historyAnchor ? [historyAnchor, ...journal] : journal);
            }
            if (path === "/pages/upload-token") return reply(200, { success: true, result: { jwt: "fixture-jwt" } });
            if (path === "/pages/deployments") return reply(200, { success: true, result: pages });
            if (path === "/pages") {
                return reply(200, { success: true, result: { canonical_deployment: pages.at(-1) ?? null } });
            }
            if (path.startsWith("/feed/") && pages.length && sites.at(-1)?.has(path.slice(5))) {
                return response.writeHead(200).end(assets.get(sites.at(-1).get(path.slice(5))));
            }
            return reply(404, {});
        }

        const chunks = [];
        for await (const chunk of request) chunks.push(chunk);
        const bytes = Buffer.concat(chunks);
        if (request.method === "PUT" && /^\/bundles\/(?:feed-[a-f0-9]{64}[.]tar|history-[a-f0-9]{64}[.]json)$/.test(path)) {
            if (bundles.has(path)) return reply(409, {});
            if (!path.includes(createHash("sha256").update(bytes).digest("hex"))) return reply(422, {});
            bundles.set(path, bytes);
            if (loseHistoryReply && path.includes("/history-")) {
                loseHistoryReply = false;
                return request.socket.destroy();
            }
            return reply(201, {});
        }
        const body = bytes.toString();
        if (path === "/repos/fixture/plugin/deployments") {
            const record = JSON.parse(body);
            if (record.auto_merge !== false || record.environment !== "feed-fixture") return reply(422, {});
            const entry = { id: journal.length + 1, sha: record.ref, payload: record.payload };
            journal.push(entry);
            if (loseJournalReply || (loseClosureReply && entry.payload.phase === "verified-closure")) {
                loseClosureReply = false;
                return request.socket.destroy();
            }
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
        if (path !== "/pages/deployments" || !attempt) return reply(422, {});
        const submitted = body.match(/name="manifest"\r\n\r\n([^\r\n]+)\r\n/)?.[1];
        if (!submitted) return reply(422, {});
        const paths = new Map(Object.entries(JSON.parse(submitted)));
        if (![...paths.values()].every((hash) => assets.has(hash))) return reply(422, {});
        if (!journal.some((entry) => `feed-attempt:${entry.payload.attempt}` === attempt)) return reply(422, {});
        createRequests++;
        if (dropBeforeCreate) return request.socket.destroy();
        const status = nextOutcome;
        nextOutcome = "success";
        sites.push(paths);
        pages.push({
            id: `fixture-deployment-${pages.length + 1}`,
            environment: "production",
            deployment_trigger: { metadata: { commit_message: attempt } },
            latest_stage: { name: "deploy", status, ended_on: "2026-01-01" },
        });
        request.socket.destroy();
    });
    await new Promise((resolve, reject) => {
        server.once("error", reject);
        server.listen(0, "127.0.0.1", resolve);
    });
    const directory = await mkdtemp(join(tmpdir(), "feed-http-"));
    let forward;
    let cacheDirectory;
    try {
        const url = `http://127.0.0.1:${server.address().port}`;
        const cachedClient = (action, version, digest, work = cacheDirectory, path = "/feed") => execute("ssh", [
            "-o", "BatchMode=yes", "freebsd", "sh", "-x", work + "/feed-cached-client.sh",
            action, work, url + path, work + "/key.pem", version, digest,
        ]);
        const newCache = async (key = "key.pem") => {
            const result = await execute("ssh", ["-o", "BatchMode=yes", "freebsd", "mktemp -d /tmp/feed-cache.XXXXXXXX"]);
            const work = result.stdout.trim();
            assert.match(work, /^\/tmp\/feed-cache[.][a-zA-Z0-9]+$/);
            await execute("scp", ["-q", fileURLToPath(new URL("./feed-cached-client.sh", import.meta.url)),
                `freebsd:${work}/`]);
            await execute("scp", ["-q", join(native, key), `freebsd:${work}/key.pem`]);
            return work;
        };
        const manifest = join(directory, "pages-manifest.json");
        let fixture;
        let nativeManifest;
        let effectiveMarker = digest;
        let candidateFiles;
        if (native) {
            const files = await readdir(join(native, "site"));
            candidateFiles = ["release.json", "generation.json", "pages-manifest.json"];
            for (const file of files) {
                if (!/^[a-zA-Z0-9_.-]+$/.test(file)) continue;
                const bytes = await readFile(join(native, "site", file));
                const hash = createHash("sha256").update(bytes).digest("hex").slice(0, 32);
                site.set("/" + file, hash);
                await writeFile(join(directory, file), bytes);
                candidateFiles.push(file);
            }
            const name = "os-encrypted-git-backup-0.0.1.pkg";
            const hashFile = async (file) => createHash("sha256").update(await readFile(join(directory, file))).digest("hex");
            nativeManifest = join(directory, "release.json");
            await writeFile(nativeManifest, JSON.stringify({
                source: (await execute("git", ["rev-parse", "HEAD"])).stdout.trim(),
                tag: "v0.0.1", version: "0.0.1", package: name,
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
        if (native) {
            fixture = await retainFixture({
                directory, endpoint: url, packageName: "os-encrypted-git-backup-0.0.1.pkg", candidateFiles,
            });
            site.set("/" + fixture.previous, fixture.previousDigest.slice(0, 32));
            const packages = { [fixture.previous]: fixture.previousDigest };
            const canonical = JSON.stringify(packages) + "\n";
            historyAnchor = { sha: fixture.sha, payload: {
                phase: "history-checkpoint", packages, release: "v0.0.1",
                digest: createHash("sha256").update(canonical).digest("hex"),
            } };
            downloaded.length = 0;
        }
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
                ...fixture.env,
                FEED_PUBLIC_KEY: join(native, "key.pem"),
                FEED_ABI: "FreeBSD:15:amd64",
                FEED_NATIVE_SSH: "freebsd",
            } : {}),
        };
        const run = (mode = "fixture", overrides = {}) => {
            const options = { env: { ...env, ...fixture?.env, ...overrides } };
            return fixture
                ? execute("bash", [dispatch, mode, ...fixture.arguments], { ...options, cwd: fixture.repo })
                : execute("bash", [publisher, mode], options);
        };

        await assert.rejects(run("production"), /Production publication requires the approved protected workflow/);
        assert.equal(journal.length, 0);
        truncatedJournal = true;
        await assert.rejects(run(), /supported complete-read bound/);
        truncatedJournal = false;
        assert.equal(createRequests, 0);
        assert.equal(assets.size, 0);
        if (native) {
            const anchor = historyAnchor;
            historyAnchor = undefined;
            await assert.rejects(run(), /missing authoritative history checkpoint/);
            historyAnchor = { ...anchor, payload: { ...anchor.payload, digest: "0".repeat(64) } };
            await assert.rejects(run(), /retained history checkpoint changed/);
            historyAnchor = anchor;
            const historyPath = `/bundles/history-${fixture.historyDigest}.json`;
            const history = bundles.get(historyPath);
            bundles.set(historyPath, Buffer.from("{}"));
            await assert.rejects(run());
            bundles.set(historyPath, history);
            assert.equal(journal.length, 0);
            assert.equal(assets.size, 0);
            downloaded.length = 0;
        }
        await assert.rejects(run(), (error) => {
            assert.match(error.stderr, /curl: [(]52[)]/, error.stderr);
            return true;
        });
        assert.equal(journal.length, 1);
        assert.equal(assets.get(key).toString(), JSON.stringify({ digest: effectiveMarker }));
        assert.equal(pages.length, 1);
        if (native) {
            loseHistoryReply = true;
            await assert.rejects(run(), /curl: [(]52[)]/);
            assert.equal(journal.length, 1);
            loseClosureReply = true;
            await assert.rejects(run(), /curl: [(]52[)]/);
            assert.equal(journal.length, 2);
        }
        const result = await run();
        if (native) {
            assert.match(result.stdout, /Native client verification passed and closure is recorded/);
            assert.equal(journal[1].payload.phase, "verified-closure");
            assert.equal(journal[1].sha, fixture.sha);
            assert.equal(journal[1].payload.version, fixture.version);
            assert.equal(journal[1].payload.digest, fixture.candidate);
            assert.equal(journal[1].payload.deployment, pages[0].id);
            const packages = journal[0].payload.packages;
            const ordered = Object.fromEntries(Object.entries(packages).sort(([a], [b]) => a < b ? -1 : 1));
            assert.equal(journal[1].payload.history,
                createHash("sha256").update(JSON.stringify(ordered) + "\n").digest("hex"));
            assert.equal(journal[0].payload.packages[fixture.previous], fixture.previousDigest);
            assert.equal(downloaded.filter((path) => path === `/bundles/history-${journal[1].payload.history}.json`).length, 2);
            const retained = await fetch(url + "/feed/" + fixture.previous);
            assert.equal(createHash("sha256").update(Buffer.from(await retained.arrayBuffer())).digest("hex"),
                fixture.previousDigest);
            await run();
            assert.equal(journal.length, 2);
            const headPath = `/bundles/history-${journal[1].payload.history}.json`;
            const headBytes = bundles.get(headPath);
            bundles.delete(headPath);
            await assert.rejects(run());
            assert.equal(bundles.has(headPath), false);
            bundles.set(headPath, Buffer.from("{}"));
            await assert.rejects(run());
            assert.equal(bundles.get(headPath).toString(), "{}");
            bundles.set(headPath, headBytes);
            const previousDigest = journal[0].payload.packages[fixture.previous];
            delete journal[0].payload.packages[fixture.previous];
            await assert.rejects(run(), /submission history does not extend/);
            assert.equal(journal.length, 2);
            journal[0].payload.packages[fixture.previous] = previousDigest;
            const closure = journal.pop();
            await assert.rejects(run("fixture", { FEED_ABI: "FreeBSD:15:aarch64" }));
            assert.equal(journal.length, 1);
            const packageKey = site.get("/os-encrypted-git-backup-0.0.1.pkg");
            const original = assets.get(packageKey);
            assets.set(packageKey, Buffer.concat([original, Buffer.from("mutation")]));
            await assert.rejects(run());
            assert.equal(journal.length, 1);
            assets.set(packageKey, original);
            const previousKey = site.get("/" + fixture.previous);
            const retainedBytes = assets.get(previousKey);
            assets.delete(previousKey);
            await assert.rejects(run());
            assert.equal(journal.length, 1);
            assets.set(previousKey, retainedBytes);
            journal.push(closure);
        } else {
            assert.match(result.stdout, /native client verification remains required/);
        }
        assert.equal(pages.length, 1);
        pages.push(pages[0]);
        await assert.rejects(run(), /unresolved Pages create/);
        assert.equal(journal.length, native ? 2 : 1);
        pages.pop();

        const firstFixture = fixture;
        if (native) {
            const initial = assets.get(site.get("/os-encrypted-git-backup-0.0.1.pkg"));
            let overlap;
            const operatorKey = join(directory, "operator.pem");
            const operatorPublic = join(directory, "operator-public.pem");
            await execute("openssl", ["genrsa", "-out", operatorKey, "2048"]);
            await execute("openssl", ["pkey", "-in", operatorKey, "-pubout", "-out", operatorPublic]);
            const keyDigest = async (path) => createHash("sha256").update((await execute("openssl",
                ["pkey", "-pubin", "-in", path, "-outform", "DER"], { encoding: "buffer" })).stdout).digest("hex");
            for (const number of [2, 3, 4, 5, 6]) {
                const next = join(directory, `generation-${number}`);
                const version = `0.0.${number}`;
                const packageName = `os-encrypted-git-backup-${version}.pkg`;
                const candidateFiles = ["release.json", "generation.json", "pages-manifest.json"];
                const paths = {};
                await mkdir(next);
                for (const file of await readdir(join(native, `site-${number}`))) {
                    const bytes = await readFile(join(native, `site-${number}`, file));
                    await writeFile(join(next, file), bytes);
                    paths["/" + file] = createHash("sha256").update(bytes).digest("hex").slice(0, 32);
                    candidateFiles.push(file);
                }
                const hashFile = async (file) => createHash("sha256").update(await readFile(join(next, file))).digest("hex");
                const release = {
                    source: fixture.sha, tag: `v${version}`, version, package: packageName,
                    packageSha256: await hashFile(packageName), catalogueSha256: await hashFile("packagesite.pkg"),
                };
                if (number === 4) {
                    release.keySha256 = await keyDigest(join(native, "next-key.pem"));
                    await mkdir(join(next, "prior-key"));
                    for (const file of await readdir(join(native, "site-3"))) {
                        const relativePath = "prior-key/" + file;
                        const bytes = await readFile(join(native, "site-3", file));
                        await writeFile(join(next, relativePath), bytes);
                        paths["/" + relativePath] = createHash("sha256").update(bytes).digest("hex").slice(0, 32);
                        candidateFiles.push(relativePath);
                    }
                    release.predecessorCatalogue = {
                        path: "prior-key", version: "0.0.3", keySha256: await keyDigest(join(native, "key.pem")),
                        packageSha256: await hashFile("prior-key/os-encrypted-git-backup-0.0.3.pkg"),
                        catalogueSha256: await hashFile("prior-key/packagesite.pkg"),
                    };
                }
                if (number === 4) overlap = release;
                if (number === 5) {
                    const trust = { before: overlap.predecessorCatalogue.keySha256, after: overlap.keySha256 };
                    release.retirement = { path: "prior-key", operatorKey: await keyDigest(operatorPublic),
                        clients: { alpha: trust, beta: trust } };
                }
                await writeFile(join(next, "release.json"), JSON.stringify(release));
                const marker = JSON.stringify({ digest: await hashFile("release.json") });
                await writeFile(join(next, "generation.json"), marker);
                paths["/generation.json"] = createHash("sha256").update(marker).digest("hex").slice(0, 32);
                await writeFile(join(next, "pages-manifest.json"), JSON.stringify(paths));
                const previous = journal.at(-1);
                fixture = await retainFixture({ directory: next, endpoint: url, packageName,
                    candidateFiles, version, predecessor: previous.payload.history,
                    previousSite: join(native, number === 2 ? "site" : number === 6 ? "site-5" : number >= 4 ? "site-3-recovery" : "site-2"),
                    predecessorCatalogue: number === 4 || number === 5 ? overlap.predecessorCatalogue : undefined,
                    keySha256: number >= 4 ? overlap.keySha256 : undefined,
                    overlapSite: number === 5 ? join(directory, "generation-4") : undefined,
                });
                // Before each dispatch only the controller's predecessor is retained.
                if (number === 4 || number === 6) nextOutcome = "failure";
                const retirementEnv = {
                    FEED_RETIREMENT_AUTHORIZED: "true", FEED_PUBLIC_KEY: join(native, "next-key.pem"),
                    FEED_PREDECESSOR_PUBLIC_KEY: join(native, "key.pem"),
                };
                if (number === 5) {
                    cacheDirectory = await newCache();
                    await cachedClient("cache", "0.0.3", overlap.predecessorCatalogue.packageSha256,
                        cacheDirectory, "/feed/prior-key");
                    const calls = createRequests;
                    await assert.rejects(run());
                    assert.equal(createRequests, calls);
                }
                await assert.rejects(run("fixture", number >= 5 ? retirementEnv : {}), /curl: [(]52[)]/);
                assert.equal(journal.at(-1).payload.predecessor, previous.payload.attempt);
                assert.equal(journal.at(-1).payload.history, previous.payload.history);
                if (number === 4) {
                    cacheDirectory = await newCache("next-key.pem");
                    await cachedClient("cache", version, await hashFile(packageName));
                    await execute("bash", [
                        fileURLToPath(new URL("../../scripts/verify-feed-generation.sh", import.meta.url)),
                        url + "/feed", join(next, "release.json"), join(native, "next-key.pem"), "FreeBSD:15:amd64",
                    ], { env: { ...env, FEED_PREDECESSOR_PUBLIC_KEY: join(native, "key.pem") } });
                    await assert.rejects(execute("bash", [
                        fileURLToPath(new URL("../../scripts/verify-feed-generation.sh", import.meta.url)),
                        url + "/feed", join(next, "release.json"), join(native, "key.pem"), "FreeBSD:15:amd64",
                    ], { env: { ...env, FEED_PREDECESSOR_PUBLIC_KEY: join(native, "key.pem") } }));
                    const calls = createRequests;
                    await assert.rejects(run());
                    assert.equal(createRequests, calls);
                    const authorized = {
                        FEED_RECOVERY_AUTHORIZED: "true", GITHUB_RUN_ID: "60",
                        FEED_PUBLIC_KEY: join(native, "next-key.pem"),
                        FEED_PREDECESSOR_PUBLIC_KEY: join(native, "key.pem"),
                    };
                    await assert.rejects(run("fixture", authorized), /curl: [(]52[)]/);
                    assert.equal(journal.at(-2).payload.phase, "recovery-required");
                    assert.equal(journal.at(-3).payload.packages["prior-key/os-encrypted-git-backup-0.0.3.pkg"],
                        release.predecessorCatalogue.packageSha256);
                    assert.match((await run("fixture", authorized)).stdout, /closure is recorded/);
                    await cachedClient("fetch", version, await hashFile(packageName));
                    await execute("ssh", ["-o", "BatchMode=yes", "freebsd", "rm -rf -- " + cacheDirectory]);
                    cacheDirectory = undefined;
                } else if (number === 5) {
                    const candidate = journal.at(-1);
                    const available = sites.at(-1);
                    const old = "/prior-key/packagesite.pkg";
                    const earlier = sites.at(-2).get(old);
                    available.set(old, earlier);
                    const calls = createRequests;
                    await assert.rejects(run("fixture", retirementEnv), /withdrawal could not be verified/);
                    assert.equal(createRequests, calls);
                    available.delete(old);
                    await assert.rejects(run("fixture", retirementEnv), /Trust finalization is pending/);
                    assert.equal(journal.at(-1).payload.phase, "trust-finalization-pending");
                    const evidence = join(next, "operator-evidence.json");
                    const signature = join(next, "operator-evidence.sig");
                    const attest = async (clients, observedAt = Math.floor(Date.now() / 1000)) => {
                        await writeFile(evidence, JSON.stringify({
                            attempt: candidate.payload.attempt, deployment: pages.at(-1).id,
                            digest: candidate.payload.digest, scope: journal.at(-1).payload.scope, observedAt, clients,
                        }));
                        await execute("openssl", ["dgst", "-sha256", "-sign", operatorKey, "-out", signature, evidence]);
                    };
                    const evidenceEnv = { ...retirementEnv, FEED_OPERATOR_KEY: operatorPublic,
                        FEED_OPERATOR_EVIDENCE: evidence, FEED_OPERATOR_SIGNATURE: signature };
                    await attest({ alpha: overlap.keySha256 });
                    await assert.rejects(run("fixture", evidenceEnv));
                    const clients = { alpha: overlap.keySha256, beta: overlap.keySha256 };
                    await attest(clients, Math.floor(Date.now() / 1000) - 901);
                    await assert.rejects(run("fixture", evidenceEnv));
                    await attest(clients);
                    assert.match((await run("fixture", evidenceEnv)).stdout, /closure is recorded/);
                    assert.equal(createRequests, calls);
                    await cachedClient("fetch", "0.0.3", overlap.predecessorCatalogue.packageSha256,
                        cacheDirectory, "/feed/prior-key");
                    await execute("ssh", ["-o", "BatchMode=yes", "freebsd", "rm -rf -- " + cacheDirectory]);
                    cacheDirectory = undefined;
                } else if (number === 6) {
                    const authorized = { ...retirementEnv, FEED_RECOVERY_AUTHORIZED: "true", GITHUB_RUN_ID: "62" };
                    await assert.rejects(run("fixture", authorized), /curl: [(]52[)]/);
                    assert.match((await run("fixture", authorized)).stdout, /closure is recorded/);
                    assert.equal(journal.at(-1).payload.withdrawn, "prior-key");
                    assert.equal((await fetch(url + "/feed/prior-key/packagesite.pkg")).status, 404);
                    const path = "/feed/prior-key/os-encrypted-git-backup-0.0.3.pkg";
                    const cached = await fetch(url + path);
                    assert.equal(createHash("sha256").update(Buffer.from(await cached.arrayBuffer())).digest("hex"),
                        overlap.predecessorCatalogue.packageSha256);
                } else {
                    assert.match((await run()).stdout, /closure is recorded/);
                }
                assert.equal(journal.at(-1).payload.version, version);
                const cached = await fetch(url + "/feed/os-encrypted-git-backup-0.0.1.pkg");
                assert.deepEqual(Buffer.from(await cached.arrayBuffer()), initial);
            }
        }

        if (native) {
            // A separate bootstrap project starts with the same approved retained bytes.
            fixture = firstFixture;
            journal.length = 0;
            pages.length = 0;
            sites.length = 0;
            nextOutcome = "failure";
            await assert.rejects(run(), /curl: [(]52[)]/);
            const candidate = journal.at(-1).payload.attempt;
            cacheDirectory = await newCache();
            const approvedPackage = JSON.parse(await readFile(nativeManifest, "utf8")).packageSha256;
            await cachedClient("cache", "0.0.1", approvedPackage);
            nextOutcome = "failure";
            const authorized = { FEED_RECOVERY_AUTHORIZED: "true", GITHUB_RUN_ID: "70" };
            await assert.rejects(run("fixture", authorized), /curl: [(]52[)]/);
            assert.equal(journal[1].payload.phase, "recovery-required");
            assert.equal(journal[1].payload.candidate, candidate);
            assert.equal(journal[2].payload.phase, "recovery-started");
            assert.equal((await fetch(url + "/feed/packagesite.pkg")).status, 404);
            await cachedClient("fetch", "0.0.1", approvedPackage);
            const packagePath = "/os-encrypted-git-backup-0.0.1.pkg";
            const packageKey = sites.at(-1).get(packagePath);
            const original = assets.get(packageKey);
            assert.deepEqual(Buffer.from(await (await fetch(url + "/feed" + packagePath)).arrayBuffer()), original);
            let requests = createRequests;
            await assert.rejects(run("fixture", authorized), /manual diagnosis/);
            assert.equal(createRequests, requests);
            assets.set(packageKey, Buffer.from("corrupt recovery"));
            nextOutcome = "failure";
            await assert.rejects(run("fixture", authorized), /curl: [(]52[)]/);
            const retry = journal.at(-1).payload;
            assert.equal(retry.dispatch, "70");
            assert.equal(retry.digest, journal[2].payload.digest);
            assets.set(packageKey, Buffer.from("corrupt recovery"));
            requests = createRequests;
            await assert.rejects(run("fixture", authorized), /already consumed/);
            assert.equal(createRequests, requests);
            const second = { ...authorized, GITHUB_RUN_ID: "71" };
            await assert.rejects(run("fixture", second), /curl: [(]52[)]/);
            assert.equal(journal.at(-1).payload.dispatch, "71");
            assert.match((await run("fixture", second)).stdout, /closure is recorded/);
        }

        if (native) {
            fixture = firstFixture;
            journal.length = 0;
            pages.length = 0;
            sites.length = 0;
            dropBeforeCreate = true;
            await assert.rejects(run(), /curl: [(]52[)]/);
            const requests = createRequests;
            await assert.rejects(run(), /unresolved Pages create/);
            assert.equal(createRequests, requests);
            assert.equal(pages.length, 0);

            // Reset only the owned fixture project. The recovery request can
            // be ambiguous before it has created a Pages deployment as well.
            journal.length = 0;
            dropBeforeCreate = false;
            nextOutcome = "failure";
            await assert.rejects(run(), /curl: [(]52[)]/);
            dropBeforeCreate = true;
            const authorized = { FEED_RECOVERY_AUTHORIZED: "true", GITHUB_RUN_ID: "90" };
            await assert.rejects(run("fixture", authorized), /curl: [(]52[)]/);
            const recoveryRequests = createRequests;
            await assert.rejects(run("fixture", { ...authorized, GITHUB_RUN_ID: "91" }), /unresolved Pages create/);
            assert.equal(createRequests, recoveryRequests);
            assert.equal(journal.at(-1).payload.phase, "recovery-started");
            dropBeforeCreate = false;
        }

        fixture = firstFixture;
        journal.length = 0;
        sites.length = 0;
        pages.length = 0;
        loseJournalReply = true;
        await assert.rejects(run());
        await assert.rejects(run(), /unresolved Pages create/);
        assert.equal(journal.length, 1);
        assert.equal(pages.length, 0);
    } finally {
        if (cacheDirectory) {
            await execute("ssh", ["-o", "BatchMode=yes", "freebsd", "rm -rf -- " + cacheDirectory]);
        }
        if (forward) forward.kill();
        await new Promise((resolve) => server.close(resolve));
        await rm(directory, { recursive: true, force: true });
    }
});
