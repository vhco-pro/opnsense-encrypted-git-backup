#!/usr/bin/env bash
set -euo pipefail

semver=$1
source_sha=$2
tag=$3
framework=$(realpath "$4")
output=$(realpath "$5")
revision=a01a2e8cef738b3762830a7bbfc6e857384328f1
root=$(git rev-parse --show-toplevel)
cd "$root"
version=$(bash scripts/package-version.sh "$semver" "$source_sha" "$tag")
test "$(uname -s)" = FreeBSD
test "$(git -C "$framework" rev-parse HEAD)" = "$revision"
stage=$(mktemp -d)
trap 'rm -rf -- "$stage"' EXIT
git -C "$framework" archive "$revision" Mk Scripts Templates | tar -xf - -C "$stage"
plugin="$stage/sysutils/encrypted-git-backup"
mkdir -p "$plugin"
git archive "$source_sha" Makefile pkg-descr src | tar -xf - -C "$plugin"
make -C "$plugin" package GITVERSION=/nonexistent PLUGIN_VERSION="$version" PLUGIN_HASH="$source_sha"
artifact="$plugin/work/pkg/os-encrypted-git-backup-$version.pkg"
test "$(pkg query -F "$artifact" '%n %v')" = "os-encrypted-git-backup $version"
install -m 0644 "$artifact" "$output/"
printf '%s\n' "$version"
