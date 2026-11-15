import { createHash } from "node:crypto";
import { readFile, realpath, stat } from "node:fs/promises";
import { extname, resolve, sep } from "node:path";

// The manifest's BLAKE3 keys are produced during bundle preparation. The
// approved bundle digest and served-file verification are separate SHA-256 checks.
const [mode, ...args] = process.argv.slice(2);
const checking = mode === "--validate";
const [directory, manifestFile] = checking ? args : args.slice(1);
const [project, assetApi] = checking ? [] : [mode, args[0]];
if (args.length !== (checking ? 2 : 3)) throw new Error("Invalid Pages asset arguments");
const manifest = JSON.parse(await readFile(manifestFile, "utf8"));
const root = await realpath(directory);
const paths = Object.entries(manifest);
if (paths.length === 0 || paths.length > 20_000) throw new Error("Invalid Pages manifest size");

async function call(url, token, payload) {
    const response = await fetch(url, {
        method: payload === undefined ? "GET" : "POST",
        headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
        body: payload === undefined ? undefined : JSON.stringify(payload),
        redirect: "error",
        signal: AbortSignal.timeout(60_000),
    });
    if (!response.ok) throw new Error(`Pages request failed (${response.status})`);
    const body = await response.json();
    if (body.success !== true) throw new Error("Pages asset API did not confirm success");
    return body.result;
}

const files = new Map();
const repeatedDigests = new Map();
const digest = async (file) => createHash("sha256").update(await readFile(file)).digest("hex");
for (const [path, key] of paths) {
    if (!/^\/(?:[a-zA-Z0-9_.-]+\/)*[a-zA-Z0-9_.-]+$/.test(path) ||
        path.split("/").some((part) => part === "." || part === "..") ||
        !/^[a-f0-9]{32}$/.test(key)) throw new Error("Invalid Pages manifest entry");
    const file = resolve(root, "." + path);
    if (!file.startsWith(root + sep) || await realpath(file) !== file) throw new Error("Unsafe Pages asset");
    const info = await stat(file);
    if (!info.isFile() || info.size > 25 * 1024 * 1024) throw new Error("Invalid Pages asset size");
    if (!files.has(key)) {
        files.set(key, file);
    } else {
        const existing = repeatedDigests.get(key) ?? await digest(files.get(key));
        if (existing !== await digest(file)) throw new Error("Pages asset key maps to different file bytes");
        repeatedDigests.set(key, existing);
    }
}
if (checking) process.exit(0);

const upload = await call(project + "/upload-token", process.env.PAGES_TOKEN);
if (typeof upload?.jwt !== "string" || !upload.jwt) throw new Error("Missing Pages upload token");
for (const [key, file] of files) {
    const contentType = extname(file) === ".json" ? "application/json" :
        extname(file) === ".html" ? "text/html; charset=utf-8" : "application/octet-stream";
    await call(assetApi + "/upload", upload.jwt, [{
        key, value: (await readFile(file)).toString("base64"),
        metadata: { contentType }, base64: true,
    }]);
}
await call(assetApi + "/upsert-hashes", upload.jwt, { hashes: [...files.keys()] });
