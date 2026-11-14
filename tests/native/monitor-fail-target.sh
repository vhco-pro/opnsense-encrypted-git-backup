#!/bin/sh
set -eu
umask 077
state=/conf/encrypted-git-backup
repo=/tmp/fixture.git
configctl encryptedgit run | grep -q '"commit"'
ref=$(git -C "$repo" rev-parse migration)
test -s "$state/verified.json"
work=$(mktemp -d /tmp/r47-monitor-proof.XXXXXXXX)
cp "$state/verified.json" "$work/verified"
test ! -e "$state/monitor-held.json"
mv "$state/activation.json" "$state/monitor-held.json"
trap 'mv "$state/monitor-held.json" "$state/activation.json"; rm -rf "$work"' EXIT
configctl encryptedgit run | grep -q '"error"'
cmp "$state/verified.json" "$work/verified"
test "$(git -C "$repo" rev-parse migration)" = "$ref"
printf '%s\n' R47_MONITOR_A_READY
