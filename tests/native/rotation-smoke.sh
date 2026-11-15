#!/bin/sh
set -eu
umask 077
state=/conf/encrypted-git-backup
repo=/tmp/fixture.git
branch=migration
proof=$(mktemp -d /tmp/encryptedgit-rotation.XXXXXXXX)
trap 'rm -rf "$proof"' EXIT
before=$(git -C "$repo" rev-parse "$branch")
cp "$state/credentials/password-fixture" "$proof/old-password"
printf '%s\n' synthetic-rotation-fixture > "$proof/new-password"
install -m 0600 "$proof/new-password" "$state/credentials/password-rotated"
php /tmp/activation-smoke.php "$branch" rotated
configctl encryptedgit run | php -r '
    $result = json_decode(stream_get_contents(STDIN), true, 8, JSON_THROW_ON_ERROR);
    exit(is_string($result["commit"] ?? null) ? 0 : 1);
'
after=$(git -C "$repo" rev-parse "$branch")
test "$before" != "$after"
git -C "$repo" show "$before:config.xml.enc" > "$proof/old.enc"
git -C "$repo" show "$after:config.xml.enc" > "$proof/new.enc"
php /tmp/restore-smoke.php "$proof/old.enc" "$proof/old-password" '<encryptionKey>fixture</encryptionKey>'
php /tmp/restore-smoke.php "$proof/new.enc" "$proof/new-password" '<encryptionKey>rotated</encryptionKey>'
printf '%s\n' NATIVE_ROTATION_RESTORE_OK
