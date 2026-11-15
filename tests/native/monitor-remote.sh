#!/bin/sh
# Isolated fixture only. Supply source path and authenticated A/B status JSON files.
set -eu
source=$1
repo=/tmp/fixture.git
work=$(mktemp -d /tmp/r47-monitor-remote.XXXXXXXX)
trap 'rm -rf "$work"' EXIT
target() {
    php -r 'echo hash("sha256",json_encode(["ssh://root@127.0.0.1:22222/tmp/fixture.git",$argv[1]], JSON_THROW_ON_ERROR));' "$1"
}
check() {
    branch=$1 status=$2 outcome=$3 expected_exit=$4
    commit=$(git -C "$repo" rev-parse "refs/heads/$branch")
    git -C "$repo" show "$commit:snapshot.json" >"$work/metadata"
    git -C "$repo" show "$commit:config.xml.enc" >"$work/artifact"
    result=0
    php "$source/tests/package/check-freshness.php" "$work/metadata" "$commit" "$work/artifact" 3600 "$(target "$branch")" "$status" >"$work/result" || result=$?
    test "$result" -eq "$expected_exit"
    jq -e --arg outcome "$outcome" '.remoteFresh == true and .attemptOutcome == $outcome' "$work/result" >/dev/null
    if [ "$result" -eq 1 ]; then cp "$work/result" "$work/notification"; fi
}
check migration "$2" failed 1
check monitor-b "$3" unknown 0
check monitor-b "$work/unreachable" unknown 0
jq 'del(.attempt.target)' "$3" >"$work/unassociated"
check monitor-b "$work/unassociated" unknown 0
jq -e '.remoteFresh == true and .attemptOutcome == "failed"' "$work/notification" >/dev/null
printf '%s\n' NATIVE_AUTHENTICATED_TARGET_ASSOCIATION_OK
