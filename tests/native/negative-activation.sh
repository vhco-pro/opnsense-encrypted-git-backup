#!/bin/sh
set -eu
state=/conf/encrypted-git-backup
password=$state/credentials/password-fixture
hook=/usr/local/etc/rc.syshook.d/config/10-git-backup
test ! -e "$hook"
before=$(sha256 -q /conf/config.xml)
trap 'chmod 0600 "$password"; rm -f "$hook"' EXIT
chmod 0644 "$password"
if php /tmp/activation-smoke.php >/tmp/fixture-invalid-mode.log 2>&1; then
    exit 1
fi
test "$(sha256 -q /conf/config.xml)" = "$before"
chmod 0600 "$password"
mkdir -p "$(dirname "$hook")"
install -m 0600 /dev/null "$hook"
if php /tmp/activation-smoke.php >/tmp/fixture-legacy-hook.log 2>&1; then
    exit 1
fi
test "$(sha256 -q /conf/config.xml)" = "$before"
printf '%s\n' NATIVE_ACTIVATION_REJECTIONS_OK
