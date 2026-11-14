#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
temporary=$(mktemp -d)
trap 'rm -rf -- "$temporary"' EXIT
mkdir "$temporary"/{assets,output,bin}
export FIXTURE_ASSETS="$temporary/assets" GITHUB_REPOSITORY=fixture/plugin
export PATH="$temporary/bin:$PATH"
cat > "$temporary/bin/gh" <<'SH'
#!/bin/sh
set -eu
test "$1 $2 $3 $4 $5 $6 $8" = "release download v1.2.3 --repo fixture/plugin --pattern --dir"
cp "$FIXTURE_ASSETS/$7" "$9/"
SH
chmod +x "$temporary/bin/gh"
for role in candidate recovery; do
    digest=$(printf %s "$role" | sha256sum | cut -d ' ' -f1)
    printf %s "$role" > "$temporary/assets/feed-$digest.tar"
    printf -v "$role" '%s' "$digest"
done
fetch() {
    bash "$root/scripts/feed-bundles.sh" v1.2.3 "$candidate" "$recovery" "$temporary/output"
}
fetch
cmp "$temporary/assets/feed-$candidate.tar" "$temporary/output/feed-$candidate.tar"
cmp "$temporary/assets/feed-$recovery.tar" "$temporary/output/feed-$recovery.tar"
rm "$temporary"/output/feed-*.tar
printf corrupt > "$temporary/assets/feed-$recovery.tar"
if fetch; then exit 1; fi
test -z "$(ls -A "$temporary/output")"
rm "$temporary/assets/feed-$recovery.tar"
if fetch; then exit 1; fi
test -z "$(ls -A "$temporary/output")"
