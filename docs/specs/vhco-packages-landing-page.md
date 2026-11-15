---
status: draft
status_description: "R-2 clarifications accepted; same-tag checkpoint and served-bundle rules revised for review."
issue: null
goal: "Visitors to pkg.vhco.pro can identify VHCO package repositories and reach their setup and signing instructions."
covers:
  - web/packages/
  - docs/prototypes/vhco-packages/
  - scripts/feed-pages-assets.mjs
  - scripts/feed-site.mjs
  - scripts/publish-feed.sh
  - scripts/feed-dispatch.sh
  - scripts/feed-recovery.sh
  - scripts/feed-close.sh
  - scripts/feed-preflight.sh
  - tests/package/feed-http-inputs.mjs
  - tests/package/feed-preflight-test.sh
  - tests/package/feed-publisher-http.mjs
  - tests/package/hosted-feed-content.sh
  - tests/browser/packages.spec.mjs
  - tests/browser/packages.config.mjs
  - .github/workflows/feed.yml
  - .github/workflows/feed-fixture.yml
---

# VHCO Packages landing page

## Context

### Owner summary

Give `pkg.vhco.pro` a VHCO-branded homepage with a list of package repositories and useful setup links.
The first entry is the published OPNsense repository and its encrypted Git backup plugin.
The page uses the company's existing logo, Inter typography, gradient colours and light/dark themes.
Its heading and structure describe VHCO Packages so additional repositories can be listed when they exist.

The owner selected the existing publisher for v1.
The page is static HTML, CSS and a small progressive-enhancement script for theme selection and copying the repository URL.
Installation commands, supported versions and signing fingerprints stay in the repository's maintained guides and release records.
This keeps the overview readable and gives those values one authoritative home.

The page assets enter the existing retained candidate and recovery bundles.
The owner selected separately reviewed homepage-only publications using the approved package, catalogue and tag.
A link correction therefore uses the protected feed publication process and preserves the package version.
Recovery restores the page and catalogue from the approved bundle actually live at the prior closure, including a previous recovery result.
The page-only path resolves its history checkpoint from that closure and retains a fresh approval for the new page bundles.
Every page-bearing bundle includes a top-level 404 document so missing package paths return HTTP 404.
Before recording success, the publisher checks the homepage at `/`, the approved error-page bytes at an unknown URL, and every other public asset's bytes and Content-Type alongside native package verification.
Page-source metadata stays inside the retained archive, and preflight rejects unlisted public files.

The requested visual prototype is a design artifact in `docs/prototypes/vhco-packages/`.
Its browser checks cover layout, theme selection, copying and navigation.
Production bundle assembly, Cloudflare serving and recovery checks remain implementation work.
The specification remains draft for independent review and owner critique of the preview.

### Background

