#!/bin/sh
# Synthetic credentials and loopback transport for a disposable guest.
set -eu
umask 077
state=/conf/encrypted-git-backup
credentials=$state/credentials
repo=/tmp/fixture.git
test ! -e "$repo"
test ! -e /tmp/encryptedgit-fixture-host
install -d -m 700 "$state" "$credentials"
ssh-keygen -q -t ed25519 -N '' -f "$credentials/identity-fixture"
ssh-keygen -q -t ed25519 -N '' -f /tmp/encryptedgit-fixture-host
cp "$credentials/identity-fixture.pub" /tmp/encryptedgit-fixture-authorized
printf '[127.0.0.1]:22222 %s\n' "$(cat /tmp/encryptedgit-fixture-host.pub)" > "$credentials/hosts-fixture"
printf '%s\n' synthetic-test-password > "$credentials/password-fixture"
git init --bare "$repo"
/usr/local/sbin/sshd -f /dev/null -h /tmp/encryptedgit-fixture-host \
    -o ListenAddress=127.0.0.1 -p 22222 -o PermitRootLogin=prohibit-password \
    -o AuthorizedKeysFile=/tmp/encryptedgit-fixture-authorized -o StrictModes=no \
    -o PidFile=/tmp/encryptedgit-fixture-sshd.pid
printf '%s\n' '{"version":1,"destination":"ssh://root@127.0.0.1:22222/tmp/fixture.git","branch":"snapshots","legacy":null}' \
    > "$state/activation.json"
