#!/usr/bin/env bash
set -euo pipefail

# Append a closure only after fresh native evidence. Never use expiring
# deployment statuses as the authoritative journal.
[[ $# == 5 ]]
journal=$1
source=$2
attempt=$3
deployment=$4
digest=$5
jq -n --arg source "$source" --arg attempt "$attempt" --arg deployment "$deployment" --arg digest "$digest" '{
    ref:$source, environment:"feed-fixture", auto_merge:false, required_contexts:[],
    transient_environment:false, production_environment:false,
    payload:{phase:"verified-closure",attempt:$attempt,deployment:$deployment,digest:$digest}
}' | curl --silent --show-error --fail --max-time 15 --retry 0 \
    -H 'Content-Type: application/json' --data-binary @- "$journal" |
    jq -e --arg attempt "$attempt" --arg digest "$digest" '
        .payload.phase == "verified-closure" and .payload.attempt == $attempt and .payload.digest == $digest
    ' >/dev/null
