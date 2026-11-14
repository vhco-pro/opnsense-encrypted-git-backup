#!/bin/sh
set -eu
test "$(uname -s)" = FreeBSD
test "$(freebsd-version -u | cut -d- -f1)" = 15.1
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
artifact="$work/pkg-2.8.4_1,1.pkg"
fetch -qo "$artifact" 'https://pkg.opnsense.org/FreeBSD:15:amd64/26.7/latest/All/pkg-2.8.4_1,1.pkg'
test "$(sha256 -q "$artifact")" = 2f40d3086883f2f64889132ab3e92ecd97f2628eaead5d9c3c2da6eaf2ec32ef
# Bootstrap the pinned package manager using OPNsense's standalone binary.
tar -xOf "$artifact" /usr/local/sbin/pkg-static > "$work/pkg-static"
chmod 0700 "$work/pkg-static"
"$work/pkg-static" add -f "$artifact"
test "$(pkg query '%v' pkg)" = '2.8.4_1,1'
