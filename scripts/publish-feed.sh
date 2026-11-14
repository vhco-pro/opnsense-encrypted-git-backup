#!/usr/bin/env bash
set -euo pipefail

# Feed journal records are append-only GitHub deployments. Workflow concurrency
# is the single-writer boundary. A missing POST response never authorizes a retry.
[[ $# == 1 ]]
scripts=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$scripts/feed-publication-mode.sh" "$1"
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
request "${github_headers[@]}" "$journal?environment=$environment&per_page=100" > "$temp/journal"
jq -e 'type == "array" and length < 100' "$temp/journal" >/dev/null
history_digest=
if [[ -n "${FEED_HISTORY:-}" ]]; then
    history_digest=$(jq -cS . "$FEED_HISTORY" | sha256sum | cut -d ' ' -f 1)
    checkpoint=$(jq -ce '
        [.[] | select(.payload.phase == "history-checkpoint")] |
        if length <= 1 then first // {} else error("conflicting history journal") end
    ' "$temp/journal")
    if [[ "$checkpoint" == '{}' ]]; then
        jq -e '. == {}' "$FEED_HISTORY" >/dev/null || {
            echo 'missing authoritative history checkpoint' >&2
            exit 1
        }
        printf '{}\n' > "$temp/checkpoint"
    else
        anchor=$(jq -er '.payload.digest | select(test("^[a-f0-9]{64}$"))' <<< "$checkpoint")
        release=$(jq -er '.payload.release | select(test("^v[0-9]+[.][0-9]+[.][0-9]+(-(alpha|beta|rc)[.][0-9]+)?$"))' \
            <<< "$checkpoint")
        [[ "$anchor" == "$history_digest" ]] || {
            echo 'retained history checkpoint changed' >&2
            exit 1
        }
        asset="history-$anchor.json"
        gh release download "$release" --repo "$GITHUB_REPOSITORY" --pattern "$asset" --dir "$temp"
        printf '%s  %s\n' "$anchor" "$temp/$asset" | sha256sum --check --status
        mv "$temp/$asset" "$temp/checkpoint"
    fi
    jq -ce --arg digest "$history_digest" --argjson checkpoint "$(jq -c . "$temp/checkpoint")" \
        -f "$scripts/feed-history.jq" "$temp/journal" > "$temp/history"
    bash "$scripts/check-feed-history.sh" "$temp/history" "$FEED_DIRECTORY"
    bash "$scripts/check-feed-history.sh" "$temp/history" "$(dirname -- "$FEED_DIRECTORY")/recovery"
fi
started=$(jq -ce '
    [.[] | select(.payload.phase == "submission-started")] |
    if length <= 1 then first // {} else error("conflicting journal") end
' "$temp/journal")

if [[ "$started" != '{}' ]]; then
    attempt=$(jq -er '.payload.attempt | select(test("^[a-f0-9]{32}$"))' <<< "$started")
    digest=$(jq -er '.payload.digest | select(test("^[a-f0-9]{64}$"))' <<< "$started")
    request "${pages_headers[@]}" "$PAGES_API/deployments?env=production&page=1&per_page=100" > "$temp/pages"
    match=$(jq -ce --arg attempt "feed-attempt:$attempt" '
        select(.success == true and (.result | length) < 100) |
        [.result[] | select(.environment == "production"
            and .deployment_trigger.metadata.commit_message == $attempt)] |
        if length == 1 then first else error("unresolved Pages create") end
    ' "$temp/pages")
    id=$(jq -er '.id | strings | select(length > 0)' <<< "$match")
    request "${pages_headers[@]}" "$PAGES_API" | jq -e --arg id "$id" '
        .success == true and .result.canonical_deployment.id == $id
    ' >/dev/null
    marker=$(jq -er '.payload.marker // .payload.digest | select(test("^[a-f0-9]{64}$"))' <<< "$started")
    request "$FEED_URL/generation.json" | jq -e --arg marker "$marker" '.digest == $marker' >/dev/null
    jq -e '.latest_stage | .name == "deploy" and .status == "success" and (.ended_on | type == "string")' \
        <<< "$match" >/dev/null
    if [[ -n "${FEED_NATIVE_MANIFEST:-}" ]]; then
        [[ "$(sha256sum -- "$FEED_NATIVE_MANIFEST" | cut -d ' ' -f 1)" == "$marker" ]]
        [[ "${FEED_DIGEST:?}" == "$digest" ]]
        [[ "${FEED_RECOVERY_DIGEST:?}" == "$(jq -er .payload.recovery <<< "$started")" ]]
        scripts=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
        bash "$scripts/run-feed-verifier.sh" "$FEED_URL" "$FEED_NATIVE_MANIFEST" "${FEED_PUBLIC_KEY:?}" "${FEED_ABI:?}"
        version=$(jq -er .version "$FEED_NATIVE_MANIFEST")
        source_sha=$(jq -er .sha <<< "$started")
        [[ "$(jq -er .source "$FEED_NATIVE_MANIFEST")" == "$source_sha" ]]
        history_head=$(jq -cS . "$temp/history" | sha256sum | cut -d ' ' -f 1)
        closed=$(jq -er --arg source "$source_sha" --arg history "$history_head" --arg version "$version" --arg attempt "$attempt" --arg id "$id" --arg digest "$digest" '
            [.[] | select(.payload.phase == "verified-closure" and .payload.attempt == $attempt)] |
            if length == 0 then "false"
            elif length == 1 and .[0].payload.deployment == $id and .[0].payload.digest == $digest
                and .[0].payload.history == $history and .[0].sha == $source and .[0].payload.version == $version then "true"
            else error("conflicting closure") end
        ' "$temp/journal")
        if [[ "$closed" == false ]]; then
            bash "$scripts/feed-close.sh" "$1" "$journal" "$source_sha" "$attempt" "$id" "$digest" "$version" "$history_head"
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
request "${pages_headers[@]}" "$PAGES_API" | jq -e '.success == true and (.result | type == "object" and has("canonical_deployment") and .canonical_deployment == null)' >/dev/null
scripts=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
attempt=$(openssl rand -hex 16)
package_history='{}'
marker=$FEED_DIGEST
if [[ -n "${FEED_HISTORY:-}" ]]; then
    marker=$(sha256sum -- "$FEED_NATIVE_MANIFEST" | cut -d ' ' -f 1)
    package_history=$(jq -ce --slurpfile manifest "$FEED_NATIVE_MANIFEST" '
        $manifest[0] as $next |
        if has($next.package) and .[$next.package] != $next.packageSha256
        then error("conflicting advertised package")
        else . + {($next.package):$next.packageSha256}
        end
    ' "$temp/history")
fi
jq -n --arg sha "$GITHUB_SHA" --arg environment "$environment" --arg attempt "$attempt" \
    --arg digest "$FEED_DIGEST" --arg marker "$marker" --arg history "$history_digest" --arg recovery "${FEED_RECOVERY_DIGEST:-}" --argjson packages "$package_history" '{
        ref:$sha, environment:$environment, auto_merge:false, required_contexts:[],
        transient_environment:false, production_environment:false,
        payload:{phase:"submission-started",attempt:$attempt,digest:$digest,marker:$marker,history:$history,recovery:$recovery,packages:$packages}
    }' > "$temp/record"
node "$scripts/feed-pages-assets.mjs" "$PAGES_API" "$PAGES_ASSET_API" "$FEED_DIRECTORY" "$FEED_MANIFEST"
request "${github_headers[@]}" -H 'Content-Type: application/json' --data-binary "@$temp/record" "$journal" > "$temp/record-result"
jq -e --arg attempt "$attempt" --arg sha "$GITHUB_SHA" --arg digest "$FEED_DIGEST" --arg marker "$marker" --arg history "$history_digest" --arg recovery "${FEED_RECOVERY_DIGEST:-}" --argjson packages "$package_history" '
    .sha == $sha and .payload.attempt == $attempt and .payload.digest == $digest
    and .payload.phase == "submission-started" and .payload.packages == $packages and .payload.marker == $marker
    and .payload.history == $history and .payload.recovery == $recovery
' "$temp/record-result" >/dev/null
request "${pages_headers[@]}" --form-string "branch=$PAGES_BRANCH" --form-string "commit_hash=$GITHUB_SHA" \
    --form-string "commit_message=feed-attempt:$attempt" -F "manifest=<$FEED_MANIFEST" \
    "$PAGES_API/deployments" | jq -e '.success == true and (.result.id | type == "string")' >/dev/null
printf '%s\n' 'Submission recorded. Reconcile the live generation on the next invocation.'