On 15 November 2026, `curl https://pkg.vhco.pro/` returned HTTP 404 while the published package and signed catalogue returned their retained bytes over verified HTTPS.
The released package is documented in [the installation guide](../installation.md) and [v0.1.0](https://github.com/vhco-pro/opnsense-encrypted-git-backup/releases/tag/v0.1.0).

The observed VHCO homepage returned HTTP 200 in Chromium and used Inter.
The site's `app/.vitepress/theme/style.css` defines its cyan, blue and purple brand gradient and dark background.
`app/.vitepress/theme/components/ScrollHero.vue:200-202` uses the existing company logo from `app/public/landing/vhco-github.png`.
These source files belong to the private VitePress repository, while the logo and homepage are publicly served by vhco.pro.

The Pages uploader currently provides explicit HTML and JSON content types and a binary fallback for other files (`scripts/feed-pages-assets.mjs:54-60`).
Retained bundles already include a validated Pages path-to-asset manifest (`scripts/feed-preflight.sh:23`, `scripts/feed-pages-assets.mjs:34-50`).
The established publisher and recovery process own the deployment and its native verification (`scripts/feed-recovery.sh:3-18`).

### Prototype verification

The 36 focused prototype scenarios passed locally with the repository's locked Playwright 1.59.1 in Chromium and Firefox.
The checks exercised six viewport sizes in both themes, keyboard access, theme persistence, URL copying, denied clipboard/storage access, explicit missing-route HTTP 404 responses, independent-channel signing guidance and reading with JavaScript disabled.
The R-1 copy-state, signing-text and missing-route regressions first failed against the original prototype, then passed after correction.
Their failing output remains under ignored `work/packages-preview-r1-red-host/`.
Representative desktop and mobile captures were inspected.
The actual owner-restricted HTTPS share also loaded its assets, changed theme and navigated to setup.
Its browser clipboard policy used the tested URL-selection fallback.
An initial npm bootstrap and missing-browser launch were corrected by using the frozen Bun lockfile and installing its matching browser bundles.
The initial missing-browser evidence remains under the ignored `work/packages-preview-missing-browsers/` directory.

## Scope

Add a generic root homepage with the actual VHCO mark, website styling and the current OPNsense repository entry.
Provide repository setup, compatibility, source and release-information links, plus a copyable repository URL.
Support ordinary reading and link navigation through HTML, and progressively enhance theme selection and copying through browser APIs.

The owner-selected v1 code home is the existing package-feed repository and publisher.
Additional repository entries and page corrections can be authored as static content and published through a separately approved homepage-only update.
Appliance configuration, repository trust changes, package installation and future repository ownership are handled by their respective approved rollout or product tasks.
The homepage presents repository information and setup references.

## Design

### Content and visual structure

The source lives in `web/packages/` when implementation is accepted.
The reviewed design prototype lives in `docs/prototypes/vhco-packages/`.
The header identifies VH & Co and Packages and links to the company website and GitHub organisation.
The main heading reads "Packages from VH & Co."
The content starts with an OPNsense repository entry, its package identifier and a short description sourced from the installation guide.
The overview links to the repository's compatibility and installation guides and its release history.

The landing page uses the site's Inter font, cyan/blue/purple gradient, rounded controls and restrained card styling.
The company logo is copied from its actual site asset.
Font licensing and asset provenance accompany the source.
The default theme follows the browser preference, and an explicit theme selection is stored locally when storage is available.
Storage denial preserves a working page and a theme selection for the current view.

The page contains the current repository information and links to its maintained references.
Version numbers, signing fingerprints and current-health assertions are read in those references.
This makes the page usable when GitHub's newest release and a temporarily restored repository generation differ.
Release-history links let the reader select the version relevant to their appliance.
Signing-related text directs the reader to the installation guide and its independent trusted-channel check of the public key fingerprint.

### Browser behaviour

The repository URL copy button writes only the URL after an explicit click.
A successful copy produces visible status and a live-region announcement.
If clipboard access is unavailable, the URL is selected, the button reads "Selected" and adjacent status explains the device's manual copy action.
Reading, setup links and compatibility information remain accessible when JavaScript is disabled.

The page uses semantic headings, keyboard-visible focus, a skip link and labelled controls.
Text reflows at narrow widths, reduced-motion settings are honoured, and buttons have at least 44 CSS-pixel heights.
The current entry's setup link scrolls to the guide and signing-information section.
External links are ordinary links to published material.
No account or provider credential is needed to read the page.

### Assembly and browser verification

The production page is the explicit static asset set in `web/packages/`.
`scripts/feed-site.mjs` stages those files into a candidate directory and extends its existing Pages manifest using the publisher's pinned asset-hash calculation.
It validates the explicit asset list, required licences and top-level `404.html` and rejects collisions with existing package, catalogue and publication metadata paths.
The same preparation step places the approved recovery page assets into the recovery directory before either archive is retained.
Both archives are independently downloaded and digest-verified through the existing retention commands.

The helper also provides a loopback-only static serving command for the staged production directory.
`tests/browser/packages.config.mjs` starts that server with Playwright's webServer facility, and `tests/browser/packages.spec.mjs` exercises the staged files.
The read-only `.github/workflows/feed-fixture.yml` runs that focused Chromium/Firefox suite with the existing locked browser dependency.
Its existing caller in `php.yml` provides public PR/main coverage.
The design prototype retains its own focused test configuration.

### Publication and recovery

Candidate and recovery bundles include `index.html`, top-level `404.html`, styles, browser script, company logo, font and licence text whenever they carry a page.
Unknown paths, absent catalogue aliases and withdrawn catalogue paths return HTTP 404.
A missing native path must never fall back to homepage HTML with HTTP 200.
The local Pages adapter models this routing, and the client-facing verification checks the actual response after a page-bearing deployment.
Existing advertised packages and available signed catalogue paths serve their retained authenticated bytes.

The asset uploader declares HTML, CSS, browser JavaScript, PNG, WOFF2 and text content types.
Its existing path, size and digest validation applies to the site assets.
`scripts/feed-site.mjs` verifies each served site asset against the retained file's SHA-256 and expected media type, accepting a compatible charset parameter.
The HTML byte source and public response are explicit.
`index.html` is read at `/` with HTTP 200 and `text/html`.
`404.html` is read as the body of a task-generated unmatched path with HTTP 404 and `text/html`.
The verifier retains the response body on HTTP 404 for its SHA-256 comparison.
Other site assets are read at their listed public paths with HTTP 200 and their expected media types.
The local Pages adapter models HTML-to-extensionless redirects, including `/index.html` to `/`, so those redirects cannot substitute for successful document verification.
Missing catalogue aliases and withdrawn catalogue paths require HTTP 404 independently of the error-page byte check.
`scripts/publish-feed.sh` and `scripts/feed-recovery.sh` call this verification before candidate or recovery closure through `scripts/feed-close.sh`.
A failed readback prevents successful closure and follows the existing recovery or hold rules for that attempt.
The native verifier continues to authenticate the catalogue and fetch the exact package using its real repository configuration and ABI.
Local fixtures check both uploader metadata and the client-facing verification failure paths.
An authorised real publication must pass the same byte, Content-Type and HTTP status readback through `pkg.vhco.pro`.

The current single-writer, durable submission, lost-response reconciliation and recovery rules apply to the complete deployment.
A retry uses its retained approved bundle identities and the existing journal correlation.
A page-bearing established recovery restores the prior served page and catalogue, with every package required by retained history.
An empty-catalogue bootstrap recovery may carry the generic page and documentation links while every absent catalogue alias returns HTTP 404.
The initial homepage publication may recover to the previously served approved bundle without a homepage, preserving its root HTTP 404 and authenticated package bytes.
For a previously retained bundle without `index.html` or `site.json`, preflight permits its existing standalone `404.html` and requires the other new page assets to be absent.
For that legacy migration shape, the expected root response is HTTP 404, derived from the selected retained baseline having no index.
Initial-adoption preparation reads the prior root response and records the HTTP 404 observation in the approved dispatch evidence before staging.
Recovery verifies HTTP 404 again and, where a retained `404.html` exists, verifies its response bytes as well.
An index without its complete site metadata and assets, or other partially present new page assets, fails preflight.

### Homepage-only updates

The owner selected page-only publications on 15 November 2026.
The protected publisher keeps the existing reviewed package source, version-workflow run, immutable tag, signing key and exact package/catalogue bytes.
A reviewed page source SHA is supplied separately from the package source and must be reachable from main.
Bundle preparation checks out that exact page source and records it with the complete site asset list in `site.json`, which is retained inside the bundle.
`site.json` contains the approved page source SHA and an explicit map of served site paths, SHA-256 values and expected media types.
It is retained archive metadata and is excluded from the Pages manifest.
Candidate preflight validates the source SHA and every listed file's bytes and media type.
The Pages paths must equal the union of those listed site paths and the approved native package, catalogue and publication-metadata paths.
That native set is derived from the verified release manifest, retained advertised-package history, existing catalogue aliases and generation marker.
Preflight rejects unlisted paths, missing entries, collisions and any attempt to publish `site.json` itself.
Established recovery retains the prior served page source and assets, checked against the actual served baseline selected below.
A page-bearing bootstrap recovery uses its explicitly approved page SHA.
Each role's approved bundle digest binds its own source metadata and bytes.
The source is provenance for the static page and does not change package release identity.
The dispatch records the page SHA and candidate/recovery digests with its approval evidence.

The new candidate archive contains the approved page and the currently verified catalogue and package files.
The recovery archive contains the prior complete served page and catalogue, plus every package byte required by retained history.
For a page-only update the advertised package history union remains identical and the package generation marker retains its existing meaning.
The candidate and recovery archive digests, submission attempt and correlated Pages deployment distinguish the publication.
Public site readback prevents an unchanged package marker from being treated as proof of the new page.
The content-addressed archives are retained under the existing release tag using fresh digest names.
Existing release assets are preserved and their retained digests are verified independently.
A page update requires neither a new package build nor a moved tag.
The protected workflow uses its reviewed operational scripts for the updated verification contract and separately checks the existing package identity.

### Selecting predecessor history and recovery bytes

`.github/workflows/feed.yml` delegates history-input preparation to `scripts/feed-dispatch.sh`.
Under the existing workflow concurrency lock, dispatch reads the complete journal and reuses `feed-journal-generation.jq` to select the predecessor closure.
For an established feed it downloads `history-<closure.history>.json` from the release named by that closure, verifies its SHA-256 and supplies those bytes to preflight and `FEED_HISTORY`.
The fixed-name `advertised-packages.json` remains the initial seed for a feed with no predecessor closure, subject to the existing bootstrap/checkpoint validation.
An established dispatch never supplies that old seed in place of the selected predecessor history.
`publish-feed.sh` independently rereads the complete journal and verifies that its selected predecessor and retained checkpoint match the dispatch selection before effects.
A changed or unresolved predecessor holds the dispatch.
Replay selects the predecessor of the original submission, retaining the existing attempt and checkpoint contract.

For an unchanged page-only history union, the desired successor digest equals the independently verified predecessor history digest.
The publisher may reuse an existing `history-<digest>.json` only when it matches those verified predecessor bytes exactly.
It still retains and independently reads back a new approval asset binding the new candidate/recovery digests, predecessor attempt, package marker and history digest before submission.
An existing successor history without its matching approval remains a hold whenever it differs from the verified closed predecessor history.
An absent or conflicting predecessor, changed history bytes, lost approval readback or unresolved journal read also holds.
Existing asset files and immutable tags are preserved.

Before approving an established recovery bundle, preparation selects the archive actually live at the predecessor closure.
It replays the journal prefix through that closure to locate the initiating submission and its candidate/recovery digest pair.
It correlates the closure's Pages deployment ID with that submission's attempt or its recorded recovery attempts using the existing provider-correlation rules.
A candidate match selects the submission's candidate archive.
A recovery match selects its pinned recovery archive.
The archive is downloaded from the submission's retained release and digest-verified.
The same selector and comparison run again in `publish-feed.sh` before a new submission and require that deployment to remain the live predecessor.
Ambiguous correlation, missing archives or a changed predecessor holds.

The recovery comparison requires exact equality of the prior served site's asset set and bytes, its retained page-source metadata and the catalogue/metadata file set and bytes, including absent catalogue aliases and any withdrawn catalogue paths.
Advertised package files are checked separately against the full required history, so the recovery archive can also retain package bytes advertised by a failed candidate.
For a recovered predecessor, the page-only approval pins the package source and release identity authenticated by the selected live catalogue, independently of the failed candidate's version.
Previously advertised failed-candidate packages remain in retained history.
The candidate's package marker and the recovery's attempt marker retain their existing distinct roles and are verified through their respective existing contracts.
An older bundle without a page uses the legacy root HTTP 404 rule above.
A prior closure that ended on recovery is tested through this same archive-selection path.

Publication follows separate owner authorisation after implementation review and acceptance.
The homepage carries repository information and maintained references without an assertion about current package availability or appliance trust.

### Glossary

| Term | Meaning |
| --- | --- |
| VHCO Packages | The generic human-facing hub at pkg.vhco.pro. |
| Repository | A native package catalogue and its package files at a configured URL. |
| Package | An installable artifact listed in a repository, such as os-encrypted-git-backup. |

## Acceptance Criteria

- [ ] AC-01: The root page identifies VHCO Packages, presents the current OPNsense repository and its actual package, and links to working setup, compatibility, source and release references.
- [ ] AC-02: The page uses the existing VHCO logo, Inter typography and brand colours, supports light and dark themes and provides readable keyboard-accessible layouts at the specified viewports.
- [ ] AC-03: Explicit URL copying and theme selection work with visible feedback; reading and reference links work with JavaScript or storage/clipboard access unavailable.
- [ ] AC-04: Public readback verifies the complete site bytes, media types and HTTP 404 responses for absent paths, while native clients retrieve and authenticate their expected catalogue and retained package bytes.
- [ ] AC-05: Package and page-only publications, established recovery and bootstrap recovery retain and verify their complete approved page assets under the existing single-writer and interrupted-publication contract.
- [ ] AC-06: The public page contains repository information without private deployment inputs or credentials, uses its glossary terms consistently and links to maintained package version information and the installation guide's independent trusted-channel verification of signing fingerprints.

## Test Plan

| Criterion | Proof |
| --- | --- |
| AC-01 | `scripts/feed-site.mjs` stages `web/packages/`; the dedicated packages Playwright configuration starts its loopback server in `feed-fixture.yml`. Playwright opens that staged page, checks the actual repository identifier and URL, follows the local setup anchor and validates each public reference's final route and expected document. A two-entry synthetic fixture verifies that an additional authored repository can be represented without another origin. |
| AC-02 | Chromium and Firefox exercise light/dark at 320×568, 390×844, 844×390, 768×1024, 1280×720 and 1440×900. Assert horizontal containment, heading readability, 44-pixel buttons, focus visibility and setup reachability. Inspect representative mobile and desktop captures. Exercise reduced motion and retain an actual 200-percent browser-zoom procedure with its effective viewport. |
| AC-03 | In Chromium and Firefox copy the repository URL, verify the clipboard result and status, choose a theme, reload and verify preference persistence. Run clipboard-denied, storage-denied and JavaScript-disabled contexts. The denied clipboard case after a successful copy selects the actual URL, resets the button label and explains manual copying beside the control. |
| AC-04 | Extend `tests/package/feed-publisher-http.mjs`, `feed-http-inputs.mjs`, `feed-preflight-test.sh` and the hosted feed fixture to assemble, upload and read back HTML, CSS, JS, PNG, WOFF2 and licence bytes. Assert declared uploader media types separately from served bytes, media types and HTTP status. The Pages adapter redirects `/index.html` to `/`; verification compares root HTTP 200 to `index.html` and an unmatched HTTP 404 body to `404.html`. Wrong error-page bytes must fail. Inject wrong media types, wrong bytes, missing assets, incomplete page sets, unlisted extra HTML, a public `site.json`, collisions and homepage fallback for missing paths and require failure before closure. Unknown paths, absent catalogue aliases and a withdrawn catalogue return HTTP 404. Run native pkg catalogue authentication and exact package fetch before and after a homepage generation. At a separately authorised live publication run the same readback against the actual Cloudflare custom domain and retain its results before closure. |
| AC-05 | The existing publisher/controller fixture exercises candidate publication, established recovery and empty-catalogue bootstrap recovery with complete approved page assets and HTTP 404 responses. Run the input-preparation entry point used by `feed.yml` against a tag with an existing closed generation, its original empty fixed-name seed and its non-empty retained closed history. A page-only update uses that closed history, the same package source, tag, version, catalogue/package hashes and package marker, with a changed page SHA and fresh archive digests. Reusing the verified unchanged history succeeds with a fresh approval; a mismatched/orphan successor, missing or mismatched approval readback and changed predecessor hold before submission. Repeat after a predecessor closed on its recovery archive and prove selection by deployment/attempt correlation and exact prior page/catalogue comparison. Check missing/ambiguous baseline, extra page files, source mismatch, concurrent dispatch exclusion, interrupted/lost responses and duplicate-correlation holds. A pre-homepage baseline verifies the initial root HTTP 404 observation and recovery HTTP 404 with its retained error-page bytes when present. `hosted-feed-content.sh` supplies native signed client proof for the controller cases. |
| AC-06 | Inspect the approved payload, complete served path set and browser requests. Public package IDs, `https://pkg.vhco.pro`, company assets and guide links must pass. Inject synthetic `PRIVATE_FIXTURE_LAB_ADDRESS`, `PRIVATE_FIXTURE_TOKEN`, `PRIVATE_FIXTURE_CONFIG_XML` and `PRIVATE_FIXTURE_SIGNER_PEM` markers into served HTML, an asset and a browser-request URL; each must fail. Retained-only `site.json` must pass, while a manifest entry serving it must fail. For signing copy, "Follow the installation guide to verify the signing key through an independent trusted channel before adding the repository" must pass. "Compare the public key's fingerprint with the release notes before trusting it" and "Trust this downloaded key without verification" must fail. Check repository/package terminology and guide/release routes. Reading the page needs no credentials. |

## Tasks

None yet; written after owner acceptance.

## Open Questions

### Q4 — Delivery details

R-3 F-02 asks for the exact recovery comparison set.
Recommend restoring the prior page and native catalogue files byte-for-byte, while constructing and verifying the recovery's `release.json`, `generation.json` and Pages manifest for their existing publication roles.

R-3 F-04 asks how site-verification failure affects each closure path.
Recommend applying the existing authorised verification-failure contract to site checks alongside package checks.
Candidate failure can enter authorised recovery.
A confirmed terminal recovery with failing site checks can use one identical-byte retry per separately authorised dispatch under the existing Q3 contract.
Rejection and failed-candidate closures hold when the previously served site fails verification.

R-3 F-06 asks which preparation component and credentials resolve the served baseline.
Recommend `feed-dispatch.sh` provide preparation's read-only journal/archive selection using the operator's existing GitHub CLI access.
The protected publication job then verifies Pages correlation using its existing environment credential.
The existing complete-read bound holds on incomplete or over-limit provider results.

R-3 F-07 asks where the page SHA is independently checked.
Recommend an explicit `page_source` dispatch input, checked against main ancestry and retained `site.json` by the protected publication job before submission.

Owner answer pending for these four details.
The earlier publisher, page-only update, public verification, actual served baseline, HTML route and retained-only metadata choices remain recorded in Design.

## Review Log

| Date | Review | Kind | Commit | Model | Isolation | Outcome |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-11-15 | R-1 | spec | `1012715422c73c326c0d3061e62dbc2c9e83c334` | claude-opus-5-5 | procedural | One blocking, four should-fix and two nits. Read-only checkout preservation verified. |
| 2026-11-15 | R-2 | spec | `23d22b463fb22cc41c8362557def8624ff05dbd7` | claude-opus-5-5 | procedural | One blocking and four should-fix. Read-only source and Git preservation verified. Shell execution was denied to this static reviewer. |
| 2026-11-15 | R-3 | spec | `340d9014f0b9671257bf6594270681967f82b6b7` | claude-opus-5-5 | procedural | Seven should-fix findings. Static source review, with read-only source and Git preservation verified. |

### R-1

TARGET: 1012715422c73c326c0d3061e62dbc2c9e83c334

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Design (Publication and recovery), Acceptance Criteria AC-04, AC-05, Test Plan AC-04, AC-05, Owner summary
EVIDENCE: Design line 115 adds a top-level `index.html` to candidate bundles but never says what a missing path returns. When a Pages deployment has no top-level 404 page, Pages treats it as a single-page app and serves the root document for unmatched paths. The repository already recorded this behaviour at docs/specs/native-encrypted-git-backup.md:956, citing Cloudflare Pages serving behaviour. In the current fixtures only the bootstrap recovery bundle carries a `404.html` (tests/package/feed-http-inputs.mjs:94-96, tests/package/feed-preflight-test.sh:41). The candidate bundle has none, and today's root 404 (line 44) matches that. Once an index page is deployed without a 404 page, `verify_withdrawal` can no longer pass, because it requires HTTP 404 for every catalogue alias under a withdrawn path (scripts/feed-retirement.sh:15-24). The bootstrap absence check at scripts/feed-recovery.sh:9-12 has the same requirement. pkg probes for alternative catalogue and metadata names would also get an HTML 200 instead of a 404. The prototype server returns 404 for unnamed paths (docs/prototypes/vhco-packages/README.md:14), so it hides this behaviour. No Test Plan row checks the not-found response of a homepage generation.
PROPOSAL: Require every page-bearing candidate and recovery bundle to include a top-level 404 document, and state the expected status for unknown, withdrawn and alternate catalogue paths. Add AC-04 and AC-05 proof that these paths return HTTP 404 through the Pages adapter and through the client-facing URL after a homepage generation, including a withdrawal case.

FINDING: F-02
KIND: judgement
SEVERITY: should-fix
WHERE: Scope, Design (Publication and recovery), Owner summary
EVIDENCE: Scope line 73 says more repository entries "can be authored as static content". Design line 124 says "An update stages and approves the page within those archives before dispatch". Retained bundles are release assets tied to a version tag. The two bundles must have different digests (scripts/feed-bundles.sh:11-15, scripts/retain-feed-bundles.sh:10-25). Publication also checks package history and the generation marker against the native manifest (scripts/publish-feed.sh:349-383). The document never says whether a page-only change, such as a link fix or a new repository entry, needs a new package release and tag. It also leaves open whether the same package can be republished with a new page, what the recovery bundle holds in that case, and how the generation marker and history treat unchanged package bytes. The Owner summary does not tell the owner that every homepage edit becomes a protected feed publication.
PROPOSAL: Define the publication path for a page-only change, including its release identity, recovery bundle contents and history and marker handling, or state that page changes ship only with a package generation. Add a Test Plan case for that path and state the consequence in the Owner summary.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Frontmatter covers, Design (Publication and recovery), Test Plan AC-01, AC-04, AC-05
EVIDENCE: The Design requires the page assets to be added to both retained bundles and the served page assets to be verified before successful closure (lines 35, 123-127). Neither step exists today. `verify_recovery` checks only advertised packages and the catalogue (scripts/feed-recovery.sh:3-19), and the only code that builds the Pages manifest is the fixture generator (tests/package/feed-http-inputs.mjs:102-108). Yet `covers` omits scripts/publish-feed.sh, scripts/feed-recovery.sh, scripts/feed-close.sh, scripts/feed-preflight.sh, tests/package/feed-http-inputs.mjs, tests/package/feed-preflight-test.sh and .github/workflows/feed.yml. The document names no component that copies web/packages/ into the bundles. AC-01 says "Playwright opens the built page" but no build step, server or workflow is named. The root playwright.config.ts:4-9 targets the appliance through FIXTURE_APPLIANCE_URL, and no covered workflow runs tests/browser/packages.spec.mjs.
PROPOSAL: Name the bundle assembly step and the closure and recovery verifier changes, and list every file they touch in `covers`. State how the production page is built and served for the browser suite, and which workflow runs it.

FINDING: F-04
KIND: judgement
SEVERITY: should-fix
WHERE: Acceptance Criteria AC-04, Test Plan AC-04
EVIDENCE: AC-04 says "The actual Pages asset path serves the complete site with the correct content types". The proof extends tests/package/feed-publisher-http.mjs and the hosted fixture, which upload to a local mock (.github/workflows/feed-fixture.yml:17, 39-42). A mock can only check the `metadata.contentType` that the uploader sends (scripts/feed-pages-assets.mjs:55-59). It cannot show which Content-Type Cloudflare Pages actually serves. A wrong mapping that Pages overrides, or a mapping Pages ignores, would still pass.
PROPOSAL: Either reword AC-04 to the uploader's declared content types, or add a client-facing readback of each page asset's served Content-Type and bytes to the post-publication verification, and name it in the AC-04 row.

FINDING: F-05
KIND: factual
SEVERITY: should-fix
WHERE: Design (Content and visual structure, Browser behaviour), Acceptance Criteria AC-06, Test Plan AC-06, supporting prototype
EVIDENCE: The prototype tells readers to "Compare the public key's fingerprint with the release notes before trusting it" (docs/prototypes/vhco-packages/index.html:75). The installation guide instead requires confirming the DER key SHA-256 "through an independent trusted channel" (docs/installation.md:7-8). The release notes sit on the same GitHub release as the downloadable key (docs/installation.md:5-6), so comparing the two is not independent verification. The Design says the page links to signing information but leaves its trust wording undefined. The AC-06 proof checks only that canonical links carry the signing detail.
PROPOSAL: Require any signing-related wording on the page to defer to the installation guide's independent-channel verification and not name the release notes as the trust anchor. Add that check to the AC-06 proof and align the prototype.

FINDING: F-06
KIND: factual
SEVERITY: nit
WHERE: Context (Background)
EVIDENCE: Line 53 says retained bundles "already include a validated Pages path-to-asset manifest (`scripts/feed-payload.sh:5-23`, `scripts/feed-dispatch.sh:20-29`)". feed-payload.sh:5-23 validates and extracts the archive. feed-dispatch.sh:20-29 only exports FEED_MANIFEST. The manifest is validated at scripts/feed-preflight.sh:23 through `feed-pages-assets.mjs --validate`.
PROPOSAL: Cite scripts/feed-preflight.sh:23 and scripts/feed-pages-assets.mjs:34-50 for the manifest validation.

FINDING: F-07
KIND: judgement
SEVERITY: nit
WHERE: Design (Browser behaviour), supporting prototype
EVIDENCE: docs/prototypes/vhco-packages/page.js:35 sets the button text to "Copied" on success but never resets it. If a later copy attempt is denied, the button still reads "Copied" while the status says "Select Copy on your device to copy the repository URL." (page.js:43). The two visible feedback states then contradict each other.
PROPOSAL: Reset or update the button label on the fallback path, or clear the copied state after a short interval.

### R-2

TARGET: 23d22b463fb22cc41c8362557def8624ff05dbd7

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Design (Homepage-only updates) lines 170, 182, 185-188, Design (Publication and recovery) line 158, Owner summary lines 42-43, Acceptance Criteria AC-05, Test Plan AC-05
EVIDENCE: The design reuses the approved tag and says "Existing release assets are preserved" and "the advertised package history union remains identical". The existing history contract rejects that combination in two places. First, the production publisher downloads the fixed-name `advertised-packages.json` from the release (.github/workflows/feed.yml:238) and passes it as FEED_HISTORY (scripts/feed-dispatch.sh:11,26). Once a predecessor closure exists, publish-feed.sh requires the SHA-256 of that file to equal the predecessor closure's history digest (scripts/publish-feed.sh:116-133). For v0.1.0 that asset is the empty seed history (docs/reviews/first-signed-feed-bootstrap.md:57), while the closure records the history that includes the 0.1.0 package. So a page-only dispatch on the same tag exits with "retained history checkpoint changed". Second, the successor history for an unchanged union equals the predecessor's (scripts/feed-history.jq:19-23, scripts/publish-feed.sh:367-383). Its `history-<successor>.json` already exists under the same tag, but the approval asset is new because it binds the fresh candidate and recovery digests (scripts/publish-feed.sh:81-88). publish-feed.sh:385-388 then stops with "Successor history has no matching retained approval." The design never says how either guard changes for a page-only publication. The AC-05 fixture cannot expose the first conflict, because the fixture loads history from `history-<digest>.json` and not from the workflow's fixed asset (tests/package/feed-http-inputs.mjs:36-43). This revision introduced the page-only path in response to R-1 F-02. The pinned vh-adlc lint was not run because shell execution was denied in this review session.
PROPOSAL: Define how a page-only dispatch supplies its predecessor history on an existing tag and how the history/approval guard treats an unchanged successor without weakening the orphan-history check. Add a Test Plan case that runs the real feed.yml input path on a tag that already holds a closed generation.

FINDING: F-02
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Homepage-only updates) lines 174-176, Design (Publication and recovery) lines 160-165, Acceptance Criteria AC-05, Test Plan AC-05
EVIDENCE: Line 174 says established recovery is "verified against the previous complete retained bundle". Line 164 says a legacy bundle "uses its recorded prior-root HTTP 404 check". The design names no component that identifies that bundle or performs the comparison: preparation, preflight (scripts/feed-preflight.sh, which receives only the new digests) or the publisher after it reads the journal. The journal does not determine the served bundle either. After a successful recovery, closure records the recovery deployment ID but the candidate digest (scripts/publish-feed.sh:269-270,314-323; scripts/feed-journal-generation.jq:52-57), so the closure digest names a bundle that is not live. Line 181 also makes the recovery a superset of the prior page and catalogue, not a byte copy of a prior archive, so the compared file subset is undefined. No journal field or retained file records a prior root status. The background observation at line 55 is the only record. One implementer could check the predecessor candidate archive at preflight, and another could check the deployed recovery bundle after correlation. The AC-05 fixture names neither a recovered predecessor nor the comparison point.
PROPOSAL: State which retained archive is the baseline (the candidate or recovery bundle actually live at the predecessor closure, located through the journal's deployment and recovery records), which files must match, and which step checks it. State where a legacy root 404 expectation comes from. Add an AC-05 case where the predecessor generation closed on its recovery bundle.

FINDING: F-03
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Publication and recovery) lines 150-151, 156, Acceptance Criteria AC-04, Test Plan AC-04
EVIDENCE: Line 150 says feed-site.mjs verifies "each served site asset against the retained file's SHA-256 and expected media type". Line 151 adds the root route and "directly served assets". The cited Cloudflare Pages serving page (Sources line 298) documents that Pages redirects HTML files to extensionless routes, for example `/index.html` to `/`, and serves `404.html` only as the body of unmatched requests. The design never maps `index.html` and `404.html` to the URLs and statuses where their bytes are read. The publisher's `request` helper fails on non-2xx responses and does not follow redirects (scripts/publish-feed.sh:16-18). A literal per-file readback of `/index.html` or `/404.html` therefore fails a correct deployment. A readback that skips `404.html` bytes would accept a wrong 404 document. The loopback adapter and the prototype server return 404 for `/index.html` (docs/prototypes/vhco-packages/preview.mjs:3-11), so neither models the 308 redirect.
PROPOSAL: Specify the public URL, expected status and byte source for each HTML document: `/` with 200 for index.html, and an unmatched path with 404 whose body equals 404.html. Model the Pages HTML redirect in the local adapter used by the AC-04 fixtures.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Test Plan AC-06, Acceptance Criteria AC-06
EVIDENCE: The AC-06 row judges free text twice: it scans the payload "against synthetic private-marker fixtures" and confirms that "the signing text directs readers to the guide's independent trusted-channel key check". The pinned conventions/feature-documents.md:126 requires a pattern proof to list its must-pass and must-fail examples in the row, and the row lists none. A check that only looks for the word "installation guide" would pass the original prototype wording, "Compare the public key's fingerprint with the release notes" (R-1 F-05), which this revision replaced. That row text changed in this revision in response to R-1 F-05, so it has not passed review.
PROPOSAL: List the private-marker classes, and must-pass and must-fail signing sentences in the row. For example, the current prototype sentence at docs/prototypes/vhco-packages/index.html:76 must pass, and release-notes comparison wording must fail.

