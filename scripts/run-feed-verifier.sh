#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
[[ $# == 4 ]]
version=$(jq -er '.version | select(test("^[0-9]+[.][0-9]+[.][0-9]+([.](alpha|beta|rc)[0-9]+)?$"))' "$2")
digest=$(jq -er '.packageSha256 | select(test("^[a-f0-9]{64}$"))' "$2")
catalogue=$(jq -er '.catalogueSha256 | select(test("^[a-f0-9]{64}$"))' "$2")
if [[ -z "${FEED_NATIVE_SSH:-}" ]]; then
    exec sh "$root/feed-verify-native.sh" "$1" "$3" "$4" "$version" "$digest" "$catalogue"
fi
[[ $# == 4 && "$FEED_NATIVE_SSH" == freebsd ]]
[[ "$1" =~ ^https://[A-Za-z0-9.-]+(/[A-Za-z0-9/_-]*)?$ ]]
[[ "$4" == FreeBSD:15:amd64 ]]
remote=$(ssh -o BatchMode=yes freebsd 'mktemp -d /tmp/feed-verify.XXXXXXXX')
[[ "$remote" =~ ^/tmp/feed-verify[.][A-Za-z0-9]+$ ]]
trap 'ssh -o BatchMode=yes freebsd "rm -rf -- $remote"' EXIT
scp -q "$root/feed-verify-native.sh" "$3" "freebsd:$remote/"
key=$(basename -- "$3")
[[ "$key" =~ ^[A-Za-z0-9_.-]+$ ]]
ssh -o BatchMode=yes freebsd "sh '$remote/feed-verify-native.sh' '$1' '$remote/$key' '$4' '$version' '$digest' '$catalogue'"
