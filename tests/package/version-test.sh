#!/usr/bin/env bash
set -euo pipefail
mapper=$(realpath scripts/package-version.sh)
repo=$(mktemp -d)
trap 'rm -rf -- "$repo"' EXIT
cd "$repo"
git init -q
git -c user.name=Fixture -c user.email=fixture@example.test commit -qm first --allow-empty
original=$(git rev-parse HEAD)
git tag v1.2.3
test "$("$mapper" 1.2.3 "$original" v1.2.3)" = 1.2.3
test "$("$mapper" 1.2.3-rc.12 "$original")" = 1.2.3.rc12
! "$mapper" 1.2.3 "$original" v9.9.9
! "$mapper" 1.2.3 0000000000000000000000000000000000000000
git -c user.name=Fixture -c user.email=fixture@example.test commit -qm second --allow-empty
! "$mapper" 1.2.3 "$(git rev-parse HEAD)"
if command -v pkg >/dev/null; then
    test "$(pkg version -t 1.2.3.alpha2 1.2.3.beta1)" = '<'
    test "$(pkg version -t 1.2.3.beta1 1.2.3.rc1)" = '<'
    test "$(pkg version -t 1.2.3.rc1 1.2.3.rc12)" = '<'
    test "$(pkg version -t 1.2.3.rc12 1.2.3)" = '<'
    test "$(pkg version -t 1.2.3 1.2.4.alpha1)" = '<'
fi