FINDING: F-05
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Homepage-only updates) lines 172-173, Design (Assembly and browser verification) line 130, Design (Publication and recovery) line 165
EVIDENCE: site.json is "retained inside the bundle". Preflight checks that its "complete asset list matches the bundle's Pages manifest". The Pages manifest also carries package, catalogue, release.json and generation.json paths (scripts/feed-preflight.sh:23-39, tests/package/feed-http-inputs.mjs:44-55), so a literal equality check cannot pass. The design leaves two things open. It does not say whether site.json is itself a Pages path published at `/site.json`. It also does not say whether the manifest may hold extra non-package paths that are absent from site.json, such as a stray HTML file. One implementer would check only that listed assets are present. Another would require the manifest's non-package paths to equal the list. Only the second rejects the "partially present new page assets" that line 165 says must fail preflight.
PROPOSAL: State whether site.json is served. Define the check as equality between site.json's asset list and the manifest's paths outside the package, catalogue and publication metadata set, and add an unlisted extra page file to the AC-04/AC-05 preflight failure cases.

### R-3

TARGET: 340d9014f0b9671257bf6594270681967f82b6b7

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Design (Selecting predecessor history and recovery bytes) lines 208-215, Owner summary line 46, Test Plan AC-05
EVIDENCE: Line 209 says dispatch "reuses `feed-journal-generation.jq` to select the predecessor closure". That filter sets `.closed` to the newest verified-closure (scripts/feed-journal-generation.jq:52-57), and that closure can belong to the submission being replayed. publish-feed.sh does something different on replay. When the started submission matches FEED_DIGEST, it replaces the predecessor with the closure of `started.payload.predecessor`, "even after closure" (scripts/publish-feed.sh:104-118). It then requires the FEED_HISTORY digest to equal that parent's history (scripts/publish-feed.sh:126-133). Take a package publication where the feed-close.sh POST succeeds but its response is lost (scripts/feed-close.sh:26-32), and the operator re-runs with the same digests. Dispatch would supply `history-<own closure.history>.json`, which is the successor history. publish-feed.sh would then hold with "retained history checkpoint changed", and line 213 makes that mismatch a hold. A page-only update hides the defect, because its successor and predecessor digests are equal (line 217). The AC-05 proof tests replay only as generic "interrupted/lost responses". This design traces to this revision's repair of R-2 F-01.
PROPOSAL: Specify that dispatch uses the same replay rule as publish-feed.sh. When the latest submission matches the requested candidate digest, dispatch should select the closure named by that submission's predecessor and not `.closed`. Add an AC-05 case for a package publication whose closure response was lost and then re-run.

