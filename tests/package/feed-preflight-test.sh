#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir "$tmp"/{repository,assets,bin,candidate,recovery,readback,missing}
cd "$tmp/repository"
git init -q
git -c user.name=Fixture -c user.email=fixture@example.invalid commit --allow-empty -qm fixture
export GITHUB_REPOSITORY=fixture/plugin FIXTURE_ASSETS="$tmp/assets"
export PATH="$tmp/bin:$PATH"
sha=$(git rev-parse HEAD)
git tag v1.2.3
workflow=vhco-pro/version-workflow/.github/workflows/version.yml@3b78b04df802ea1592cbe19338d7a882d1888389
jq -n --arg sha "$sha" --arg workflow "$workflow" '
 {repository:"fixture/plugin",workflow:$workflow,source:$sha,run:42,attempt:2,tag:"v1.2.3",version:"1.2.3"}
' > "$tmp/version.json"
jq -n --arg sha "$sha" --arg workflow "$workflow" '
 {repository:{full_name:"fixture/plugin"},head_sha:$sha,id:42,run_attempt:2,event:"push",conclusion:"success",
 path:".github/workflows/php.yml",referenced_workflows:[{path:$workflow,sha:($workflow|split("@")[1])}]}
' > "$tmp/run.json"
cat > "$tmp/bin/gh" <<'SH'
#!/bin/sh
set -eu
test "$1" = release && test "$3" = v1.2.3
case "$2" in
    upload) cp -n -- "$4" "$FIXTURE_ASSETS/" ;;
    download)
        test -f "$FIXTURE_ASSETS/$7"
        mkdir -p "$9"
        cp -- "$FIXTURE_ASSETS/$7" "$9/"
        ;;
    *) exit 1 ;;
esac
SH
chmod +x "$tmp/bin/gh"
package=os-encrypted-git-backup-1.2.3.pkg
printf synthetic-package > "$tmp/candidate/$package"
cp "$tmp/candidate/$package" "$tmp/recovery/"
printf synthetic-catalogue > "$tmp/candidate/packagesite.pkg"
printf bootstrap > "$tmp/recovery/404.html"
mkdir "$tmp"/{candidate,recovery}/prior
printf retained > "$tmp/candidate/prior/os-encrypted-git-backup-1.2.2.pkg"
cp "$tmp/candidate/prior/"*.pkg "$tmp/recovery/prior/"
hash() { sha256sum "$1" | cut -d ' ' -f1; }
jq -n --arg digest "$(hash "$tmp/candidate/prior/os-encrypted-git-backup-1.2.2.pkg")" \
    '{"prior/os-encrypted-git-backup-1.2.2.pkg":$digest}' > "$tmp/history.json"
jq -n --arg source "$sha" --arg package "$package" --arg packageSha256 "$(hash "$tmp/candidate/$package")" \
    --arg catalogueSha256 "$(hash "$tmp/candidate/packagesite.pkg")" \
    '{source:$source,package:$package,packageSha256:$packageSha256,catalogueSha256:$catalogueSha256,
      tag:"v1.2.3",version:"1.2.3"}' > "$tmp/candidate/release.json"
jq -n --arg digest "$(hash "$tmp/candidate/release.json")" '{digest:$digest}' > "$tmp/candidate/generation.json"
for role in candidate recovery; do
    (cd "$tmp/$role" && tar -cf "$tmp/$role.tar" *)
done
retained=$(bash "$root/scripts/retain-feed-bundles.sh" v1.2.3 "$tmp/candidate.tar" "$tmp/recovery.tar")
mapfile -t digests <<< "$retained"
preflight() {
    bash "$root/scripts/feed-preflight.sh" "$tmp/version.json" "$tmp/run.json" "$sha" "$sha" \
        "${digests[@]}" "$tmp/history.json" "$1"
}
preflight "$tmp/readback"
cmp "$tmp/recovery/$package" "$tmp/readback/recovery/$package"
# Run the dispatch entrypoint here as well: no publishing configuration is
# present in this fixture, so verified preflight must still stop before effects.
if env -u PAGES_API -u FEED_URL bash "$root/scripts/feed-dispatch.sh" fixture \
    "$tmp/version.json" "$tmp/run.json" "$sha" "$sha" "${digests[@]}" "$tmp/history.json" > "$tmp/dispatch.log" 2>&1
then
    exit 1
fi
grep -E 'GITHUB_API_URL|PAGES_API' "$tmp/dispatch.log"
rm "$tmp/assets/feed-${digests[1]}.tar"
if preflight "$tmp/missing"; then exit 1; fi
test -z "$(ls -A "$tmp/missing")"
