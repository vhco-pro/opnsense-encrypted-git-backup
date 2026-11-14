#!/bin/sh
# Run inside the disposable FreeBSD fixture with its reverse loopback tunnel.
set -eu
action=$1
work=$2
url=$3
key=$4
version=$5
case "$work" in /tmp/feed-cache.*) ;; *) exit 64 ;; esac
case "$action" in
    cache)
        mkdir -p "$work/repos" "$work/db" "$work/cache"
        printf 'fixture: {url:"%s", signature_type:"pubkey", pubkey:"%s", enabled:yes}\n' "$url" "$key" > "$work/repos/fixture.conf"
        ;;
    fetch) ;;
    *) exit 64 ;;
esac
client() {
    pkg -o "REPOS_DIR=$work/repos" -o "PKG_DBDIR=$work/db" -o "PKG_CACHEDIR=$work/cache" "$@"
}
if [ "$action" = cache ]; then
    client update -f -r fixture </dev/null
fi
test "$(client rquery -r fixture '%v' os-encrypted-git-backup)" = "$version"
if [ "$action" = fetch ]; then
    # Fetch using the original authenticated repo DB, with autoupdate disabled
    # and an empty download cache.
    if [ -n "$(find "$work/cache" -type f -name '*.pkg' -print)" ]; then
        echo 'The native download cache already has a package.' >&2
        exit 1
    fi
    client -o REPO_AUTOUPDATE=false fetch -U -y -r fixture os-encrypted-git-backup
    for package in "$work"/cache/*; do
        [ -f "$package" ] || continue
        if [ "$(pkg query -F "$package" '%n %v')" = "os-encrypted-git-backup $version" ]; then
            exit 0
        fi
    done
    echo 'Native pkg did not download the cached catalogue version.' >&2
    exit 1
fi