FINDING: F-02
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Selecting predecessor history and recovery bytes) lines 233-237, Design (Homepage-only updates) lines 187-190 and 197, Test Plan AC-05
EVIDENCE: Line 233 requires "exact equality" with the prior served archive for "the catalogue/metadata file set and bytes". Line 188 lists the generation marker among publication-metadata paths. Line 237 then says "the recovery's attempt marker retain[s] [its] existing distinct role". Existing recovery bundles carry their own `generation.json` (`{recoveryOf, version}`) and a reconstructed `release.json` (tests/package/feed-http-inputs.mjs:76-81, 101). Both differ from the candidate's `generation.json` digest marker and its full release.json. When the predecessor closed on its candidate, the served `generation.json` is the candidate marker. Requiring exact metadata equality drops the distinct recovery marker, and keeping that marker breaks equality. The marker matters to existing checks: publish-feed.sh:287 and scripts/feed-recovery.sh:76 test `.digest == marker`, and scripts/feed-recovery.sh:90 compares served and recovery `generation.json` bytes. The document never says whether `release.json`, `generation.json` or `pages-manifest.json` are inside the exact comparison. Different implementers would build incompatible recovery archives. This traces to this revision's repair of R-2 F-02.
PROPOSAL: List exactly which files the recovery-to-served comparison covers. State how the recovery's `generation.json` and `release.json` relate to the prior served bytes in two cases: when the predecessor closed on its candidate, and when it closed on its recovery. Add both cases to the AC-05 assertions.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Design (Homepage-only updates) lines 181, 196-204, Owner summary lines 43-46, Acceptance Criteria AC-05, Test Plan AC-05
EVIDENCE: A page-only publication reuses the "exact package/catalogue bytes", so it also reuses the approved `release.json` (line 181). The publisher reads `retirement` from that manifest (scripts/feed-retirement.sh:3). When the predecessor closure has a `withdrawn` path, it requires `retirement == {}` (scripts/publish-feed.sh:351-353). Otherwise a non-empty retirement needs FEED_RETIREMENT_AUTHORIZED (scripts/publish-feed.sh:361-365). On success it reruns trust finalization, which needs fresh signed operator evidence (scripts/publish-feed.sh:289-292, scripts/feed-retirement.sh:26-53). So a page-only update on the release that performed a catalogue retirement either holds unconditionally after that retirement closes, or repeats the retirement and trust-finalization flow. The design does not say whether page-only updates are allowed on such a release or how retirement state carries forward. AC-05 has no retirement case.
PROPOSAL: Define page-only behaviour for a release whose manifest carries a retirement plan and for a predecessor closure with `withdrawn` set, either a carried-forward withdrawal or an explicit exclusion. Add the matching AC-05 case.

