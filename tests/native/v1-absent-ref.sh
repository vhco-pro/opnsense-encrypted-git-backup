#!/bin/sh
# Run across the package upgrade on an owned v1 fixture with pending work.
set -eu
umask 077
helpers=$(dirname "$0")
phase=$1
retained=$2
state=/conf/encrypted-git-backup
repo=/tmp/fixture.git
ref=refs/heads/snapshots
test ! -e /conf/backup/git
test "$(jq -r .version "$state/activation.json")" = 1
case "$phase" in
    prepare)
        mkdir "$retained"
        pending=$(git -C "$state/pending" rev-parse HEAD)
        remote=$(git -C "$repo" rev-parse "$ref")
        test "$pending" != "$remote"
        git -C "$state/pending" merge-base --is-ancestor "$remote" "$pending"
        printf '%s\n' "$pending" > "$retained/pending"
        for name in attempt.json verified.json creation.json initial-rejected; do
            if [ -e "$state/$name" ]; then mv "$state/$name" "$retained/$name"; fi
        done
        git -C "$repo" update-ref -d "$ref" "$remote"
        exit 0
        ;;
    verify) ;;
    *) exit 64 ;;
esac
pending=$(cat "$retained/pending")
test "$(git -C "$state/pending" rev-parse HEAD)" = "$pending"
for name in attempt.json verified.json creation.json initial-rejected; do
    test ! -e "$state/$name"
done
php "$helpers/activation-smoke.php"
configctl encryptedgit run | jq -e '(.error | type == "string") and (.commit == null)'
test "$(git -C "$state/pending" rev-parse HEAD)" = "$pending"
test ! -e "$state/verified.json"
test ! -e "$state/creation.json"
if git -C "$repo" show-ref --verify --quiet "$ref"; then exit 1; fi
printf '%s\n' NATIVE_V1_UPGRADE_ABSENT_REF_HELD
