#!/usr/bin/env bash
set -euo pipefail

# Inputs are the previously advertised path/digest manifest and a complete staged bundle.
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 advertised-packages.json generation" >&2
    exit 64
fi
bundle=$(realpath "$2")
jq -er '
  if type != "object" then error("expected path-to-digest object") else
    to_entries[]? |
    if (.key | test("^([A-Za-z0-9_-]+/)*os-encrypted-git-backup-[A-Za-z0-9._-]+[.]pkg$"))
      and (.value | type == "string" and test("^[a-f0-9]{64}$")) then
      [.key, .value] | @tsv
    else error("invalid advertised package entry") end
  end
' "$1" > /dev/null || {
    jq -e 'type == "object" and length == 0' "$1" >/dev/null || exit 1
}
records=$(jq -r 'to_entries[] | [.key, .value] | @tsv' "$1")
[[ -n "$records" ]] || exit 0
while IFS=$'\t' read -r path expected; do
    [[ -f "$bundle/$path" ]] || exit 1
    actualPath=$(realpath "$bundle/$path")
    [[ "$actualPath" == "$bundle/$path" ]] || exit 1
    actual=$(openssl dgst -sha256 -r "$actualPath" | cut -d ' ' -f 1)
    [[ "$actual" == "$expected" ]] || exit 1
done <<< "$records"
