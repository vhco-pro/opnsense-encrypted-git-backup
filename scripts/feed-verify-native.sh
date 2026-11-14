#!/bin/sh
set -eu
test "$#" -eq 6
url=$1
key=$2
abi=$3
version=$4
digest=$5
catalogue=$6
test "$(uname -s)" = FreeBSD
printf '%s\n' "$url" | grep -Eq '^http://127[.]0[.]0[.]1:[0-9]+(/[A-Za-z0-9/_-]*)?$|^https://[a-zA-Z0-9.-]+(/[A-Za-z0-9/_-]*)?$'
printf '%s\n' "$key" | grep -Eq '^/[a-zA-Z0-9/_.-]+$'
test "$(pkg config ABI)" = "$abi"
printf '%s\n' "$version" | grep -Eq '^[0-9]+[.][0-9]+[.][0-9]+([.](alpha|beta|rc)[0-9]+)?$'
for hash in "$digest" "$catalogue"; do
    printf '%s\n' "$hash" | grep -Eq '^[a-f0-9]{64}$'
done
package="os-encrypted-git-backup-$version.pkg"
temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
mkdir "$temp/repos" "$temp/db" "$temp/cache"
printf 'fixture: {url:"%s", signature_type:"pubkey", pubkey:"%s", enabled:yes}\n' "$url" "$key" > "$temp/repos/fixture.conf"
client() {
    pkg -o "REPOS_DIR=$temp/repos" -o "PKG_DBDIR=$temp/db" -o "PKG_CACHEDIR=$temp/cache" "$@"
}
fetch -qo "$temp/catalogue" "$url/packagesite.pkg"
test "$(sha256 -q "$temp/catalogue")" = "$catalogue"
ASSUME_ALWAYS_YES=no client update -f -r fixture </dev/null
test "$(client rquery -r fixture '%v' os-encrypted-git-backup)" = "$version"
client fetch -y -r fixture os-encrypted-git-backup
fetch -qo "$temp/$package" "$url/$package"
test "$(sha256 -q "$temp/$package")" = "$digest"
test "$(pkg query -F "$temp/$package" '%n %v')" = "os-encrypted-git-backup $version"
