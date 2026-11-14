#!/usr/bin/env bash
set -euo pipefail

python3 -m venv work/security
work/security/bin/pip install semgrep==1.185.0
archive=work/security/gitleaks.tar.gz
curl -fsSL https://github.com/gitleaks/gitleaks/releases/download/v8.21.2/gitleaks_8.21.2_linux_x64.tar.gz -o "$archive"
printf '%s  %s\n' 5bc41815076e6ed6ef8fbecc9d9b75bcae31f39029ceb55da08086315316e3ba "$archive" | sha256sum -c
tar -xzf "$archive" -C work/security/bin gitleaks
