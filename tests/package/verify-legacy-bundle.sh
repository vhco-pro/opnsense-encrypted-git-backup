#!/bin/sh
set -eu
umask 077

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 retrieved-encrypted-bundle password-file final-tip prior-remote-tip" >&2
    exit 64
fi
archive=$1
password=$2
tip=$3
remote=$4
for oid in "$tip" "$remote"; do
    case "$oid" in
        *[!0-9a-f]*|'') exit 64 ;;
    esac
    [ "${#oid}" -eq 40 ] || [ "${#oid}" -eq 64 ] || exit 64
done

scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
trap 'exit 1' HUP INT TERM
openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -md sha512 \
    -pass "file:$password" -in "$archive" -out "$scratch/history.bundle"
git init --bare "$scratch/verify.git" >/dev/null
git -C "$scratch/verify.git" bundle verify "$scratch/history.bundle" >/dev/null
git -C "$scratch/verify.git" bundle unbundle "$scratch/history.bundle" >/dev/null
git -C "$scratch/verify.git" cat-file -e "$tip^{commit}"
git -C "$scratch/verify.git" merge-base --is-ancestor "$remote" "$tip"
openssl dgst -sha256 -r "$archive" | cut -d ' ' -f 1
