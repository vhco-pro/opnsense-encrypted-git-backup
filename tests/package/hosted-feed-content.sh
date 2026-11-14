#!/bin/sh
# Runs in the disposable FreeBSD CI VM. Build a synthetic package and sign its catalogue.
set -eu
umask 077
test "$#" -eq 1
out=$1
mkdir -p "$out/files"
name=os-encrypted-git-backup
openssl genrsa -out "$out/sign.pem" 2048
openssl pkey -in "$out/sign.pem" -pubout -out "$out/key.pem"
openssl genrsa -out "$out/next-sign.pem" 2048
openssl pkey -in "$out/next-sign.pem" -pubout -out "$out/next-key.pem"
for generation in 1 2 3 4; do
    version="0.0.$generation"
    site="$out/site-$generation"
    mkdir "$site"
    cat > "$out/+MANIFEST" <<MANIFEST
name: "$name"
version: "$version"
origin: "sysutils/encrypted-git-backup"
comment: "Isolated feed fixture"
desc: "Synthetic package for testing native feed transport"
maintainer: "fixture@example.invalid"
www: "https://example.invalid"
prefix: "/usr/local"
abi: "FreeBSD:15:amd64"
MANIFEST
    pkg create -M "$out/+MANIFEST" -r "$out/files" -o "$site"
    key="$out/sign.pem"
    if [ "$generation" -eq 4 ]; then key="$out/next-sign.pem"; fi
    pkg repo "$site" "$key"
done
mv "$out/site-1" "$out/site"
rm "$out/sign.pem" "$out/next-sign.pem"
