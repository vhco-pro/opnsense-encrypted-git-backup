#!/usr/bin/env bash
set -euo pipefail
mkdir -p work
fixture=$(mktemp -d "$PWD/work/psalm-fixture.XXXXXXXX")
trap 'rm -rf -- "$fixture"' EXIT
flags=(--taint-analysis --no-progress --no-cache --threads=1 --output-format=json)
cp tests/security/psalm-fixtures/framework.php.fixture "$fixture/input.php"
status=0
vendor/bin/psalm "${flags[@]}" "$fixture/input.php" > "$fixture/result.json" || status=$?
test "$status" -eq 2
php -r '
$issues = json_decode(file_get_contents($argv[1]), true, flags: JSON_THROW_ON_ERROR);
exit(array_column($issues, "type") === ["TaintedSSRF", "TaintedFile"] ? 0 : 1);
' "$fixture/result.json"
