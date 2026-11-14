#!/bin/sh
# Recreate only the runtime objects lost when the owned appliance reboots.
set -eu
umask 077
state=/conf/encrypted-git-backup
repo=/tmp/fixture.git
test -e "$state/pending/.git"
test ! -e /tmp/encryptedgit-fixture-host
ssh-keygen -q -t ed25519 -N '' -f /tmp/encryptedgit-fixture-host
cp "$state/credentials/identity-fixture.pub" /tmp/encryptedgit-fixture-authorized
printf '[127.0.0.1]:22222 %s\n' "$(cat /tmp/encryptedgit-fixture-host.pub)" > "$state/credentials/hosts-fixture"
if [ ! -e "$repo" ]; then
    git clone --bare "$state/pending" "$repo"
    git -C "$repo" update-ref refs/heads/migration "$(git -C "$state/pending" rev-parse HEAD)"
fi
/usr/local/sbin/sshd -f /dev/null -h /tmp/encryptedgit-fixture-host \
    -o ListenAddress=127.0.0.1 -p 22222 -o PermitRootLogin=prohibit-password \
    -o AuthorizedKeysFile=/tmp/encryptedgit-fixture-authorized -o StrictModes=no \
    -o PidFile=/tmp/encryptedgit-fixture-sshd.pid
