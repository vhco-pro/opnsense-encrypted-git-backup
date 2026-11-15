#!/bin/sh
# Run on the owned synthetic appliance after starting its loopback SSH fixture.
set -eu
umask 077
state=/conf/encrypted-git-backup
temp=$(mktemp -d "$state/status-fixture.XXXXXXXX")
restore() {
    for name in activation.json password-rotated; do
        test ! -f "$temp/$name" || mv "$temp/$name" "$state/$(case "$name" in password-*) echo credentials/ ;; esac)$name"
    done
    rm -rf "$temp"
}
trap restore EXIT
configctl encryptedgit run | grep -q '"commit"'
cp "$state/verified.json" "$temp/verified"
target=$(jq -er .target "$state/attempt.json")
check() {
    jq -e --arg category "$1" --arg target "$target" '
        .attempt.category == $category and .attempt.outcome == "failed" and .attempt.target == $target
        and (.attempt | keys == ["attempt","category","outcome","target"])
    ' >/dev/null
    cmp "$temp/verified" "$state/verified.json"
}
mv "$state/activation.json" "$temp/"
configctl encryptedgit run | grep -q '"error"'
configctl encryptedgit status | check activation
mv "$temp/activation.json" "$state/"
mv "$state/credentials/password-rotated" "$temp/"
configctl encryptedgit run | grep -q '"error"'
configctl encryptedgit status | check credentials
mv "$temp/password-rotated" "$state/credentials/"
php "$1"
configctl encryptedgit status | check configuration
printf '%s\n' NATIVE_PRECONDITION_STATUS_OK
