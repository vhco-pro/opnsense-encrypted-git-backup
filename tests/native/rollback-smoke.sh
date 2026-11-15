#!/bin/sh
# Verify interrupted rollback fails closed on the older package in the isolated guest.
set -eu
umask 077
old=$1
current=$2
state=/conf/encrypted-git-backup
repo=/tmp/fixture.git
backup=$(mktemp -d /tmp/encryptedgit-rollback.XXXXXXXX)
ref=$(git -C "$repo" rev-parse refs/heads/migration)
pending=$(git -C "$state/pending" rev-parse HEAD)
install -m 0600 "$state/activation.json" "$backup/checkpoint"
install -m 0600 /conf/config.xml "$backup/settings"
cmp "$state/activation.json" "$backup/checkpoint"
cmp /conf/config.xml "$backup/settings"
mv "$state/activation.json" "$backup/paused"
pkg add -f "$old"
service configd restart
# Confirm the old action is reachable before interpreting the failure.
for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if configctl encryptedgit status | php -r '
        $status = json_decode(stream_get_contents(STDIN), true);
        exit(is_array($status) ? 0 : 1);
    '; then
        break
    fi
    test "$attempt" -lt 10
    sleep 2
done
# A restarted old worker must reject the partial state before contacting the remote.
configctl encryptedgit run | php -r '
    $response = json_decode(stream_get_contents(STDIN), true, 8, JSON_THROW_ON_ERROR);
    exit(is_string($response["error"] ?? null) && !isset($response["commit"]) ? 0 : 1);
'
if php /usr/local/opnsense/scripts/system/remote_backup.php 0; then
    exit 1
fi
test "$(git -C "$repo" rev-parse refs/heads/migration)" = "$ref"
test "$(git -C "$state/pending" rev-parse HEAD)" = "$pending"
pkg add -f "$current"
mv "$backup/paused" "$state/activation.json"
cmp "$state/activation.json" "$backup/checkpoint"
service configd restart
configctl encryptedgit run | grep -q '"commit"'
printf '%s\n' NATIVE_INTERRUPTED_ROLLBACK_HOLD_OK
