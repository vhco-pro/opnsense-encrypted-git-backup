#!/bin/sh
# Run only on the disconnected appliance with the old worker and the new operator.
set -eu
umask 077
state=/conf/encrypted-git-backup
operator=/usr/local/opnsense/scripts/encryptedgit/rollback.php
repo=/tmp/fixture.git
fixture=$(mktemp -d /tmp/encryptedgit-operator-drain.XXXXXXXX)
pending=$(git -C "$state/pending" rev-parse HEAD)
remote=$(git -C "$repo" rev-parse migration)
worker=
trap 'touch "$fixture/release-config"; if [ -n "$worker" ]; then kill -CONT "$worker" 2>/dev/null || :; fi' EXIT
php /tmp/drain-legacy-worker.php "$fixture" &
guard=$!
for i in $(jot 15); do
    [ ! -e "$fixture/config-locked" ] || break
    sleep 1
done
test -e "$fixture/config-locked"
configctl encryptedgit run > "$fixture/admitted.json" &
request=$!
for i in $(jot 15); do
    worker=$(pgrep -f '^/usr/local/bin/php /usr/local/opnsense/scripts/encryptedgit/run.php$' || :)
    if [ -n "$worker" ] && procstat -kk "$worker" | grep -Eq 'flock|lf_advlock'; then
        break
    fi
    sleep 1
done
test -n "$worker"
procstat -kk "$worker" | grep -E 'flock|lf_advlock'
kill -STOP "$worker"
touch "$fixture/release-config"
wait "$guard"
php "$operator" hold > "$fixture/operator.log" 2>&1 &
hold=$!
for i in $(jot 15); do
    [ -e "$state/activation.json" ] || break
    sleep 1
done
test ! -e "$state/activation.json"
sleep 2
kill -0 "$hold"
test ! -s "$fixture/operator.log"
kill -CONT "$worker"
worker=
wait "$request"
wait "$hold"
cat "$fixture/operator.log"
grep -qx HELD_AND_DRAINED "$fixture/operator.log"
php -r '
    $reply = json_decode(file_get_contents($argv[1]), true, 8, JSON_THROW_ON_ERROR);
    exit(is_string($reply["error"] ?? null) && !isset($reply["commit"]) ? 0 : 1);
' "$fixture/admitted.json"
test "$(git -C "$state/pending" rev-parse HEAD)" = "$pending"
test "$(git -C "$repo" rev-parse migration)" = "$remote"
php "$operator" verify
printf '%s\n' NATIVE_OPERATOR_DRAINED_ADMITTED_WORKER
