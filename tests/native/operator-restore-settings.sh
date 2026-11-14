#!/bin/sh
# Run on the disconnected synthetic fixture with a compatible activated package.
set -eu
umask 077
state=/conf/encrypted-git-backup
repo=/tmp/fixture.git
operator=/usr/local/opnsense/scripts/encryptedgit/rollback.php
pending=$(git -C "$state/pending" rev-parse HEAD)
remote=$(git -C "$repo" rev-parse migration)
php "$operator" hold
original=$(php "$operator" revision)
changed_hours=${1:-37}
php /tmp/operator-change-settings.php "$changed_hours"
grep -q "<freshnessHours>$changed_hours</freshnessHours>" /conf/config.xml
if php "$operator" restore-settings "$original"; then exit 1; fi
test ! -e "$state/activation.json"
changed=$(php "$operator" revision)
php "$operator" restore-settings "$changed"
test ! -e "$state/activation.json"
grep -q '<domain>operator-fixture.invalid</domain>' /conf/config.xml
if grep -q "<freshnessHours>$changed_hours</freshnessHours>" /conf/config.xml; then exit 1; fi
test "$(git -C "$state/pending" rev-parse HEAD)" = "$pending"
test "$(git -C "$repo" rev-parse migration)" = "$remote"
if php "$operator" resume "$changed"; then exit 1; fi
test ! -e "$state/activation.json"
configctl encryptedgit run | grep -q '"error"'
restored=$(php "$operator" revision)
php "$operator" resume "$restored"
configctl encryptedgit run | grep -q '"commit"'
after=$(git -C "$repo" rev-parse migration)
git -C "$state/pending" merge-base --is-ancestor "$pending" "$after"
grep -q "$after" "$state/verified.json"
printf '%s\n' NATIVE_CHANGED_SETTINGS_RESTORED
