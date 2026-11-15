#!/bin/sh
set -eu
umask 077
state=/conf/encrypted-git-backup
repo=/tmp/fixture.git
legacy=/conf/backup/git
fixture=$(mktemp -d /tmp/encryptedgit-migration.XXXXXXXX)
mode=${1:-}
interrupted_shutdown=
if [ "$mode" = --interrupted-shutdown ]; then
    interrupted_shutdown=yes
    mode=--unpublished
fi
test ! -e "$legacy"
git init -b migration "$legacy"
printf '<opnsense><fixture>legacy-only</fixture></opnsense>\n' > "$legacy/config.xml"
git -C "$legacy" add config.xml
git -C "$legacy" -c user.name=Fixture -c user.email=fixture@example.test commit -m 'Synthetic legacy snapshot'
git -C "$legacy" push "$repo" HEAD:refs/heads/migration
remote=$(git -C "$legacy" rev-parse HEAD)
if [ "$mode" = "--unpublished" ]; then
    # An admitted synthetic writer finishes after preliminary retention.
    hook=/usr/local/etc/rc.syshook.d/config/10-git-backup
    test ! -e "$hook"
    test ! -L "$hook"
    git -C "$legacy" bundle create "$fixture/preliminary.bundle" --all HEAD
    mkdir -p "$(dirname "$hook")"
    cat >"$hook" <<'HOOK'
#!/bin/sh
set -eu
legacy=$1
fixture=$2
touch "$fixture/writer-admitted"
for tick in $(jot 30); do
    if [ -f "$fixture/writer-release" ]; then
        printf '<opnsense><fixture>unpublished-legacy</fixture></opnsense>\n' > "$legacy/config.xml"
        git -C "$legacy" add config.xml
        git -C "$legacy" -c user.name=Fixture -c user.email=fixture@example.test commit -m 'Unpublished legacy snapshot'
        exit 0
    fi
    sleep 1
done
exit 1
HOOK
    chmod 0700 "$hook"
    sh "$hook" "$legacy" "$fixture" &
    writer=$!
    trap 'touch "$fixture/writer-release"; wait "$writer" || :; rm -f "$hook"' EXIT
    for tick in $(jot 10); do
        [ ! -f "$fixture/writer-admitted" ] || break
        sleep 1
    done
    test -f "$fixture/writer-admitted"
    before=$(sha256 -q /conf/config.xml)
    if php /tmp/activation-smoke.php migration > "$fixture/active-writer.log" 2>&1; then exit 1; fi
    test "$(sha256 -q /conf/config.xml)" = "$before"
    # Quiesce entry before releasing and joining the already admitted writer.
    if [ "$interrupted_shutdown" = yes ]; then
        (
            rm "$hook"
            touch "$fixture/hook-withdrawn"
            for tick in $(jot 20); do sleep 1; done
        ) &
        shutdown=$!
        for tick in $(jot 10); do
            [ ! -e "$fixture/hook-withdrawn" ] || break
            sleep 1
        done
        test -e "$fixture/hook-withdrawn"
        kill -TERM "$shutdown"
        if wait "$shutdown"; then exit 1; fi
        kill -0 "$writer"
        if php /tmp/activation-smoke.php migration > "$fixture/interrupted-writer.log" 2>&1; then exit 1; fi
        test "$(sha256 -q /conf/config.xml)" = "$before"
        test "$(git -C "$repo" rev-parse migration)" = "$remote"
        printf '%s\n' NATIVE_PRELIMINARY_WRITER_SHUTDOWN_INTERRUPTED
    else
        rm "$hook"
    fi
    touch "$fixture/writer-release"
    wait "$writer"
    trap - EXIT
    git -C "$legacy" bundle list-heads "$fixture/preliminary.bundle" |
        grep -qx "$remote refs/heads/migration"
    rm "$fixture/preliminary.bundle"
    printf '%s\n' NATIVE_LEGACY_WRITER_DRAINED
fi
tip=$(git -C "$legacy" rev-parse HEAD)
test "$(git -C "$repo" rev-parse refs/heads/migration)" = "$remote"
if [ "$mode" = "--unpublished" ]; then test "$tip" != "$remote"; fi
git -C "$legacy" bundle create "$fixture/legacy.bundle" --all HEAD
export FIXTURE_ARCHIVE_PASSWORD=synthetic-archive-fixture
openssl enc -aes-256-cbc -pbkdf2 -salt -in "$fixture/legacy.bundle" \
    -out "$fixture/legacy.enc" -pass env:FIXTURE_ARCHIVE_PASSWORD
rm "$fixture/legacy.bundle"
openssl enc -d -aes-256-cbc -pbkdf2 -in "$fixture/legacy.enc" \
    -out "$fixture/retrieved.bundle" -pass env:FIXTURE_ARCHIVE_PASSWORD
unset FIXTURE_ARCHIVE_PASSWORD
git clone --bare "$fixture/retrieved.bundle" "$fixture/independent.git"
test "$(git -C "$fixture/independent.git" rev-parse refs/heads/migration)" = "$tip"
git -C "$fixture/independent.git" merge-base --is-ancestor "$remote" "$tip"
rm "$fixture/retrieved.bundle"
archive=$(sha256 -q "$fixture/legacy.enc")
php /tmp/migration-checkpoint.php stale "$tip" "$remote" "$archive" "$fixture"
before=$(sha256 -q /conf/config.xml)
if php /tmp/activation-smoke.php migration > "$fixture/stale.log" 2>&1; then
    exit 1
fi
test "$(sha256 -q /conf/config.xml)" = "$before"
php /tmp/migration-checkpoint.php current "$tip" "$remote" "$archive" "$fixture"
php /tmp/activation-smoke.php migration
mkdir "$fixture/prior"
for name in target.json pending verified.json attempt.json; do
    if [ -e "$state/$name" ]; then
        mv "$state/$name" "$fixture/prior/"
    fi
done
if [ "$mode" = "--unpublished" ]; then
    # After activation, a rejected first delivery must retain its exact pending object.
    hook=$repo/hooks/pre-receive
    test ! -e "$hook"
    printf '#!/bin/sh\nexit 1\n' > "$hook"
    chmod 0700 "$hook"
    trap 'rm -f "$hook"' EXIT
    configctl encryptedgit run | grep -q '"error"'
    test "$(git -C "$repo" rev-parse refs/heads/migration)" = "$remote"
    pending=$(git -C "$state/pending" rev-parse HEAD)
    test "$(git -C "$state/pending" rev-parse "$pending^")" = "$remote"
    test ! -e "$state/verified.json"
    test "$(git -C "$legacy" rev-parse HEAD)" = "$tip"
    rm "$hook"
    trap - EXIT
fi
configctl encryptedgit run | php -r '
    $result = json_decode(stream_get_contents(STDIN), true, 8, JSON_THROW_ON_ERROR);
    exit(is_string($result["commit"] ?? null) ? 0 : 1);
'
commit=$(git -C "$repo" rev-parse refs/heads/migration)
test "$(git -C "$repo" rev-parse "$commit^")" = "$remote"
if [ "$mode" = "--unpublished" ]; then test "$commit" = "$pending"; fi
test "$(git -C "$repo" ls-tree --name-only "$commit" | tr '\n' ' ')" = 'config.xml.enc snapshot.json '
test "$(git -C "$legacy" rev-parse HEAD)" = "$tip"
printf 'NATIVE_LEGACY_CUTOVER_OK %s\n' "$commit"
