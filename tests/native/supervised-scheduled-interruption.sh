#!/bin/sh
# Run on an owned disposable appliance with a verified migration receipt.
set -eu
umask 077
source=$1
state=/conf/encrypted-git-backup
repo=/tmp/fixture.git
ref=refs/heads/migration
actions=/usr/local/opnsense/service/conf/actions.d/actions_encryptedgit.conf
hook=$repo/hooks/pre-receive
work=$(mktemp -d /tmp/eg-supervised-cron.XXXXXXXX)
worker=/usr/local/opnsense/scripts/encryptedgit/run.php
command="command:/usr/bin/timeout -k 5 195 /usr/local/bin/php $worker"
grep -Fx "$command" "$actions"
test ! -e "$hook"
cp "$actions" "$work/actions"
restore() {
    touch "$work/release"
    rm -f "$hook"
    cp "$work/actions" "$actions"
    service configd restart
}
trap restore EXIT

configctl encryptedgit run | grep -q '"commit"'
cp "$state/verified.json" "$work/verified"
previous=$(git -C "$repo" rev-parse "$ref")
cat > "$work/worker" <<SH
#!/bin/sh
trap '' TERM
echo \$\$ > "$work/supervised.pid"
/usr/local/bin/php "$worker" &
echo \$! > "$work/worker.pid"
wait \$! || :
# Keep the TERM-ignoring harness alive until the real timeout escalates.
while :; do sleep 1; done
SH
cat > "$work/supervise" <<SH
#!/bin/sh
/usr/bin/timeout -v -k 2 12 "$work/worker" 2> "$work/signals"
echo \$? > "$work/timeout.status"
SH
chmod 0700 "$work/worker" "$work/supervise"
sed "s|^$command\$|command:$work/supervise|" "$work/actions" > "$actions"
grep -Fx "command:$work/supervise" "$actions"
cat > "$hook" <<SH
#!/bin/sh
touch "$work/entered"
for n in \$(jot 40); do
    test ! -e "$work/release" || exit 1
    sleep 1
done
exit 1
SH
chmod 0700 "$hook"
service configd restart
for n in $(jot 15); do
    if timeout 2 configctl encryptedgit status 2>/dev/null | jq -e '.attempt' >/dev/null; then break; fi
    sleep 2
done
# Invoke the same native action used by the configured Remote Backup cron job.
configctl -w 30 system remote backup 0 > "$work/scheduled" &
scheduled=$!
for n in $(jot 12); do
    test ! -e "$work/entered" || break
    sleep 1
done
test -e "$work/entered"
worker_pid=$(cat "$work/worker.pid")
git_pid=$(pgrep -P "$worker_pid" -x git)
ssh_pid=$(pgrep -P "$git_pid" -x ssh)
supervised=$(cat "$work/supervised.pid")
supervisor=$(ps -o ppid= -p "$supervised" | tr -d ' ')
test "$(ps -o comm= -p "$supervisor")" = timeout
test "$(ps -o ppid= -p "$worker_pid" | tr -d ' ')" = "$supervised"
pending=$(git -C "$state/pending" rev-parse HEAD)
test "$pending" != "$previous"
for n in $(jot 24); do
    kill -0 "$supervisor" 2>/dev/null || break
    sleep 1
done
for n in $(jot 5); do
    if ! kill -0 "$worker_pid" 2>/dev/null && ! kill -0 "$git_pid" 2>/dev/null &&
        ! kill -0 "$ssh_pid" 2>/dev/null; then break; fi
    sleep 1
done
for pid in "$supervisor" "$supervised" "$worker_pid" "$git_pid" "$ssh_pid"; do
    if kill -0 "$pid" 2>/dev/null; then
        echo 'A supervised process remained after the deadline.' >&2
        exit 1
    fi
done
wait "$scheduled" || :
test "$(cat "$work/timeout.status")" = 124
grep -F 'sending signal term(15)' "$work/signals"
grep -F 'sending signal kill(9)' "$work/signals"
test "$(git -C "$repo" rev-parse "$ref")" = "$previous"
test "$(git -C "$state/pending" rev-parse HEAD)" = "$pending"
cmp "$state/verified.json" "$work/verified"
configctl encryptedgit status > "$work/status"
jq -c '{nativeAttempt: .attempt.outcome, lastReceipt: .verification.commit}' "$work/status"
jq -c '{diskAttempt: .outcome}' "$state/attempt.json"
outcome=$(jq -er '.attempt.outcome | select(. == "running" or . == "failed")' "$work/status")
test "$outcome" = "$(jq -er .outcome "$state/attempt.json")"
test "$(jq -er .verification.commit "$work/status")" = "$previous"
target=$(php -r 'echo hash("sha256", json_encode(["ssh://root@127.0.0.1:22222/tmp/fixture.git", "migration"], JSON_THROW_ON_ERROR));')
git -C "$repo" show "$previous:snapshot.json" > "$work/metadata"
git -C "$repo" show "$previous:config.xml.enc" > "$work/artifact"
result=0
php "$source/tests/package/check-freshness.php" "$work/metadata" "$previous" "$work/artifact" 2 \
    "$target" "$work/status" > "$work/freshness" || result=$?
test "$result" = 1
jq -e --arg outcome "$outcome" '.remoteFresh == false and .attemptOutcome == $outcome' "$work/freshness" >/dev/null
restore
trap - EXIT
for n in $(jot 15); do
    if timeout 2 configctl encryptedgit status 2>/dev/null | jq -e '.attempt' >/dev/null; then break; fi
    sleep 2
done
configctl encryptedgit run | grep -q '"commit"'
test "$(git -C "$repo" rev-parse "$ref")" = "$pending"
grep -q "$pending" "$state/verified.json"
printf '%s\n' NATIVE_SUPERVISOR_KILL_RETRY_AND_STALE_STATUS_OK
