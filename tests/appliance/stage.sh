#!/usr/bin/env bash
# Download and verify the pinned inputs outside the appliance, which has no egress.
set -euo pipefail
directory=$(realpath "$1")
mkdir -p "$directory"/{downloads,inputs/All,artifacts}
lock=$PWD/tests/appliance/inputs.sha256
(
    cd "$directory/downloads"
    awk '{ print $2 }' "$lock" | xargs -P8 -n1 bash -ec '
        file=$1
        mkdir -p "$(dirname "$file")"
        if [ ! -f "$file" ]; then
            curl --fail --silent --show-error --location --retry 2 \
                "https://pkg.opnsense.org/$file" --output "$file.partial"
            mv "$file.partial" "$file"
        fi
    ' download
    sha256sum --check "$lock"
)
downloads=$directory/downloads
bzip2 -dc "$downloads/releases/26.7/OPNsense-26.7-serial-amd64.img.bz2" >"$directory/installer.img"
cp "$downloads"/FreeBSD:15:amd64/26.7/sets/* "$directory/inputs/"
cp "$downloads"/FreeBSD:15:amd64/26.7/latest/All/*.pkg "$directory/inputs/All/"
git bundle create "$directory/inputs/plugin.bundle" HEAD
framework=$directory/framework
git init -q "$framework"
git -C "$framework" fetch https://github.com/opnsense/plugins.git a01a2e8cef738b3762830a7bbfc6e857384328f1
git -C "$framework" checkout --detach FETCH_HEAD
git -C "$framework" bundle create "$directory/inputs/framework.bundle" HEAD
printf '%s\n' "$(git rev-parse HEAD)" >"$directory/inputs/source-sha"
cp tests/appliance/prepare-guest.sh "$directory/inputs/"
(umask 077; printf '%s\n' "$FIXTURE_READER_PASSWORD" >"$directory/inputs/browser-password")
xorriso -as mkisofs -quiet -R -o "$directory/inputs.iso" "$directory/inputs"
