import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdir, writeFile, copyFile, readFile } from "node:fs/promises";
import { join } from "node:path";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";

const execute = promisify(execFile);
const root = fileURLToPath(new URL("../../", import.meta.url));
const sharedSha = "3b78b04df802ea1592cbe19338d7a882d1888389";
const workflow = `vhco-pro/version-workflow/.github/workflows/version.yml@${sharedSha}`;

export async function retainFixture({ directory, endpoint, packageName, candidateFiles }) {
    const sha = (await execute("git", ["rev-parse", "HEAD"])).stdout.trim();
    const version = "0.0.1";
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
    await mkdir(join(directory, "prior"));
    await writeFile(join(directory, previous), previousBytes);
    const previousDigest = createHash("sha256").update(previousBytes).digest("hex");
    await writeFile(history, JSON.stringify({ [previous]: previousDigest }));
    const manifest = join(directory, "pages-manifest.json");
    const paths = JSON.parse(await readFile(manifest, "utf8"));
    paths["/" + previous] = previousDigest.slice(0, 32);
    await writeFile(manifest, JSON.stringify(paths));
    const recovery = join(directory, "recovery");
    await mkdir(join(recovery, "prior"), { recursive: true });
    await copyFile(join(directory, previous), join(recovery, previous));
    await copyFile(join(directory, packageName), join(recovery, packageName));
    await writeFile(join(recovery, "404.html"), "Fixture catalogue unavailable");
    const candidateTar = join(directory, "candidate.tar");
    const recoveryTar = join(directory, "recovery.tar");
    await execute("tar", ["-cf", candidateTar, "-C", directory, "prior", ...candidateFiles]);
    await execute("tar", ["-cf", recoveryTar, "-C", recovery, "404.html", "prior", packageName]);
    const shim = join(assets, "gh");
    await writeFile(shim, `#!/bin/sh
set -eu
test "$1" = release && test "$3" = v0.0.1
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
    const [candidate, recoveryDigest] = retained.stdout.trim().split("\n");
    return {
        arguments: [record, run, sha, sha, candidate, recoveryDigest, history],
        candidate, env, repo, sha, version, previous, previousDigest,
    };
}
