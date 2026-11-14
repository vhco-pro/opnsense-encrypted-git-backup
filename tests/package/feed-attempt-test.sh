#!/usr/bin/env bash
set -euo pipefail
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
export FIXTURE_STATE="$work"
cat > "$work/adapter" <<'SH'
#!/bin/sh
set -eu
jq -e --arg attempt "$1" --arg digest "$2" '
    .attempt == $attempt and .bundleDigest == $digest and .resolved == false
    and .consumed == ["23"]
' "$FIXTURE_STATE/attempt.json" >/dev/null
printf '%s\n' "$1" >> "$FIXTURE_STATE/creates"
exit 1
SH
chmod 0700 "$work/adapter"
digest=$(printf '%064d' 1)
jq -n --arg digest "$digest"     '{outcome:"failure", live:"recovery", checks:"fail",authorized:true,bundleDigest:$digest}' > "$work/evidence"
if bash scripts/feed-attempt.sh "$work" "$work/evidence" 23 "$work/adapter"; then
    exit 1
fi
test "$(wc -l < "$work/creates")" -eq 1
if bash scripts/feed-attempt.sh "$work" "$work/evidence" 24 "$work/adapter"; then
    exit 1
fi
test "$(wc -l < "$work/creates")" -eq 1
jq '.resolved = true' "$work/attempt.json" > "$work/resolved"
mv "$work/resolved" "$work/attempt.json"
test "$(bash scripts/feed-attempt.sh "$work" "$work/evidence" 23 "$work/adapter")" = hold
test "$(wc -l < "$work/creates")" -eq 1
