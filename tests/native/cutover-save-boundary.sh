#!/bin/sh
# Run only on an owned synthetic appliance with a verified v2 checkpoint,
# before saving activation. The installed check action is fault-injected
# temporarily to stop the native save immediately after validation.
set -eu
umask 077
state=/conf/encrypted-git-backup
checkpoint=$state/activation.json
repo=/tmp/fixture.git
actions=/usr/local/opnsense/service/conf/actions.d/actions_encryptedgit.conf
fixture=$(mktemp -d /tmp/cutover-save.XXXXXXXX)
remote=$(git -C "$repo" rev-parse migration)
before=$(sha256 -q /conf/config.xml)
cp "$checkpoint" "$fixture/checkpoint"
cp "$actions" "$fixture/actions"
trap 'touch "$fixture/release" "$fixture/proceed"; cp "$fixture/checkpoint" "$checkpoint"; cp "$fixture/actions" "$actions"; service configd restart' EXIT

assert_rejected() {
    if php /tmp/activation-smoke.php migration > "$fixture/rejected" 2>&1; then
        exit 1
    fi
    grep -Fq 'Backup activation or credential validation failed.' "$fixture/rejected"
    test "$(sha256 -q /conf/config.xml)" = "$before"
    test "$(git -C "$repo" rev-parse migration)" = "$remote"
}
rm "$checkpoint"
assert_rejected
jq '.version = 1 | del(.exportSha256, .configurationSha256)' "$fixture/checkpoint" > "$checkpoint"
assert_rejected
cp "$fixture/checkpoint" "$checkpoint"
printf '%s\n' NATIVE_CUTOVER_MISSING_AND_V1_EVIDENCE_HELD

cat > "$fixture/check.sh" <<'SH'
#!/bin/sh
set -eu
fixture=$(dirname "$0")
response=$(/usr/local/bin/php /usr/local/opnsense/scripts/encryptedgit/check.php "$@")
printf '%s\n' "$response" | grep -Eq '^[a-f0-9]{64}$'
touch "$fixture/checked"
for attempt in $(jot 20); do
    if [ -e "$fixture/release" ]; then
        printf '%s\n' "$response"
        exit 0
    fi
    sleep 1
done
exit 1
SH
sed "s@^command:/usr/local/bin/php /usr/local/opnsense/scripts/encryptedgit/check.php\$@command:/bin/sh $fixture/check.sh@" \
    "$fixture/actions" > "$actions"
wait_ready() {
    for attempt in $(jot 15); do
        if timeout 2 configctl encryptedgit status | jq -e 'type == "object" or type == "array"' >/dev/null; then
            return 0
        fi
        sleep 2
    done
    return 1
}
service configd restart
wait_ready
start_save() {
    php /tmp/activation-smoke.php migration > "$fixture/save" 2>&1 &
    saver=$!
    for attempt in $(jot 20); do
        test ! -e "$fixture/checked" || break
        kill -0 "$saver"
        sleep 1
    done
    test -e "$fixture/checked"
}
start_save
kill -TERM "$saver"
if wait "$saver"; then exit 1; fi
touch "$fixture/release"
test "$(sha256 -q /conf/config.xml)" = "$before"
test "$(git -C "$repo" rev-parse migration)" = "$remote"
cmp "$checkpoint" "$fixture/checkpoint"
printf '%s\n' NATIVE_CUTOVER_INTERRUPTED_AFTER_CHECK_HELD

# Restart configd to retire the interrupted request before repeating the save.
service configd restart
rm "$fixture/checked" "$fixture/release"
wait_ready
start_save
php /tmp/queued-settings.php "$fixture" &
writer=$!
for attempt in $(jot 8); do
    if procstat -kk "$writer" | grep -Eq 'flock|lf_advlock'; then
        break
    fi
    sleep 1
done
procstat -kk "$writer" | grep -Eq 'flock|lf_advlock'
test ! -e "$fixture/locked"
test "$(sha256 -q /conf/config.xml)" = "$before"
touch "$fixture/release"
wait "$saver"
grep -qx NATIVE_ACTIVATION_SAVE_OK "$fixture/save"
for attempt in $(jot 8); do
    test ! -e "$fixture/locked" || break
    sleep 1
done
test -e "$fixture/locked"
grep -Fq "<activation>$(sha256 -q "$checkpoint")</activation>" /conf/config.xml
touch "$fixture/proceed"
wait "$writer"
test "$(git -C "$repo" rev-parse migration)" = "$remote"
printf '%s\n' NATIVE_CUTOVER_COMPARE_AND_SAVE_SERIALIZED
