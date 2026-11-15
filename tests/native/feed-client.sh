#!/bin/sh
# Run on a disconnected disposable appliance with two native packages for the same ABI.
set -eu
umask 077
source=$1
older=$(realpath "$2")
newer=$(realpath "$3")
work=$(mktemp -d /tmp/encryptedgit-feed.XXXXXXXX)
mkdir "$work/repos" "$work/generations"
openssl genrsa -out "$work/signing.pem" 2048
openssl pkey -in "$work/signing.pem" -pubout -out "$work/trusted.pem"
openssl genrsa -out "$work/rejected.pem" 2048
for generation in older newer wrong; do
    case "$generation" in
        older) package=$older; key=$work/signing.pem ;;
        newer) package=$newer; key=$work/signing.pem ;;
        wrong) package=$newer; key=$work/rejected.pem ;;
    esac
    sh "$source/tests/package/build-feed.sh" "$work/generations" "$generation" "$key" "$package"
done

select_generation()
{
    printf 'fixture: { url: "file://%s/%s", enabled: yes, signature_type: "pubkey", pubkey: "%s/trusted.pem" }\n' \
        "$work/generations" "$1" "$work" > "$work/repos/fixture.conf"
}

fixture_pkg()
{
    pkg -o REPOS_DIR="$work/repos" "$@"
}

select_generation older
fixture_pkg update -f -r fixture
expected=$(pkg query -F "$older" '%v')
test "$(fixture_pkg rquery -r fixture '%v' os-encrypted-git-backup)" = "$expected"
fixture_pkg install -y -f -r fixture os-encrypted-git-backup
test "$(pkg query '%v' os-encrypted-git-backup)" = "$expected"

select_generation wrong
fixture_pkg update -f -r fixture > "$work/wrong-key.log" 2>&1 || :
if fixture_pkg rquery -r fixture '%v' os-encrypted-git-backup > "$work/wrong-query.log" 2>&1; then
    exit 1
fi

select_generation newer
fixture_pkg update -f -r fixture
expected=$(pkg query -F "$newer" '%v')
test "$(fixture_pkg rquery -r fixture '%v' os-encrypted-git-backup)" = "$expected"
fixture_pkg upgrade -y -r fixture os-encrypted-git-backup
test "$(pkg query '%v' os-encrypted-git-backup)" = "$expected"
rm -f "$work/signing.pem" "$work/rejected.pem"
printf 'SIGNED_NATIVE_INSTALL_AND_UPGRADE_OK %s\n' "$expected"
