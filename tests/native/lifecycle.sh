#!/bin/sh
# Synthetic fixture. The caller supplies the already-built current package.
set -eu
artifact=$1
umask 077
state=/conf/encrypted-git-backup
test -s "$state/activation.json"
before=$(sha256 -q "$state/activation.json")
pkg delete -y os-encrypted-git-backup
test "$(sha256 -q "$state/activation.json")" = "$before"
if pkg info -e os-encrypted-git-backup; then
    echo 'The package remained installed.' >&2
    exit 1
fi
pkg add "$artifact"
test "$(sha256 -q "$state/activation.json")" = "$before"
service configd restart
ready=
for attempt in $(jot 15); do
    if timeout 2 configctl encryptedgit status 2>/dev/null |
        php -r 'exit(is_array(json_decode(stream_get_contents(STDIN), true)) ? 0 : 1);'; then
        ready=yes
        break
    fi
    sleep 2
done
if [ "$ready" != yes ]; then
    echo 'configd did not return provider status after restart.' >&2
    exit 1
fi
response=$(configctl encryptedgit run)
printf '%s\n' "$response" | php -r '
    $response = json_decode(stream_get_contents(STDIN), true, 8, JSON_THROW_ON_ERROR);
    exit(is_string($response["commit"] ?? null) ? 0 : 1);
'
printf '%s\n' NATIVE_REMOVE_REINSTALL_OK
