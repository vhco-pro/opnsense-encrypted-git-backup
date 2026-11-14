#!/usr/bin/env bash
set -euo pipefail
version=$1
source_sha=$2
tag=${3:-}
number='(0|[1-9][0-9]*)'
pattern="^$number[.]$number[.]$number"
if [[ "$version" =~ $pattern$ ]]; then
    package_version=$version
elif [[ "$version" =~ $pattern-(alpha|beta|rc)[.]$number$ ]]; then
    package_version="${version%%-*}.${BASH_REMATCH[4]}${BASH_REMATCH[5]}"
else
    echo 'Unsupported GitVersion SemVer for a native package.' >&2
    exit 1
fi
if [[ ! "$source_sha" =~ ^[0-9a-f]{40}$ || "$(git rev-parse HEAD)" != "$source_sha" ]]; then
    echo 'The checkout does not match the versioned source.' >&2
    exit 1
fi
expected_tag="v$version"
if [[ -n "$tag" && "$tag" != "$expected_tag" ]]; then
    echo 'The supplied tag does not match GitVersion.' >&2
    exit 1
fi
if [[ -n "$tag" ]] || git show-ref --verify --quiet "refs/tags/$expected_tag"; then
    if [[ "$(git rev-parse --verify "refs/tags/$expected_tag^{commit}")" != "$source_sha" ]]; then
        echo 'The tag resolves to a different commit.' >&2
        exit 1
    fi
fi
printf '%s\n' "$package_version"
