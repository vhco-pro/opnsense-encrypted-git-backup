#!/usr/bin/env bash
set -euo pipefail

# The preparation job retains the bundles before the approved publisher runs.
# The publisher starts from empty storage and independently retrieves both.
[[ $# == 8 ]]
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
mode=$1
shift
if [[ "$mode" == production ]]; then
    export FEED_NATIVE_MANIFEST=retained-bundle FEED_HISTORY=$7
    source "$root/feed-publication-mode.sh" "$mode"
else
    [[ "$mode" == fixture ]]
fi
record=$1
source=$3
directory=$(mktemp -d)
trap 'rm -rf -- "$directory"' EXIT
bash "$root/feed-preflight.sh" "$@" "$directory"
export FEED_DIRECTORY="$directory/candidate"
export FEED_MANIFEST="$FEED_DIRECTORY/pages-manifest.json"
export FEED_NATIVE_MANIFEST="$FEED_DIRECTORY/release.json"
export FEED_DIGEST=$5
export FEED_RECOVERY_DIGEST=$6
export FEED_HISTORY=$7
export GITHUB_SHA=$source
jq -e --arg sha "$source" '.source == $sha' "$record" >/dev/null
bash "$root/publish-feed.sh" "$mode"
