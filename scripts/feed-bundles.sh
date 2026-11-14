#!/usr/bin/env bash
set -euo pipefail

# Retrieve approved immutable bytes with a read-only repository token.
# No fallback to the mutable staging deployment or the runner's previous files.
[[ $# == 4 ]]
release=$1
candidate=$2
recovery=$3
destination=$4
[[ "$release" =~ ^v[0-9]+[.][0-9]+[.][0-9]+(-(alpha|beta|rc)[.][0-9]+)?$ ]]
for digest in "$candidate" "$recovery"; do
    [[ "$digest" =~ ^[a-f0-9]{64}$ ]]
done
[[ "$candidate" != "$recovery" ]]
umask 077
temporary=$(mktemp -d "$destination/.feed-download.XXXXXXXX")
trap 'rm -rf -- "$temporary"' EXIT
for digest in "$candidate" "$recovery"; do
    asset="feed-$digest.tar"
    gh release download "$release" --repo "${GITHUB_REPOSITORY:?}" --pattern "$asset" --dir "$temporary"
    printf '%s  %s\n' "$digest" "$temporary/$asset" | sha256sum --check --status
done
for digest in "$candidate" "$recovery"; do
    mv -- "$temporary/feed-$digest.tar" "$destination/feed-$digest.tar"
done
