#!/bin/sh
set -eu
umask 077
# Run only on a disposable appliance. Arguments are a complete checkout,
# the pinned framework, and an existing writable package output directory.
source=$(realpath "$1")
framework=$(realpath "$2")
output=$(realpath "$3")
sha=$(git -C "$source" rev-parse HEAD)
work=$(mktemp -d /tmp/encryptedgit-firmware.XXXXXXXX)
trap 'rm -rf "$work"' EXIT
mkdir "$work/repos" "$work/feed"
printf 'FIRMWARE_FIXTURE_SOURCE=%s\n' "$sha"
openssl genrsa -out "$work/key.pem" 2048
openssl pkey -in "$work/key.pem" -pubout -out "$work/public.pem"
for version in 93 94; do
    cd "$source"
    bash scripts/prepare-native-package.sh "0.0.9-alpha.$version" "$sha" '' "$framework" "$output"
    package="$output/os-encrypted-git-backup-0.0.9.alpha$version.pkg"
    sha256 "$package"
    sh tests/package/build-feed.sh "$work/feed" "release-$version" "$work/key.pem" "$package"
done
# Pass a fixture-only repository directory to the same native Firmware launcher used by configd.
export REPOS_DIR="$work/repos"
export LOCKFILE="$work/firmware.log"
if pkg info -e os-encrypted-git-backup; then
    pkg delete -y os-encrypted-git-backup
fi
for version in 93 94; do
    printf 'Fixture: { url: "file://%s/feed/release-%s", enabled: yes, signature_type: pubkey, pubkey: "%s/public.pem" }\n' \
        "$work" "$version" "$work" >"$REPOS_DIR/Fixture.conf"
    pkg update -f -r Fixture
    test "$(pkg rquery -r Fixture '%v' os-encrypted-git-backup)" = "0.0.9.alpha$version"
    /usr/local/opnsense/scripts/firmware/launcher.sh install os-encrypted-git-backup
    grep -F '***DONE***' "$LOCKFILE"
    test "$(pkg query '%v' os-encrypted-git-backup)" = "0.0.9.alpha$version"
    pkg check -s os-encrypted-git-backup
    printf 'NATIVE_FIRMWARE_INSTALL_VERIFIED=%s\n' "$version"
done
