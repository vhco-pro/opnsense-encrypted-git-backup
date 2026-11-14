#!/usr/bin/env bash
set -euo pipefail
plan() {
    jq -r -f scripts/feed-reconcile.jq
}
check() {
    local expected=$1 actual
    actual=$(plan)
    if [[ "$actual" != "$expected" ]]; then
        printf 'Expected %s, got %s\n' "$expected" "$actual" >&2
        return 1
    fi
}
check hold <<<'{"outcome":"unknown","live":"source","authorized":true}'
check hold <<<'{"outcome":"failure","live":"conflict","authorized":true}'
check retry <<<'{"outcome":"rejected","live":"source","authorized":true}'
check recover <<<'{"outcome":"failure","live":"candidate","authorized":true}'
check recover <<<'{"outcome":"success","live":"candidate","checks":"pass","recoveryRequired":true,"authorized":true}'
check close <<<'{"outcome":"success","live":"candidate","checks":"pass"}'
check validate <<<'{"outcome":"unknown","live":"recovery","checks":"pass"}'
check hold <<<'{"outcome":"failure","live":"recovery","checks":"pass","authorized":true}'
check retry-recovery <<<'{"outcome":"failure","live":"recovery","checks":"fail","authorized":true,"dispatch":"3","consumed":["1","2"]}'
check hold <<<'{"outcome":"failure","live":"recovery","checks":"fail","authorized":true,"dispatch":"1","consumed":["1","2"]}'
check hold <<<'{"outcome":"failure","live":"recovery","checks":"fail","authorized":false,"dispatch":"3","consumed":[]}'
