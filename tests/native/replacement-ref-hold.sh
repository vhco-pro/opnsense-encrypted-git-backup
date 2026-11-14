#!/bin/sh
# Run after verified migration on an owned synthetic appliance.
set -eu
umask 077
state=/conf/encrypted-git-backup
repo=/tmp/fixture.git
ref=refs/heads/migration
operator=/usr/local/opnsense/scripts/encryptedgit/rollback.php
fixture=$(mktemp -d /tmp/replacement-ref.XXXXXXXX)
case "${1:-absent}" in
    absent|incompatible|retained) mode=${1:-absent} ;;
    *) exit 64 ;;
esac
cp "$state/verified.json" "$fixture/verified"
pending=$(git -C "$state/pending" rev-parse HEAD)
remote=$(git -C "$repo" rev-parse "$ref")
tip=$(git -C /conf/backup/git rev-parse HEAD)
parent=$(jq -er .legacy.remote "$state/activation.json")
if [ "$mode" = incompatible ]; then
    parent=$tip
    if git -C "$state/pending" merge-base --is-ancestor "$parent" "$pending"; then exit 1; fi
fi
archive=$(jq -er .legacy.archiveSha256 "$state/activation.json")
before=$(sha256 -q "$state/activation.json")
php "$operator" hold
php /tmp/migration-checkpoint.php replacement "$tip" "$parent" "$archive" "$fixture"
php "$operator" replace
test "$(sha256 -q "$state/activation.json")" != "$before"
configctl encryptedgit run | jq -e '(.error | type == "string") and (.commit == null)'
php /tmp/activation-smoke.php migration
if [ "$mode" = retained ]; then
    hook=$repo/hooks/pre-receive
    test ! -e "$hook"
    trap 'rm -f "$hook"' EXIT
    printf '#!/bin/sh\nexit 1\n' > "$hook"
    chmod 0700 "$hook"
    configctl encryptedgit run | jq -e '(.error | type == "string") and (.commit == null)'
    retained=$(git -C "$state/pending" rev-parse HEAD)
    test "$retained" != "$pending"
    git -C "$state/pending" merge-base --is-ancestor "$pending" "$retained"
    cmp "$fixture/verified" "$state/verified.json"
    rm "$hook"
    # Accept the pending object independently without returning a receipt to
    # the interrupted delivery process.
    git -C "$state/pending" push "$repo" "HEAD:$ref"
    printf '#!/bin/sh\ncat >> "%s/pushes"\n' "$fixture" > "$hook"
    chmod 0700 "$hook"
    configctl encryptedgit run | jq -e '.commit | type == "string"'
    after=$(git -C "$repo" rev-parse "$ref")
    git -C "$state/pending" merge-base --is-ancestor "$retained" "$after"
    test "$(jq -r .commit "$state/verified.json")" = "$after"
    if [ -e "$fixture/pushes" ]; then
        awk -v retained="$retained" '$2 == retained { exit 1 }' "$fixture/pushes"
    fi
    printf '%s\n' NATIVE_REPLACEMENT_RETAINED_REF_VERIFIED
    exit 0
fi
if [ "$mode" = absent ]; then
    git -C "$repo" update-ref -d "$ref" "$remote"
fi
configctl encryptedgit run | jq -e '(.error | type == "string") and (.commit == null)'
test "$(git -C "$state/pending" rev-parse HEAD)" = "$pending"
cmp "$fixture/verified" "$state/verified.json"
if [ "$mode" = absent ]; then
    if git -C "$repo" show-ref --verify --quiet "$ref"; then exit 1; fi
else
    test "$(git -C "$repo" rev-parse "$ref")" = "$remote"
fi
printf '%s %s\n' NATIVE_REPLACEMENT_LEGACY_REF_HELD "$mode"
