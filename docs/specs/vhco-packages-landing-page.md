---
status: draft
status_description: "R-8 findings addressed by removing backend CI filtering and clarifying independent site verification, deployment concurrency and source restoration. Fresh review pending."
issue: null
goal: "Visitors to pkg.vhco.pro can identify VHCO package repositories and reach their setup and signing instructions."
covers:
  - README.md
  - web/packages/
  - package.json
  - bun.lock
  - docs/prototypes/vhco-packages/
  - tests/browser/packages.spec.mjs
  - tests/browser/packages.config.mjs
  - .github/workflows/packages-site.yml
---

# VHCO Packages landing page

## Context

### Owner summary

Give pkg.vhco.pro a small VHCO-branded homepage listing package repositories and their setup guides.
Start with the released OPNsense encrypted Git backup plugin.
Use the existing company logo, Inter font, brand colours and the reviewed sun/moon theme switch.

The owner clarified on 16 November 2026 that the homepage has an independent deployment lifecycle.
Page edits use an ordinary static-site workflow and can be redeployed from Git.
The package artifact keeps its existing shared GitVersion version.
The page links to the artifact's release and installation documentation.
Git commits and Cloudflare's deployment history identify page edits.

GitHub's native artifact attestations are the selected direction for package provenance.
They identify the artifact digest and the producing workflow/source identity.
The package build and release path owns their adoption.
FreeBSD's native signed catalogue remains the installation trust mechanism described in the current guide.

The owner selected native Cloudflare static hosting with narrow homepage routes and pipeline-managed deployment on 16 November 2026.
The site uses the official Cloudflare Wrangler action after its verification passes.
Package URLs continue directly to their existing Pages origin.
A new main commit restoring previously reviewed page files recovers a broken page through the ordinary pipeline.
The site pipeline uses a credential for the existing site Worker.
Lab owns the one-time Worker bootstrap, route, redirect and main-only deployment-environment setup.
Production site deployments use their own concurrency group, separate from package publication.
A running site deployment finishes, and a newly pending deployment replaces an older pending one under GitHub's default single-pending behaviour.
The page's own free secret scan and browser checks gate its deployment.
Existing package workflows retain their current checks and triggers.

The prototype passed 40 local Chromium/Firefox cases.
Production hosting and native attestation integration are still unimplemented.
This revised draft requires fresh independent review before acceptance.

### Background and revision

