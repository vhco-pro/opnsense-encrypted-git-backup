import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdir, writeFile, copyFile, readFile, readdir } from "node:fs/promises";
import { dirname, join } from "node:path";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";

const execute = promisify(execFile);
const root = fileURLToPath(new URL("../../", import.meta.url));
const sharedSha = "3b78b04df802ea1592cbe19338d7a882d1888389";
const workflow = `vhco-pro/version-workflow/.github/workflows/version.yml@${sharedSha}`;

export async function retainFixture({ directory, endpoint, packageName, candidateFiles, version = "0.0.1", predecessor, previousSite, predecessorCatalogue, keySha256, overlapSite }) {
    const sha = (await execute("git", ["rev-parse", "HEAD"])).stdout.trim();
    const tag = `v${version}`;
    const repo = join(directory, "repository");
    const assets = join(directory, "bin");
    await mkdir(repo);
    await mkdir(assets);
    await execute("git", ["init", "-q", repo]);
    await execute("git", ["-C", repo, "fetch", "--depth=1", root, sha]);
    await execute("git", ["-C", repo, "checkout", "-q", "--detach", "FETCH_HEAD"]);
    await execute("git", ["-C", repo, "tag", tag]);
    const record = join(directory, "version.json");
    const run = join(directory, "run.json");
    const history = join(directory, "history.json");
    const repository = "fixture/plugin";
    await writeFile(record, JSON.stringify({ repository, workflow, source: sha, run: 42, attempt: 2, version, tag }));
    await writeFile(run, JSON.stringify({
        repository: { full_name: repository }, head_sha: sha, id: 42, run_attempt: 2, event: "push",
        conclusion: "success", path: ".github/workflows/php.yml", referenced_workflows: [{ path: workflow, sha: sharedSha }],
    }));
    const previous = "prior/os-encrypted-git-backup-0.0.0.pkg";
    const previousBytes = "synthetic previously advertised package";
    const previousDigest = createHash("sha256").update(previousBytes).digest("hex");
    let packages;
    if (predecessor) {
        const response = await fetch(`${endpoint}/bundles/history-${predecessor}.json`);
        if (!response.ok) throw new Error("Fixture could not retrieve controller history");
        packages = await response.json();
    } else {
        packages = { [previous]: previousDigest };
    }
    await writeFile(history, JSON.stringify(packages));
    const manifest = join(directory, "pages-manifest.json");
    const paths = JSON.parse(await readFile(manifest, "utf8"));
    for (const [path, digest] of Object.entries(packages)) {
        const output = join(directory, path);
        await mkdir(dirname(output), { recursive: true });
        const bytes = predecessor
            ? Buffer.from(await (await fetch(`${endpoint}/feed/${path}`)).arrayBuffer())
            : Buffer.from(previousBytes);
        await writeFile(output, bytes);
        paths["/" + path] = digest.slice(0, 32);
    }
    await writeFile(manifest, JSON.stringify(paths));
    const recovery = join(directory, "recovery");
    await mkdir(recovery);
    for (const path of [...Object.keys(packages), packageName]) {
        const output = join(recovery, path);
        await mkdir(dirname(output), { recursive: true });
        await copyFile(join(directory, path), output);
    }
    const catalogueFiles = [];
    if (previousSite) {
        const entries = await readdir(previousSite);
        const priorPackages = entries.filter((name) => /^os-encrypted-git-backup-[0-9.]+[.]pkg$/.test(name));
        if (priorPackages.length !== 1) throw new Error("Expected one package in the retained catalogue fixture");
        const [priorPackage] = priorPackages;
        const priorVersion = priorPackage.slice("os-encrypted-git-backup-".length, -".pkg".length);
        for (const path of entries) {
            if (!/^(?:meta|packagesite|data)[.](?:conf|pkg|txz)$/.test(path)) continue;
            await copyFile(join(previousSite, path), join(recovery, path));
            catalogueFiles.push(path);
        }
        const digest = async (path) => createHash("sha256").update(await readFile(join(recovery, path))).digest("hex");
        await writeFile(join(recovery, "release.json"), JSON.stringify({
            version: priorVersion, packageSha256: await digest(priorPackage),
            catalogueSha256: await digest("packagesite.pkg"),
            ...(predecessorCatalogue ? { predecessorCatalogue, keySha256 } : {}),
        }));
        catalogueFiles.push("release.json");
        if (predecessorCatalogue) {
            const overlapFiles = overlapSite
                ? (await readdir(join(overlapSite, predecessorCatalogue.path))).map((name) => predecessorCatalogue.path + "/" + name)
                : candidateFiles.filter((name) => name.startsWith(predecessorCatalogue.path + "/"));
            for (const path of overlapFiles) {
                if (catalogueFiles.includes(path) || path in packages) continue;
                const output = join(recovery, path);
                await mkdir(dirname(output), { recursive: true });
                await copyFile(overlapSite ? join(overlapSite, path) : join(directory, path), output);
                catalogueFiles.push(path);
            }
        }
    } else {
        await writeFile(join(recovery, "404.html"), "Fixture catalogue unavailable");
        catalogueFiles.push("404.html");
    }
    const candidateTar = join(directory, "candidate.tar");
    const recoveryTar = join(directory, "recovery.tar");
    await execute("tar", ["-cf", candidateTar, "-C", directory, ...Object.keys(packages), ...candidateFiles]);
    await writeFile(join(recovery, "generation.json"), JSON.stringify({ recoveryOf: sha, version }));
    const recoveryPaths = {};
    const recoveryFiles = [...catalogueFiles, "generation.json", ...Object.keys(packages), packageName];
    for (const path of recoveryFiles) {
        recoveryPaths["/" + path] = createHash("sha256").update(await readFile(join(recovery, path))).digest("hex").slice(0, 32);
    }
    await writeFile(join(recovery, "pages-manifest.json"), JSON.stringify(recoveryPaths));
    await execute("tar", ["-cf", recoveryTar, "-C", recovery, "pages-manifest.json", ...recoveryFiles]);
    const shim = join(assets, "gh");
    await writeFile(shim, `#!/bin/sh
set -eu
test "$1" = release
case "$3" in v0.0.[1-6]) ;; *) exit 1 ;; esac
case "$2" in
    upload)
        test "$5 $6" = "--repo fixture/plugin"
        curl -fsS -o /dev/null -X PUT --data-binary "@$4" "$FIXTURE_RELEASE_ENDPOINT/bundles/$(basename "$4")"
        ;;
    download)
        test "$4 $5 $6 $8" = "--repo fixture/plugin --pattern --dir"
        mkdir -p "$9"
        curl -fsS "$FIXTURE_RELEASE_ENDPOINT/bundles/$7" -o "$9/$7"
        ;;
    *) exit 1 ;;
esac
`, { mode: 0o700 });
    const env = { PATH: assets + ":" + process.env.PATH, GITHUB_REPOSITORY: repository,
        FIXTURE_RELEASE_ENDPOINT: endpoint };
    const retained = await execute("bash", [
        join(root, "scripts/retain-feed-bundles.sh"), tag, candidateTar, recoveryTar,
    ], { env: { ...process.env, ...env }, cwd: repo });
    const historyBytes = JSON.stringify({ [previous]: previousDigest }) + "\n";
    const historyDigest = createHash("sha256").update(historyBytes).digest("hex");
    const historyAsset = join(directory, `history-${historyDigest}.json`);
    await writeFile(historyAsset, historyBytes);
    if (!predecessor) await execute(shim, ["release", "upload", tag, historyAsset, "--repo", repository],
        { env: { ...process.env, ...env }, cwd: repo });
    const [candidate, recoveryDigest] = retained.stdout.trim().split("\n");
    return {
        arguments: [record, run, sha, sha, candidate, recoveryDigest, history],
        candidate, env, repo, sha, version, previous, previousDigest, historyDigest,
    };
}
