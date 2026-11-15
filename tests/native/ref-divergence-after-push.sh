#!/bin/sh
# Exercise exact and conflicting read-back through the installed delivery code.
set -eu
umask 077
helpers=$(dirname "$0")
git=/usr/local/bin/git
root=$(mktemp -d /tmp/ref-readback.XXXXXXXX)
for kind in exact descendant unrelated; do
    work=$root/$kind
    state=$work/state
    repo=$work/remote
    mkdir -p "$state"
    printf '%s\n' "$kind" > "$state/kind"
    "$git" init --bare "$repo"
    cat > "$work/git" <<'SH'
#!/bin/sh
set -eu
case "$*" in
    *'push --porcelain '*)
        /usr/local/bin/git "$@" >/dev/null
        remote=$(dirname "$FIXTURE_STATE")/remote
        ref=refs/heads/snapshots
        accepted=$(/usr/local/bin/git -C "$remote" rev-parse "$ref")
        printf '%s\n' "$accepted" >> "$FIXTURE_STATE/pushed"
        kind=$(cat "$FIXTURE_STATE/kind")
        if [ "$kind" = exact ]; then exit 1; fi
        tree=$(/usr/local/bin/git -C "$remote" rev-parse "$accepted^{tree}")
        if [ "$kind" = descendant ]; then set -- -p "$accepted"; else set --; fi
        changed=$(/usr/local/bin/git -C "$remote" -c user.name=Fixture -c user.email=fixture@example.test \
            commit-tree "$tree" "$@" -m 'Synthetic conflicting remote tip')
        /usr/local/bin/git -C "$remote" update-ref "$ref" "$changed" "$accepted"
        printf '%s\n' "$changed" > "$FIXTURE_STATE/changed"
        exit 1
        ;;
    *) exec /usr/local/bin/git "$@" ;;
esac
SH
    chmod 0700 "$work/git"
    if [ "$kind" = exact ]; then
        php "$helpers/first-ref-crash.php" "$work/git" "$state" "$repo"
        receipt=$(jq -r .commit "$state/verified.json")
        test "$("$git" -C "$repo" rev-parse refs/heads/snapshots)" = "$receipt"
        test "$(cat "$state/pushed")" = "$receipt"
    else
        if php "$helpers/first-ref-crash.php" "$work/git" "$state" "$repo" > "$work/first.log" 2>&1; then exit 1; fi
        grep -Fx 'The remote did not retain the expected encrypted backup.' "$work/first.log"
        if php "$helpers/first-ref-crash.php" "$work/git" "$state" "$repo" > "$work/retry.log" 2>&1; then exit 1; fi
        grep -Fx 'The remote backup branch has diverged.' "$work/retry.log"
        test "$(cat "$state/pushed")" = "$("$git" -C "$state/pending" rev-parse HEAD)"
        test "$("$git" -C "$repo" rev-parse refs/heads/snapshots)" = "$(cat "$state/changed")"
        test ! -e "$state/verified.json"
    fi
    printf '%s %s\n' NATIVE_INITIAL_READBACK_IDENTITY "$kind"
done
