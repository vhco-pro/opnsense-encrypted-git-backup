#!/bin/sh
set -eu
state=/conf/encrypted-git-backup
repo=/tmp/fixture.git
configctl encryptedgit run | php -r '
    $response = json_decode(stream_get_contents(STDIN), true, 8, JSON_THROW_ON_ERROR);
    exit(is_string($response["commit"] ?? null) ? 0 : 1);
'
commit=$(git -C "$repo" rev-parse refs/heads/snapshots)
test "$(git -C "$repo" ls-tree --name-only "$commit" | tr '\n' ' ')" = 'config.xml.enc snapshot.json '
actual=$(git -C "$repo" show "$commit:config.xml.enc" | sha256 -q)
php -r '
    $proof = json_decode(file_get_contents($argv[1]), true, 8, JSON_THROW_ON_ERROR);
    exit($proof["commit"] === $argv[2] && $proof["sha256"] === $argv[3] ? 0 : 1);
' "$state/verified.json" "$commit" "$actual"
printf 'NATIVE_VERIFIED_DELIVERY_OK %s %s\n' "$commit" "$actual"
