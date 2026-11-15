#!/bin/sh
# Run as root only on the disposable appliance created by this fixture.
set -eu
input=/tmp/browser-inputs
build=/tmp/browser-build
mkdir "$build"
case "$1" in
    sets)
        opnsense-verify "$input/base-26.7.9-amd64.txz"
        opnsense-verify "$input/kernel-26.7.9-amd64.txz"
        opnsense-update -bkf -l "$input" -r 26.7.9
        ;;
    package)
        pkg-static add -f "$input"/All/pkg-*.pkg
        mkdir "$build/repo" "$build/repos"
        cp "$input"/All/*.pkg "$build/repo/"
        pkg repo "$build/repo"
        printf 'Fixture: { url: "file://%s/repo", enabled: yes }\n' "$build" >"$build/repos/Fixture.conf"
        pkg -o REPOS_DIR="$build/repos" update -f
        pkg -o REPOS_DIR="$build/repos" upgrade -y -r Fixture
        pkg -o REPOS_DIR="$build/repos" install -y -r Fixture bash git
        test "$(freebsd-version -k)" = 15.1-RELEASE-p6
        test "$(pkg query '%v' opnsense)" = 26.7.9_1
        test "$(php -r 'echo PHP_VERSION;')" = 8.5.12
        test "$(pkg config ABI)" = FreeBSD:15:amd64
        git clone "$input/plugin.bundle" "$build/plugin"
        git clone "$input/framework.bundle" "$build/framework"
        cd "$build/plugin"
        source_sha=$(cat "$input/source-sha")
        git checkout --detach "$source_sha"
        bash scripts/prepare-native-package.sh 0.0.9-alpha.90 "$source_sha" '' "$build/framework" "$build"
        package="$build/os-encrypted-git-backup-0.0.9.alpha90.pkg"
        sha256 "$package"
        pkg add "$package"
        pkg check -s os-encrypted-git-backup
        service configd restart
        ifconfig em0 inet 10.0.2.15/24 up
        pfctl -d
        sh tests/native/ssh-fixture.sh migration
        php tests/native/activation-smoke.php migration
        php tests/native/browser-users.php "$input/browser-password"
        php tests/native/browser-theme.php opnsense
        configctl encryptedgit run | grep -q '"commit"'
        ;;
    *) exit 64 ;;
esac
