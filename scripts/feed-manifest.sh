#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 5 ]]; then
    echo "Usage: $0 semver source-sha tag package generation-directory" >&2
    exit 64
fi
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
version=$("$root/package-version.sh" "$1" "$2" "$3")
[[ -n "$3" ]]
name=os-encrypted-git-backup
[[ $(basename -- "$4") == "$name-$version.pkg" ]]
[[ $(pkg query -F "$4" '%n %v') == "$name $version" ]]
generation=$(realpath "$5")
packageDigest=$(openssl dgst -sha256 -r "$4" | cut -d ' ' -f 1)
[[ $(openssl dgst -sha256 -r "$generation/$name-$version.pkg" | cut -d ' ' -f 1) == "$packageDigest" ]]
catalogue="$generation/packagesite.pkg"
catalogueChecksum=$(tar -xOf "$catalogue" packagesite.yaml |
    jq -ser --arg name "$name" --arg version "$version" '
        [.[] | select(.name == $name and .version == $version)] |
        select(length == 1 and .[0].path == ($name + "-" + $version + ".pkg")) |
        .[0].sum | strings | select(length > 0)
    ')
# pkg catalogues carry an algorithm-tagged checksum. The feed manifest
# separately records SHA-256 for byte identity across generations.
pkg checksum -q -c "$catalogueChecksum" "$generation/$name-$version.pkg"
catalogueDigest=$(openssl dgst -sha256 -r "$catalogue" | cut -d ' ' -f 1)
jq -n --arg source "$2" --arg tag "$3" --arg semver "$1" --arg version "$version" \
    --arg package "$name-$version.pkg" --arg packageSha256 "$packageDigest" --arg catalogueSha256 "$catalogueDigest" \
    '{source: $source, tag: $tag, semver: $semver, version: $version, package: $package,
      packageSha256: $packageSha256, catalogueSha256: $catalogueSha256}'