The released package is documented in [the installation guide](../installation.md) and [v0.1.0](https://github.com/vhco-pro/opnsense-encrypted-git-backup/releases/tag/v0.1.0).
The draft's first six reviews covered a design that carried page files inside package candidate and recovery archives.
The owner requested independent page deployment and removal of the additional page-publication controls on 16 November 2026.
That direction replaces the earlier Q7 decisions.
Former AC-05 described the joint publication lifecycle and is retired by this scope correction.
AC-07 defines independent page delivery.
Historical reviewer records are retained verbatim below.

The existing publisher deploys a complete retained Pages bundle through `scripts/publish-feed.sh` and `.github/workflows/feed.yml`.
Deploying only a homepage directory into that Pages project would replace the package snapshot.
Cloudflare documents static asset hosting and path-based routing, which provide a platform-native approach to examine before implementation.
The precise route configuration requires verification against the existing Pages custom domain.

The owner also selected the official action as the shared default for pipeline-driven static Cloudflare hosting.
The shared [static-site standard](https://github.com/vhco-pro/docs/blob/2028365d39ff0bebf7698fff975ae04d0dac133e/conventions/cloudflare-static-sites.md) and complete example were merged through [Docs PR #46](https://github.com/vhco-pro/docs/pull/46).
The current VHCO Worker CI action explicitly rejects an `assets` configuration and requires a single JavaScript module (`worker-ci-action@5ef3cf6`, `scripts/verify.ts:40-44`).
The existing Worker deploy action verifies an exact release tag and `worker.mjs` (`worker-deploy-action@bcf1117`, `scripts/activate.ts:26-44`).
The official action supports Bun and multiple native Wrangler commands through its declared inputs at `953926a2e2182532811c01a25e53647d93bf07c0`.

### Prototype verification

The 40 focused prototype scenarios passed locally with the repository's locked Playwright 1.59.1 in Chromium and Firefox.
The checks exercised six viewport sizes in both themes, keyboard switch activation, reduced motion, theme persistence, URL copying, denied clipboard/storage access, explicit missing-route HTTP 404 responses, independent-channel signing guidance and reading with JavaScript disabled.
The R-1 copy-state, signing-text and missing-route regressions first failed against the original prototype, then passed after correction.
Their failing output remains under ignored `work/packages-preview-r1-red-host/`.
The logo-notice regression also failed in both engines before the notice and link were added, then passed in the complete 38-case run.
Its initial output remains under ignored `work/packages-preview-logo-red/`.
The theme-switch regression failed in both engines before the switch was added, with output under `work/packages-preview-theme-red/`.
An initial reduced-motion assertion ran without browser media emulation and failed in both engines.
Explicit emulation corrected that test setup, and the final 40-case run passed in 38.3 seconds.
The failed run remains under ignored `work/packages-preview-theme-motion-failure/`.
Representative desktop and mobile captures were inspected.
The actual owner-restricted HTTPS share also loaded its assets, changed theme and navigated to setup.
Its browser clipboard policy used the tested URL-selection fallback.
An initial npm bootstrap and missing-browser launch were corrected by using the frozen Bun lockfile and installing its matching browser bundles.
The initial missing-browser evidence remains under the ignored `work/packages-preview-missing-browsers/` directory.


### Native hosting compatibility check

On 16 November 2026, Wrangler 4.162.0 accepted an assets-only configuration with the proposed exact-root and `/_site/*` routes during `wrangler deploy --dry-run`.
The command exited successfully after reading the staged static files.
The local `wrangler dev --local` runtime served the root and six prefixed assets with the expected bytes and media types.
Three absent-path requests returned HTTP 404.
Chromium and Firefox loaded the page, changed and retained the theme, reached the setup section and reported zero page errors.

This check exercised Cloudflare's local workerd runtime and configuration parser.
The edge route selection and root-query redirect still require live verification at the separately authorised cutover.
The public feed returned HTTP 200 for `/meta.conf` and HTTP 404 at `/` during the same read-only check.

## Scope

Add a generic homepage at pkg.vhco.pro with the VHCO mark, website styling and current OPNsense repository entry.
Provide setup, compatibility, source and release links and a copyable repository URL.
Support reading and navigation through HTML, with theme selection and URL copying as progressive browser enhancements.

Keep the v1 page source and generic static configuration in this repository under `web/packages/`.
Deploy through the official `cloudflare/wrangler-action` from the site's GitHub workflow.
Lab owns bootstrap, the site-specific routes and redirect, and the GitHub environment inputs.
Public route activation follows the initial page upload and settings verification.
Page delivery uses the reviewed Git commit and ordinary workflow results.
Any package version displayed on the page comes from that artifact's published release.
The release link remains the reference for its version and download.

Package provenance uses GitHub's native attestation facilities in the package build/release path.
Attestation adoption is a package-delivery follow-up to specify against that actual producing job.
The homepage's acceptance depends on its static delivery and package-route isolation.

## Design

### Content and visual structure

The header identifies VH & Co and Packages and links to vhco.pro and the GitHub organisation.
The main heading reads "Packages from VH & Co."
Each authored repository entry contains its package identifier, short description and links to maintained installation, compatibility and release references.
Additional entries are ordinary static content changes.

Use the actual company logo and the site's Inter font, cyan/blue/purple gradient, rounded controls and restrained cards.
The public asset set retains `VHCO-LOGO-NOTICE.txt` with the logo and `INTER-LICENSE.txt` with Inter.
The prototype's asset provenance is recorded in its README.

The default theme follows the browser preference.
The sun/moon switch has a stable "Dark theme" accessible label, a checked state matching the active theme and native Space/Enter activation.
Store the selected theme locally when storage is available.
Storage denial still permits a selection for the current page view.
The switch honours reduced motion and offers a 44 CSS-pixel touch target.

URL copying requires an explicit click and produces visible and live-region feedback.
When clipboard access fails, select the URL, label the control "Selected" and explain the manual copy action.
Reading and navigation work with JavaScript disabled.
Use semantic headings, a skip link, visible keyboard focus and responsive text.

### Independent hosting

Use Cloudflare Workers Static Assets for the homepage and a dedicated `/_site/` asset prefix.
Production files live in `web/packages/public/`, with `index.html` and `404.html` at that directory's root and the stylesheet, browser script, logo, font and both notices under `_site/`.
HTML and stylesheet references use the same public prefix.
The generic Wrangler configuration at `web/packages/wrangler.toml` points its assets directory at `public/`, uses the native `404-page` setting and declares workers.dev and preview URLs disabled.
Lab's bootstrap applies these settings on the live Worker through native deployment, then explicitly reads back its subdomain and preview settings before activating public routes.

Lab owns the site Worker bootstrap and subsequent activation of two routes, `pkg.vhco.pro/` and `pkg.vhco.pro/_site/*`.
Initial setup verifies the proxied hostname and checks the site-specific routes and redirect for conflicts with existing rules.
Other request paths reach the existing Pages package origin through the current DNS configuration.
The exact-root route matches query-free root URLs.
A native Single Redirect matches host `pkg.vhco.pro`, path `/` and a nonempty query, returns HTTP 301 to `https://pkg.vhco.pro/` and sets `preserve_query_string=false`.
This canonicalises a homepage query URL before the visitor requests the exact root.
Site asset queries match the prefixed wildcard route.

```mermaid
flowchart LR
  Browser[Browser] --> Root[pkg.vhco.pro homepage]
  Root --> Site[Independent Cloudflare static deployment]
  Client[Native pkg client] --> Feed[Existing repository URLs]
  Feed --> Packages[Signed package feed]
  Git[Reviewed page commit] --> Site
  Release[Versioned package release] --> Packages
```

The fixture exercises the configured public files through native Wrangler and checks the intended routing boundary.
The authorised cutover checks actual edge routing and redirect behaviour against the existing Pages custom domain.
Missing catalogue and package paths return HTTP 404.
Initial route activation follows the bootstrap's successful site upload and settings readback.
Native package verification immediately follows cutover.

### First cutover and infrastructure ownership

The initial Lab-controlled bootstrap runs the official action's native `deploy` command against the selected reviewed page source with a creation-capable bootstrap credential.
It creates the asset Worker with that actual page content and its public route settings disabled.
This step precedes the resource-scoped Editor credential used by ordinary site CI, since that role requires an existing Worker.
The bootstrap credential and its broader creation permission belong to the separately authorised initial setup.
Its site upload is followed by a native API readback requiring workers.dev and version preview access to be disabled.

Lab then configures the site GitHub environment with a selected-branches policy permitting the branch `main` and its Cloudflare account, Worker name and Editor credential.
That environment permits workflow runs on `main` through GitHub's native branch policy.
Lab's maintained infrastructure configuration owns the two routes and the canonical-query redirect.
Routine Lab runs manage those infrastructure settings and reference the already created Worker by identity.
The page pipeline owns the Worker's content after bootstrap.

The cutover first confirms the expected HTTP 404 root and authenticated existing feed baseline.
After checking the uploaded site in the native fixture, it applies the two routes and redirect, checks their actual public responses and runs native catalogue authentication and package fetch.
If any cutover check fails, revert the site-specific routes and redirect through the Lab configuration and verify the existing Pages origin again.
The restored baseline has HTTP 404 at `/` and absent page paths, with the retained catalogue and package responding as they did before cutover.
Completion requires the public response checks and native package verification to pass after restoration.
A failed or unverified restoration is reported as an incomplete cutover.

The repository-level `PACKAGES_SITE_PUBLISH_ENABLED` variable enables routine main-push publication only after the initial cutover succeeds.
The first setup records the Worker identity, environment branch policy, disabled public preview settings and verified routes in Lab's deployment procedure.

### Pipeline and reuse

Use `cloudflare/wrangler-action@953926a2e2182532811c01a25e53647d93bf07c0` (v4.1.3) directly in `.github/workflows/packages-site.yml`.
Install Wrangler as an exact root development dependency through the existing Bun lockfile, then select `packageManager: bun` in the action.
The action uses the installed tool.
The consumer's workflow owns its static-file checks, browser suite and HTTP smoke check.
Its verification job scans the actual `web/packages/public/` payload with the free upstream Gitleaks CLI, using the official container pinned by released version and digest in the workflow.
Use `gitleaks dir --redact=100 --no-banner` against that payload and let the repository's updater discover the container pin.
Both a finding and a scanner error fail verification.
The deployment job depends on this same verification job, including the secret scan.
Pull requests run that job with read-only GitHub permissions and without Cloudflare credentials.
An enabled main-branch push deploys only after it succeeds.

The deployment job uses the site's GitHub environment for the Cloudflare account, Worker name and deployment credential.
The environment's native deployment-branch policy allows only the branch `main`, with tag refs excluded.
Lab configures that policy and the cutover procedure verifies it through the GitHub environment API before enabling routine publication.
Its credential grants native Editor access to the existing site Worker.
Initial infrastructure setup owns Worker creation, the two routes and the redirect.
The consumer pipeline operates on the configured Worker through two native commands in the official action's multiline `command` input.
Run `versions upload` with the static config, configured Worker name and an annotation tag formed from the GitHub run ID and attempt.
Then run `versions deploy` for that annotation tag at 100 percent, using `--version-tag` and `--yes`.
These are Cloudflare's deployment identifiers for the Actions run.
Any package version displayed by the page is the package artifact's release version.
The pipeline's root and asset HTTP smoke check reports its deployment result through the normal Actions run.

Use the site-only production group `vhco-packages-site-production` with `cancel-in-progress: false` and GitHub's default `queue: single` behaviour.
This group is separate from the package publisher's `native-package-pages-publisher` group.
One site deployment can run while one waits.
A new pending site job replaces the previous pending site job, and the running site job finishes.
That behaviour permits missed intermediate homepage updates, as selected by the owner.
Read-only verification can cancel superseded work independently.

Recover older page content by restoring the selected page files in a new main commit and letting the ordinary verification and deployment run.
This source-restoration path works beyond Actions' rerun window and keeps the deployment environment on `main`.
GitHub also permits an authorised rerun within 30 days of the initial run, up to 50 attempts, using the original source, ref and initial actor's privileges.
Such a rerun can restore older content and uses the same site-only concurrency group.
The Actions run and Cloudflare deployment history identify the selected source and result.

Existing PHP, native-browser, native-feed and package-publisher workflow definitions retain their current verification, triggers and source-proof contract.
The site workflow's verification and deployment are independent of their results.
Its source paths and workflow select its own checks.
Review the feature diff to confirm that package workflow definitions were not changed, then verify that a failing native-feed run cannot become a passing package-source proof by skipping its fixture on a page-only commit.

Other static-site consumers reuse the same upstream action with their own build, native command and hosting configuration.
The shared standard and complete example are available on the shared docs main branch through Docs PR #46.

A page failure is recovered by the new-main-commit source-restoration procedure above.
A concurrent package publication or package recovery can proceed against the feed target.
The homepage can show a slightly older repository description or release link while a page fix is prepared.

### Artifact provenance

GitHub documents native attestation generation and verification, including `gh attestation verify` for a downloaded artifact.
Use those facilities for the package artifact's provenance and the producing job's actual identity.
The producing job must build the artifact it attests, and the published artifact must match that digest.
Attestation work must account for the current off-host package preparation and signing workflow in the installation guide.
An attestation produced by a publishing job that downloads prebuilt bytes must accurately describe that job's operation.

Attestation integration is still proposed.
The existing v0.1.0 release has the verification evidence recorded in its release and installation guide.
The native installation guide continues to require an independently verified package-repository signing key and authenticated catalogue.
The page points readers to that guide and the artifact's release.

### Browser and workflow checks

Use the existing locked Bun/Playwright dependencies and a loopback fixture serving the production static files.
Exercise Chromium and Firefox in both themes at 320 by 568, 390 by 844, 844 by 390, 768 by 1024, 1280 by 720 and 1440 by 900.
Check keyboard navigation, the switch, saved preference, clipboard denial, unavailable storage and JavaScript-disabled reading.
Inspect representative mobile and desktop captures and run actual 200 percent browser zoom before implementation completion.

Ordinary page CI checks the explicit public files, required notices, its own blocking Gitleaks payload scan and browser suite.
The deployment publishes the checked-out site through the official action and performs a root/assets HTTP smoke check.
Page CI is scoped to the site source and its workflow/tests.
One native package-client check during the separately authorised hosting cutover confirms that route isolation preserves catalogue authentication and package fetch.
The routing fixture provides repeatable coverage for later page edits.

### Terms

| Term | Meaning |
| --- | --- |
| VHCO Packages | The human-facing hub at pkg.vhco.pro. |
| Repository | A native package catalogue and its package files at a configured URL. |
| Package | An installable artifact listed in a repository. |
| Artifact attestation | GitHub's signed provenance statement bound to an artifact digest. |

## Acceptance Criteria

- [ ] AC-01: The root page identifies VHCO Packages, presents the current OPNsense repository and its actual package, and links to working setup, compatibility, source and release references.
- [ ] AC-02: The page uses the existing VHCO logo, Inter typography and brand colours, supports light and dark themes and provides readable keyboard-accessible layouts at the specified viewports.
- [ ] AC-03: Explicit URL copying and theme selection work with visible feedback, and reading and reference links work with JavaScript or storage/clipboard access unavailable.
- [ ] AC-04: The public page and its assets return their expected HTTP responses while native repository paths retain catalogue authentication, package retrieval and missing-path HTTP 404 behaviour.
- [ ] AC-06: The public page contains repository information without private deployment inputs or credentials, uses its glossary terms consistently and links to maintained package version information and the installation guide's independent trusted-channel verification of signing fingerprints.
- [ ] AC-07: A page edit and page rollback deploy independently of package releases, version calculation, package publication failures and package recovery.

## Test Plan

| Criterion | Proof |
| --- | --- |
| AC-01 | Serve the production static directory in the packages Playwright fixture. Check the actual package identifier and repository URL, follow the setup anchor and verify each public reference's final route. A two-entry synthetic page checks that another authored repository can be listed. |
| AC-02 | Run the specified viewport/theme matrix in Chromium and Firefox. Check overflow, readable type, 44-pixel touch targets, focus and headings. Inspect representative screenshots. Exercise actual 200 percent browser zoom and record its method and resulting viewport. |
| AC-03 | Run the current prototype's keyboard switch, saved theme, storage denial, URL copy, clipboard failure after success and JavaScript-disabled cases against the production static files. Check the switch state and reduced-motion behaviour. |
| AC-04 | Serve the production directory through native Wrangler. Check the root and every prefixed asset's HTTP response and media type, plus native missing-asset HTTP 404. The routing fixture checks the exact root, the `/_site/*` prefix and the canonical-query redirect, with package and catalogue requests reaching a synthetic feed target. Replace and roll back the site while that target serves recorded fixture bytes, then compare responses with those bytes. At authorised bootstrap read back disabled workers.dev and preview access before route activation. At cutover verify the actual hostname's root with and without a query, an asset with a query, missing paths, root/assets smoke responses and native catalogue authentication plus exact package fetch. Inject failure in the owned cutover fixture and revert the site-specific routes and redirect, requiring the prior HTTP 404 root and authenticated package responses. Verify a later Lab infrastructure run preserves the pipeline-selected Worker content. Local Wrangler proof is recorded separately from live edge proof. |
| AC-06 | Check the explicit public asset list, both licence notices and the site verification job's Gitleaks payload scan. Review rendered text and network requests for deployment-specific addresses or credentials. Verify maintained documentation links and glossary terms. "Follow the installation guide to verify the signing key through an independent trusted channel before adding the repository" passes the signing-copy check. "Trust this downloaded key without verification" fails it. |
| AC-07 | Run actionlint and verify the selected official action's supplied inputs against its exact metadata. The site workflow installs the locked tool and uses the upstream action for native upload and deployment. Check that PR verification has read-only GitHub permissions and can finish without a Cloudflare credential, failed verification prevents deployment, a disabled publication flag skips the deployment job and enabled successful main verification permits it. Read the site's environment branch policy through GitHub and require only branch `main`, with tag refs excluded. Exercise an owned non-main rejection case without exposing the real credential. Check that the site group is `vhco-packages-site-production`, distinct from the package publication group, with one running and one pending job, pending replacement and no running-job cancellation. Confirm that the package workflow files retain their existing definitions and that a failing native-feed fixture cannot be hidden by page-only job skipping. Inject a synthetic secret into the public payload and require the site verification job to fail with deployment skipped. Exercise scanner error and clean-payload cases separately. Run the normal site workflow against an owned isolated deployment. Publish a changed page, then restore older page files in a new main commit while a synthetic package publisher is unavailable. Require the restored content to deploy through verification, its native deployment to be recorded and the package target's recorded hashes to be retained. Check the documented native rerun window and original-source behaviour separately. Review the workflow's mutations and require them to be confined to site deployment. |

## Tasks

Tasks follow owner acceptance.

## Open Questions

None. The owner selected native static hosting and the official action on 16 November 2026.

## Review Log

| Date | Review | Kind | Commit | Model | Isolation | Outcome |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-11-15 | R-1 | spec | `1012715422c73c326c0d3061e62dbc2c9e83c334` | claude-opus-5-5 | procedural | One blocking, four should-fix and two nits. Read-only checkout preservation verified. |
| 2026-11-15 | R-2 | spec | `23d22b463fb22cc41c8362557def8624ff05dbd7` | claude-opus-5-5 | procedural | One blocking and four should-fix. Read-only source and Git preservation verified. Shell execution was denied to this static reviewer. |
| 2026-11-15 | R-3 | spec | `340d9014f0b9671257bf6594270681967f82b6b7` | claude-opus-5-5 | procedural | Seven should-fix findings. Static source review, with read-only source and Git preservation verified. |
| 2026-11-16 | R-4 | spec | `e7056a8df471b467d140b965cbc08540373a6fe2` | claude-opus-5-5 | procedural | Five should-fix findings. Static review with matched read-only source/Git snapshots. Reviewer shell execution was denied. |
| 2026-11-16 | R-5 | spec | `30ef9f29d39e7771fffecf406db7b4c23228a7fc` | claude-opus-5-5 | procedural | Six should-fix findings and two nits. Independent pinned lint passed. Static source/Git snapshots matched; PHP/actionlint checks were unexecuted. |
| 2026-11-16 | R-6 | spec | `2589d822e1be608a5867232dba7a995cccf98bba` | claude-opus-5-5 | procedural | Four should-fix findings and one nit. Static read-only source/Git snapshots matched. Pinned lint/fresh and repository checks were not executed after host refusal. |
| 2026-11-16 | R-7 | spec | `daaadce631326105842f7165640d697dc9e8fe67` | claude-opus-5-5 | procedural | Five should-fix findings. First-party primary reviewer attested, with Haiku also listed separately in usage metadata. Independent lint passed, fresh reported baseline/covered drift, and the boundary denied the planned gate and repository tests. Read-only snapshots matched. |
| 2026-11-16 | R-8 | spec | `a19054e76b712b303c936efdf2d6558d3b40fe83` | claude-opus-5-5 | procedural | Five should-fix findings. First-party primary reviewer attested, with Haiku also listed separately in usage metadata. Independent lint passed, fresh reported the expected baseline change, and the planned gate and two shell requests were denied. Repository tests were unexecuted. Read-only snapshots matched. |

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

### R-4

TARGET: e7056a8df471b467d140b965cbc08540373a6fe2

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Design (Selecting predecessor history and recovery bytes) lines 237-248 and 257-270, Design (Homepage-only updates) lines 200-201 and 209, Design (Completed catalogue withdrawals) line 227, Owner summary lines 45-47, Test Plan AC-05
EVIDENCE: The replay rule at line 240 covers only history input. When the latest submission matches the candidate digest, dispatch selects the closure named by that submission's `predecessor`, matching scripts/publish-feed.sh:104-118. The recovery baseline uses a different rule. Line 257 says the preparation entry point "resolves the currently closed baseline". Line 266 says the protected job "repeats the selection". Line 201 checks established recovery "against the selected prior archive's approved provenance", and line 227 requires a page-only dispatch to match "the selected live baseline". Take a closure POST that commits but loses its response (scripts/feed-close.sh:26-32). The journal then holds the replayed submission's own verified-closure (scripts/feed-journal-generation.jq:52-57), so the currently closed baseline is the replayed candidate and not its predecessor. That candidate is also what is live. If the protected job compares the recovery archive's page, site.json and catalogue with that baseline, a correct replay holds. Line 270 says a replay reconciles its own deployment, but it does not say whether the recovery-provenance and page-only baseline checks are skipped on replay or run against the submission's predecessor. Two implementers would choose differently. The AC-05 lost-closure case covers only a package publication's history input. It does not cover a page-only replay or the recovery-archive provenance check. This traces to this revision's repair of R-3 F-01. Shell execution was denied in this review session, so the pinned vh-adlc lint and the repository checks were not run. This is a static review.
PROPOSAL: Apply the replay predecessor rule to baseline archive selection, recovery page provenance and the page-only live-baseline proof as well, or state which of those checks a replay skips. Add an AC-05 case that replays a page-only update after its closure response was lost.

FINDING: F-02
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Publication and recovery) lines 167, 172, 175 and 183, Design (Homepage-only updates) lines 200 and 210, Acceptance Criteria AC-05, Test Plan AC-04, AC-05
EVIDENCE: Line 167 puts site verification inside `verify_unchanged_feed`, and line 175 requires "the appropriate retained site's successful verification" on every closure path. Line 183 lets an empty-catalogue bootstrap recovery carry the generic page. For a bootstrap generation the prior deployment is empty, so `verify_unchanged_feed` requires `canonical_deployment` to be null and the recovery bundle to have no release.json (scripts/publish-feed.sh:213-219). It then expects HTTP 404 for every catalogue file, because nothing is served (scripts/feed-recovery.sh:9-12). Rejection closure (scripts/publish-feed.sh:232-238) and failed-candidate closure (scripts/publish-feed.sh:272-282) both call that function while no deployment is live. A site check against a page-bearing bootstrap recovery's site.json then requires `/` to return the page with HTTP 200, which cannot happen. So under a literal reading a correctly rejected or terminally failed bootstrap candidate can never close. Another implementer would skip the site check or expect only HTTP 404s when the prior deployment is empty. The AC-04 row tests only "a wrong previously served site" on these closures. No AC-04 or AC-05 case closes a bootstrap candidate with a page-bearing recovery.
PROPOSAL: State which site expectation `verify_unchanged_feed` applies when no prior deployment exists, for example root and unknown paths HTTP 404 with no page-byte check. Add rejection and failed-candidate closure cases for a page-bearing bootstrap recovery.

FINDING: F-03
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Completed catalogue withdrawals) lines 227-233, Design (Publication and recovery) lines 173-174, Owner summary line 48, Test Plan AC-05
EVIDENCE: Line 231 says only "the current `retirement == {}` guard" (scripts/publish-feed.sh:353) is adjusted for a carried-forward page-only withdrawal. The next block still runs for any non-empty retirement. It calls validate_retirement and requires `FEED_RETIREMENT_AUTHORIZED == true` (scripts/publish-feed.sh:361-365), which feed.yml:200 maps from `authorize_retirement`. Reconciliation enters `verify_retirement` whenever `outcome == success && retirement != '{}'` (scripts/publish-feed.sh:289-292). On first entry that function appends a new trust-finalization-pending row and exits (scripts/feed-retirement.sh:30-38). Line 230 says the page-only path "skips new trust-finalisation work". It does not say whether a carried-forward dispatch must set `authorize_retirement` true, must leave it false, or ignores it. That choice decides whether the owner's retirement approval is reused for page edits. Line 229's "completed retirement's journal evidence" is also unnamed. The retirement rows sit in an earlier generation, because each submission resets `.retirement` (scripts/feed-journal-generation.jq:11). Candidate evidence would be the trust-finalization-pending `scope` (feed-journal-generation.jq:47-51) and the verified-closure `withdrawn` for that attempt (scripts/feed-close.sh:25). The existing fixture's retirement release carries `retirement` (tests/package/feed-publisher-http.mjs:511-515). So a page-only update on that tag reaches all three branches. This traces to this revision's repair of R-3 F-03.
PROPOSAL: State the required `authorize_retirement` value for a carried-forward page-only dispatch, and name the journal rows and fields that prove the plan already completed. Cover both the submission branch and the reconciliation branch. Add AC-05 assertions for the authorisation value and for the absence of a new trust-finalization-pending row.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Test Plan AC-06, Acceptance Criteria AC-06
EVIDENCE: The row gives one must-fail value per class: `192.168.231.17`, `100.101.102.103`, `"ghp_" + "A".repeat(36)`, one `<opnsense>` fragment and a PKCS#8 `-----BEGIN PRIVATE KEY-----` block. A detector that matches only those literals or narrow forms passes the row. Examples are a `192.168.` prefix, a `ghp_` prefix or the exact PKCS#8 header. Such a detector misses `10.0.0.0/8` and `172.16.0.0/12` addresses and the repository's own credential shapes. The plugin stores SSH private keys and encryption passwords (docs/specs/native-encrypted-git-backup.md:172, docs/security/cve-2025-15367.md:71), whose usual form is `-----BEGIN OPENSSH PRIVATE KEY-----`. The publisher's live secret is a Cloudflare Pages API token (.github/workflows/feed.yml:206), not a GitHub `ghp_` token. The row has no near-miss must-pass values, such as `172.32.0.1` or `100.128.0.1`, that would separate a range check from a broad numeric match. The row changed in this revision in response to R-3 F-05, so it has not passed review and this is not a widening nit.
PROPOSAL: Give at least two must-fail values per class, including `10.x` and `172.16-31.x` addresses, an OpenSSH private-key block and a Cloudflare-token-shaped value. Add near-miss must-pass values at the range boundaries.

