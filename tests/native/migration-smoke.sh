#!/bin/sh
set -eu
umask 077
state=/conf/encrypted-git-backup
repo=/tmp/fixture.git
legacy=/conf/backup/git
fixture=$(mktemp -d /tmp/encryptedgit-migration.XXXXXXXX)
test ! -e "$legacy"
git init -b migration "$legacy"
printf '<opnsense><fixture>legacy-only</fixture></opnsense>\n' > "$legacy/config.xml"
git -C "$legacy" add config.xml
git -C "$legacy" -c user.name=Fixture -c user.email=fixture@example.test commit -m 'Synthetic legacy snapshot'
git -C "$legacy" push "$repo" HEAD:refs/heads/migration
remote=$(git -C "$legacy" rev-parse HEAD)
if [ "${1:-}" = "--unpublished" ]; then
    printf '<opnsense><fixture>unpublished-legacy</fixture></opnsense>\n' > "$legacy/config.xml"
    git -C "$legacy" add config.xml
    git -C "$legacy" -c user.name=Fixture -c user.email=fixture@example.test commit -m 'Unpublished legacy snapshot'
fi
tip=$(git -C "$legacy" rev-parse HEAD)
test "$(git -C "$repo" rev-parse refs/heads/migration)" = "$remote"
if [ "${1:-}" = "--unpublished" ]; then test "$tip" != "$remote"; fi
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
configctl encryptedgit run | php -r '
    $result = json_decode(stream_get_contents(STDIN), true, 8, JSON_THROW_ON_ERROR);
    exit(is_string($result["commit"] ?? null) ? 0 : 1);
'
commit=$(git -C "$repo" rev-parse refs/heads/migration)
test "$(git -C "$repo" rev-parse "$commit^")" = "$remote"
test "$(git -C "$repo" ls-tree --name-only "$commit" | tr '\n' ' ')" = 'config.xml.enc snapshot.json '
test "$(git -C "$legacy" rev-parse HEAD)" = "$tip"
printf 'NATIVE_LEGACY_CUTOVER_OK %s\n' "$commit"
