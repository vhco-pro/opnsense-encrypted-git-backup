#!/bin/sh
# Run on the disconnected appliance with a verified migration receipt.
set -eu
umask 077
state=/conf/encrypted-git-backup
operator=/usr/local/opnsense/scripts/encryptedgit/rollback.php
repo=/tmp/fixture.git
before=$(git -C "$repo" rev-parse migration)
pending=$(git -C "$state/pending" rev-parse HEAD)
php "$operator" hold
# Repeat after a separate CLI invocation to exercise the retained interruption state.
php "$operator" hold
php "$operator" verify
test ! -e "$state/activation.json"
configctl encryptedgit run | php -r '
    $reply = json_decode(stream_get_contents(STDIN), true, 8, JSON_THROW_ON_ERROR);
    exit(is_string($reply["error"] ?? null) && !isset($reply["commit"]) ? 0 : 1);
'
if php /usr/local/opnsense/scripts/system/remote_backup.php 0; then
    exit 1
fi
test "$(git -C "$state/pending" rev-parse HEAD)" = "$pending"
test "$(git -C "$repo" rev-parse migration)" = "$before"
root_sha=$(sha256 -q /conf/config.xml)
php /tmp/cron-smoke.php add
test "$(sha256 -q /conf/config.xml)" != "$root_sha"
if php "$operator" verify; then
    exit 1
fi
test ! -e "$state/activation.json"
test "$(git -C "$state/pending" rev-parse HEAD)" = "$pending"
printf '%s\n' NATIVE_OPERATOR_STALE_PAIR_HELD