FINDING: F-05
KIND: judgement
SEVERITY: should-fix
WHERE: Owner summary lines 42-54, Scope line 94, Design (Selecting predecessor history and recovery bytes) lines 238 and 266-269, Test Plan AC-05
EVIDENCE: Scope line 94 presents page-only updates as the normal way to add repository entries and correct links. Every page-only publication adds at least one production Pages deployment (scripts/publish-feed.sh:407), and recoveries and retries add more (scripts/feed-recovery.sh:36-44). It also adds at least two journal rows, submission-started and verified-closure. Line 267 keeps the provider bound of 25 production deployments, and line 266 now applies it before every new submission, not only during reconciliation (scripts/publish-feed.sh:164-174). Line 238 relies on reading the complete journal, but the existing journal bound is under 100 rows with no next page (scripts/publish-feed.sh:61-66). The document never states that bound. Once either bound is reached, every later publication holds, including package releases, and the document defines no way back below the bound. The owner accepted holding on incomplete results in R-3. The Owner summary does not say that each page edit uses up a fixed lifetime publication budget shared with package releases. It also does not mention the journal bound.
PROPOSAL: State both bounds and their effect on how many page-only and package publications remain in the Owner summary and the Design. Raise for the owner whether reaching a bound needs a defined remedy within this feature or stays a permanent hold.

