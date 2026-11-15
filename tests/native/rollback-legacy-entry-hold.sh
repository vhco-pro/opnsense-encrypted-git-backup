#!/bin/sh
# Run on the disposable snapshot fixture after a verified non-legacy backup.
set -eu
state=/conf/encrypted-git-backup
legacy=/conf/backup/git
operator=/usr/local/opnsense/scripts/encryptedgit/rollback.php
error=$(mktemp)
test ! -e "$legacy" && test ! -L "$legacy"
trap 'rm -f "$legacy" "$error"' EXIT
activation=$(sha256 -q "$state/activation.json")
receipt=$(sha256 -q "$state/verified.json")
pending=$(git -C "$state/pending" rev-parse HEAD)
php "$operator" hold
install -m 0600 /dev/null "$legacy"
if php "$operator" resume > "$error" 2>&1; then
    echo 'Rollback resumed with an unexpected legacy entry.' >&2
    exit 1
fi
grep -Fx 'ROLLBACK_HOLD: A verified activation checkpoint is required for this backup target.' "$error"
test ! -e "$state/activation.json"
test "$(sha256 -q "$state/verified.json")" = "$receipt"
test "$(git -C "$state/pending" rev-parse HEAD)" = "$pending"
rm "$legacy"
php "$operator" resume
test "$(sha256 -q "$state/activation.json")" = "$activation"
printf '%s\n' NATIVE_ROLLBACK_LEGACY_ENTRY_HELD
