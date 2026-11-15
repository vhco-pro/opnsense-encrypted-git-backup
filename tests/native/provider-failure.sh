#!/bin/sh
# Install a throwing sibling provider only in the disposable guest.
set -eu
directory=/usr/local/opnsense/mvc/app/library/OPNsense/Backup
fixture=$directory/AAAFixtureFailure.php
test ! -e "$fixture"
trap 'rm -f "$fixture"' EXIT
cat > "$fixture" <<'PHP'
<?php
namespace OPNsense\Backup;

final class AAAFixtureFailure extends Base implements IBackupProvider
{
    public function getName() { return 'Synthetic earlier provider'; }
    public function isEnabled() { return true; }
    public function getConfigurationFields() { return []; }
    public function setConfiguration($conf) { return []; }
    public function backup() { throw new \RuntimeException('fixture provider failed'); }
}
PHP
repo=/tmp/fixture.git
before=$(git -C "$repo" rev-parse migration)
if php /usr/local/opnsense/scripts/system/remote_backup.php 0 > /tmp/native-provider-failure.log; then
    exit 1
fi
grep -F 'fixture provider failed' /tmp/native-provider-failure.log
test "$(git -C "$repo" rev-parse migration)" != "$before"
printf '%s\n' NATIVE_FAILURE_ISOLATION_OK
