#!/bin/sh
# Run only inside an isolated synthetic appliance with no other delivery activity.
set -eu
umask 077
state=/conf/encrypted-git-backup
repo=/tmp/fixture.git
work=$(mktemp -d /tmp/eg-native-interrupt.XXXXXXXX)
hook=$repo/hooks/pre-receive
test ! -e "$hook"
trap 'touch "$work/release"; rm -f "$hook"' EXIT
configctl encryptedgit run | grep -q '"commit"'
cp "$state/verified.json" "$work/verified"
remote=$(git -C "$repo" rev-parse migration)
php "$1" opnsense
cat >"$hook" <<HOOK
#!/bin/sh
touch "$work/entered"
for n in \$(jot 30); do
    [ ! -f "$work/release" ] || exit 1
    sleep 1
done
exit 1
HOOK
chmod 0700 "$hook"
configctl encryptedgit run >"$work/first" &
first=$!
for n in $(jot 15); do
    [ ! -f "$work/entered" ] || break
    sleep 1
done
test -f "$work/entered"
worker=$(pgrep -f '^/usr/local/bin/php /usr/local/opnsense/scripts/encryptedgit/run.php$')
test "$(printf '%s\n' "$worker" | wc -l)" -eq 1
pending=$(git -C "$state/pending" rev-parse HEAD)
test "$pending" != "$remote"
configctl encryptedgit run >"$work/second" &
second=$!
sleep 1
kill -0 "$second"
cmp "$state/verified.json" "$work/verified"
test "$(git -C "$repo" rev-parse migration)" = "$remote"
kill -TERM "$worker"
# Both requests remain fenced by the hook until their pending objects are inspected.
wait "$first" || :
test "$(git -C "$state/pending" rev-parse HEAD)" = "$pending"
test "$(git -C "$repo" rev-parse migration)" = "$remote"
cmp "$state/verified.json" "$work/verified"
touch "$work/release"
wait "$second" || :
grep -q '"error"' "$work/second"
rm "$hook"
configctl encryptedgit run | grep -q '"commit"'
test "$(git -C "$repo" rev-parse migration)" = "$pending"
grep -q "$pending" "$state/verified.json"
printf '%s\n' NATIVE_OVERLAP_TERMINATION_RETRY_OK
