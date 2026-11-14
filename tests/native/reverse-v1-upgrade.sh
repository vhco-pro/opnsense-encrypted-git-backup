#!/bin/sh
# Run only on an owned synthetic null-legacy upgrade fixture. The retained
# settings and checkpoint must have been retrieved from independent storage.
set -eu
umask 077
boundary=$1
old_package=$2
retained=$3
helpers=$(dirname "$0")
case "$boundary" in before-save|after-save) ;; *) exit 64 ;; esac
state=/conf/encrypted-git-backup
repo=/tmp/fixture.git
branch=refs/heads/snapshots
operator=/usr/local/opnsense/scripts/encryptedgit/rollback.php
fixture=$(mktemp -d /tmp/reverse-v1.XXXXXXXX)
remote=$(git -C "$repo" rev-parse "$branch")
pending=$(git -C "$state/pending" rev-parse HEAD)
test "$(jq -r '.version' "$retained/checkpoint")" = 1
cmp "$retained/checkpoint" "$state/activation.json"
test ! -e /usr/local/etc/rc.syshook.d/config/10-git-backup
if [ "$boundary" = after-save ]; then
    php "$helpers/activation-smoke.php"
fi
php "$operator" hold
test ! -e "$state/activation.json"
pkg add -f "$old_package"
pkg check -s os-encrypted-git-backup
service configd restart
configctl -w 40 encryptedgit status | jq -e 'type == "object" or type == "array"' >/dev/null

assert_no_push() {
    test ! -e /tmp/fixture-push-seen
    test "$(git -C "$repo" rev-parse "$branch")" = "$1"
    test "$(git -C "$state/pending" rev-parse HEAD)" = "$pending"
}
printf '#!/bin/sh\ntouch /tmp/fixture-push-seen\nexit 1\n' > "$repo/hooks/pre-receive"
chmod 0700 "$repo/hooks/pre-receive"
trap 'rm -f "$repo/hooks/pre-receive"' EXIT
configctl encryptedgit run | jq -e '(.error | type == "string") and (.commit == null)'
if php /usr/local/opnsense/scripts/system/remote_backup.php 0; then exit 1; fi
assert_no_push "$remote"

# Restore the compatible v1 settings while activation remains withheld.
php -r '
    require "/usr/local/opnsense/mvc/script/load_phalcon.php";
    exit(\OPNsense\Core\Config::getInstance()->restoreBackup($argv[1]) ? 0 : 1);
' "$retained/settings"
# The old provider lacks the current ref protections. Leave both entry
# points disabled before restoring the compatible checkpoint.
touch "$fixture/proceed"
php "$helpers/queued-settings.php" "$fixture"
install -m 0600 "$retained/checkpoint" "$state/activation.json"
tree=$(git -C "$repo" rev-parse "$remote^{tree}")
changed=$(git -C "$repo" -c user.name=Fixture -c user.email=fixture@example.test \
    commit-tree "$tree" -p "$remote" -m 'Synthetic remote advance during rollback')
git -C "$repo" update-ref "$branch" "$changed" "$remote"
configctl encryptedgit run | jq -e '(.error | type == "string") and (.commit == null)'
php /usr/local/opnsense/scripts/system/remote_backup.php 0
assert_no_push "$changed"
printf '%s %s %s\n' NATIVE_V1_REVERSAL_HELD "$boundary" "$pending"