FINDING: F-04
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Publication and recovery) lines 161-162 and 175, Owner summary line 48, Acceptance Criteria AC-04, AC-05, Test Plan AC-04
EVIDENCE: Line 162 says a failed site readback "follows the existing recovery or hold rules for that attempt", but the existing rules fork in three places. First, a candidate whose native verification fails moves to recovery when authorised (scripts/publish-feed.sh:293-302). Second, a failing `verify_recovery` after a recovery deployment allows a new per-dispatch retry submission (scripts/feed-recovery.sh:91-108). Third, `verify_unchanged_feed` gates rejection closure and failed-candidate closure (scripts/publish-feed.sh:210-231). The document does not say whether a site byte, media-type or status mismatch on a successful Pages deployment is a recovery trigger or a hold. It also does not say whether the site check goes inside `verify_recovery`, and therefore into retry and unchanged-feed closures. A deterministic serving mismatch from the provider, such as a Content-Type override, would cause repeated retries under one reading and a single hold under the other. The AC-04 row checks only "failure before closure".
PROPOSAL: State which outcome a site readback failure causes for a candidate, for a recovery deployment and for rejection or failed-candidate closures. Add one AC-04 or AC-05 fixture case for each outcome.

FINDING: F-05
KIND: factual
SEVERITY: should-fix
WHERE: Test Plan AC-06, Acceptance Criteria AC-06
EVIDENCE: The row's must-fail examples are the literal tokens `PRIVATE_FIXTURE_LAB_ADDRESS`, `PRIVATE_FIXTURE_TOKEN`, `PRIVATE_FIXTURE_CONFIG_XML` and `PRIVATE_FIXTURE_SIGNER_PEM`. None of them has the shape of the data it stands for. A class-based detector, for example one that matches private IPv4 ranges, PEM private-key headers or OPNsense config XML, would not reject them. Only a literal `PRIVATE_FIXTURE_` matcher passes the row. That matcher also passes a page that leaks a real lab address, token, config fragment or private key, so the proof can pass a wrong implementation. The row changed in this revision in response to R-2 F-04 and has not passed review.
PROPOSAL: Replace or supplement the markers with synthetic values in the real shapes, such as an RFC 1918 or tailnet address, a token-shaped string, an `<opnsense>` config fragment and a `-----BEGIN PRIVATE KEY-----` block. Each must fail in served HTML, in an asset and in a browser-request URL.

