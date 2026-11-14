#!/usr/bin/env bash
set -euo pipefail

fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
scan=(semgrep scan --metrics=off --disable-version-check --error --strict --no-git-ignore)
must_exit() {
    local expected=$1 rc=0
    shift
    "$@" >/dev/null 2>"$fixture/log" || rc=$?
    if [[ "$rc" != "$expected" ]]; then
        printf 'Expected exit %s, observed %s\n' "$expected" "$rc" >&2
        return 1
    fi
}
cat > "$fixture/unsafe.php" <<'PHP'
<?php
system($_POST['demo']);
echo $_GET['demo'];
file_get_contents(htmlspecialchars($_GET['path']));
$xml = new DOMDocument();
$xml->substituteEntities = true;
PHP
printf '%s\n' '<?php echo htmlspecialchars($_GET["name"], ENT_QUOTES);' > "$fixture/safe.php"
rc=0
"${scan[@]}" --config tests/security/php.yml --json "$fixture/unsafe.php" > "$fixture/findings.json" || rc=$?
test "$rc" -eq 1
python3 - "$fixture/findings.json" <<'PY'
import json
import sys
with open(sys.argv[1]) as source:
    report = json.load(source)
expected = {
    "php-dynamic-shell", "php-request-html", "php-request-path", "php-xml-entity-expansion"
}
assert not report["errors"]
assert {item["check_id"].rsplit(".", 1)[-1] for item in report["results"]} == expected
PY
must_exit 0 "${scan[@]}" --config tests/security/php.yml "$fixture/safe.php"
must_exit 7 "${scan[@]}" --config "$fixture/missing.yml" "$fixture/safe.php"
printf 'token = "ghp_%s%s"\n' abcdefghijklmnopqrstuvwxyz ABCDEFGHIJ > "$fixture/secret.txt"
must_exit 23 gitleaks dir --redact=100 --no-banner --exit-code 23 "$fixture/secret.txt"
must_exit 1 gitleaks dir --redact=100 --no-banner --exit-code 23 "$fixture/missing.txt"
