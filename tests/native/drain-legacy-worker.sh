#!/bin/sh
# Run the 05489b6 encrypted provider on the disposable guest, with a valid
# checkpoint, working loopback transport, and an existing migration receipt.
set -eu
umask 077
state=/conf/encrypted-git-backup
remote=/tmp/fixture.git
fixture=$(mktemp -d /tmp/encryptedgit-drain.XXXXXXXX)
before=$(git -C "$remote" rev-parse refs/heads/migration)
pending=$(git -C "$state/pending" rev-parse HEAD)
test -f "$state/activation.json"
install -m 0600 /conf/config.xml "$fixture/settings"
install -m 0600 "$state/activation.json" "$fixture/checkpoint.readback"
cmp "$state/activation.json" "$fixture/checkpoint.readback"

php /tmp/drain-legacy-worker.php "$fixture" &
config_lock=$!
trap 'touch "$fixture/release-config"; wait "$config_lock" || :' EXIT
for i in $(jot 15); do
    [ ! -e "$fixture/config-locked" ] || break
    sleep 1
done
test -e "$fixture/config-locked"

configctl encryptedgit run > "$fixture/admitted.json" &
admitted=$!
# Require a blocked PHP action rather than assuming the request was admitted.
for i in $(jot 15); do
    worker=$(pgrep -f '^/usr/local/bin/php /usr/local/opnsense/scripts/encryptedgit/run.php$' || :)
    if [ -n "$worker" ] && procstat -kk "$worker" | grep -Eq 'flock|lf_advlock'; then
        break
    fi
    sleep 1
done
test -n "$worker"
procstat -kk "$worker" | grep -E 'flock|lf_advlock'

# Fence the effective Git write boundary before releasing the queued worker.
php /tmp/drain-write-fence.php "$state" "$fixture" &
fence=$!
wait "$admitted"
test ! -e "$state/activation.json"
touch "$fixture/worker-drained"
wait "$fence"
php -r '
    $reply = json_decode(file_get_contents($argv[1]), true, 8, JSON_THROW_ON_ERROR);
    exit(is_string($reply["error"] ?? null) && !isset($reply["commit"]) ? 0 : 1);
' "$fixture/admitted.json"
test ! -e "$state/activation.json"
test "$(git -C "$remote" rev-parse refs/heads/migration)" = "$before"
test "$(git -C "$state/pending" rev-parse HEAD)" = "$pending"
cmp "$fixture/checkpoint" "$fixture/checkpoint.readback"
sh /tmp/check-rollback-pair.sh "$fixture"
# Exercise new admission attempts with the checkpoint still withheld.
configctl encryptedgit run > "$fixture/direct-held.json"
php -r '
    $reply = json_decode(file_get_contents($argv[1]), true, 8, JSON_THROW_ON_ERROR);
    exit(is_string($reply["error"] ?? null) && !isset($reply["commit"]) ? 0 : 1);
' "$fixture/direct-held.json"
if php /usr/local/opnsense/scripts/system/remote_backup.php 0 > "$fixture/scheduled-held.log"; then
    exit 1
fi
grep -F 'Encrypted Git backup failed.' "$fixture/scheduled-held.log"
test "$(git -C "$remote" rev-parse refs/heads/migration)" = "$before"
test "$(git -C "$state/pending" rev-parse HEAD)" = "$pending"
printf '%s\n' NATIVE_ADMITTED_WORKER_DRAIN_OK