FINDING: F-06
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Selecting predecessor history and recovery bytes) lines 224-231, Design (Homepage-only updates) lines 183 and 190, Design (Assembly and browser verification) line 134, frontmatter covers
EVIDENCE: Line 224 says "preparation" selects the live predecessor archive by correlating Pages deployment IDs through "the existing provider-correlation rules". Bundle preparation today is an operator procedure outside the protected job (docs/reviews/first-signed-feed-bootstrap.md:49-57). The Pages token exists only in the protected `publish` job (.github/workflows/feed.yml:206). The document names no script or job for this preparation-time selector and no credential for its journal and Pages reads. scripts/feed-site.mjs (line 134) is described only as placing assets. The existing correlation also holds unless the whole production deployment list fits on one page of 25 (scripts/publish-feed.sh:164-174), and every page-only publication adds deployments. The document does not say what happens once that bound is exceeded. The journal alone already identifies a recovery closure: `recovery-required` and `recovery-started` rows exist for the candidate, and `closure.deployment` differs from `recovery-required.source` (scripts/feed-journal-generation.jq:12-24). The document does not say whether provider correlation is required beyond that.
PROPOSAL: Name the component, job and credentials that perform preparation-time selection and list them in `covers`. State whether selection relies on journal rows alone or also on provider correlation. Define the hold or fallback when the provider deployment list exceeds the existing complete-read bound.

