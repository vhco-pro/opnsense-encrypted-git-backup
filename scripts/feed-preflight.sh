#!/usr/bin/env bash
set -euo pipefail

# Verify the approved identity and both retained bundles in an empty workspace.
[[ $# == 8 ]]
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
record=$1
run=$2
source=$3
remote_tag_sha=$4
candidate=$5
recovery=$6
history=$7
directory=$8
version=$(bash "$root/feed-release-identity.sh" "$record" "$run" "$source" "$remote_tag_sha")
release=$(jq -er '.tag' "$record")
bash "$root/feed-bundles.sh" "$release" "$candidate" "$recovery" "$directory"
for role in candidate recovery; do
    digest=${!role}
    mkdir "$directory/$role"
    bash "$root/feed-payload.sh" "$directory/feed-$digest.tar" "$digest" "$directory/$role"
    bash "$root/check-feed-history.sh" "$history" "$directory/$role"
done
manifest="$directory/candidate/release.json"
jq -e --arg source "$source" --arg tag "$release" --arg version "$version" '
    .source == $source and .tag == $tag and .version == $version
    and .package == ("os-encrypted-git-backup-" + $version + ".pkg")
    and (.packageSha256 | test("^[a-f0-9]{64}$"))
    and (.catalogueSha256 | test("^[a-f0-9]{64}$"))
' "$manifest" >/dev/null
package=$(jq -er '.package' "$manifest")
for role in candidate recovery; do
    printf '%s  %s\n' "$(jq -er '.packageSha256' "$manifest")" "$directory/$role/$package" | sha256sum -c --status
done
printf '%s  %s\n' "$(jq -er '.catalogueSha256' "$manifest")" "$directory/candidate/packagesite.pkg" | sha256sum -c --status

marker=$(sha256sum -- "$manifest" | cut -d ' ' -f 1)
jq -e --arg marker "$marker" '.digest == $marker' "$directory/candidate/generation.json" >/dev/null
