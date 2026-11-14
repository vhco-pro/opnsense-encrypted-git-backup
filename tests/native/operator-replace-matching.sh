#!/bin/sh
# Run after operator-rollback.sh on the owned disconnected fixture only.
set -eu
umask 077
cd /conf/encrypted-git-backup
operator=/usr/local/opnsense/scripts/encryptedgit/rollback.php
mv rollback.json activation.json
mv rollback-pair.json /tmp/stale-replacement-pair.json
php "$operator" hold
dir=$(mktemp -d /tmp/encryptedgit-replace-ok.XXXXXX)
tip=$(git -C /conf/backup/git rev-parse HEAD)
remote=$(git -C /tmp/fixture.git rev-parse migration)
php /tmp/migration-checkpoint.php replacement "$tip" "$remote" "$(printf '%064d' 0)" "$dir"
php "$operator" replace
test -f activation.json
test -f rollback.json
test -f rollback-pair.json
test ! -e activation.next
configctl encryptedgit run | php -r '
    $value = json_decode(stream_get_contents(STDIN), true, 8, JSON_THROW_ON_ERROR);
    exit(is_string($value["error"] ?? null) && !isset($value["commit"]) ? 0 : 1);
'
test "$(git -C /tmp/fixture.git rev-parse migration)" = "$remote"
echo NATIVE_MATCHING_REPLACEMENT_STAGED_WITHOUT_DELIVERY