FINDING: F-07
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Homepage-only updates) lines 182-186 and 194, Test Plan AC-05
EVIDENCE: Line 182 says the reviewed page source SHA is "supplied separately" and "must be reachable from main". Line 186 says "Candidate preflight validates the source SHA". The `publish` dispatch has no page-source input (.github/workflows/feed.yml:4-39). It checks only `APPROVED_SOURCE` with `git merge-base --is-ancestor` (.github/workflows/feed.yml:226-227). scripts/feed-preflight.sh receives no page SHA (scripts/feed-preflight.sh:5-14). The document does not say whether the protected job independently checks that the page SHA in the retained `site.json` is reachable from main, or only that it is consistent with the listed bytes. One implementer would add a dispatch input and an ancestry check. Another would trust the SHA recorded at preparation. AC-05 lists "source mismatch" but no unreachable page SHA case.
PROPOSAL: State where the page SHA enters the protected run and which step verifies its ancestry from main against the `site.json` value. Add an AC-05 case where an unreachable page SHA holds before submission.

## Sources

- [VHCO homepage](https://vhco.pro/) provides the observed branding and navigation style. Chromium returned HTTP 200 on 15 November 2026 and computed Inter for the body text.
- [Site theme source](https://github.com/michielvha/vitepress/blob/main/app/.vitepress/theme/style.css) defines the observed brand gradient and dark background.
- [Company mark](https://vhco.pro/landing/vhco-github.png) is the existing VH & Co logo used by the site.
- [Current installation guide](../installation.md) supplies the repository URL, native installation boundary and signing instructions.
- [Pages uploader](../../scripts/feed-pages-assets.mjs) owns the current path checks, asset upload and content-type selection.
- [Recovery verifier](../../scripts/feed-recovery.sh) owns retained recovery checks.
- [FreeBSD pkg repository manual](https://man.freebsd.org/cgi/man.cgi?query=pkg-repo&sektion=8) defines a catalogue containing available packages.
- [Cloudflare Pages serving behaviour](https://developers.cloudflare.com/pages/configuration/serving-pages/) documents root 404 handling and the default SPA fallback when a top-level `404.html` is absent.
- [Cloudflare Pages custom domains](https://developers.cloudflare.com/pages/configuration/custom-domains/) describes the existing static hosting and custom hostname boundary.
- [Inter licence](https://github.com/rsms/inter/blob/v4.1/LICENSE.txt) permits the bundled font under the SIL Open Font License.
