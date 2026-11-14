#!/usr/bin/env bash
set -euo pipefail

[[ $# == 4 ]]
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
url=$1
manifest=$2
key=$3
abi=$4
bash "$root/run-feed-verifier.sh" "$url" "$manifest" "$key" "$abi"

# The predecessor catalogue is a separate path with independent trust. Its
# descriptor is part of the digest-verified release manifest.
if jq -e 'has("predecessorCatalogue")' "$manifest" >/dev/null; then
    predecessor=$(jq -cer '.predecessorCatalogue |
        select(type == "object" and (.path | type == "string" and test("^[A-Za-z0-9_-]+$")))' "$manifest")
    path=$(jq -r .path <<< "$predecessor")
    directory=$(mktemp -d)
    trap 'rm -rf -- "$directory"' EXIT
    printf '%s\n' "$predecessor" > "$directory/release.json"
    bash "$root/run-feed-verifier.sh" "$url/$path" "$directory/release.json" "${FEED_PREDECESSOR_PUBLIC_KEY:?}" "$abi"
fi