### R-5

TARGET: 30ef9f29d39e7771fffecf406db7b4c23228a7fc

FINDING: F-01
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Publication and recovery) lines 185-188 and 195-196, Design (Selecting predecessor history and recovery bytes) lines 286-287 and 298-306, Owner summary line 46, Test Plan AC-04, AC-05
EVIDENCE: The design covers a bootstrap predecessor only through `canonical_deployment == null` (line 185). It does not cover a predecessor that closed on an empty-catalogue bootstrap recovery, although that state is reachable. A bootstrap candidate fails native verification and the authorised recovery deploys (scripts/publish-feed.sh:293-302). reconcile_recovery then passes verify_recovery without a release.json, which checks only root catalogue 404s and advertised bytes (scripts/feed-recovery.sh:5-18,91-97). After that, publish-feed.sh:305-324 closes with `deployment` set to the recovery ID. Line 196 lets that served recovery carry the homepage. For the next generation, `prior` is non-empty, so verify_unchanged_feed requires a recovery release.json and runs verify-feed-generation.sh against it (scripts/publish-feed.sh:215-216, scripts/feed-recovery.sh:5-7). Line 302 also requires the new recovery's release.json to describe "the prior authenticated catalogue's version, package and catalogue hashes". No such catalogue exists, so a correct rejection or failed-candidate closure after this predecessor cannot pass, and the recovery archive has no defined metadata. Line 287 selects the pinned recovery archive, but lines 304-305 assume it holds a native catalogue. No AC-04 or AC-05 case uses this predecessor. This gap remains after this revision's empty-predecessor repair of R-4 F-02. Tool record for this pass: `vh-adlc lint` with the relative path and plugin pin passed. `vh-adlc fresh` reported R-4 stale with `baseline-changed`. `vh-adlc gate planned` and one combined command were denied by the host permission mode. Repository PHP and actionlint checks were not run.
PROPOSAL: Define the expected site, catalogue and release.json shape when the predecessor closed on an empty-catalogue bootstrap recovery: served page with HTTP 200 and catalogue aliases HTTP 404, with no release.json. State how verify_unchanged_feed and recovery construction choose that branch other than through `prior` being empty. Add rejection, failed-candidate and recovery cases for this predecessor to AC-04 and AC-05.

