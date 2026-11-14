#!/usr/bin/env bash
set -euo pipefail

# Probe the same served catalogue and package that production clients consume.
[[ $# == 4 ]]
url=$1
manifest=$2
key=$3
abi=$4
[[ "$(uname -s)" == FreeBSD ]]
[[ "$url" =~ ^http://127[.]0[.]0[.]1:[0-9]+(/[A-Za-z0-9/_-]*)?$ ]]
[[ "$key" =~ ^/[a-zA-Z0-9/_.-]+$ && "$abi" =~ ^FreeBSD:[0-9]+:[a-zA-Z0-9_]+$ ]]
version=$(jq -er '.version | select(test("^[0-9]+[.][0-9]+[.][0-9]+([.](alpha|beta|rc)[0-9]+)?$"))' "$manifest")
package="os-encrypted-git-backup-$version.pkg"
digest=$(jq -er '.packageSha256 | select(test("^[0-9a-f]{64}$"))' "$manifest")
catalogue=$(jq -er '.catalogueSha256 | select(test("^[0-9a-f]{64}$"))' "$manifest")
temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
mkdir "$temp"/{repos,db,cache}
printf 'fixture: {url:"%s", signature_type:"pubkey", pubkey:"%s", enabled:yes}\n' "$url" "$key" > "$temp/repos/fixture.conf"
client() {
    pkg -o "REPOS_DIR=$temp/repos" -o "PKG_DBDIR=$temp/db" -o "PKG_CACHEDIR=$temp/cache" -o "ABI=$abi" "$@"
}
curl -fsS --max-time 30 "$url/packagesite.pkg" -o "$temp/catalogue"
[[ "$(sha256 -q "$temp/catalogue")" == "$catalogue" ]]
client update -f -r fixture
[[ "$(client rquery -r fixture '%v' os-encrypted-git-backup)" == "$version" ]]
client fetch -y -r fixture os-encrypted-git-backup
curl -fsS --max-time 30 "$url/$package" -o "$temp/$package"
[[ "$(sha256 -q "$temp/$package")" == "$digest" ]]
[[ "$(pkg query -F "$temp/$package" '%n %v')" == "os-encrypted-git-backup $version" ]]
