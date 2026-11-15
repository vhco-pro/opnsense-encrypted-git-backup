#!/bin/sh
# Run only on the isolated appliance with the synthetic older package installed.
set -eu
umask 077
source=$1
checkout=$2
framework=$3
output=$4
state=/conf/encrypted-git-backup
mkdir -p "$output"
before=$(pkg query '%v' os-encrypted-git-backup)
activation=$(sha256 -q "$state/activation.json")
pending=$(git -C "$state/pending" rev-parse HEAD)
cd "$checkout"
bash scripts/prepare-native-package.sh 0.0.9-alpha.2 "$source" '' "$framework" "$output"
artifact="$output/os-encrypted-git-backup-0.0.9.alpha2.pkg"
sha256 "$artifact"
test "$(pkg version -t "$before" 0.0.9.alpha2)" = '<'
pkg add "$artifact"
test "$(pkg query '%v' os-encrypted-git-backup)" = 0.0.9.alpha2
test "$(sha256 -q "$state/activation.json")" = "$activation"
test "$(git -C "$state/pending" rev-parse HEAD)" = "$pending"
service configd restart
printf 'NATIVE_UPGRADE_OK %s %s\n' "$source" "$pending"
