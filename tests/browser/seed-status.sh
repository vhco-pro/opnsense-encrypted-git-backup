#!/bin/sh
# Run only inside the owned synthetic OPNsense fixture.
set -eu

install -d -m 700 /conf/encrypted-git-backup
umask 077
printf '%s\n' '{"attempt":"2026-11-14T12:00:00+00:00","outcome":"failed"}' > /conf/encrypted-git-backup/attempt.json
printf '%s\n' '{"version":1,"observedAt":"2026-11-14T11:00:00+00:00","commit":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","revision":"1.0","key":"fixture","sha256":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}' > /conf/encrypted-git-backup/verified.json
configctl encryptedgit status
