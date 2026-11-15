#!/usr/bin/env bash
set -euo pipefail

if [[ $# != 4 ]]; then
    echo "Usage: $0 version-record.json run-attempt.json reviewed-source exact-remote-tag-sha" >&2
    exit 64
fi
record=$1
attempt=$2
source_sha=$3
tag_sha=$4
[[ "$source_sha" == "$tag_sha" && "$source_sha" =~ ^[a-f0-9]{40}$ ]]
repo=${GITHUB_REPOSITORY:?}
workflow=vhco-pro/version-workflow/.github/workflows/version.yml@3b78b04df802ea1592cbe19338d7a882d1888389
[[ $(jq -s 'length' "$attempt") == 1 && $(jq -s 'length' "$record") == 1 ]]
version=$(jq -er --slurpfile runs "$attempt" --arg repo "$repo" --arg workflow "$workflow" --arg sha "$source_sha" '
    . as $record | $runs[0] as $run |
    select(
        .repository == $repo and .workflow == $workflow and .source == $sha
        and .run == $run.id and .attempt == $run.run_attempt
        and $run.repository.full_name == $repo and $run.head_sha == $sha
        and $run.event == "push" and $run.conclusion == "success"
        and $run.path == ".github/workflows/php.yml"
        and .tag == ("v" + .version)
        and any($run.referenced_workflows[]?; .path == $workflow
            and .sha == ($workflow | split("@")[1]))
    ) | $record.version
' "$record")
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bash "$root/package-version.sh" "$version" "$source_sha" "v$version"
