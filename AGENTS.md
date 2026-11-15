# Repository instructions

Read the personal conventions at
https://github.com/vhco-pro/docs/blob/1edeb5f32d868bbe761ef3221f350634cd6ff022/AGENTS.md
and follow the task routes there before implementation.
Read conventions/coding.md for code, conventions/feature-documents.md for features,
and conventions/documentation.md and guides/humanize-prose.md for prose.
Read conventions/php.md before PHP specification, implementation or review.
Read conventions/repository-security.md before configuring security scans.
Read conventions/frontend-testing.md for native browser settings and status interfaces.
CI and packaging also use conventions/delivery.md and knowledge/shared-delivery.md.
Report inaccessible required sources before proceeding.

Feature documents: docs/specs/

## Project scope

This repository owns a reusable native OPNsense encrypted Git backup provider.
The owner selected a separate provider integrated into the native backup framework.
Design uses PHP and native OPNsense interfaces, XML models and standard package tooling.
Deployment-specific configuration belongs in vhco-pro/lab and maintained Homelab
procedures belong in michielvha/vitepress.

On 2026-11-14 the owner approved BSD-2-Clause as an exception to the shared
Apache-2.0 default, matching OPNsense contribution requirements.
Preserve upstream notices for reused source.

Keep credentials, real configuration exports, private inventories, repository
state and backup data outside this source repository.
Use synthetic fixtures and sanitized evidence for public-facing documentation.
The owner authorizes prompt pushes of documentation-only changes, including drafts.
Implementation, release, upstream submissions and live firewall changes retain
their separate design, review and owner approvals.

## Verification

Run available local checks before pushing. Batch related fixes and use one exact
pre-merge verification run. Diagnose failures locally before another push or
dispatch. Automatic hosted validation runs on pull requests and pushes to main.
Cancel superseded verification for the same PR or ref. Protected publication
keeps its separate non-cancelling concurrency group.

Use standard GitHub-hosted Linux runners in public repositories. Hosted runs in
private repositories and paid or larger runners require fresh, explicit owner
approval. Keep uploaded artifacts limited to sanitized review evidence with
short retention. See [GitHub Actions billing](https://docs.github.com/en/actions/concepts/billing-and-usage).

The PHP guidance was introduced in https://github.com/vhco-pro/docs/pull/37.
The pinned revision includes the security requirements from
https://github.com/vhco-pro/docs/pull/38.
Use the verified vh-adlc binary for feature-document lint and review checks.
Run `git diff --check` before committing.
After installing the locked development dependencies and fetching the pinned core
symbols as shown in `.github/workflows/php.yml`, run:

```sh
find src tests -name '*.php' -exec php -l {} \;
vendor/bin/phpcs
vendor/bin/phpstan analyse --no-progress
vendor/bin/phpunit
actionlint
```

See [native build observations](docs/compatibility.md) for the verified package
commands and remaining appliance checks.
