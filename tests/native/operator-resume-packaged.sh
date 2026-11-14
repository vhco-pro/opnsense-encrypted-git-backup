#!/bin/sh
# Continue after operator-drain-admitted.sh on the disconnected appliance.
set -eu
umask 077
state=/conf/encrypted-git-backup
repo=/tmp/fixture.git
operator=/usr/local/opnsense/scripts/encryptedgit/rollback.php
package=$1
before=$(git -C "$state/pending" rev-parse HEAD)
remote=$(git -C "$repo" rev-parse migration)
test ! -e "$state/activation.json"
pkg add -f "$package"
pkg check -s os-encrypted-git-backup
test ! -e "$state/activation.json"
for attempt in $(jot 15); do
    if configctl encryptedgit status | php -r 'exit(is_array(json_decode(stream_get_contents(STDIN), true)) ? 0 : 1);'; then
        break
    fi
    test "$attempt" -lt 15
    sleep 2
done
php "$operator" verify
php "$operator" resume
configctl encryptedgit run | grep -q '"commit"'
after=$(git -C "$repo" rev-parse migration)
git -C "$state/pending" merge-base --is-ancestor "$before" "$after"
git -C "$state/pending" merge-base --is-ancestor "$remote" "$after"
grep -q "$after" "$state/verified.json"
printf '%s\n' NATIVE_OPERATOR_PACKAGED_RESUME_VERIFIED
