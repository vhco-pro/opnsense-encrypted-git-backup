#!/usr/bin/env bash
set -euo pipefail

composer_phar=$1
base=$2
php "$composer_phar" audit --locked
semgrep scan --jobs 1 --metrics=off --disable-version-check --error --strict \
    --config tests/security/php.yml src tests
gitleaks git --redact=100 --no-banner --log-opts="$base..HEAD" .
gitleaks dir --redact=100 --no-banner src
