#!/bin/sh
# Runs only in the owned disposable appliance. It saves the fixture configuration.
set -eu
actions=$1
work=$(mktemp -d /tmp/encryptedgit-timeout.XXXXXXXX)
trap 'rm -rf "$work"' EXIT
boot=/usr/local/opnsense/mvc/script/load_phalcon.php
worker=/usr/local/opnsense/scripts/encryptedgit/run.php
command=$(awk '/^\[run\]$/ { run=1; next } run && /^command:/ { sub(/^command:/, ""); print; exit }' "$actions")
case "$command" in
    "/usr/local/bin/php $worker")
        set --
        ;;
    "/usr/bin/timeout -k 5 195 /usr/local/bin/php $worker")
        # Use the same native reaper with shorter test durations.
        set -- /usr/bin/timeout -k 1 2
        ;;
    *) exit 2 ;;
esac

"$@" /usr/local/bin/php -r '
    require $argv[1];
    $config = OPNsense\Core\Config::getInstance();
    $config->lock();
    touch($argv[2]);
    sleep(6);
' "$boot" "$work/locked" &
worker_pid=$!
while [ ! -f "$work/locked" ]; do
    kill -0 "$worker_pid"
    sleep 0.1
done

elapsed=$(/usr/local/bin/php -r '
    require $argv[1];
    $start = hrtime(true);
    $config = OPNsense\Core\Config::getInstance();
    $config->lock();
    try {
        $config->save(null, false);
    } finally {
        $config->unlock();
    }
    echo (int) ((hrtime(true) - $start) / 1_000_000);
' "$boot")
status=0
wait "$worker_pid" || status=$?
printf 'Native config save waited %s ms; worker exit %s\n' "$elapsed" "$status"
test "$elapsed" -lt 4000
test "$status" -eq 124
