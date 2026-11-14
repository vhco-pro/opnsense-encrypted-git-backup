#!/usr/bin/env bash
set -euo pipefail
checker=$(realpath scripts/check-feed-history.sh)
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/bundle/old"
path=old/os-encrypted-git-backup-0.0.9.alpha1.pkg
printf 'fixture\n' > "$work/bundle/$path"
digest=$(openssl dgst -sha256 -r "$work/bundle/$path" | cut -d ' ' -f 1)
jq -n --arg path "$path" --arg digest "$digest" '{($path): $digest}' > "$work/history.json"
bash "$checker" "$work/history.json" "$work/bundle"
mv "$work/bundle/$path" "$work/package"
if bash "$checker" "$work/history.json" "$work/bundle"; then
    exit 1
fi
ln -s "$work/package" "$work/bundle/$path"
if bash "$checker" "$work/history.json" "$work/bundle"; then
    exit 1
fi
rm "$work/bundle/$path"
printf 'changed\n' > "$work/bundle/$path"
if bash "$checker" "$work/history.json" "$work/bundle"; then
    exit 1
fi
root_path=os-encrypted-git-backup-0.0.9.alpha2.pkg
printf 'fixture\n' > "$work/bundle/$root_path"
jq --arg path "$root_path" --arg digest "$digest" '{($path):$digest}' "$work/history.json" > "$work/root.json"
bash "$checker" "$work/root.json" "$work/bundle"
