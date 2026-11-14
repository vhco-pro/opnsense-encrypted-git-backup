#!/bin/sh
# Run only on an owned synthetic migration fixture. Transfer both files
# through independent storage between capture and verify.
set -eu
umask 077
phase=$1
directory=$2
state=/conf/encrypted-git-backup
operator=/usr/local/opnsense/scripts/encryptedgit/rollback.php
checks=$(dirname "$0")/check-rollback-pair.sh

case "$phase" in
    capture)
        mkdir "$directory"
        cp /conf/config.xml "$directory/settings"
        cp "$state/activation.json" "$directory/checkpoint"
        php "$operator" hold
        php "$operator" verify
        sh "$checks" "$directory"
        ;;
    verify)
        php "$operator" verify
        cmp "$directory/checkpoint" "$state/rollback.json"
        sh "$checks" "$directory"
        remote=$(git -C /tmp/fixture.git rev-parse refs/heads/migration)
        pending=$(git -C "$state/pending" rev-parse HEAD)
        php "$operator" resume
        configctl encryptedgit run | jq -e '.commit | type == "string"'
        after=$(git -C /tmp/fixture.git rev-parse refs/heads/migration)
        git -C "$state/pending" merge-base --is-ancestor "$remote" "$after"
        git -C "$state/pending" merge-base --is-ancestor "$pending" "$after"
        printf '%s\n' NATIVE_RETRIEVED_ROLLBACK_PAIR_RESUMED
        ;;
    *) exit 64 ;;
esac
