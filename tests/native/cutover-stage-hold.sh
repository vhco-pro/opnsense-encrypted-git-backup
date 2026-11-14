#!/bin/sh
# Run on the owned cutover fixture before publishing its v2 checkpoint.
set -eu
stage=$1
case "$stage" in drained|final-archive) ;; *) exit 64 ;; esac
state=/conf/encrypted-git-backup
repo=/tmp/fixture.git
work=$(mktemp -d /tmp/cutover-stage.XXXXXXXX)
trap 'rm -rf "$work"' EXIT
test ! -e /usr/local/etc/rc.syshook.d/config/10-git-backup
test "$(jq -r .version "$state/activation.json")" = 1
before=$(sha256 -q /conf/config.xml)
remote=$(git -C "$repo" rev-parse refs/heads/migration)
legacy=$(git -C /conf/backup/git rev-parse HEAD)
test "$remote" != "$legacy"
if php /tmp/activation-smoke.php migration > "$work/save.log" 2>&1; then exit 1; fi
grep -Fq 'Backup activation or credential validation failed.' "$work/save.log"
test "$(sha256 -q /conf/config.xml)" = "$before"
test "$(git -C "$repo" rev-parse refs/heads/migration)" = "$remote"
test "$(git -C /conf/backup/git rev-parse HEAD)" = "$legacy"
test ! -e "$state/pending"
printf '%s %s\n' NATIVE_CUTOVER_STAGE_HELD "$stage"
