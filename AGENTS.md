# Repository instructions

Read the personal conventions at
https://github.com/vhco-pro/docs/blob/06c929bea58e31d28a2a1ae9b563d10c744d9886/AGENTS.md
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

The repository currently contains design documents only.
The PHP guidance is adopted from the immutable revision proposed in
https://github.com/vhco-pro/docs/pull/37, which remains under review.
Use the verified vh-adlc binary for feature-document lint and review checks.
Run `git diff --check` before committing.
Record native build and integration commands after observing them on a disposable
compatible OPNsense/FreeBSD environment.