FINDING: F-02
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Homepage-only updates) lines 208 and 227, Design (Completed catalogue withdrawals) lines 241-255, Design (Selecting predecessor history and recovery bytes) lines 263-265, Owner summary line 47, Test Plan AC-05
EVIDENCE: `page_only` is a per-dispatch input (line 208). The submission-started payload (scripts/publish-feed.sh:398-404) and the approval asset (scripts/publish-feed.sh:81-86) do not record it. Line 265 validates a replay only against the "candidate/recovery pair and approved source identities". The design does not say whether a replay must repeat the original mode or how that mode is recovered. It also does not say whether the carried-forward recognition at lines 252-254 depends on the `page_only` flag or only on the journal completion evidence at lines 246-250. Suppose a page-only submission on a retirement release is reconciled by a dispatch with `page_only=false`. If recognition depends on the flag, reconciliation enters `outcome == success && retirement != '{}'` (scripts/publish-feed.sh:289-291). verify_retirement then appends a new trust-finalization-pending row for that attempt (scripts/feed-retirement.sh:30-38). The reducer accepts the row (scripts/feed-journal-generation.jq:47-51), and the attempt now needs fresh signed operator evidence. That is the row line 253 forbids, and a later `page_only=true` replay meets a state the design never defines. The reverse case, `page_only=true` on replay of a package submission, is also undefined. AC-05 tests the `authorize_retirement` value but not a mode mismatch on replay. This traces to this revision's repair of R-4 F-03.
PROPOSAL: State whether page-only mode and carried-forward recognition come from the dispatch flag, from the journal evidence and native identity, or from a field recorded in the submission. Require replay and reconciliation to hold when the dispatch mode differs from the original submission's mode. Add an AC-05 replay case with a mismatched `page_only` value on a retirement release.

FINDING: F-03
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Public content checks) lines 150-154, Design (Homepage-only updates) lines 209-212 and 214, Owner summary lines 51-52, Test Plan AC-05, AC-06
EVIDENCE: Line 151 relies on "the repository's existing pinned Gitleaks job" to scan source history. That scan runs inside the php.yml `php` job on pull requests and pushes to main (.github/workflows/php.yml:1-6,28-39). The package source is bound to a successful php.yml run: the tag job checks the version run's `head_sha`, `conclusion == "success"` and `path == ".github/workflows/php.yml"` (.github/workflows/feed.yml:85-90). The protected job only requires `page_source` to be a main ancestor that matches site.json (lines 210-212, 214). Neither the job nor the AC-05 and AC-06 rows checks that the page commit's php.yml run, and therefore its Gitleaks scan, succeeded. A page commit that reached main with a failed secret scan could be published. The manual payload review "records that review against the approved bundle digest" (line 154), but no step checks for that record. One implementer would add a CI-success check for the page commit and another would rely on main ancestry. This traces to this revision's repair of R-4 F-04, which replaced pattern fixtures with the Gitleaks path.
PROPOSAL: State whether the protected job requires a successful php.yml run, including its Gitleaks step, for `page_source` and `recovery_page_source`, and how it identifies that run. Also state where the manual payload review record is kept and whether the dispatch checks it. Add an AC-05 or AC-06 hold case for a main-reachable page commit without a passing scan.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Frontmatter covers, Design (Completed catalogue withdrawals) lines 246-254, Design (Selecting predecessor history and recovery bytes) lines 261-263 and 285-288, Design (Assembly and browser verification) line 140
EVIDENCE: The design changes behaviour that lives in files `covers` does not list. verify_retirement and verify_withdrawal, the branch line 254 must distinguish and the HTTP 404 checks line 244 carries forward, are defined in scripts/feed-retirement.sh:15-55. The journal reducer that dispatch must share with publish-feed.sh, and whose reset of `.retirement` line 249 works around, is scripts/feed-journal-generation.jq:6-11,47-57. Line 140 relies on "the existing retention commands", which are scripts/retain-feed-bundles.sh and scripts/feed-bundles.sh. A change to any of these can affect the feature, but none appears in covers (lines 6-25). `vh-adlc fresh` and the `feature_tree_clean` condition therefore cannot see such a change.
PROPOSAL: Add scripts/feed-retirement.sh and scripts/feed-journal-generation.jq to covers, plus the retention scripts if the design relies on their behaviour. Otherwise, state that these files stay unchanged and where the new logic lives instead.

FINDING: F-05
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Homepage-only updates) lines 234-236, Design (Complete inventory reads) lines 314-336, Owner summary lines 49-50, Test Plan AC-05
EVIDENCE: Every page-only publication adds at least `feed-<candidate>.tar`, `feed-<recovery>.tar` and `approval-<digest>.json` to the same release tag (scripts/retain-feed-bundles.sh:15-24, scripts/publish-feed.sh:88,390, design line 234). All reads use `gh release download --pattern` against that one release (scripts/feed-bundles.sh:21, scripts/publish-feed.sh:91,135). This revision defines complete pagination and consistency for the journal and Pages inventories only. It does not cover the growing asset list of a reused tag, and it gives no bound or hold on asset count. GitHub limits the number of assets per release. This review could not confirm the current documented figure, but such a limit would recreate the lifetime publication budget that R-4 F-05 raised, now for page edits on one tag. The Owner summary says pagination removes the read limits, without this residual.
PROPOSAL: State how asset listing on a reused tag stays complete as it grows, and what happens at GitHub's per-release asset limit (hold, a new tag, or pruning). Cite the GitHub source and reflect the result in the Owner summary.

FINDING: F-06
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Content and visual structure) lines 110-111, Design (Assembly and browser verification) line 138, Test Plan AC-06, supporting prototype README
EVIDENCE: The repository is licensed BSD-2-Clause (AGENTS.md project scope, LICENSE). The design copies the company logo into public source and bundles (line 110, docs/prototypes/vhco-packages/README.md "Asset sources") and requires "required licences" in assembly (line 138). It names a licence only for Inter (Sources, INTER-LICENSE.txt). It does not say whether the logo is covered by the repository's BSD-2-Clause licence or kept under separate terms with a notice. A permissive licence over a company mark may not be what the owner intends. One implementer would add a logo notice to the required-licence list and another would add nothing. This is a licensing choice for the owner.
PROPOSAL: Raise an Open Question on the logo's licence terms in this repository and its published bundles. Then name the required notice, if any, in the assembly's required-licence list and the AC-06 file-list check.

FINDING: F-07
KIND: judgement
SEVERITY: nit
WHERE: Acceptance Criteria AC-05, Test Plan AC-05
EVIDENCE: The Owner summary (lines 49-50) and Design (lines 314-336) make complete journal and Pages pagination, and the carried-forward withdrawal (lines 239-256), outcomes of this feature. AC-05's text only mentions retaining and verifying page assets under the existing single-writer and interrupted-publication contract. The pagination and withdrawal end states appear only in the AC-05 proof row.
PROPOSAL: Extend AC-05's text, or add a criterion, for publication proceeding past one inventory page and for carried-forward withdrawals that need no new retirement authorisation.

FINDING: F-08
KIND: factual
SEVERITY: nit
WHERE: Design (Complete inventory reads) lines 318 and 332, Design (Selecting predecessor history and recovery bytes) line 284
EVIDENCE: Line 332 says the reader takes two complete views "Under the existing single-writer lock". The same reader also serves read-only preparation, which runs with the operator's GitHub CLI login outside the protected workflow (lines 284 and 318). The workflow concurrency group applies only to feed.yml jobs (.github/workflows/feed.yml:44-46).
PROPOSAL: Say that the two-view check runs under the lock only in the protected job, and that preparation's result is advisory until the protected job repeats it.

### R-6

TARGET: 2589d822e1be608a5867232dba7a995cccf98bba

