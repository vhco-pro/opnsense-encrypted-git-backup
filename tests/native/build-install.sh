#!/bin/sh
# Run inside the owned, network-disconnected FreeBSD appliance.
set -eu
umask 077

inputs=$1
source=$2
output=$3
mkdir -p "$output"
git clone "$inputs/plugin.bundle" "$output/plugin"
git -C "$output/plugin" checkout --detach "$source"
git clone "$inputs/plugins-source.bundle" "$output/framework"
cd "$output/plugin"
printf 'SOURCE=%s\n' "$(git rev-parse HEAD)"
freebsd-version -kru
pkg query '%n %v' opnsense php85 git pkg
php -v
# This version labels the disposable fixture, independently of release CI.
bash scripts/prepare-native-package.sh 0.0.9-alpha.1 "$source" '' "$output/framework" "$output"
artifact="$output/os-encrypted-git-backup-0.0.9.alpha1.pkg"
sha256 "$artifact"
pkg add -f "$artifact"
pkg info -l os-encrypted-git-backup
service configd restart
