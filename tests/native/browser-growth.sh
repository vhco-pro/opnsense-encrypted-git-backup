#!/bin/sh
# Measure the loopback repository created by the disposable browser fixture.
set -eu
cd /tmp/browser-build/plugin
repo=/tmp/fixture.git
ref=refs/heads/migration
# Reconcile work left pending by the rejected-delivery journey before taking the baseline.
configctl encryptedgit run | grep -q '"commit"'
before=$(git -C "$repo" rev-list --count "$ref")
size_before=$(du -sk "$repo" | awk '{print $1}')
previous=$(git -C "$repo" rev-parse "$ref")
previous_blob=$(git -C "$repo" rev-parse "$previous:config.xml.enc")
for theme in opnsense opnsense-dark opnsense; do
    php tests/native/browser-theme.php "$theme"
    configctl encryptedgit run | grep -q '"commit"'
    commit=$(git -C "$repo" rev-parse "$ref")
    test "$(git -C "$repo" rev-parse "$commit^")" = "$previous"
    test "$(git -C "$repo" ls-tree --name-only "$commit")" = "$(printf 'config.xml.enc\nsnapshot.json')"
    blob=$(git -C "$repo" rev-parse "$commit:config.xml.enc")
    test "$blob" != "$previous_blob"
    bytes=$(git -C "$repo" cat-file -s "$blob")
    printf 'FIXTURE_ENCRYPTED_BLOB_BYTES=%s\n' "$bytes"
    previous=$commit
    previous_blob=$blob
    sleep 1
done
after=$(git -C "$repo" rev-list --count "$ref")
size_after=$(du -sk "$repo" | awk '{print $1}')
test "$((after - before))" -eq 3
printf 'FIXTURE_REPOSITORY_GROWTH commits=%s before_KiB=%s after_KiB=%s\n' \
    "$((after - before))" "$size_before" "$size_after"
