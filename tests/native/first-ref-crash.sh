#!/bin/sh
# Isolated installed-package fixture. Interrupt between read-back and receipt.
set -eu
umask 077
work=$(mktemp -d /tmp/first-ref-crash.XXXXXXXX)
helpers=$(dirname "$0")
git=/usr/local/bin/git
repo=$work/remote
mkdir "$work/state"
"$git" init --bare "$repo"
cat > "$work/git" <<'SH'
#!/bin/sh
set -eu
case "$*" in
    *'show '*:config.xml.enc)
        if [ -e "$FIXTURE_STATE/readback" ]; then
            touch "$FIXTURE_STATE/before-receipt"
            for attempt in $(jot 20); do
                [ ! -e "$FIXTURE_STATE/release" ] || exit 1
                sleep 1
            done
            exit 1
        fi
        /usr/local/bin/git "$@"
        touch "$FIXTURE_STATE/readback"
        ;;
    *) exec /usr/local/bin/git "$@" ;;
esac
SH
chmod 0700 "$work/git"
trap 'touch "$work/state/release"' EXIT
php "$helpers/first-ref-crash.php" "$work/git" "$work/state" "$repo" &
worker=$!
for attempt in $(jot 20); do
    [ ! -e "$work/state/before-receipt" ] || break
    kill -0 "$worker"
    sleep 1
done
test -e "$work/state/before-receipt"
test ! -e "$work/state/verified.json"
pending=$("$git" -C "$work/state/pending" rev-parse HEAD)
test "$("$git" -C "$repo" rev-parse refs/heads/snapshots)" = "$pending"
kill -TERM "$worker"
wait "$worker" || :
touch "$work/state/release"
"$git" -C "$repo" update-ref -d refs/heads/snapshots "$pending"
# The interrupted Git child can still own the inherited PHP lock until it
# observes release and exits.
ready=
for attempt in $(jot 15); do
    if php -r '
        $lock = fopen($argv[1], "r+");
        exit($lock !== false && flock($lock, LOCK_EX | LOCK_NB) ? 0 : 1);
    ' "$work/state/delivery.lock"; then
        ready=yes
        break
    fi
    sleep 1
done
test "$ready" = yes
if php "$helpers/first-ref-crash.php" "$git" "$work/state" "$repo" > "$work/retry.log" 2>&1; then exit 1; fi
grep -Fx 'The absent branch requires independent recovery verification.' "$work/retry.log"
test ! -e "$work/state/verified.json"
test "$("$git" -C "$work/state/pending" rev-parse HEAD)" = "$pending"
test "$(jq -r .commit "$work/state/creation.json")" = "$pending"
if "$git" -C "$repo" show-ref --verify --quiet refs/heads/snapshots; then exit 1; fi
printf '%s\n' NATIVE_INITIAL_READBACK_CRASH_HELD
