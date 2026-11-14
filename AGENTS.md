# Repository instructions

Read the personal conventions at
https://github.com/vhco-pro/docs/blob/d59008a3d135dfac17e93033a854dc67065d7a40/AGENTS.md
and follow the task routes there before implementation.
Read conventions/coding.md for code, conventions/feature-documents.md for features,
and conventions/documentation.md and guides/humanize-prose.md for prose.
Read conventions/php.md before PHP specification, implementation or review.
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

The PHP guidance is adopted from the merged revision in
https://github.com/vhco-pro/docs/pull/37.
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
