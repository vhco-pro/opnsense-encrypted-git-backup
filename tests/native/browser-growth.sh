#!/bin/sh
# Measure the loopback repository created by the disposable browser fixture.
set -eu
cd /tmp/browser-build/plugin
repo=/tmp/fixture.git
ref=refs/heads/migration
before=$(git -C "$repo" rev-list --count "$ref")
size_before=$(du -sk "$repo" | awk '{print $1}')
previous=$(git -C "$repo" rev-parse "$ref")
for theme in opnsense opnsense-dark opnsense; do
    php tests/native/browser-theme.php "$theme"
    configctl encryptedgit run | grep -q '"commit"'
    commit=$(git -C "$repo" rev-parse "$ref")
    test "$(git -C "$repo" rev-parse "$commit^")" = "$previous"
    test "$(git -C "$repo" ls-tree --name-only "$commit")" = "$(printf 'config.xml.enc\nsnapshot.json')"
    bytes=$(git -C "$repo" cat-file -s "$commit:config.xml.enc")
    printf 'FIXTURE_ENCRYPTED_BLOB_BYTES=%s\n' "$bytes"
    previous=$commit
    sleep 1
done
after=$(git -C "$repo" rev-list --count "$ref")
size_after=$(du -sk "$repo" | awk '{print $1}')
test "$((after - before))" -eq 3
printf 'FIXTURE_REPOSITORY_GROWTH commits=%s before_KiB=%s after_KiB=%s\n' \
    "$((after - before))" "$size_before" "$size_after"