FINDING: F-01
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Public content checks) lines 166 and 169-174, Design (Homepage-only updates) lines 241-242, 247 and 250, Owner summary lines 61-63, Test Plan AC-06
EVIDENCE: The CI and Gitleaks proof is tied to the page commit, but nothing in the protected job ties the archived page bytes to that commit. The byte-for-byte copy and SHA-256 check happen at assembly (line 166). Assembly is part of read-only preparation, which runs outside the protected job with the operator's CLI login (lines 320, 328, 370). The protected job compares only the commit SHA with site.json (line 241). Protected preflight checks "every listed file's bytes and media type" (line 250), but against the hashes that site.json lists, and preparation wrote site.json too. So an archive whose site.json names a valid main commit with a successful php.yml run, and lists hashes for bytes that are not at that commit, passes every protected check except the human review. Package bytes have an independent binding: feed-preflight.sh:15,26-36 checks release.json against the version run and tag through feed-release-identity.sh:16-28. The protected checkout already has fetch-depth 0 at feed.yml:179-184, so it could compare against `git show <page_source>:web/packages/<file>`. AC-06's "altered staged bytes must fail source-provenance comparison" does not say which job runs that comparison. An implementation that compares only at assembly passes it. Tool record for this pass: Bash ran the first few read commands. Then `vh-adlc lint docs/specs/vhco-packages-landing-page.md --repo . --plugin-pin 1ccf8f314575ece1f3fcc8e48c4fd804a1ca88ff` and `vh-adlc fresh` were refused by the host permission mode ("don't ask mode"), as were two later read-only shell commands. The rest of the review read files with the Read and Grep tools. Pinned lint, fresh, PHP checks and actionlint were not executed in this pass.
PROPOSAL: Require the protected job, before effects, to compare every site.json-listed file in each archive with the same path at the verified `page_source`, or `recovery_page_source` for a new bootstrap recovery, from its own checkout. Name the protected job in the AC-06 altered-bytes case.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Design (Public content checks) lines 176-179, Owner summary lines 62-63, Test Plan AC-06
EVIDENCE: Line 177 calls the approval "the existing required `signed-feed-production` environment approval", and line 178 says "GitHub enforces that approval before the job executes". The repository shows only that the publish, tag and verify-release jobs name that environment (.github/workflows/feed.yml:57,140,169). An environment gates a job on approval only if it has required reviewers configured. No workflow step, script or repository document records or checks that setting. The only other mentions are long lines in docs/specs/native-encrypted-git-backup.md:2369,2441. The AC-06 row says "The protected environment must require approval for the exact run inputs" but gives no procedure, such as reading the environment's protection rules through the GitHub API. Without required reviewers, the job runs with no payload review at all, and every fixture in the row still passes. This is the manual review that the R-5 F-03 repair relies on.
PROPOSAL: Give a written check of the environment's required-reviewer protection rule, run before publication approval and kept as sanitized evidence, or have the protected job check it. Say whether self-review is acceptable for a sole owner.

FINDING: F-03
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Publication and recovery) lines 213-218 and 227, Design (Homepage-only updates) lines 263 and 265, Design (Completed catalogue withdrawals) line 278, Design (Selecting predecessor history and recovery bytes) lines 340 and 345, Owner summary lines 54-56, Test Plan AC-05
EVIDENCE: The R-5 F-01 repair defines verification and recovery construction for a predecessor that closed on a deployed empty-catalogue bootstrap recovery. It does not define a page-only update on top of that predecessor. Line 278 requires a new page-only submission to prove that "the native catalogue, package bytes and release identity match the selected predecessor archive and its live deployment". That predecessor serves no catalogue and has no release.json (line 214). A page-only candidate must still carry a candidate release.json with catalogue and package (line 265, scripts/feed-preflight.sh:25-36). Line 345 says what a page-only approval pins only "When a recovered predecessor serves a catalogue". The closure still records the failed bootstrap candidate's version and release, because scripts/publish-feed.sh:254,321-323 passes them from the candidate manifest to feed-close.sh. So an implementer who compares closure release identity would let a page-only dispatch publish the catalogue that failed native verification. An implementer who compares catalogue bytes would hold every page-only update until a package publication succeeds. The Owner summary presents page-only updates as the way to correct the page (line 108) and does not state either outcome. AC-05's page-only cases repeat only "after both candidate and recovery predecessor closures".
PROPOSAL: State that a page-only dispatch holds when the selected predecessor is catalogue-absent, or define what it pins in that case. Add that case to AC-05 and mention the result in the Owner summary.

FINDING: F-04
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Retained release assets and capacity) lines 384-391, Design (Selecting predecessor history and recovery bytes) line 320, Design (Complete inventory reads) line 370, Owner summary line 60, Test Plan AC-05
EVIDENCE: Line 386 splits the quota check. Archive retention counts only the candidate and recovery archives, and only the protected publisher counts the approval and history assets. Archive retention runs during preparation, through scripts/retain-feed-bundles.sh:15-24 with the operator's asset-writer token, outside the feed.yml concurrency lock (.github/workflows/feed.yml:44-46). Its result is advisory (line 370). The approval name is computable at preparation, because the approval inputs at scripts/publish-feed.sh:81-86 are all known then. Even so, preparation can fill the release to the quota with archives that the protected job can never submit, since it then holds for the missing approval. Lines 271 and 390 keep every retained asset, so archives from such holds and from abandoned or concurrent preparations use quota permanently. The design and the Owner summary do not state this cost. AC-05's capacity case checks only the protected hold "before submission".
PROPOSAL: Have archive retention reserve the phase's approval and new history names in its capacity count, or state that preparation-retained archives and their holds use quota permanently. Add an AC-05 case for retention at the quota boundary.

FINDING: F-05
KIND: judgement
SEVERITY: nit
WHERE: Design (Publication and recovery) lines 230-232, Test Plan AC-05
EVIDENCE: Line 231 says initial-adoption preparation "records the HTTP 404 observation in the approved dispatch evidence", but neither the Design nor the site.json, approval or submission fields at lines 248 and 258 name that record. Line 230 already derives the expected root HTTP 404 from the selected baseline having no index, so the record does not affect any later check. AC-05's "verifies the initial root HTTP 404 observation" leaves open where that observation is read.
PROPOSAL: Name where the observation is stored, or drop the recording step and keep the derived expectation with the recovery-time HTTP 404 check.

### R-7

TARGET: daaadce631326105842f7165640d697dc9e8fe67

FINDING: F-01
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Pipeline and reuse) lines 194-196, Design (Browser and workflow checks) lines 225 and 227, frontmatter covers (.github/workflows/php.yml, .github/workflows/native-browser.yml), Owner summary lines 29-31, Acceptance Criteria AC-07, Test Plan AC-07
EVIDENCE: Line 194 says page-only changes use only the site checks, so php.yml and native-browser.yml would get path filters. Both run today on every pull request and every push to main (.github/workflows/php.yml:3-6, .github/workflows/native-browser.yml:3-7). Two existing contracts depend on php.yml running for every main commit. First, the feed `tag` job requires a successful `push` run of `.github/workflows/php.yml` whose `head_sha` equals the reviewed source on main (.github/workflows/feed.yml:82-90). A page-only commit at the tip of main would have no such run, so the package cannot be tagged at that commit. That makes package release depend on page edits, which goes against AC-07 and Owner summary line 31. Second, GitHub documents that "If a workflow is skipped due to branch filtering, path filtering, or a commit message, then checks associated with that workflow will remain in a 'Pending' state. A pull request that requires those checks to be successful will be blocked from merging." (Workflow syntax for GitHub Actions, path filters). Line 225 also depends on "the existing secret scan", and that scan runs inside the php.yml `php` job through php-ci-action (.github/workflows/php.yml:28-41; docs/compatibility.md:36-42). The document does not say whether the site workflow runs its own Gitleaks scan once php.yml is skipped. The AC-07 trigger-selection check counts which workflows run. It does not check release tagging after a page-only main commit, required-check behaviour or secret-scan coverage, so a filter that breaks any of these passes. covers does not list .github/workflows/feed.yml, whose tag guard is affected. Tool record for this pass: `vh-adlc lint docs/specs/vhco-packages-landing-page.md --repo <repo> --plugin-pin 1ccf8f3...` passed. `vh-adlc fresh` reported R-6 stale with `baseline-changed` and `covered-drift` on five prototype files. The host permission mode refused `vh-adlc gate planned`, one combined status command and every repository check (PHP lint, phpcs, phpstan, phpunit, actionlint, Playwright). Everything else came from Read, Grep and public documentation fetches.
PROPOSAL: Say how page-only main commits keep a php.yml success record for release tagging, or how the tag guard changes. Say how required checks behave under path filters and where Gitleaks runs for page-only changes. Add AC-07 cases that tag a package after a page-only main commit and confirm the secret scan runs on a page-only change.

