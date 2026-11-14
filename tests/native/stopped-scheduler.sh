#!/bin/sh
# Run only on the owned synthetic appliance with an active migration branch.
set -eu
umask 077
source=$1
repo=/tmp/fixture.git
ref=refs/heads/migration
state=/conf/encrypted-git-backup
work=$(mktemp -d /tmp/eg-monitor.XXXXXXXX)
trap 'rm -rf "$work"' EXIT
configctl encryptedgit run | grep -q '"commit"'
initial=$(git -C "$repo" rev-parse "$ref")
digest=$(git -C "$repo" rev-parse "$initial:config.xml.enc")
sleep 2
configctl encryptedgit run | grep -q '"commit"'
commit=$(git -C "$repo" rev-parse "$ref")
test "$commit" != "$initial"
test "$(git -C "$repo" rev-parse "$commit:config.xml.enc")" = "$digest"
git -C "$repo" show "$commit:snapshot.json" >"$work/metadata"
git -C "$repo" show "$commit:config.xml.enc" >"$work/ciphertext"
cp "$state/verified.json" "$work/verified"
php "$source/tests/package/check-freshness.php" "$work/metadata" "$commit" "$work/ciphertext" 120
service cron onestop
trap 'service cron onestart; rm -rf "$work"' EXIT
sleep 4
if php "$source/tests/package/check-freshness.php" "$work/metadata" "$commit" "$work/ciphertext" 2; then
    exit 1
else
    test "$?" -eq 1
    printf '%s\n' 'fixture: remote receipt stale with scheduler stopped' >"$work/notification"
fi
test "$(git -C "$repo" rev-parse "$ref")" = "$commit"
cmp "$state/verified.json" "$work/verified"
# Synthetic local notification sink, no external delivery.
grep -qx 'fixture: remote receipt stale with scheduler stopped' "$work/notification"
printf '%s\n' NATIVE_STOPPED_SCHEDULER_AND_NOOP_RECEIPT_OK
