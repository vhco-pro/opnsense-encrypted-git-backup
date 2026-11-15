#!/bin/sh
# Resume after a verified hold using the newer conditionally-writing package.
set -eu
umask 077
pair=$1
package=$2
state=/conf/encrypted-git-backup
repo=/tmp/fixture.git
test ! -e "$state/activation.json"
pkg add -f "$package"
sh /tmp/check-rollback-pair.sh "$pair"
before=$(git -C "$repo" rev-parse refs/heads/migration)
install -m 0600 "$pair/checkpoint" "$state/activation.next"
mv "$state/activation.next" "$state/activation.json"
for attempt in $(jot 15); do
    if configctl encryptedgit status | php -r 'exit(is_array(json_decode(stream_get_contents(STDIN), true)) ? 0 : 1);'; then
        break
    fi
    test "$attempt" -lt 15
    sleep 2
done
configctl encryptedgit run | grep -q '"commit"'
after=$(git -C "$repo" rev-parse refs/heads/migration)
test "$after" != "$before"
grep -q "$after" "$state/verified.json"
printf '%s\n' NATIVE_COMPATIBLE_RESUME_OK
