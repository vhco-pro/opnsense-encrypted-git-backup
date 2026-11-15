#!/bin/sh
# Use the installed delivery code and owned Git refs only.
set -eu
umask 077
work=$(mktemp -d /tmp/ref-delete-race.XXXXXXXX)
helpers=$(dirname "$0")
git=/usr/local/bin/git
repo=$work/remote
state=$work/state
ref=refs/heads/snapshots
mkdir "$state"
"$git" init --bare "$repo"
php "$helpers/first-ref-crash.php" "$git" "$state" "$repo"
old=$("$git" -C "$repo" rev-parse "$ref")
cp "$state/verified.json" "$work/verified"
cat > "$work/git" <<'SH'
#!/bin/sh
set -eu
case "$*" in
    *'push --porcelain '*)
        remote=$(dirname "$FIXTURE_STATE")/remote
        ref=refs/heads/snapshots
        observed=$(/usr/local/bin/git -C "$remote" rev-parse "$ref")
        printf '%s\n' "$observed" > "$FIXTURE_STATE/deleted"
        /usr/local/bin/git -C "$remote" update-ref -d "$ref" "$observed"
        ;;
esac
exec /usr/local/bin/git "$@"
SH
chmod 0700 "$work/git"
if php "$helpers/first-ref-crash.php" "$work/git" "$state" "$repo" > "$work/race.log" 2>&1; then exit 1; fi
grep -Fx 'The remote did not retain the expected encrypted backup.' "$work/race.log"
test "$(cat "$state/deleted")" = "$old"
pending=$("$git" -C "$state/pending" rev-parse HEAD)
test "$pending" != "$old"
"$git" -C "$state/pending" merge-base --is-ancestor "$old" "$pending"
cmp "$work/verified" "$state/verified.json"
if php "$helpers/first-ref-crash.php" "$git" "$state" "$repo" > "$work/retry.log" 2>&1; then exit 1; fi
grep -Fx 'The absent branch requires independent recovery verification.' "$work/retry.log"
test "$("$git" -C "$state/pending" rev-parse HEAD)" = "$pending"
cmp "$work/verified" "$state/verified.json"
if "$git" -C "$repo" show-ref --verify --quiet "$ref"; then exit 1; fi
printf '%s\n' NATIVE_OBSERVED_REF_DELETION_HELD
