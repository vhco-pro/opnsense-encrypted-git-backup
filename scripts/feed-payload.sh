#!/usr/bin/env bash
set -euo pipefail

# Only extract a plain, bounded archive. No links, devices or path traversal.
[[ $# == 3 ]]
archive=$1
digest=$2
destination=$3
[[ "$digest" =~ ^[a-f0-9]{64}$ ]]
printf '%s  %s\n' "$digest" "$archive" | sha256sum --check --status
[[ -d "$destination" && -z "$(ls -A -- "$destination")" ]]
[[ $(stat -c '%s' -- "$archive") -le 536870912 ]]
listing=$(LC_ALL=C tar --quoting-style=escape -tf "$archive")
[[ -n "$listing" ]]
while IFS= read -r path; do
    [[ "$path" =~ ^([A-Za-z0-9_-][A-Za-z0-9._-]*/)*[A-Za-z0-9_-][A-Za-z0-9._-]*/?$ ]]
done <<< "$listing"
[[ $(sort -u <<< "$listing" | wc -l) == $(wc -l <<< "$listing") ]]
LC_ALL=C tar --quoting-style=escape -tvf "$archive" | awk '
    !/^[-d]/ { invalid = 1 }
    END { exit invalid }
'
tar --extract --file "$archive" --directory "$destination" --no-same-owner --no-same-permissions
