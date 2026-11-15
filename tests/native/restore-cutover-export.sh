#!/bin/sh
# Run on the owned cutover fixture after independent archive and export read-back.
set -eu
umask 077
state=/conf/encrypted-git-backup
repo=/tmp/fixture.git
legacy=/conf/backup/git
hook=/usr/local/etc/rc.syshook.d/config/10-git-backup
fixture=$1
archive=$2
exported=$3
password=$4
export_password=$5
archive_password=$6
helpers=$(dirname "$0")
tip=$(git -C "$legacy" rev-parse HEAD)
remote=$(git -C "$repo" rev-parse migration)
test "$tip" != "$remote"
test "$(sha256 -q "$exported")" = "$(jq -r .exportSha256 "$state/activation.json")"
test "$(sha256 -q "$archive")" = "$(jq -r .legacy.archiveSha256 "$state/activation.json")"
test ! -e "$hook"
cp "$state/activation.json" "$fixture/verified-checkpoint"
printf '{}\n' > "$state/activation.json"
before=$(sha256 -q /conf/config.xml)
if php /tmp/activation-smoke.php migration rotated; then exit 1; fi
test "$(sha256 -q /conf/config.xml)" = "$before"
cp "$fixture/verified-checkpoint" "$state/activation.json"
install -m 0600 "$password" "$state/credentials/password-rotated"
php /tmp/activation-smoke.php migration rotated
test "$(git -C "$repo" rev-parse migration)" = "$remote"
service configd restart
ready=
for attempt in $(jot 15); do
    if timeout 2 configctl encryptedgit status | jq -e 'type == "object" or type == "array"' >/dev/null; then ready=yes; break; fi
    sleep 2
done
test "$ready" = yes
printf '#!/bin/sh\nexit 1\n' > "$repo/hooks/pre-receive"
chmod 700 "$repo/hooks/pre-receive"
configctl encryptedgit run | jq -e '(.error|type=="string") and (.commit == null)'
test "$(git -C "$repo" rev-parse migration)" = "$remote"
pending=$(git -C "$state/pending" rev-parse HEAD)
test "$(git -C "$state/pending" rev-parse "$pending^")" = "$remote"
echo AC06_POST_SAVE_RESTART_REJECTED_DELIVERY_OK
rm "$repo/hooks/pre-receive"
printf 'synthetic stale writer marker\n' > "$legacy/stale-marker"
git -C "$legacy" add stale-marker
git -C "$legacy" -c user.name=Fixture -c user.email=fixture@example.test commit -m 'Synthetic stale legacy tip'
configctl encryptedgit run | jq -e '(.error|type=="string") and (.commit == null)'
test "$(git -C "$repo" rev-parse migration)" = "$remote"
test "$(git -C "$state/pending" rev-parse HEAD)" = "$pending"
echo AC06_STALE_LEGACY_TIP_HELD_OK
rm "$fixture/pre-cutover.enc" "$fixture/legacy.enc" "$state/credentials/password-rotated"
php "$helpers/restore-smoke.php" "$exported" "$export_password" '<system>'
test ! -e "$state/credentials/password-rotated"
test ! -e "$hook"
openssl enc -d -aes-256-cbc -pbkdf2 -in "$archive" -out "$fixture/independent-recovery.bundle" -pass "file:$archive_password"
mv "$legacy" "$fixture/stale-legacy"
git clone -b migration "$fixture/independent-recovery.bundle" "$legacy"
rm "$fixture/independent-recovery.bundle"
test "$(git -C "$legacy" rev-parse HEAD)" = "$tip"
git -C "$legacy" merge-base --is-ancestor "$remote" "$tip"
install -m 0600 "$password" "$state/credentials/password-rotated"
test "$(stat -f '%u %Lp %l' "$state/credentials/password-rotated")" = '0 600 1'
php /tmp/migration-checkpoint.php current "$tip" "$remote" "$(sha256 -q "$archive")" "$fixture"
php /tmp/activation-smoke.php migration rotated
configctl -w 40 encryptedgit run | jq -e '.commit|type=="string"'
after=$(git -C "$repo" rev-parse migration)
git -C "$state/pending" merge-base --is-ancestor "$pending" "$after"
test "$(git -C "$legacy" rev-parse HEAD)" = "$tip"
test ! -e "$hook"
test "$(git -C "$repo" ls-tree --name-only "$after" | tr '\n' ' ')" = 'config.xml.enc snapshot.json '
if git -C "$legacy" log -p --all | grep -Fq -f "$password"; then exit 1; fi
echo AC06_INDEPENDENT_FULL_EXPORT_RESTORED_AND_DELIVERED_OK
