#!/bin/sh
set -eu
repo=/tmp/fixture.git
ref=refs/heads/migration
state=/conf/encrypted-git-backup
before=$(git -C "$repo" rev-parse "$ref")
trap 'php /tmp/cron-smoke.php remove && configctl cron restart' EXIT
php /tmp/cron-smoke.php add
configctl cron restart
grep -F 'system remote backup 0' /var/cron/tabs/nobody
for attempt in $(jot 25); do
    after=$(git -C "$repo" rev-parse "$ref")
    if [ "$after" != "$before" ] && grep -q "$after" "$state/verified.json"; then
        printf 'NATIVE_POST_UPGRADE_CRON_OK %s %s\n' "$before" "$after"
        exit 0
    fi
    sleep 4
done
exit 1
