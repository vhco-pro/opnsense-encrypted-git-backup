#!/usr/bin/env bash
set -euo pipefail

# Append a closure only after fresh native evidence. Never use expiring
# deployment statuses as the authoritative journal.
[[ $# == 10 ]]
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$root/feed-publication-mode.sh" "$1"
temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
publication_headers "$temp"
shift
journal=$1
source=$2
attempt=$3
deployment=$4
digest=$5
version=$6
history=$7
release=$8
withdrawn=$9
jq -n --arg environment "$environment" --arg source "$source" --arg attempt "$attempt" --arg deployment "$deployment" --arg digest "$digest" --arg version "$version" --arg history "$history" --arg release "$release" --arg withdrawn "$withdrawn" '{
    ref:$source, environment:$environment, auto_merge:false, required_contexts:[],
    transient_environment:false, production_environment:false,
    payload:{phase:"verified-closure",attempt:$attempt,deployment:$deployment,digest:$digest,version:$version,history:$history,release:$release,withdrawn:$withdrawn}
}' | curl --silent --show-error --fail --max-time 15 --retry 0 \
    "${github_headers[@]}" -H 'Content-Type: application/json' --data-binary @- "$journal" |
    jq -e --arg attempt "$attempt" --arg digest "$digest" --arg version "$version" --arg history "$history" --arg release "$release" --arg withdrawn "$withdrawn" \
        --arg source "$source" --arg deployment "$deployment" '
        .sha == $source and .payload.withdrawn == $withdrawn and .payload.history == $history and .payload.release == $release and .payload.deployment == $deployment
        and .payload.phase == "verified-closure" and .payload.attempt == $attempt and .payload.digest == $digest and .payload.version == $version
    ' >/dev/null
