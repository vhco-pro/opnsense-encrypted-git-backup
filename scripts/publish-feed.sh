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
publication_headers "$temp"
request() {
    curl --silent --show-error --fail --max-time 15 --retry 0 "$@"
}

append_verified_submission() {
    local record=$1 id
    id=$(request "${github_headers[@]}" -H 'Content-Type: application/json' \
        --data-binary "@$record" "$journal" | jq -er '.id | select(type == "number" and . > 0 and . == floor)') ||
        return 1
    [[ "$id" =~ ^[0-9]+$ ]] || return 1
    request "${github_headers[@]}" "$journal/$id" |
        jq -e --argjson id "$id" --slurpfile sent "$record" '
            .id == $id and .sha == $sent[0].ref and .environment == $sent[0].environment
            and .payload == $sent[0].payload
        ' >/dev/null
}

# Classify only a complete, structured Pages authentication rejection. A lost
# response or any other response stays unresolved until provider correlation.
create_pages() {
    local create_source=$1 submission=$2 manifest=$3 status
    status=$(request --no-fail --output "$temp/create-response" --write-out '%{http_code}' \
        "${pages_headers[@]}" --form-string "branch=$PAGES_BRANCH" --form-string "commit_hash=$create_source" \
        --form-string "commit_message=feed-attempt:$submission" -F "manifest=<$manifest" \
        "$PAGES_API/deployments") || return 1
    if [[ "$status" == 403 ]] && jq -es '
        length == 1 and (.[0] | .success == false and .result == null
        and (.errors | type == "array" and length == 1 and .[0].code == 10000))
    ' "$temp/create-response" >/dev/null; then
        jq -n --arg environment "$environment" --arg source "$create_source" --arg attempt "$submission" '{
            ref:$source, environment:$environment, auto_merge:false, required_contexts:[],
            transient_environment:false, production_environment:false,
            payload:{phase:"create-rejected",attempt:$attempt,category:"authentication"}
        }' > "$temp/rejection"
        request "${github_headers[@]}" -H 'Content-Type: application/json' --data-binary "@$temp/rejection" "$journal" |
            jq -e --slurpfile sent "$temp/rejection" '.sha == $sent[0].ref and .payload == $sent[0].payload' >/dev/null ||
            return 1
        echo 'Pages create rejected (HTTP 403 authentication).' >&2
        return 1
    fi
    [[ "$status" =~ ^2[0-9]{2}$ ]] &&
        jq -e '.success == true and (.result.id | strings | length > 0)' "$temp/create-response" >/dev/null
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
history_record() {
    jq -cS . "$1" > "$temp/successor"
    successor=$(sha256sum "$temp/successor" | cut -d ' ' -f 1)
    history_asset="history-$successor.json"
    history_release=$(jq -er .tag "$FEED_NATIVE_MANIFEST")
    jq -cnS --arg sha "$GITHUB_SHA" --arg candidate "$FEED_DIGEST" --arg recovery "$FEED_RECOVERY_DIGEST" \
        --arg prior "$history_digest" --arg successor "$successor" --arg predecessor "$2" \
        --arg marker "$(sha256sum "$FEED_NATIVE_MANIFEST" | cut -d ' ' -f 1)" '
        {sha:$sha,candidate:$candidate,recovery:$recovery,prior:$prior,successor:$successor,
            predecessor:$predecessor,manifest:$marker}
    ' > "$temp/approval"
    approval=$(sha256sum "$temp/approval" | cut -d ' ' -f 1)
    approval_asset="approval-$approval.json"
}
read_history_asset() {
    gh release download "$history_release" --repo "$GITHUB_REPOSITORY" --pattern "$1" --dir "$temp/readback"
}
store_history_asset() {
    cp "$1" "$temp/$2"
    GH_TOKEN="${FEED_ASSET_TOKEN:-${GH_TOKEN:-}}" gh release upload "$history_release" "$temp/$2" \
        --repo "$GITHUB_REPOSITORY" >&2
    read_history_asset "$2"
}
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
    if [[ "$started" != '{}' ]]; then
        history_record "$temp/history" "$(jq -r '.payload.predecessor // ""' <<< "$started")"
        jq -e --arg successor "$successor" --arg approval "$approval" '
            .payload.successor == $successor and .payload.approval == $approval
        ' <<< "$started" >/dev/null
        mkdir "$temp/readback"
        read_history_asset "$approval_asset"
        cmp "$temp/approval" "$temp/readback/$approval_asset"
        read_history_asset "$history_asset"
        cmp "$temp/successor" "$temp/readback/$history_asset"
    fi
