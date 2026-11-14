#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
cd "$temp"
git init -q
git -c user.name=Fixture -c user.email=fixture@example.invalid commit --allow-empty -qm fixture
sha=$(git rev-parse HEAD)
export GITHUB_REPOSITORY=fixture/plugin
workflow=vhco-pro/version-workflow/.github/workflows/version.yml@3b78b04df802ea1592cbe19338d7a882d1888389
jq -n --arg sha "$sha" --arg repo "$GITHUB_REPOSITORY" --arg workflow "$workflow" '
 {repository:$repo,workflow:$workflow,source:$sha,run:42,attempt:2,tag:"v1.2.3-rc.4",version:"1.2.3-rc.4"}
' > record.json
jq -n --arg sha "$sha" --arg repo "$GITHUB_REPOSITORY" --arg workflow "$workflow" '
 {repository:{full_name:$repo},head_sha:$sha,id:42,run_attempt:2,event:"push",conclusion:"success",
 path:".github/workflows/php.yml",referenced_workflows:[{path:$workflow,sha:($workflow|split("@")[1])}]}
' > run.json
git tag v1.2.3-rc.4
check() { bash "$root/scripts/feed-release-identity.sh" "$1" "$2" "$sha" "$3"; }
[[ "$(check record.json run.json "$sha")" == '1.2.3.rc4' ]]
for patch in '.run_attempt=1' '.conclusion="failure"' '.event="pull_request"' '.referenced_workflows=[]'; do
    jq "$patch" run.json > bad.json
    if check record.json bad.json "$sha"; then exit 1; fi
done
if check record.json run.json "$(printf '%040d' 0)"; then exit 1; fi
jq '.version="1.2.3-feature.4" | .tag="v1.2.3-feature.4"' record.json > preview.json
if check preview.json run.json "$sha"; then exit 1; fi
