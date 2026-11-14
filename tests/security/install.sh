#!/usr/bin/env bash
set -euo pipefail

python3 -m venv work/security
work/security/bin/pip install --require-hashes -r tests/security/requirements.txt
version=$(sed -n 's/^version=//p' tests/security/gitleaks.lock)
checksum=$(sed -n 's/^sha256=//p' tests/security/gitleaks.lock)
archive=work/security/gitleaks.tar.gz
curl -fsSL https://github.com/gitleaks/gitleaks/releases/download/v${version}/gitleaks_${version}_linux_x64.tar.gz -o "$archive"
printf '%s  %s\n' "$checksum" "$archive" | sha256sum -c
tar -xzf "$archive" -C work/security/bin gitleaks