fi
if [[ "$started" != '{}' ]]; then
    attempt=$(jq -er '.payload.attempt | select(test("^[a-f0-9]{32}$"))' <<< "$started")
    digest=$(jq -er '.payload.digest | select(test("^[a-f0-9]{64}$"))' <<< "$started")
    request "${pages_headers[@]}" "$PAGES_API/deployments?env=production&page=1&per_page=25" > "$temp/pages"
    if ! jq -e '
        .success == true and (.result | type == "array" and length <= 25)
        and .result_info.page == 1 and .result_info.per_page == 25
        and .result_info.count == (.result | length)
        and .result_info.total_count == .result_info.count
        and (.result_info.total_pages == (if .result_info.count == 0 then 0 else 1 end))
    ' "$temp/pages" >/dev/null; then
        echo 'incomplete Pages deployment list' >&2
        exit 1
    fi
    correlate() {
        jq -ce --arg attempt "feed-attempt:$1" '
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
    canonical_id() {
        request "${pages_headers[@]}" "$PAGES_API" | jq -er '
            select(.success == true and (.result | type == "object" and has("canonical_deployment"))) |
            .result.canonical_deployment |
            if . == null then "" else .id | strings | select(length > 0) end
        '
    }
    terminal_outcome() {
        jq -r '.latest_stage |
            if (.ended_on | type != "string" or length == 0) then "unknown"
            elif .name == "deploy" and .status == "success" then "success"
            elif .status == "failure" or .status == "canceled" then "failure"
            else "unknown" end'
    }
    rejected() {
        jq -e --arg attempt "$1" '.rejected | index($attempt) != null' <<< "$generation" >/dev/null
    }
    confirm_rejected() {
        jq -e --arg message "feed-attempt:$1" '
            all(.result[]; .deployment_trigger.metadata.commit_message != $message)
        ' "$temp/pages" >/dev/null
    }
    prior=$(jq -r '.payload.deployment // ""' <<< "$predecessor")
    verify_unchanged_feed() {
        local recovery_dir observed
        recovery_dir="$(dirname -- "$FEED_DIRECTORY")/recovery"
        observed=$(canonical_id) || return 1
        [[ "$observed" == "$prior" ]] || return 1
        if [[ -n "$prior" ]]; then
            [[ -f "$recovery_dir/release.json" ]] || return 1
        else
            [[ ! -e "$recovery_dir/release.json" ]] || return 1
        fi
        withdrawn=$(jq -r '.payload.withdrawn // ""' <<< "$predecessor")
        if [[ -n "${FEED_HISTORY:-}" ]]; then
            jq -r 'to_entries[] | [.key, .value] | @tsv' "$temp/checkpoint" > "$temp/advertised"
        else
            : > "$temp/advertised"
        fi
        if [[ -n "$withdrawn" ]]; then source "$scripts/feed-retirement.sh"; fi
        source "$scripts/feed-recovery.sh"
        verify_recovery "$recovery_dir" || return 1
        observed=$(canonical_id) || return 1
        [[ "$observed" == "$prior" ]]
    }
    if rejected "$attempt"; then
        confirm_rejected "$attempt"
        [[ "$(jq -r .sha <<< "$started")" == "$GITHUB_SHA" ]]
        if [[ -n "${FEED_HISTORY:-}" ]]; then
            [[ "$(jq -er .payload.recovery <<< "$started")" == "${FEED_RECOVERY_DIGEST:?}" ]]
        fi
        verify_unchanged_feed
        jq -n --arg attempt "$attempt" '{attempt:$attempt}' > "$temp/rejection-closure"
        source_sha=$(jq -er .sha <<< "$started")
        append_recovery rejection-closure "$(cat "$temp/rejection-closure")"
        printf '%s\n' 'Rejected candidate closed after verifying the unchanged feed.'
        exit 0
    fi
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
            if [[ "$outcome" == failure ]]; then
                live=$(canonical_id)
                if [[ "$live" == "$prior" && "$id" != "$prior" ]]; then
                    [[ "$source_sha" == "$GITHUB_SHA" ]]
                    [[ "$(jq -r '.closed.payload.attempt // ""' <<< "$generation")" != "$attempt" ]]
                    verify_unchanged_feed
                    payload=$(jq -cn --arg attempt "$attempt" --arg deployment "$id" --arg predecessor "$prior" \
                        --arg digest "$digest" '{attempt:$attempt,deployment:$deployment,predecessor:$predecessor,digest:$digest}')
                    append_recovery candidate-failure-closure "$payload"
                    printf '%s\n' 'Terminally failed candidate closed after verifying the unchanged feed.'
                    exit 0
                fi
                [[ "$live" == "$id" ]]
            fi
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
attempt=$(openssl rand -hex 16)
package_history='{}'
marker=$FEED_DIGEST
successor=
approval=
if [[ -n "${FEED_HISTORY:-}" ]]; then
    source "$scripts/feed-retirement.sh"
    withdrawn=$(jq -r '.payload.withdrawn // ""' <<< "$predecessor")
    if [[ -n "$withdrawn" ]]; then
        [[ "$withdrawn" =~ ^[A-Za-z0-9_-]+$ && "$retirement" == '{}' ]]
        for bundle in "$FEED_DIRECTORY" "$(dirname -- "$FEED_DIRECTORY")/recovery"; do
            jq -e --arg path "$withdrawn" 'all(keys[];
                . != ("/" + $path + "/meta.conf") and
                (test("^/" + $path + "/(packagesite|data|meta)[.](pkg|txz)$") | not))' \
                "$bundle/pages-manifest.json" >/dev/null
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
    history_record "$temp/proposed-history" "$parent"
    mkdir "$temp/readback"
    if ! read_history_asset "$approval_asset"; then
        if read_history_asset "$history_asset"; then
            echo 'Successor history has no matching retained approval.' >&2
            exit 1
        fi
        store_history_asset "$temp/approval" "$approval_asset"
    fi
    cmp "$temp/approval" "$temp/readback/$approval_asset"
    if ! read_history_asset "$history_asset"; then
        store_history_asset "$temp/successor" "$history_asset"
    fi
    cmp "$temp/successor" "$temp/readback/$history_asset"
fi
jq -n --arg sha "$GITHUB_SHA" --arg environment "$environment" --arg attempt "$attempt" \
    --arg successor "$successor" --arg approval "$approval" \
    --arg digest "$FEED_DIGEST" --arg marker "$marker" --arg history "$history_digest" --arg parent "$parent" --arg recovery "${FEED_RECOVERY_DIGEST:-}" --argjson packages "$package_history" '{
        ref:$sha, environment:$environment, auto_merge:false, required_contexts:[],
        transient_environment:false, production_environment:false,
        payload:{phase:"submission-started",attempt:$attempt,digest:$digest,marker:$marker,history:$history,predecessor:$parent,recovery:$recovery,packages:$packages,successor:$successor,approval:$approval}
    }' > "$temp/record"
node "$scripts/feed-pages-assets.mjs" "$PAGES_API" "$PAGES_ASSET_API" "$FEED_DIRECTORY" "$FEED_MANIFEST"
append_verified_submission "$temp/record" || exit 1
create_pages "$GITHUB_SHA" "$attempt" "$FEED_MANIFEST"
printf '%s\n' 'Submission recorded. Reconcile the live generation on the next invocation.'
