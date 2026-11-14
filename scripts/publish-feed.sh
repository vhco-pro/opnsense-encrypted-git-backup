#!/usr/bin/env bash
set -euo pipefail

# Feed journal records are append-only GitHub deployments. Workflow concurrency
# is the single-writer boundary. A missing POST response never authorizes a retry.
[[ $# == 1 ]]
case "$1" in
    fixture)
        : "${GITHUB_API_URL:?}" "${PAGES_API:?}" "${PAGES_ASSET_API:?}" "${FEED_URL:?}"
        for url in "$GITHUB_API_URL" "$PAGES_API" "$PAGES_ASSET_API" "$FEED_URL"; do
            [[ "$url" =~ ^http://127[.]0[.]0[.]1:[0-9]+(/[A-Za-z0-9/_-]*)?$ ]]
        done
        environment=feed-fixture
        ;;
    *) echo 'Production publication is disabled.' >&2; exit 64 ;;
esac
: "${GITHUB_REPOSITORY:?}" "${GITHUB_SHA:?}"
[[ "$GITHUB_REPOSITORY" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]
[[ "$GITHUB_SHA" =~ ^[a-f0-9]{40}$ ]]
journal="$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/deployments"
temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
request() {
    curl --silent --show-error --fail --max-time 15 --retry 0 "$@"
}

# A bounded complete read. Hold if pagination would be required.
request "$journal?environment=$environment&per_page=100" > "$temp/journal"
jq -e 'type == "array" and length < 100' "$temp/journal" >/dev/null
started=$(jq -ce '
    [.[] | select(.payload.phase == "submission-started")] |
    if length <= 1 then first // {} else error("conflicting journal") end
' "$temp/journal")

if [[ "$started" != '{}' ]]; then
    attempt=$(jq -er '.payload.attempt | select(test("^[a-f0-9]{32}$"))' <<< "$started")
    digest=$(jq -er '.payload.digest | select(test("^[a-f0-9]{64}$"))' <<< "$started")
    request "$PAGES_API/deployments?env=production&page=1&per_page=100" > "$temp/pages"
    match=$(jq -ce --arg attempt "feed-attempt:$attempt" '
        select(.success == true and (.result | length) < 100) |
        [.result[] | select(.environment == "production"
            and .deployment_trigger.metadata.commit_message == $attempt)] |
        if length == 1 then first else error("unresolved Pages create") end
    ' "$temp/pages")
    id=$(jq -er '.id | strings | select(length > 0)' <<< "$match")
    request "$PAGES_API" | jq -e --arg id "$id" '
        .success == true and .result.canonical_deployment.id == $id
    ' >/dev/null
    request "$FEED_URL/generation.json" | jq -e --arg digest "$digest" '.digest == $digest' >/dev/null
    jq -e '.latest_stage | .name == "deploy" and .status == "success" and (.ended_on | type == "string")' \
        <<< "$match" >/dev/null
    if [[ -n "${FEED_NATIVE_MANIFEST:-}" ]]; then
        [[ "${FEED_DIGEST:?}" == "$digest" ]]
        scripts=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
        bash "$scripts/feed-verify-native.sh" "$FEED_URL" "$FEED_NATIVE_MANIFEST" "${FEED_PUBLIC_KEY:?}" "${FEED_ABI:?}"
        closed=$(jq -er --arg attempt "$attempt" --arg id "$id" --arg digest "$digest" '
            [.[] | select(.payload.phase == "verified-closure" and .payload.attempt == $attempt)] |
            if length == 0 then "false"
            elif length == 1 and .[0].payload.deployment == $id and .[0].payload.digest == $digest then "true"
            else error("conflicting closure") end
        ' "$temp/journal")
        if [[ "$closed" == false ]]; then
            bash "$scripts/feed-close.sh" "$journal" "$(jq -er .sha <<< "$started")" "$attempt" "$id" "$digest"
        fi
        printf '%s\n' 'Native client verification passed and closure is recorded.'
    else
        printf '%s\n' 'Matching terminal live generation observed; native client verification remains required.'
    fi
    exit 0
fi

: "${FEED_MANIFEST:?}" "${FEED_DIGEST:?}" "${PAGES_BRANCH:?}" "${FEED_DIRECTORY:?}"
[[ "$FEED_DIGEST" =~ ^[a-f0-9]{64}$ ]]
jq -e 'type == "object" and length > 0' "$FEED_MANIFEST" >/dev/null
request "$PAGES_API" | jq -e '.success == true and (.result | type == "object" and has("canonical_deployment") and .canonical_deployment == null)' >/dev/null
scripts=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
node "$scripts/feed-pages-assets.mjs" "$PAGES_API" "$PAGES_ASSET_API" "$FEED_DIRECTORY" "$FEED_MANIFEST"
attempt=$(openssl rand -hex 16)
package_history='{}'
if [[ -n "${FEED_HISTORY:-}" ]]; then
    package_history=$(jq -ce --slurpfile manifest "$FEED_NATIVE_MANIFEST" '
        $manifest[0] as $next |
        if has($next.package) and .[$next.package] != $next.packageSha256
        then error("conflicting advertised package")
        else . + {($next.package):$next.packageSha256}
        end
    ' "$FEED_HISTORY")
fi
jq -n --arg sha "$GITHUB_SHA" --arg environment "$environment" --arg attempt "$attempt" \
    --arg digest "$FEED_DIGEST" --argjson packages "$package_history" '{
        ref:$sha, environment:$environment, auto_merge:false, required_contexts:[],
        transient_environment:false, production_environment:false,
        payload:{phase:"submission-started",attempt:$attempt,digest:$digest,packages:$packages}
    }' > "$temp/record"
request -H 'Content-Type: application/json' --data-binary "@$temp/record" "$journal" > "$temp/record-result"
jq -e --arg attempt "$attempt" --arg sha "$GITHUB_SHA" --arg digest "$FEED_DIGEST" --argjson packages "$package_history" '
    .sha == $sha and .payload.attempt == $attempt and .payload.digest == $digest
    and .payload.phase == "submission-started" and .payload.packages == $packages
' "$temp/record-result" >/dev/null
request --form-string "branch=$PAGES_BRANCH" --form-string "commit_hash=$GITHUB_SHA" \
    --form-string "commit_message=feed-attempt:$attempt" -F "manifest=<$FEED_MANIFEST" \
    "$PAGES_API/deployments" | jq -e '.success == true and (.result.id | type == "string")' >/dev/null
printf '%s\n' 'Submission recorded. Reconcile the live generation on the next invocation.'
