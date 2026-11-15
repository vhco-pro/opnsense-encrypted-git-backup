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

None.
The owner selected reuse of the existing publisher for v1 on 15 November 2026.

## Review Log

| Date | Review | Kind | Commit | Model | Isolation | Outcome |
| --- | --- | --- | --- | --- | --- | --- |

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
