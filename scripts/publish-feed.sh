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
request "${github_headers[@]}" -D "$temp/journal-headers" "$journal?environment=$environment&per_page=100" > "$temp/journal"
if grep -Ei '^link:' "$temp/journal-headers" | grep -Eq 'rel="next"'; then
    echo 'Feed journal exceeds the supported complete-read bound.' >&2
    exit 1
fi
jq -e 'type == "array" and length < 100' "$temp/journal" >/dev/null
generation=$(jq -ce -f "$scripts/feed-journal-generation.jq" "$temp/journal")
started=$(jq -c '.latest // {}' <<< "$generation")
predecessor=$(jq -c '.closed // {}' <<< "$generation")
[[ "$(jq -r .payload.digest <<< "$started")" == "${FEED_DIGEST:-}" || "$started" == '{}' ||
   "$(jq -r .payload.attempt <<< "$started")" == "$(jq -r .payload.attempt <<< "$predecessor")" ]]
if [[ "$started" != '{}' && "$(jq -r .payload.digest <<< "$started")" != "${FEED_DIGEST:-}" ]]; then
    started='{}'
fi
history_digest=
if [[ -n "${FEED_HISTORY:-}" ]]; then
    checkpoint=$(jq -ce '
        [.[] | select(.payload.phase == "history-checkpoint")] |
        if length <= 1 then first // {} else error("conflicting history journal") end
    ' "$temp/journal")
    # Replay uses the predecessor it originally extended, even after closure.
    if [[ "$started" != '{}' ]]; then
        parent=$(jq -r '.payload.predecessor // ""' <<< "$started")
        if [[ -n "$parent" ]]; then
            predecessor=$(jq -ce --arg parent "$parent" '
                [.[] | select(.payload.phase == "verified-closure" and .payload.attempt == $parent)] |
                if length == 1 then first else error("missing predecessor closure") end
            ' "$temp/journal")
        else
            predecessor='{}'
        fi
    fi
    if [[ "$predecessor" != '{}' ]]; then
        checkpoint=$(jq -c '{payload:{digest:.payload.history,release:.payload.release}}' <<< "$predecessor")
    fi
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
        requested=$(jq -cS . "$FEED_HISTORY" | sha256sum | cut -d ' ' -f 1)
        [[ "$requested" == "$anchor" ]] || {
            echo 'retained history checkpoint changed' >&2
            exit 1
        }
        asset="history-$anchor.json"
        gh release download "$release" --repo "$GITHUB_REPOSITORY" --pattern "$asset" --dir "$temp"
        printf '%s  %s\n' "$anchor" "$temp/$asset" | sha256sum --check --status
        mv "$temp/$asset" "$temp/checkpoint"
    fi
    history_digest=$(jq -cS . "$temp/checkpoint" | sha256sum | cut -d ' ' -f 1)
    jq -e --slurpfile checkpoint "$temp/checkpoint" '. == $checkpoint[0]' "$FEED_HISTORY" >/dev/null || {
        echo 'retained history checkpoint changed' >&2
        exit 1
    }
    jq -n --argjson started "$started" '[ $started | select(. != {}) ]' |
        jq -ce --arg digest "$history_digest" --argjson checkpoint "$(jq -c . "$temp/checkpoint")" \
            -f "$scripts/feed-history.jq" > "$temp/history"
    bash "$scripts/check-feed-history.sh" "$temp/history" "$FEED_DIRECTORY"
    bash "$scripts/check-feed-history.sh" "$temp/history" "$(dirname -- "$FEED_DIRECTORY")/recovery"
fi
if [[ "$started" != '{}' ]]; then
    attempt=$(jq -er '.payload.attempt | select(test("^[a-f0-9]{32}$"))' <<< "$started")
    digest=$(jq -er '.payload.digest | select(test("^[a-f0-9]{64}$"))' <<< "$started")
    request "${pages_headers[@]}" "$PAGES_API/deployments?env=production&page=1&per_page=100" > "$temp/pages"
    correlate() {
        jq -ce --arg attempt "feed-attempt:$1" '
            select(.success == true and (.result | type == "array" and length < 100)) |
            [.result[] | select(.environment == "production"
                and .deployment_trigger.metadata.commit_message == $attempt)] |
            if length == 1 then first else error("unresolved Pages create") end
        ' "$temp/pages"
    }
    live_id_is() {
        request "${pages_headers[@]}" "$PAGES_API" | jq -e --arg id "$1" '
            .success == true and .result.canonical_deployment.id == $id
        ' >/dev/null
    }
    terminal_outcome() {
        jq -r '.latest_stage |
            if (.ended_on | type != "string" or length == 0) then "unknown"
            elif .name == "deploy" and .status == "success" then "success"
            elif .status == "failure" or .status == "canceled" then "failure"
            else "unknown" end'
    }
    match=$(correlate "$attempt")
    id=$(jq -er '.id | strings | select(length > 0)' <<< "$match")
    outcome=$(terminal_outcome <<< "$match")
    marker=$(jq -er '.payload.marker // .payload.digest | select(test("^[a-f0-9]{64}$"))' <<< "$started")
    if [[ -n "${FEED_NATIVE_MANIFEST:-}" ]]; then
        [[ "$(sha256sum -- "$FEED_NATIVE_MANIFEST" | cut -d ' ' -f 1)" == "$marker" ]]
        [[ "${FEED_DIGEST:?}" == "$digest" ]]
        recovery_digest=$(jq -er .payload.recovery <<< "$started")
        [[ "${FEED_RECOVERY_DIGEST:?}" == "$recovery_digest" ]]
        version=$(jq -er .version "$FEED_NATIVE_MANIFEST")
        source_sha=$(jq -er .sha <<< "$started")
        [[ "$(jq -er .source "$FEED_NATIVE_MANIFEST")" == "$source_sha" ]]
        jq -r 'to_entries[] | [.key, .value] | @tsv' "$temp/history" > "$temp/advertised"
        source "$scripts/feed-retirement.sh"
        if [[ "$retirement" != '{}' ]]; then validate_retirement; fi
        withdrawn=$(jq -r '.payload.withdrawn // ""' <<< "$predecessor")
        if [[ -n "$withdrawn" ]]; then
            [[ "$withdrawn" =~ ^[A-Za-z0-9_-]+$ ]]
        fi
        if jq -e '.recovery != null' <<< "$generation" >/dev/null; then
            source "$scripts/feed-recovery.sh"
            [[ "$(jq -r .payload.source <<< "$(jq -c .recovery <<< "$generation")")" == "$id" ]]
            if jq -e '.retries | length == 0' <<< "$generation" >/dev/null; then live_id_is "$id"; fi
            [[ "${FEED_RECOVERY_AUTHORIZED:-}" == true ]]
            reconcile_recovery "$id"
            [[ "$id" != "$(jq -r .id <<< "$match")" ]] || exit 0
        else
            live_id_is "$id"
            request "$FEED_URL/generation.json" | jq -e --arg marker "$marker" '.digest == $marker' >/dev/null
            [[ "$outcome" != unknown ]]
            if [[ "$outcome" == success && "$retirement" != '{}' ]]; then
                bash "$scripts/verify-feed-generation.sh" "$FEED_URL" "$FEED_NATIVE_MANIFEST" "${FEED_PUBLIC_KEY:?}" "${FEED_ABI:?}"
                verify_retirement
                withdrawn=$(jq -er .path <<< "$retirement")
            elif [[ "$outcome" == failure ]] ||
                ! bash "$scripts/verify-feed-generation.sh" "$FEED_URL" "$FEED_NATIVE_MANIFEST" "${FEED_PUBLIC_KEY:?}" "${FEED_ABI:?}"
            then
                # A later verification failure on a closed generation holds
                # for diagnosis; it cannot reopen this activation.
                [[ "$(jq -r '.closed.payload.attempt // ""' <<< "$generation")" != "$attempt" ]] || exit 1
                [[ "${FEED_RECOVERY_AUTHORIZED:-}" == true ]]
                source "$scripts/feed-recovery.sh"
                reconcile_recovery "$id"
                exit 0
            fi
        fi
        if [[ -n "$withdrawn" ]]; then verify_withdrawal "$withdrawn"; fi
        while IFS=$'\t' read -r path expected; do
            actual=$(request "$FEED_URL/$path" | sha256sum | cut -d ' ' -f 1)
            [[ "$actual" == "$expected" ]] || {
                echo 'Served package history does not match the journal.' >&2
                exit 1
            }
        done < "$temp/advertised"
        history_head=$(jq -cS . "$temp/history" | sha256sum | cut -d ' ' -f 1)
        closed=$(jq -er --arg source "$source_sha" --arg history "$history_head" --arg withdrawn "$withdrawn" --arg version "$version" --arg attempt "$attempt" --arg id "$id" --arg digest "$digest" '
            [.[] | select(.payload.phase == "verified-closure" and .payload.attempt == $attempt)] |
            if length == 0 then "false"
            elif length == 1 and .[0].payload.deployment == $id and .[0].payload.digest == $digest
                and (.[0].payload.withdrawn // "") == $withdrawn and .[0].payload.history == $history and .[0].sha == $source and .[0].payload.version == $version then "true"
            else error("conflicting closure") end
        ' "$temp/journal")
        release=$(jq -er .tag "$FEED_NATIVE_MANIFEST")
        asset="history-$history_head.json"
        jq -cS . "$temp/history" > "$temp/$asset"
        mkdir "$temp/readback"
        if ! gh release download "$release" --repo "$GITHUB_REPOSITORY" --pattern "$asset" --dir "$temp/readback"; then
            [[ "$closed" == false ]]
            GH_TOKEN="${FEED_ASSET_TOKEN:-${GH_TOKEN:-}}" gh release upload "$release" "$temp/$asset" \
                --repo "$GITHUB_REPOSITORY" >&2
            gh release download "$release" --repo "$GITHUB_REPOSITORY" --pattern "$asset" --dir "$temp/readback"
        fi
        cmp "$temp/$asset" "$temp/readback/$asset"
        if [[ "$closed" == false ]]; then
            bash "$scripts/feed-close.sh" "$1" "$journal" "$source_sha" "$attempt" "$id" "$digest" "$version" "$history_head" "$release" "$withdrawn"
        fi
        printf '%s\n' 'Native client verification passed and closure is recorded.'
    else
        live_id_is "$id"
        [[ "$outcome" == success ]]
        request "$FEED_URL/generation.json" | jq -e --arg marker "$marker" '.digest == $marker' >/dev/null
        printf '%s\n' 'Matching terminal live generation observed; native client verification remains required.'
    fi
    exit 0
fi

: "${FEED_MANIFEST:?}" "${FEED_DIGEST:?}" "${PAGES_BRANCH:?}" "${FEED_DIRECTORY:?}"
[[ "$FEED_DIGEST" =~ ^[a-f0-9]{64}$ ]]
jq -e 'type == "object" and length > 0' "$FEED_MANIFEST" >/dev/null
prior_id=$(jq -r '.payload.deployment // ""' <<< "$predecessor")
request "${pages_headers[@]}" "$PAGES_API" | jq -e --arg prior "$prior_id" '
    .success == true and (.result | type == "object" and has("canonical_deployment")
    and (if $prior == "" then .canonical_deployment == null else .canonical_deployment.id == $prior end))
' >/dev/null
parent=$(jq -r '.payload.attempt // ""' <<< "$predecessor")
scripts=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
attempt=$(openssl rand -hex 16)
package_history='{}'
marker=$FEED_DIGEST
if [[ -n "${FEED_HISTORY:-}" ]]; then
    source "$scripts/feed-retirement.sh"
    withdrawn=$(jq -r '.payload.withdrawn // ""' <<< "$predecessor")
    if [[ -n "$withdrawn" ]]; then
        [[ "$withdrawn" =~ ^[A-Za-z0-9_-]+$ && "$retirement" == '{}' ]]
        for bundle in "$FEED_DIRECTORY" "$(dirname -- "$FEED_DIRECTORY")/recovery"; do
            jq -e --arg path "$withdrawn" 'all(keys[];
                . != ("/" + $path + "/meta.conf") and
                (test("^/" + $path + "/(packagesite|data|meta)[.](pkg|txz)$") | not))'                 "$bundle/pages-manifest.json" >/dev/null
        done
    fi
    if [[ "$retirement" != '{}' ]]; then
        validate_retirement
        [[ "$predecessor" != '{}' ]]
        [[ "${FEED_RETIREMENT_AUTHORIZED:-}" == true ]]
    fi
    marker=$(sha256sum -- "$FEED_NATIVE_MANIFEST" | cut -d ' ' -f 1)
    package_history=$(jq -ce --slurpfile manifest "$FEED_NATIVE_MANIFEST" '
        def retain($path; $digest):
            if has($path) and .[$path] != $digest
            then error("conflicting advertised package")
            else . + {($path):$digest}
            end;
        $manifest[0] as $next |
        retain($next.package; $next.packageSha256) |
        if $next | has("predecessorCatalogue") then
            $next.predecessorCatalogue as $old |
            retain(($old.path + "/os-encrypted-git-backup-" + $old.version + ".pkg"); $old.packageSha256)
        else . end
    ' "$temp/history")
    printf '%s\n' "$package_history" > "$temp/proposed-history"
    bash "$scripts/check-feed-history.sh" "$temp/proposed-history" "$FEED_DIRECTORY"
    bash "$scripts/check-feed-history.sh" "$temp/proposed-history" "$(dirname -- "$FEED_DIRECTORY")/recovery"
fi
jq -n --arg sha "$GITHUB_SHA" --arg environment "$environment" --arg attempt "$attempt" \
    --arg digest "$FEED_DIGEST" --arg marker "$marker" --arg history "$history_digest" --arg parent "$parent" --arg recovery "${FEED_RECOVERY_DIGEST:-}" --argjson packages "$package_history" '{
        ref:$sha, environment:$environment, auto_merge:false, required_contexts:[],
        transient_environment:false, production_environment:false,
        payload:{phase:"submission-started",attempt:$attempt,digest:$digest,marker:$marker,history:$history,predecessor:$parent,recovery:$recovery,packages:$packages}
    }' > "$temp/record"
node "$scripts/feed-pages-assets.mjs" "$PAGES_API" "$PAGES_ASSET_API" "$FEED_DIRECTORY" "$FEED_MANIFEST"
request "${github_headers[@]}" -H 'Content-Type: application/json' --data-binary "@$temp/record" "$journal" > "$temp/record-result"
jq -e --arg attempt "$attempt" --arg sha "$GITHUB_SHA" --arg digest "$FEED_DIGEST" --arg marker "$marker" --arg history "$history_digest" --arg parent "$parent" --arg recovery "${FEED_RECOVERY_DIGEST:-}" --argjson packages "$package_history" '
    .sha == $sha and .payload.attempt == $attempt and .payload.digest == $digest
    and .payload.phase == "submission-started" and .payload.packages == $packages and .payload.marker == $marker
    and .payload.history == $history and .payload.predecessor == $parent and .payload.recovery == $recovery
' "$temp/record-result" >/dev/null
request "${pages_headers[@]}" --form-string "branch=$PAGES_BRANCH" --form-string "commit_hash=$GITHUB_SHA" \
    --form-string "commit_message=feed-attempt:$attempt" -F "manifest=<$FEED_MANIFEST" \
    "$PAGES_API/deployments" | jq -e '.success == true and (.result.id | type == "string")' >/dev/null
printf '%s\n' 'Submission recorded. Reconcile the live generation on the next invocation.'
