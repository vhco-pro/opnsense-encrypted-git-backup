#!/usr/bin/env bash
set -euo pipefail
if [[ $# != 4 ]]; then
    echo "Usage: $0 state-directory observations.json dispatch-id adapter" >&2
    exit 64
fi
state=$(realpath "$1")
evidence=$2
dispatch=$3
adapter=$(realpath "$4")
script=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
[[ "$dispatch" =~ ^[0-9]+$ ]]
# The adapter is invoked only after one exclusive holder has committed the intent.
exec 9>"$state/lock"
flock -n 9
journal="$state/attempt.json"
if [[ -e "$journal" ]]; then
    # An unresolved create must be reconciled by the publisher before another create.
    jq -e '.resolved == true' "$journal" >/dev/null
    consumed=$(jq -ec '.consumed | select(type == "array")' "$journal")
else
    consumed='[]'
fi
decision=$(jq --arg dispatch "$dispatch" --argjson consumed "$consumed"     '. + {dispatch:$dispatch, consumed:$consumed}' "$evidence" | jq -r -f "$script/feed-reconcile.jq")
case "$decision" in
    retry|recover|retry-recovery) ;;
    *) printf '%s\n' "$decision"; exit 0 ;;
esac
digest=$(jq -er '.bundleDigest | select(test("^[a-f0-9]{64}$"))' "$evidence")
if [[ "$decision" == retry-recovery ]]; then
    consumed=$(jq -cn --argjson consumed "$consumed" --arg dispatch "$dispatch" '$consumed + [$dispatch]')
fi
umask 077
temporary=$(mktemp "$state/attempt.XXXXXXXX")
trap 'rm -f -- "$temporary"' EXIT
attempt=$(openssl rand -hex 16)
jq -n --arg attempt "$attempt" --arg digest "$digest" --arg action "$decision" --argjson consumed "$consumed"     '{attempt:$attempt, bundleDigest:$digest, action:$action, consumed:$consumed, resolved:false}' > "$temporary"
mv -f -- "$temporary" "$journal"
"$adapter" "$attempt" "$digest"