FINDING: F-02
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Pipeline and reuse) lines 180-183, Owner summary line 44, Scope line 111, Test Plan AC-07
EVIDENCE: The design keeps the Cloudflare credential in "the site's GitHub environment" (line 182), and a main-branch push deploys (line 180). It does not say which branches or refs may use that environment. GitHub documents three deployment-branch settings: "No restriction", "Protected branches only" and "Selected branches and tags". Environment secrets "are only available to workflow jobs that reference the environment". With no restriction, a job from any pushed branch with an edited workflow can reference the environment and get the Worker Editor credential. Docs PR #46 at 3429803 requires making the deployment job "eligible only on the selected trusted branch or an explicitly authorised dispatch". The AC-07 row checks only that PR verification has read-only permissions and can finish without a credential. It does not check the environment's branch policy, so an unrestricted environment passes. Lab provisions the environment inputs (line 111), and the document does not give Lab a branch policy to configure.
PROPOSAL: Require the site environment to allow only `main` (and any explicitly authorised dispatch), and name who configures it. Add an AC-07 check that reads the environment's deployment-branch policy, plus a case where a non-main branch cannot reach the credential.

FINDING: F-03
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Pipeline and reuse) lines 192-193, Design (Pipeline and reuse) line 201, Owner summary line 43, Test Plan AC-07
EVIDENCE: Line 192 uses one site concurrency group that cancels superseded work, and line 193 recovers a failed run with "a normal rerun". A rerun of an older workflow run builds that run's commit and joins the same group. With cancel-in-progress it can cancel a newer in-progress deployment, then run `versions deploy` at 100 percent for the older commit's tag (lines 186-187). The live page then goes back to stale content, and nothing in the workflow notices. The design has no guard that the deploying commit is still the head of main, and AC-07 has no ordering or stale-rerun case. The repository instructions also say "Protected publication keeps its separate non-cancelling concurrency group" (AGENTS.md, Verification), and the existing publisher follows that rule (.github/workflows/feed.yml:44-46). The document does not say whether an environment-gated production site deployment counts as protected publication under that rule. That is an owner decision, and the document gives no open question for it.
PROPOSAL: Raise an Open Question on whether the site deploy job cancels or queues. Define a guard that stops a rerun of a superseded commit from replacing a newer deployment, for example a check that the commit is still main's head before `versions deploy`. Add an AC-07 case for a rerun of an older run after a newer one has deployed.

FINDING: F-04
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Independent hosting) line 149, Design (Pipeline and reuse) lines 183-187, Owner summary lines 44-45, Test Plan AC-04, AC-06
EVIDENCE: Line 149 says the generic wrangler.toml "disables workers.dev and preview URLs". The pipeline only runs `versions upload` and `versions deploy` (lines 185-187). Cloudflare's Wrangler command reference says `wrangler triggers deploy` applies "changes to triggers (Routes or domains and Cron Triggers) when using `wrangler versions upload`". It does not say that `versions upload` applies `workers_dev`. The configuration reference says of `preview_urls`: "If omitted, Wrangler does not change an existing setting". It also says `workers_dev` "Defaults to `true` when the configuration has no `route` or `routes`". Lab creates the Worker (line 184) by a method the document does not name. So whether workers.dev and version preview URLs end up disabled depends on Lab's creation step, not on the configuration file the design points to. The Workers permissions page lists no permission for these settings, so the Editor credential (line 183) may not be able to change them either. No AC-04 or AC-06 proof checks that the live Worker has no workers.dev route or preview URL, so an implementation that leaves both enabled passes.
PROPOSAL: Say which step disables workers.dev and preview URLs on the live Worker (Lab provisioning or a named command with its permission). Add a cutover check that the Worker's workers.dev and preview URLs are disabled.

FINDING: F-05
KIND: judgement
SEVERITY: should-fix
WHERE: Owner summary lines 40-45, Scope line 111, Design (Independent hosting) lines 151-153 and 170-172, Design (Pipeline and reuse) line 184, Test Plan AC-04
EVIDENCE: Scope line 111 says Lab supplies the infrastructure "ahead of the first live deployment", and line 151 lists the two routes among Lab's provisioning. Line 172 instead says "Initial route activation follows a successful site upload". The two orderings disagree on whether routes exist before the first pipeline upload. The Workers permissions page says per-Worker roles "cannot cover Workers that do not exist yet" and that Editor "Cannot create or delete Workers". So Lab must create the Worker with some first version before the site credential can exist. The document does not say what that first version contains, or whether later Lab infrastructure runs manage the Worker's content. If they do, they can replace the pipeline's deployed version. Line 172 also requires native package verification right after cutover, but it does not say what happens when that verification, or the edge route and redirect checks at line 170, fail. It does not say who removes the routes and redirect, or what state counts as restored (today the feed returns 404 at `/`, line 101). This crosses the Cloudflare and GitHub boundary with two owners of one Worker, and the partial-failure and rollback path is undefined. AC-04 gives the cutover checks but no failure outcome.
PROPOSAL: Fix one cutover order (Worker creation, first upload, routes and redirect) and say whether Lab manages Worker versions after creation. Define the cutover failure path: who removes the routes and redirect, and the expected restored responses. Add that rollback to the AC-04 cutover procedure.

### R-8

TARGET: a19054e76b712b303c936efdf2d6558d3b40fe83

FINDING: F-01
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Pipeline and reuse) lines 233-238, Owner summary line 50, Test Plan AC-07
EVIDENCE: Line 235 skips the native-feed and appliance jobs at job level for page-only changes. Line 236 relies on GitHub reporting skipped jobs as "Success" (Control jobs with conditions: "A job that is skipped will report its status as "Success". It will not prevent a pull request from merging, even if it is a required check."). The native-feed job is the `feed-fixture` job inside php.yml (.github/workflows/php.yml:54-58). The feed `tag` guard accepts any php.yml push run at the source with `.conclusion == "success"` (.github/workflows/feed.yml:85-90). Today that conclusion means the signed-feed fixture passed at that exact source. Under this design, suppose a plugin commit's feed-fixture fails and a page-only commit then lands on top of it. The page-only commit's php.yml run concludes success with the fixture skipped, and the tag guard accepts it. A package can then be tagged at a source whose native-feed verification last failed and never passed. The AC-07 row makes this outcome a pass condition: a page-only main commit "must ... supply a successful source run accepted by native package-tag preflight". The pinned delivery convention says "Report a skipped run as skipped, never as a pass" (conventions/delivery.md:95). This design traces to this revision's repair of R-7 F-01. Tool record for this pass: `vh-adlc lint docs/specs/vhco-packages-landing-page.md --repo <clone> --plugin-pin 1ccf8f3...` passed with no findings. `vh-adlc fresh` reported R-7 stale with `baseline-changed`, no implementation review and a clean feature tree. The host permission mode refused `vh-adlc gate planned`, a final `git status` and a combined command. I did not attempt the repository checks (PHP lint, phpcs, phpstan, phpunit, actionlint, Playwright) after those refusals. Everything else came from Read, Grep and public documentation fetches. No live provider access was used.
PROPOSAL: State how a page-only commit's php.yml success keeps meaning that the native-feed fixture passed for the package source, for example by having the tag guard also require a non-skipped successful fixture for the last commit that changed package inputs. Add an AC-07 case where a failing plugin commit followed by a page-only commit must be rejected by tag preflight.

