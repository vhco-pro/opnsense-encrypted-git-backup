#!/bin/sh
# Independently verify the retained synthetic input pair while admission is closed.
set -eu
directory=$1
state=/conf/encrypted-git-backup
repo=/tmp/fixture.git
test ! -e "$state/activation.json"
test ! -e /usr/local/etc/rc.syshook.d/config/10-git-backup
test "$(sha256 -q /conf/config.xml)" = "$(sha256 -q "$directory/settings")"
php -r '
    $checkpoint = json_decode(file_get_contents($argv[1]), true, 8, JSON_THROW_ON_ERROR);
    $config = simplexml_load_file($argv[2], "SimpleXMLElement", LIBXML_NONET);
    $provider = $config->system->backup->encryptedgit;
    exit(
        $checkpoint["destination"] === (string)$provider->destination
        && $checkpoint["branch"] === (string)$provider->branch
        && hash_file("sha256", $argv[1]) === (string)$provider->activation
        ? 0 : 1
    );
' "$directory/checkpoint" "$directory/settings"
parent=$(php -r '
    $checkpoint = json_decode(file_get_contents($argv[1]), true, 8, JSON_THROW_ON_ERROR);
    echo $checkpoint["legacy"]["remote"];
' "$directory/checkpoint")
pending=$(git -C "$state/pending" rev-parse HEAD)
remote=$(git -C "$repo" rev-parse refs/heads/migration)
git -C "$state/pending" merge-base --is-ancestor "$parent" "$pending"
git -C "$state/pending" merge-base --is-ancestor "$remote" "$pending"
printf '%s\n' NATIVE_ROLLBACK_PAIR_VERIFIED
