#!/bin/sh
set -eu
repo=/tmp/fixture.git
state=/conf/encrypted-git-backup
test ! -e "$repo/refs/heads/monitor-b"
git -C "$repo" update-ref refs/heads/monitor-b "$(git -C "$repo" rev-parse migration)" ""
before=$(sha256 -q "$state/attempt.json")
php "$1" monitor-b
test "$(sha256 -q "$state/attempt.json")" = "$before"
printf '%s\n' R47_MONITOR_B_READY