FINDING: F-02
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Pipeline and reuse) lines 235-238, Design (Browser and workflow checks) line 269, Test Plan AC-07
EVIDENCE: The design scopes jobs "at job level for page-only changes" but does not say how a job learns that a change is page-only. GitHub's job conditions page says `jobs.<job_id>.if` takes expressions only and that shell-style conditions must go in steps, and it offers no job-level path condition. So the implementation needs a classifier job or step whose output gates the jobs. The document names no classifier, no path set that counts as page-only, and no diff base. For a push to main that diff could cover only the last commit, `github.event.before..github.sha`, or the merge base. It also says nothing about a zero `before` SHA, a force push or a rerun. Take a push carrying a plugin commit followed by a page-only commit. A last-commit classifier skips the appliance and native-feed jobs for the plugin change, but a push-range classifier does not. The AC-07 row lists page-only, plugin-only, mixed and shared-lockfile changes but no multi-commit push and no classifier failure. Nor does the document say whether an unknown classification runs everything. The document also names no required check contexts. `feed-fixture` is a reusable-workflow caller whose inner jobs are `fixture` and `native-verifier` (.github/workflows/feed-fixture.yml:10,20). So the claim that required job contexts stay available (line 235) cannot be checked against named contexts.
PROPOSAL: Name the classifier, the exact page-only path set, its diff base for pull requests and pushes, and a fail-closed rule that runs every job when classification is uncertain. Name the required check contexts. Add AC-07 cases for a multi-commit push whose last commit is page-only and for a classifier error.

FINDING: F-03
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Pipeline and reuse) line 212, Design (Browser and workflow checks) lines 267-268, Test Plan AC-06, Test Plan AC-07
EVIDENCE: Line 267 says "Ordinary page CI checks the explicit public files, required notices, existing secret scan and browser suite". Line 212 says a main push "deploys after that same verification succeeds". The existing secret scan is Gitleaks inside the php.yml `php` job through php-ci-action (.github/workflows/php.yml:28-38; docs/compatibility.md:38,42). Line 233 keeps it there. The site workflow is a separate file (.github/workflows/packages-site.yml, line 208), and the document does not say how its deployment job depends on a check in another workflow. One implementer would add a Gitleaks step to packages-site.yml. Another would rely on php.yml running in parallel. In that case a secret committed in a page change deploys even when php.yml fails. AC-06 checks only that the "existing Gitleaks scan" runs. AC-07's "failed verification prevents deployment" does not say whether a failed secret scan is among the failures that must block deployment. This traces to this revision's answer to R-7 F-01 about where Gitleaks runs.
PROPOSAL: State whether the site workflow runs its own pinned secret scan before deployment or gates on the php.yml result for the same SHA. Add an AC-07 case where a synthetic secret in a page-only change must prevent the deployment job.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Owner summary line 48, Design (Pipeline and reuse) lines 226-231, Test Plan AC-07
EVIDENCE: Line 48 says production site deployments "use the repository's non-cancelling publication queue". Line 226 instead says "one production deployment concurrency group for this site". The repository's existing non-cancelling publication group is `native-package-pages-publisher` in feed.yml (.github/workflows/feed.yml:44-46), and AGENTS.md says protected publication keeps "its separate non-cancelling concurrency group". If the site shared that group, page deployments would wait behind package publication, which contradicts AC-07. GitHub's concurrency documentation also says that with `cancel-in-progress: false`, "any existing pending job or workflow in the same concurrency group will be canceled" when a new one is queued. The default `queue: single` allows at most one pending run, and only `queue: max` holds up to 100. So `cancel-in-progress: false` alone is not a queue. In a shared group, a page run could cancel a pending feed publication. In a site-only group, a rerun of an older run cancels a newer pending page deployment. Owner scope accepts missed homepage deployments, but the document does not state either behaviour. AC-07's "Check the non-cancelling deployment group" checks neither that the group is separate nor what happens to pending runs. This traces to this revision's repair of R-7 F-03.
PROPOSAL: Name a site-only group distinct from `native-package-pages-publisher`, state the `queue` setting and that a newer pending run replaces an older pending one, and make the Owner summary match. Extend the AC-07 check to the group name and the pending-run replacement behaviour.

FINDING: F-05
KIND: judgement
SEVERITY: should-fix
WHERE: Owner summary lines 45 and 49, Scope line 118, Design (Pipeline and reuse) lines 228-231 and 243, Test Plan AC-07
EVIDENCE: The design recovers a page by "a normal rerun or source redeploy" (line 228) or by "redeploying a known source commit" (line 243). The only defined way to deploy a chosen older commit is a rerun, which uses the original run's commit (line 229). GitHub's re-run documentation says a run can be re-run "up to 30 days after its initial run", at most 50 times, with "the privileges of the actor who initially triggered the workflow". The design defines triggers only for pull requests and main pushes (line 212) and no `workflow_dispatch` with a source input. Docs PR #46 at 105e87c allows "an explicitly authorised dispatch", while line 215 lets only branch `main` use the environment. So after 30 days, "redeploying a known source commit" has no defined mechanism. One implementer would add a dispatch with a commit input, and that checks out arbitrary history under the main-only environment. Another would rely only on revert commits or Cloudflare rollback. The document also does not say who performs a Cloudflare rollback or with which credential. AC-07 tests only a rerun of a recent run.
PROPOSAL: State the recovery paths and their limits: rerun within 30 days, Cloudflare rollback naming the actor and credential, and a revert commit or a defined dispatch for older content. If a dispatch is kept, state whether it may select a source other than main's head. Add the selected path to AC-07.

## Sources

- [GitHub artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations) documents digest-bound provenance and workflow/source identity.
- [Native attestation generation](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations) documents the producing job, native action and required OIDC/attestation permissions.
- [GitHub CLI verification](https://cli.github.com/manual/gh_attestation_verify) documents verification of the downloaded artifact and signer restrictions.
- [Official Wrangler action metadata](https://github.com/cloudflare/wrangler-action/blob/953926a2e2182532811c01a25e53647d93bf07c0/action.yml) declares the Bun package manager and multiline native command inputs.
- [Worker CI source](https://github.com/vhco-pro/worker-ci-action/blob/5ef3cf6b375c6247a28fffb7c19b8d6c5aae97c3/scripts/verify.ts) rejects static assets in its single-module profile.
- [Worker deploy source](https://github.com/vhco-pro/worker-deploy-action/blob/bcf11171c29a610971f45a867daba8c684c7d198/scripts/activate.ts) verifies exact tag and module release inputs.
- [Shared static-site standard](https://github.com/vhco-pro/docs/blob/2028365d39ff0bebf7698fff975ae04d0dac133e/conventions/cloudflare-static-sites.md) records the merged official-action default and visibility-based CI policy.
- [Native Worker commands](https://developers.cloudflare.com/workers/wrangler/commands/workers/) document upload and deployment through native version annotations.
- [Workers permissions](https://developers.cloudflare.com/workers/authorization/workers/) documents existing-Worker Editor access and separate route-write permissions.
- [GitHub concurrency](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency) documents separate group names, the default single-pending replacement and running-job cancellation.
- [GitHub reruns](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs) documents the 30-day window, 50-attempt limit and original actor/source identity.
- [Gitleaks upstream CLI and images](https://github.com/gitleaks/gitleaks) documents free native directory scans and the official container. Its [MIT licence](https://github.com/gitleaks/gitleaks/blob/v8.30.1/LICENSE) permits this use.
- [Worker subdomain settings API](https://developers.cloudflare.com/api/resources/workers/subresources/scripts/subresources/subdomain/) documents native workers.dev and preview-access readback and updates.
- [Cloudflare static assets](https://developers.cloudflare.com/workers/static-assets/) documents native static hosting and its deployed asset versions.
- [Cloudflare routes](https://developers.cloudflare.com/workers/configuration/routing/routes/) documents path matching, query-string behaviour and the proxied-host requirement.
- [Cloudflare Single Redirect settings](https://developers.cloudflare.com/rules/url-forwarding/single-redirects/settings/) documents static targets and query-string removal.
- [Cloudflare redirect rules](https://developers.cloudflare.com/rules/url-forwarding/) documents native redirects, their execution and availability across plans.
- [Wrangler configuration](https://developers.cloudflare.com/workers/wrangler/configuration/) documents the static-assets and route configuration used by the local dry run.
- [Cloudflare Direct Upload](https://developers.cloudflare.com/pages/how-to/use-direct-upload-with-continuous-integration/) documents publishing a static directory through native tooling.
- [VHCO homepage](https://vhco.pro/) and its [theme source](https://github.com/michielvha/vitepress/blob/main/app/.vitepress/theme/style.css) supply the observed styling.
- [Company mark](https://vhco.pro/landing/vhco-github.png) is the existing VH & Co logo.
- [Current installation guide](../installation.md) documents version calculation, off-host native package preparation, signing and client trust.
- [Prototype asset provenance](../prototypes/vhco-packages/README.md#asset-sources) records the logo and font sources and notices.
