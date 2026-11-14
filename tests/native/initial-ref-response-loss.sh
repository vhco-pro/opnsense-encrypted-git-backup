#!/bin/sh
# Use the installed delivery code and an owned bare repository.
set -eu
umask 077
work=$(mktemp -d /tmp/initial-ref-loss.XXXXXXXX)
helpers=$(dirname "$0")
git=/usr/local/bin/git
repo=$work/remote
state=$work/state
mkdir "$state"
"$git" init --bare "$repo"
cat > "$work/git" <<'SH'
#!/bin/sh
set -eu
case "$*" in
    *'push --porcelain '*)
        /usr/local/bin/git "$@" >/dev/null
        remote=$(dirname "$FIXTURE_STATE")/remote
        commit=$(/usr/local/bin/git -C "$remote" rev-parse refs/heads/snapshots)
        printf '%s\n' "$commit" > "$FIXTURE_STATE/accepted"
        /usr/local/bin/git -C "$remote" update-ref -d refs/heads/snapshots "$commit"
        exit 1
        ;;
    *) exec /usr/local/bin/git "$@" ;;
esac
SH
chmod 0700 "$work/git"
if php "$helpers/first-ref-crash.php" "$work/git" "$state" "$repo" > "$work/first.log" 2>&1; then exit 1; fi
grep -Fx 'The remote did not retain the expected encrypted backup.' "$work/first.log"
pending=$("$git" -C "$state/pending" rev-parse HEAD)
test "$(cat "$state/accepted")" = "$pending"
test "$(jq -r .commit "$state/creation.json")" = "$pending"

assert_absence_hold() {
    if php "$helpers/first-ref-crash.php" "$git" "$state" "$repo" > "$work/retry.log" 2>&1; then exit 1; fi
    grep -Fx 'The absent branch requires independent recovery verification.' "$work/retry.log"
    test ! -e "$state/verified.json"
    test "$("$git" -C "$state/pending" rev-parse HEAD)" = "$pending"
    if "$git" -C "$repo" show-ref --verify --quiet refs/heads/snapshots; then exit 1; fi
}
assert_absence_hold
printf '%s\n' NATIVE_INITIAL_RESPONSE_LOSS_AND_DELETION_HELD

# Simulate the persisted inputs found on an upgrade without trusted evidence.
mv "$state/creation.json" "$work/creation.retained"
mv "$state/attempt.json" "$work/attempt.retained"
assert_absence_hold
printf '%s\n' NATIVE_ABSENT_REF_WITHOUT_TRUSTED_ATTEMPT_HELD
