#!/bin/sh
set -eu
umask 077

if [ "$#" -lt 4 ]; then
    echo "Usage: $0 output-root generation private-key package [...]" >&2
    exit 64
fi

root=$(realpath "$1")
generation=$2
key=$(realpath "$3")
shift 3
case "$generation" in
    ''|.|..|*[!a-zA-Z0-9._-]*) exit 64 ;;
esac
case "$key" in
    "$root"/*) echo 'Keep the signing key outside the output root.' >&2; exit 64 ;;
esac
final="$root/$generation"
if [ -e "$final" ] || [ -L "$final" ]; then
    echo 'The generation already exists.' >&2
    exit 1
fi
stage=$(mktemp -d "$root/build.XXXXXXXX")
trap 'rm -rf -- "$stage"' EXIT
trap 'exit 1' HUP INT TERM
for package do
    name=$(basename "$package")
    case "$name" in
        os-encrypted-git-backup-*.pkg) ;;
        *) echo 'Unexpected package filename.' >&2; exit 64 ;;
    esac
    if [ -e "$stage/$name" ]; then
        echo 'Duplicate package filename.' >&2
        exit 64
    fi
    install -m 0644 "$package" "$stage/$name"
done
pkg repo "$stage" "$key"
test -s "$stage/packagesite.pkg"
mv -n -- "$stage" "$final"
test ! -d "$stage"
