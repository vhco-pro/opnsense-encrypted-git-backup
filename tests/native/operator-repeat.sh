#!/bin/sh
# Run on the owned appliance with a verified active checkpoint.
set -eu
operator=/usr/local/opnsense/scripts/encryptedgit/rollback.php
state=/conf/encrypted-git-backup
php "$operator" hold
before=$(sha256 -q "$state/rollback-pair.json")
php "$operator" hold
test "$(sha256 -q "$state/rollback-pair.json")" = "$before"
php "$operator" verify
# Simulate interruption after journaling the verified pair but before restoring activation.
mv "$state/rollback-pair.json" "$state/rollback-closing.json"
test ! -e "$state/activation.json"
php "$operator" verify
php "$operator" resume
test -f "$state/activation.json"
test -f "$state/rollback-closing.json"
php "$1" opnsense-dark
php "$operator" hold
test "$(sha256 -q "$state/rollback-pair.json")" != "$before"
test ! -e "$state/rollback-closing.json"
php "$operator" verify
php "$operator" resume
printf '%s\n' NATIVE_OPERATOR_REPEAT_OK
