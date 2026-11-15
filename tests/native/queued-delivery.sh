#!/bin/sh
# Run after the upgraded browser fixture has verified its migration branch.
set -eu
work=$(mktemp -d /tmp/encryptedgit-queue.XXXXXXXX)
trap 'rm -rf "$work"' EXIT
repo=/tmp/fixture.git
before=$(git -C "$repo" rev-parse migration)
php /tmp/queued-settings.php "$work" &
writer=$!
while [ ! -f "$work/locked" ]; do
    kill -0 "$writer"
    sleep 1
done
configctl encryptedgit run > "$work/run.json" &
delivery=$!
# Keep the old settings locked while configd starts the delivery worker.
sleep 3
touch "$work/proceed"
wait "$writer"
wait "$delivery"
php -r '
    $reply = json_decode(file_get_contents($argv[1]), true, 8, JSON_THROW_ON_ERROR);
    exit(is_string($reply["error"] ?? null) && !isset($reply["commit"]) ? 0 : 1);
' "$work/run.json"
test "$(git -C "$repo" rev-parse migration)" = "$before"
printf '%s\n' NATIVE_QUEUED_DISABLED_WRITE_OK
