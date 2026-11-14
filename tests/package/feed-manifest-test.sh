#!/usr/bin/env bash
set -euo pipefail

script=$(realpath scripts/feed-manifest.sh)
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
cd "$fixture"
git init -q
git -c user.name=Fixture -c user.email=fixture@example.test commit -qm fixture --allow-empty
source=$(git rev-parse HEAD)
git tag v0.0.9-alpha.1
mkdir bin generation
# Model the native command boundary using an algorithm-tagged fixture checksum.
cat > bin/pkg <<'SH'
#!/bin/sh
set -eu
case "$1" in
    query) printf '%s\n' 'os-encrypted-git-backup 0.0.9.alpha1' ;;
    checksum)
        test "$2 $3" = '-q -c'
        digest=$(openssl dgst -sha256 -r "$5" | cut -d ' ' -f 1)
        test "$4" = "1\$$digest"
        ;;
    *) exit 64 ;;
esac
SH
chmod +x bin/pkg
export PATH="$fixture/bin:$PATH"
package=os-encrypted-git-backup-0.0.9.alpha1.pkg
printf 'synthetic package\n' > "$package"
cp "$package" generation/
digest=$(openssl dgst -sha256 -r "$package" | cut -d ' ' -f 1)
jq -n --arg sum "1\$$digest" --arg path "$package" \
    '{name:"os-encrypted-git-backup",version:"0.0.9.alpha1",sum:$sum,path:$path}' > packagesite.yaml
tar -cf generation/packagesite.pkg packagesite.yaml

bash "$script" 0.0.9-alpha.1 "$source" v0.0.9-alpha.1 "$package" generation |
    jq -e --arg sha "$source" --arg digest "$digest" '.source == $sha and .packageSha256 == $digest' >/dev/null
! bash "$script" 0.0.9-alpha.1 "$source" v0.0.9-alpha.2 "$package" generation
printf 'changed\n' >> "generation/$package"
! bash "$script" 0.0.9-alpha.1 "$source" v0.0.9-alpha.1 "$package" generation
cp "$package" "generation/$package"
jq '.sum = "invalid"' packagesite.yaml > changed
mv changed packagesite.yaml
tar -cf generation/packagesite.pkg packagesite.yaml
! bash "$script" 0.0.9-alpha.1 "$source" v0.0.9-alpha.1 "$package" generation
