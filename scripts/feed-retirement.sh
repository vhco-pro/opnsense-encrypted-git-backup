# Sourced by the publisher. The approved manifest pins the predecessor path,
# operator key and the complete client scope with expected trust on either side.
retirement=$(jq -c '.retirement // {}' "$FEED_NATIVE_MANIFEST")
validate_retirement() {
    jq -e '
        (.path | type == "string" and test("^[A-Za-z0-9_-]+$")) and
        (.operatorKey | type == "string" and test("^[a-f0-9]{64}$")) and
        (.clients | type == "object" and length > 0 and all(to_entries[];
            (.key | test("^[A-Za-z0-9_-]+$")) and
            (.value.before | test("^[a-f0-9]{64}$")) and
            (.value.after | test("^[a-f0-9]{64}$")) and
            .value.before != .value.after))
    ' <<< "$retirement" >/dev/null
}
verify_retirement() {
    local path alias status pending
    path=$(jq -er .path <<< "$retirement")
    for alias in packagesite.pkg packagesite.txz meta.conf meta.pkg meta.txz data.pkg data.txz; do
        status=$(request --no-fail -o /dev/null -w '%{http_code}' "$FEED_URL/$path/$alias")
        [[ "$status" == 404 ]] || {
            echo 'Predecessor catalogue withdrawal could not be verified.' >&2
            return 1
        }
    done
    pending=$(jq -c '.retirement // {}' <<< "$generation")
    if [[ "$pending" == '{}' ]]; then
        source "$scripts/feed-recovery.sh"
        append_recovery trust-finalization-pending "$(jq -cn --arg attempt "$attempt" \
            --arg deployment "$id" --arg digest "$digest" \
            '{attempt:$attempt,deployment:$deployment,digest:$digest}')"
        echo 'Withdrawal verified. Trust finalization is pending.' >&2
        return 1
    fi
    jq -e --arg id "$id" '.payload.deployment == $id' <<< "$pending" >/dev/null
    : "${FEED_OPERATOR_KEY:?}" "${FEED_OPERATOR_EVIDENCE:?}" "${FEED_OPERATOR_SIGNATURE:?}"
    local fingerprint
    fingerprint=$(openssl pkey -pubin -in "$FEED_OPERATOR_KEY" -outform DER | sha256sum | cut -d ' ' -f 1)
    [[ "$fingerprint" == "$(jq -er .operatorKey <<< "$retirement")" ]]
    openssl dgst -sha256 -verify "$FEED_OPERATOR_KEY" -signature "$FEED_OPERATOR_SIGNATURE" \
        "$FEED_OPERATOR_EVIDENCE" >/dev/null
    jq -e --arg attempt "$attempt" --arg deployment "$id" --arg digest "$digest" \
        --argjson retirement "$retirement" '
        .attempt == $attempt and .deployment == $deployment and .digest == $digest and
        (.observedAt | type == "number" and . <= now and . > now - 900) and
        .clients == ($retirement.clients | map_values(.after))
    ' "$FEED_OPERATOR_EVIDENCE" >/dev/null
    live_id_is "$id"
}
