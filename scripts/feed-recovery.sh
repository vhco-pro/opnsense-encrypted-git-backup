# Sourced by publish-feed.sh after candidate, history and provider correlation.
# These functions use the same HTTP adapter and journal as candidate submission.
verify_recovery() {
    local recovery_dir=$1 path expected actual status
    if [[ -f "$recovery_dir/release.json" ]]; then
        bash "$scripts/verify-feed-generation.sh" "$FEED_URL" "$recovery_dir/release.json" "$FEED_PUBLIC_KEY" "$FEED_ABI" ||
            return 1
    else
        for path in packagesite.pkg packagesite.txz meta.conf meta.pkg meta.txz data.pkg data.txz; do
            status=$(request --no-fail -o /dev/null -w '%{http_code}' "$FEED_URL/$path") || return 1
            [[ "$status" == 404 ]] || return 1
        done
    fi
    if [[ -n "$withdrawn" ]]; then verify_withdrawal "$withdrawn" || return 1; fi
    while IFS=$'\t' read -r path expected; do
        actual=$(request "$FEED_URL/$path" | sha256sum | cut -d ' ' -f 1) || return 1
        [[ "$actual" == "$expected" ]] || return 1
    done < "$temp/advertised"
}

append_recovery() {
    local phase=$1 payload=$2
    jq -n --arg environment "$environment" --arg source "$source_sha" --arg phase "$phase" --argjson payload "$payload" '{
        ref:$source, environment:$environment, auto_merge:false, required_contexts:[],
        transient_environment:false, production_environment:false,
        payload:($payload + {phase:$phase})
    }' > "$temp/recovery-write"
    if [[ "$phase" == recovery-started ]]; then
        append_verified_submission "$temp/recovery-write"
        return
    fi
    request "${github_headers[@]}" -H 'Content-Type: application/json' --data-binary "@$temp/recovery-write" "$journal" |
        jq -e --slurpfile sent "$temp/recovery-write" '.sha == $sent[0].ref and .payload == $sent[0].payload' >/dev/null
}

submit_recovery() {
    local dispatch=$1 source_id=$2 recovery_dir=$3 new_attempt
    new_attempt=$(openssl rand -hex 16)
    node "$scripts/feed-pages-assets.mjs" "$PAGES_API" "$PAGES_ASSET_API" "$recovery_dir" "$recovery_dir/pages-manifest.json"
    append_recovery recovery-started "$(jq -cn --arg candidate "$attempt" --arg attempt "$new_attempt" \
        --arg digest "$recovery_digest" --arg dispatch "$dispatch" --arg source "$source_id" \
        '{candidate:$candidate,attempt:$attempt,digest:$digest,dispatch:$dispatch,source:$source}')" || return 1
    create_pages "$source_sha" "$new_attempt" "$recovery_dir/pages-manifest.json"
}

reconcile_recovery() {
    local candidate_id=$1 recovery_dir latest recovery_match recovery_id recovery_outcome dispatch
    recovery_dir="$(dirname -- "$FEED_DIRECTORY")/recovery"
    latest=$(jq -c --arg candidate "$attempt" '
        [.[] | select(.payload.phase == "recovery-started" and .payload.candidate == $candidate)]
        | sort_by(.id) | last // {}
    ' "$temp/journal")
    if [[ "$latest" == '{}' ]]; then
        # A hold becomes durable before assets or create. A lost response
        # leaves the next dispatch to read the committed decision.
        if ! jq -e --arg candidate "$attempt" '
            any(.[]; .payload.phase == "recovery-required" and .payload.candidate == $candidate)
        ' "$temp/journal" >/dev/null; then
            append_recovery recovery-required "$(jq -cn --arg candidate "$attempt" \
                --arg digest "$recovery_digest" --arg source "$candidate_id" '{candidate:$candidate,digest:$digest,source:$source}')"
        fi
        submit_recovery "" "$candidate_id" "$recovery_dir"
        return
    fi
    local rejected_attempt
    rejected_attempt=$(jq -er .payload.attempt <<< "$latest")
    if rejected "$rejected_attempt"; then
        confirm_rejected "$rejected_attempt" || return 1
        latest=$(jq -c --arg candidate "$attempt" --argjson rejected "$(jq -c .rejected <<< "$generation")" '
            [.[] | select(.payload.phase == "recovery-started" and .payload.candidate == $candidate
                and (.payload.attempt as $attempt | $rejected | index($attempt) == null))]
            | sort_by(.id) | last // {}
        ' "$temp/journal")
        if [[ "$latest" == '{}' ]]; then
            live_id_is "$candidate_id" || return 1
            request "$FEED_URL/generation.json" | jq -e --arg marker "$marker" '.digest == $marker' >/dev/null ||
                return 1
            submit_recovery "" "$candidate_id" "$recovery_dir"
            return
        fi
    fi
    recovery_match=$(correlate "$(jq -er .payload.attempt <<< "$latest")")
    recovery_id=$(jq -er '.id | strings | select(length > 0)' <<< "$recovery_match")
    live_id_is "$recovery_id"
    recovery_outcome=$(terminal_outcome <<< "$recovery_match")
    [[ "$recovery_outcome" != unknown ]]
    # A mismatched live marker is ambiguous and cannot authorize a retry.
    local served_marker
    served_marker=$(request "$FEED_URL/generation.json" | sha256sum | cut -d ' ' -f 1)
    [[ "$served_marker" == "$(sha256sum "$recovery_dir/generation.json" | cut -d ' ' -f 1)" ]]
    if verify_recovery "$recovery_dir"; then
        [[ "$recovery_outcome" == success ]] || {
            echo 'Terminal recovery failure with passing checks requires manual diagnosis.' >&2
            return 1
        }
        id=$recovery_id
        return 0
    fi
    [[ "$(jq -r '.closed.payload.attempt // ""' <<< "$generation")" != "$attempt" ]] || return 1
    dispatch=${GITHUB_RUN_ID:-}
    [[ "$dispatch" =~ ^[0-9]+$ ]]
    if jq -e --arg candidate "$attempt" --arg dispatch "$dispatch" '
        any(.[]; .payload.phase == "recovery-started" and .payload.candidate == $candidate and .payload.dispatch == $dispatch)
    ' "$temp/journal" >/dev/null; then
        echo 'This dispatch already consumed its recovery authorization.' >&2
        return 1
    fi
    submit_recovery "$dispatch" "$recovery_id" "$recovery_dir"
}
