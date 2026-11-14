#!/usr/bin/env bash
set -euo pipefail

# This preparation phase uses an asset-writer token. The publisher retrieves
# these immutable-by-digest assets with a separate read-only repository token.
[[ $# == 3 ]]
release=$1
candidate=$(realpath "$2")
recovery=$(realpath "$3")
[[ "$release" =~ ^v[0-9]+[.][0-9]+[.][0-9]+(-(alpha|beta|rc)[.][0-9]+)?$ ]]
repo=${GITHUB_REPOSITORY:?}
umask 077
temporary=$(mktemp -d)
trap 'rm -rf -- "$temporary"' EXIT
for archive in "$candidate" "$recovery"; do
    digest=$(sha256sum -- "$archive" | cut -d ' ' -f 1)
    path="$temporary/feed-$digest.tar"
    cp -- "$archive" "$path"
    if ! gh release download "$release" --repo "$repo" --pattern "feed-$digest.tar" --dir "$temporary/readback"; then
        gh release upload "$release" "$path" --repo "$repo" >&2
        gh release download "$release" --repo "$repo" --pattern "feed-$digest.tar" --dir "$temporary/readback"
    fi
    cmp -- "$path" "$temporary/readback/feed-$digest.tar"
    rm -- "$temporary/readback/feed-$digest.tar"
    printf '%s\n' "$digest"
done
