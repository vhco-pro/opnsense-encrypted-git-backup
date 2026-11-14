#!/bin/sh
set -eu

generation=$(realpath "$1")
version=$2
name=os-encrypted-git-backup
test "$(pkg query -F "$generation/$name-$version.pkg" '%n %v')" = "$name $version"
tar -xOf "$generation/packagesite.pkg" packagesite.yaml |
    jq -se --arg name "$name" --arg version "$version" '
        any(.[]; .name == $name and .version == $version
            and (.path | endswith($name + "-" + $version + ".pkg")))'
