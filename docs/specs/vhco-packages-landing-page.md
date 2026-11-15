---
status: draft
status_description: "Owner-selected publisher reuse; visual prototype prepared for review."
issue: null
goal: "Visitors to pkg.vhco.pro can identify VHCO package repositories and reach their setup and signing instructions."
covers:
  - web/packages/
  - docs/prototypes/vhco-packages/
  - scripts/feed-pages-assets.mjs
  - tests/package/feed-publisher-http.mjs
  - tests/package/hosted-feed-content.sh
  - tests/browser/packages.spec.mjs
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
The native client continues to retrieve the same catalogue and package paths.
Cloudflare Pages serves the static page using the current protected publication workflow and credentials.
The publisher verifies the served page assets alongside its existing native verification before recording a successful publication.

The requested visual prototype is a design artifact in `docs/prototypes/vhco-packages/`.
Its browser checks cover layout, theme selection, copying and navigation.
The production bundle, hosted content types and recovery tests below are planned implementation proof.
This specification remains draft for owner critique of the design and preview.

### Background

On 15 November 2026, `curl https://pkg.vhco.pro/` returned HTTP 404 while the published package and signed catalogue returned their retained bytes over verified HTTPS.
The released package is documented in [the installation guide](../installation.md) and [v0.1.0](https://github.com/vhco-pro/opnsense-encrypted-git-backup/releases/tag/v0.1.0).

The observed VHCO homepage returned HTTP 200 in Chromium and used Inter.
The site's `app/.vitepress/theme/style.css` defines its cyan, blue and purple brand gradient and dark background.
`app/.vitepress/theme/components/ScrollHero.vue:200-202` uses the existing company logo from `app/public/landing/vhco-github.png`.
These source files belong to the private VitePress repository, while the logo and homepage are publicly served by vhco.pro.

The Pages uploader currently provides explicit HTML and JSON content types and a binary fallback for other files (`scripts/feed-pages-assets.mjs:54-60`).
Retained bundles already include a validated Pages path-to-asset manifest (`scripts/feed-payload.sh:5-23`, `scripts/feed-dispatch.sh:20-29`).
The established publisher and recovery process own the deployment and its native verification (`scripts/feed-recovery.sh:3-18`).

### Prototype verification

The 32 focused prototype scenarios passed locally with the repository's locked Playwright 1.59.1 in Chromium and Firefox.
The checks exercised six viewport sizes in both themes, keyboard access, theme persistence, URL copying, denied clipboard/storage access and reading with JavaScript disabled.
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
Additional repository entries can be authored as static content when they become available.
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

### Browser behaviour

The repository URL copy button writes only the URL after an explicit click.
A successful copy produces visible status and a live-region announcement.
If clipboard access is unavailable, the URL is selected and the page explains the device's manual copy action.
Reading, setup links and compatibility information remain accessible when JavaScript is disabled.

The page uses semantic headings, keyboard-visible focus, a skip link and labelled controls.
Text reflows at narrow widths, reduced-motion settings are honoured, and buttons have at least 44 CSS-pixel heights.
The current entry's setup link scrolls to the guide and signing-information section.
External links are ordinary links to published material.
No account or provider credential is needed to read the page.

### Publication and recovery

The page is published as ordinary static assets through the existing Pages publisher.
Candidate bundles include `index.html`, its styles, browser script, company logo, font and required licence file.
Existing catalogue, metadata and package URL paths continue to serve their authenticated retained bytes.
The native verifier continues to use its actual repository configuration and ABI.

The asset uploader assigns explicit content types for HTML, CSS, browser JavaScript, PNG, WOFF2 and licence text.
Its existing path validation, size limits, digest checks and authentication apply to every site asset.
Local and hosted fixtures verify those content types and asset bytes through the actual upload/readback adapter.

Retained candidate and recovery archives contain the complete page asset set for their generation.
An update stages and approves the page within those archives before dispatch.
The existing single-writer publication, durable submission and reconciliation rules apply to the resulting deployment.
An interrupted publication is reconciled through its existing journal and attempt identity.
The site assets are verified against the retained manifest before successful closure.

An established recovery restores its retained page and authenticated package generation together.
Bootstrap recovery serves the generic information page and its documentation links while the native catalogue paths return their expected withdrawal responses.
The homepage makes no assertion about live availability, an installed package or the appliance's trust state.
A first deployment can recover to the previously approved archive which has no homepage; that returns the previously observed root response and preserves existing clients.
The publication follows the existing separately authorised release path after implementation review and acceptance.

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
- [ ] AC-04: The actual Pages asset path serves the complete site with the correct content types, while existing native catalogue and package clients continue to retrieve and verify their expected retained bytes.
- [ ] AC-05: Candidate publication, established recovery and bootstrap recovery retain and verify the appropriate page assets under the existing single-writer and interrupted-publication contract.
- [ ] AC-06: The public page contains repository information without private deployment inputs or credentials, uses its glossary terms consistently and leaves package versions and signing fingerprints with their authoritative release and guide records.

## Test Plan

| Criterion | Proof |
| --- | --- |
| AC-01 | Playwright opens the built page, checks the actual repository identifier and URL, follows the local setup anchor and validates each public reference's final route and expected document. A two-entry synthetic fixture verifies that an additional authored repository can be represented without another origin. |
| AC-02 | Chromium and Firefox exercise light/dark at 320×568, 390×844, 844×390, 768×1024, 1280×720 and 1440×900. Assert horizontal containment, heading readability, 44-pixel buttons, focus visibility and setup reachability. Inspect representative mobile and desktop captures. Exercise reduced motion and retain an actual 200-percent browser-zoom procedure with its effective viewport. |
| AC-03 | In Chromium and Firefox copy the repository URL, verify the clipboard result and status, choose a theme, reload and verify preference persistence. Run clipboard-denied, storage-denied and JavaScript-disabled contexts. The denied clipboard case selects the actual URL and explains manual copying. |
| AC-04 | Extend `tests/package/feed-publisher-http.mjs` and the hosted feed fixture to upload/read back HTML, CSS, JS, PNG, WOFF2 and licence bytes using the real uploader. Assert each MIME type and retained digest. Run native pkg catalogue authentication and exact package fetch before and after the homepage generation. |
| AC-05 | The existing publisher/controller fixture exercises a live candidate, an established recovery and an empty-catalogue bootstrap recovery including all page assets. Interrupted/lost-response and duplicate-correlation checks show the same attempt is reconciled. An older retained generation without a page also restores its recorded prior root response and authenticates its package bytes. |
| AC-06 | Scan the final approved site payload against synthetic private-marker fixtures and inspect its complete asset list, HTML and browser network requests. Check repository/package terminology and confirm canonical guide/release links carry the runtime and signing detail. The page's browser context needs no credentials to render. |

## Tasks

None yet; written after owner acceptance.

## Open Questions

The owner selected reuse of the existing publisher for v1 on 15 November 2026.

### Q1 — Homepage-only publication

R-1 F-02 asks whether a homepage-only edit may reuse the approved package and tag with new retained page bundles, or must accompany a package release.
Recommend allowing a separately approved page-only publication through the existing protected publisher.
It would retain the exact package/catalogue bytes and package identity, verify the new complete site bundle and preserve the previous complete bundle for recovery.
This requires implementation and its own proof.
Owner answer pending.

### Q2 — Served content verification

R-1 F-04 asks whether publication must verify the actual public asset bytes and Content-Type headers, or the criterion should cover only uploader metadata in local fixtures.
Recommend actual client-facing readback before successful closure.
Owner answer pending.

## Review Log

| Date | Review | Kind | Commit | Model | Isolation | Outcome |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-11-15 | R-1 | spec | `1012715422c73c326c0d3061e62dbc2c9e83c334` | claude-opus-5-5 | procedural | One blocking, four should-fix and two nits. Read-only checkout preservation verified. |

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

## Sources

- [VHCO homepage](https://vhco.pro/) provides the observed branding and navigation style. Chromium returned HTTP 200 on 15 November 2026 and computed Inter for the body text.
- [Site theme source](https://github.com/michielvha/vitepress/blob/main/app/.vitepress/theme/style.css) defines the observed brand gradient and dark background.
- [Company mark](https://vhco.pro/landing/vhco-github.png) is the existing VH & Co logo used by the site.
- [Current installation guide](../installation.md) supplies the repository URL, native installation boundary and signing instructions.
- [Pages uploader](../../scripts/feed-pages-assets.mjs) owns the current path checks, asset upload and content-type selection.
- [Recovery verifier](../../scripts/feed-recovery.sh) owns retained recovery checks.
- [FreeBSD pkg repository manual](https://man.freebsd.org/cgi/man.cgi?query=pkg-repo&sektion=8) defines a catalogue containing available packages.
- [Cloudflare Pages custom domains](https://developers.cloudflare.com/pages/configuration/custom-domains/) describes the existing static hosting and custom hostname boundary.
- [Inter licence](https://github.com/rsms/inter/blob/v4.1/LICENSE.txt) permits the bundled font under the SIL Open Font License.
