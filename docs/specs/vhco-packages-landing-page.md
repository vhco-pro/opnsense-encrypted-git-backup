---
status: draft
status_description: "This revision simplifies documentation ownership and specifies native workflow checks. Review dispatch remains coordinated."
issue: null
goal: "Visitors to pkg.vhco.pro can identify VHCO package repositories and reach their setup and signing instructions."
covers:
  - AGENTS.md
  - README.md
  - web/packages/
  - package.json
  - bun.lock
  - docs/prototypes/vhco-packages/
  - tests/packages/
  - renovate.json
  - .github/workflows/packages-site.yml
---

# VHCO Packages landing page

## Context

### Owner summary

Give pkg.vhco.pro a small VHCO-branded homepage listing package repositories and their setup guides.
Start with the released OPNsense encrypted Git backup plugin.
Use the existing company logo, Inter font, brand colours and the reviewed sun/moon theme switch.
The current prototype is plain HTML/CSS with 45 lines of browser JavaScript for theme selection and repository-URL copying.
Bun, Playwright, Wrangler and the scanner are development or deployment tooling.
The page has no frontend framework or runtime package dependencies.

The owner clarified on 16 November 2026 that the homepage has an independent deployment lifecycle.
Page edits use an ordinary static-site workflow and can be redeployed from Git.
The package artifact keeps its existing shared GitVersion policy.
Page and tooling commits share that Git history and can contribute their normal version intent to the next package calculation.
A page deployment creates neither a package tag nor a package release.
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
Lab owns the separately reviewed one-time Worker bootstrap, route, redirect and main-only deployment-environment setup.
The component README documents development and pipeline usage.
Homelab operator deployment procedures and execution notes belong in private VitePress, with deployment configuration in Lab.
Production site deployments use their own concurrency group, separate from package publication.
A running site deployment finishes, and a newly pending deployment replaces an older pending one under GitHub's default single-pending behaviour.
The page's own free secret scan and browser checks gate its deployment.
Existing package workflows retain their current checks and triggers.
On 16 November 2026 the owner selected ordinary managed Renovate dependency updates and continuation of the homepage.
Use the shared repository baseline and normal manager detection, with the page's run/verify commands documented in README and AGENTS.
AGENTS.md Project scope also names the v1 hub under the retained 15 November code-home decision.
The shared Playwright dependency also serves the appliance tests.
Normal Renovate dependency PRs are planned for supported, discoverable inputs through the repository's existing review and merge policy.
Its managed App activation for this repository is still pending.

During cutover, the normal pipeline runs once after bootstrap checks.
For any non-success initial cutover result, the operator follows the private deployment procedure to disable publication and restore the prior Pages routing baseline.
A permanent main-only manual trigger provides redeployment for repository writers under the publication flag and environment policy.

The prototype passed 40 local Chromium/Firefox cases.
Production hosting and native attestation integration are still unimplemented.
This revised draft requires fresh independent review before acceptance.

### Background and revision

The released package is documented in [the installation guide](../installation.md) and [v0.1.0](https://github.com/vhco-pro/opnsense-encrypted-git-backup/releases/tag/v0.1.0).
The draft's first six reviews covered a design that carried page files inside package candidate and recovery archives.
The owner selected the existing package-feed repository as the v1 code home in the design recorded on 15 November 2026 at `1012715`.
The owner requested independent page deployment and removal of the additional page-publication controls on 16 November 2026.
That direction replaces the earlier Q7 decisions.
Former AC-05 described the joint publication lifecycle and is retired by this scope correction.
AC-07 defines independent page delivery.
AC-08 is retired with removal of the added public cutover-guide requirement.
Component usage remains in the README, and Homelab deployment procedures stay with their private owners.
Historical reviewer records are retained verbatim below.

The existing publisher deploys a complete retained Pages bundle through `scripts/publish-feed.sh` and `.github/workflows/feed.yml`.
Deploying only a homepage directory into that Pages project would replace the package snapshot.
Cloudflare documents static asset hosting and path-based routing, which provide a platform-native approach to examine before implementation.
The precise route configuration requires verification against the existing Pages custom domain.

The owner also selected the official action as the shared default for pipeline-driven static Cloudflare hosting.
This document explicitly adopts the [static-site standard](https://github.com/vhco-pro/docs/blob/2028365d39ff0bebf7698fff975ae04d0dac133e/conventions/cloudflare-static-sites.md) and complete example merged through [Docs PR #46](https://github.com/vhco-pro/docs/pull/46).
The repository's general convention pin remains `1edeb5f`, which predates that page.
The current VHCO Worker CI action explicitly rejects an `assets` configuration and requires a single JavaScript module (`worker-ci-action@5ef3cf6`, `scripts/verify.ts:40-44`).
The existing Worker deploy action verifies an exact release tag and `worker.mjs` (`worker-deploy-action@bcf1117`, `scripts/activate.ts:26-44`).
The official action supports Bun and multiple native Wrangler commands through its declared inputs at `953926a2e2182532811c01a25e53647d93bf07c0`.

### Pre-existing maintenance observation

The inspected repository has neither Renovate nor Dependabot configuration.
Composer dependencies and existing package-workflow refs therefore have no configured version-update coverage established by this inspection.
The owner-selected standard Renovate configuration enables normal manager detection for Bun, Composer and supported workflow refs.
The homepage's verification exercises every introduced pin and the shared Bun toolchain.
The existing shell-fetched core-symbol SHA, custom PHP-version input and untagged PHP/version reusable-action refs need separate maintenance assessment.
Normal detection does not establish update coverage for those pre-existing inputs.
Their current package-workflow definitions remain outside this feature.
Dependabot security-update settings were not inspected or changed.

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

The initial dry-run configuration included the earlier proposed routes.
The production configuration in Design is route-free.

## Scope

Add a generic homepage at pkg.vhco.pro with the VHCO mark, website styling and current OPNsense repository entry.
Provide setup, compatibility, source and release links and a copyable repository URL.
Support reading and navigation through HTML, with theme selection and URL copying as progressive browser enhancements.

Keep the v1 page source in this owner-selected existing publisher repository under `web/packages/`.
Extend the AGENTS.md Project scope and verification route to name the v1 hub and its commands.
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
Keep the prototype frozen as the historical design snapshot.
Its README records that status and retains its original asset provenance.
The maintained production page and its provenance/notice links live under `web/packages/`, and the root README links to the production notices.

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
It declares neither a `route` nor a `routes` key.
Lab owns route creation independently of the asset upload.
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

The operator uses the separately reviewed Lab provisioning and private VitePress deployment procedure for the live cutover.
Those deployment artifacts are maintained by their owning repositories.
This public feature delivers the static page, its workflow, tests and component usage documentation.

The operator's initial bootstrap uses native Wrangler `deploy` with a creation-capable credential to create the asset Worker.
The route-free configuration leaves public routes inactive and disables workers.dev and preview URLs.
Read back those settings before Lab activates the two routes and canonical-query redirect.
Lab supplies the main-only GitHub environment, Worker identity and existing-Worker Editor credential for routine site publication.
The page pipeline owns Worker content after bootstrap, while Lab owns the routes and redirect.

First confirm the prior root HTTP 404 and authenticated package-feed baseline.
After bootstrap and settings readback, activate the site routes, check the public responses and run native catalogue authentication/package fetch.
Then enable `PACKAGES_SITE_PUBLISH_ENABLED` and dispatch the normal site workflow once on reviewed `main`.
Require its verification and deployment jobs to pass, record the native deployment/version and compare the public bytes/media types.
Repeat native package verification before declaring cutover complete.

For any non-success result, including a cancelled, replaced, skipped or unverified run, the operator disables publication and restores the prior routing baseline through the private procedure.
Verify the prior root HTTP 404 and authenticated package responses and report an incomplete cutover if restoration is uncertain.
Routine site deployment cannot restore removed routes because its credential controls Worker content only.

Lab retains deployment configuration, and private VitePress retains Homelab inputs, detailed execution notes and raw operational output.
Public criterion evidence records run ID/attempt, source SHA, native deployment/version ID and response status/hash/media-type summaries.
It may record the opaque external Lab revision as a rollout reference.
Private Lab review is outside the AC-04 and AC-07 proofs; their verdicts rest on public behavior and workflow evidence.

### Pipeline and reuse

Use `cloudflare/wrangler-action@953926a2e2182532811c01a25e53647d93bf07c0` (v4.1.3) directly in `.github/workflows/packages-site.yml`.
Check out through `actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1` (v7.0.1) and install Bun through `oven-sh/setup-bun@0c5077e51419868618aeaa5fe8019c62421857d6` (v2.2.0).
Set its explicit `bun-version` input to the repository's existing 1.4.3 toolchain baseline from `native-browser.yml:25-27`.
Retain the verified release comments beside each action SHA so the native updater can track them.
Install Wrangler as an exact root development dependency through the existing Bun lockfile, then select `packageManager: bun` in the action.
The action uses the installed tool.
The consumer's workflow owns its static-file checks, browser suite and HTTP smoke check.
Its verification job scans `web/packages/`, including the public payload and generic README, with the free upstream Gitleaks CLI, using the official container pinned by released version and digest in the workflow.
Reference the official image directly as `uses: docker://ghcr.io/gitleaks/gitleaks:<released-version>@sha256:<digest>`.
Pass `dir --redact=100 --no-banner` and `web/packages/` as its arguments.
The managed Renovate GitHub Actions manager discovers this native container reference.
Add the actual shared baseline `renovate.json` from `knowledge/managed-renovate.md` at the explicitly cited shared-docs revision.
Its verified presets are `config:recommended` and `helpers:pinGitHubActionDigests`, with the shared manual-review rules for action majors and unversioned action digests.
Use normal manager detection so the Bun manager maintains `package.json` with `bun.lock`, the GitHub Actions manager tracks native action/container refs and Composer receives its ordinary dependency PRs.
Preserve any established consumer rules and update coverage encountered during implementation.
Verify actual extraction of every introduced workflow action/container ref and runtime input, including checkout, setup-bun, wrangler-action, the Bun runtime version and scanner image/version/digest, plus Wrangler and Playwright associated with `bun.lock`.
Use a managed update proposal to verify that a tool-version change also maintains the Bun lock and passes a frozen install.
Require confirmed managed App access plus a Dependency Dashboard entry or proposed update identifying the introduced scanner dependency for AC-06.
An unavailable updater remains an unmet criterion or separately approved tracked residual.
The repository currently has no updater configuration.
On 16 November, `gh api --paginate orgs/vhco-pro/installations` succeeded, and filtering its installation records for the Renovate App returned an empty list.
An authenticated issue-title query also returned no Dependency Dashboard.
Managed App activation uses GitHub's normal owner-controlled installation for this repository, outside source commits.
Verify actual App access and the repository Dashboard/update record during ordinary bot setup.
Check the existing repository-security settings at takeover, keeping Dependabot alerts on and duplicate Dependabot version/security updates off for Renovate-owned ecosystems.
Both a finding and a scanner error fail verification.
The deployment job depends on this same verification job, including the secret scan.
Pull requests run that job with read-only GitHub permissions and without Cloudflare credentials.
An enabled main-branch push or a repository writer's `workflow_dispatch` on `main` deploys only after it succeeds.
Keep `workflow_dispatch` as a permanent main-only manual redeployment trigger after cutover.
It selects that `main` source and uses the same publication flag, verification and production environment policy.
The live cutover authorisation covers its first dispatch.
Use native workflow path filters for `web/packages/**`, `tests/packages/**`, `package.json`, `bun.lock`, `renovate.json` and `.github/workflows/packages-site.yml` on pull requests and main pushes.
A lockfile-only change therefore runs site verification.
Keep the existing branch-required checks as configured, so site workflow path filtering does not add a new pending required context to unrelated changes.

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
The smoke checker accepts a base URL.
The production job supplies `CLOUDFLARE_SITE_URL` from its deployment environment and requires its value to be `https://pkg.vhco.pro`.
At that base, check `/` and each listed `/_site/` asset against the checked-out `web/packages/public/` bytes and expected media type.
Compare the media type before an optional charset parameter.
Also require an owned missing `/_site/` URL to return HTTP 404 with the checked-out `404.html` bytes and HTML media type.
Retry failed public checks at five-second intervals for at most 60 seconds to allow propagation, then fail the deployment job if any check still differs.
A stale HTTP 200 page fails the byte comparison.
The ordinary Actions run reports the result.
Local restoration and stale-response tests pass an owned loopback fixture URL to that same checker and require the selected host to be loopback.
They use native Wrangler asset serving plus the owned HTTP fixture to vary responses and package-origin availability.
These are local delivery simulations.
The real official-action deployment and public checks are verified during the authorised production cutover.

Use the site-only production group `vhco-packages-site-production` with `cancel-in-progress: false` and GitHub's default `queue: single` behaviour.
This group is separate from the package publisher's `native-package-pages-publisher` group.
One site deployment can run while one waits.
A new pending site job replaces the previous pending site job, and the running site job finishes.
That behaviour permits missed intermediate homepage updates, as selected by the owner.
Verification must have its own job-level concurrency group keyed by PR number or ref, with `cancel-in-progress: true`.
There is no workflow-level concurrency group, so verification cancellation cannot cancel a running deployment job.

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
Keep site specs and their explicit Playwright configuration under `tests/packages/`, outside the appliance config's `tests/browser/` directory.
The site workflow selects that configuration explicitly.
Compare native Playwright test collection before and after the feature and require the appliance job to collect its existing specs only.
Wrangler's exact root development dependency participates in the normal frozen-lockfile installation and package verification.
Exercise Chromium and Firefox in both themes at 320 by 568, 390 by 844, 844 by 390, 768 by 1024, 1280 by 720 and 1440 by 900.
Check keyboard navigation, the switch, saved preference, clipboard denial, unavailable storage and JavaScript-disabled reading.
Inspect representative mobile and desktop captures and run actual 200 percent browser zoom before implementation completion.

Ordinary page CI checks the explicit public files, required notices, its own blocking Gitleaks source scan and browser suite.
The deployment publishes the checked-out site through the official action and performs the bounded public byte/media-type checks above.
Page CI uses the exact native trigger paths listed above.
One native package-client check during the separately authorised hosting cutover confirms that route isolation preserves catalogue authentication and package fetch.
The routing fixture provides repeatable coverage for later page edits.

Document the local workflow in `web/packages/README.md`, link it from the root README and add its commands to the AGENTS.md verification route.
Bootstrap with `bun install --frozen-lockfile --ignore-scripts` and `bun x playwright install chromium firefox`.
`bun run packages:preview` starts the owned loopback fixture with the static repository entries and prints its local URL.
`bun run packages:verify` runs static checks, the pinned redacted scanner, the native routing fixture and the explicit `tests/packages/` Chromium/Firefox suite.
Document Docker with daemon access as a local scanner prerequisite.
The local scanner reads the `secrets` step's immutable `uses: docker://` reference from `.github/workflows/packages-site.yml` with Bun's built-in YAML parser and runs that same image through Docker, with a read-only `web/packages/` mount and network disabled.
This workflow reference is the single authoritative scanner pin.
Missing Docker, an invalid reference or a scanner error fails the aggregate command.
`bun run packages:smoke -- <base-url>` runs the same bounded response checks used after deployment.
The aggregate command launches and stops only its owned fixture processes and temporary data, retaining the stated browser evidence.
Ctrl+C stops the manually started preview.
The documented cleanup is aggregate-owned teardown and Ctrl+C for the foreground preview.
Run these bootstrap, preview, aggregate, smoke and teardown procedures from a fresh development checkout before completion.

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
- [ ] AC-06: The public page contains repository information without private deployment inputs or credentials, uses its glossary terms consistently, has verified managed update coverage for its scanner/tooling and links to maintained package version information and the installation guide's independent trusted-channel verification of signing fingerprints.
- [ ] AC-07: A page edit and page rollback deploy independently of package releases, version calculation, package publication failures and package recovery.

## Test Plan

| Criterion | Proof |
| --- | --- |
| AC-01 | Serve the production static directory in the packages Playwright fixture. Check the actual package identifier and repository URL, follow the setup anchor and verify each public reference's final route. A two-entry synthetic page checks that another authored repository can be listed. |
| AC-02 | Run the specified viewport/theme matrix in Chromium and Firefox. Check overflow, readable type, 44-pixel touch targets, focus and headings. Inspect representative screenshots. Exercise actual 200 percent browser zoom and record its method and resulting viewport. |
| AC-03 | Run the current prototype's keyboard switch, saved theme, storage denial, URL copy, clipboard failure after success and JavaScript-disabled cases against the production static files. Check the switch state and reduced-motion behaviour. |
| AC-04 | **Static checks** require the Wrangler file to have no `route` or `routes` key. **Local checks** serve production files through native Wrangler, verify root/prefixed assets and media types, missing-asset HTTP 404 and a synthetic package origin through the routing fixture. **Live cutover observation** checks the actual root with/without a query, queried asset, missing paths, exact public bytes/media types and native signed catalogue authentication/package fetch. **Independent re-observation** repeats public GETs and native pkg verification from the identified source and public signing inputs. Record response status/hash/media-type summaries, source SHA, run/attempt and native deployment/version ID in this document. The opaque Lab revision is a rollout reference only. Public behavior is verified through these actual reads; private Lab review is outside this criterion's proof. |
| AC-06 | Check the explicit public asset list, both licence notices and the site verification job's Gitleaks source scan. Run Renovate's actual GitHub Actions dependency extraction against the workflow and require every introduced action/container ref, verified release/digest and runtime input to appear, including checkout, setup-bun, wrangler-action, Bun and the scanner image. Require Bun extraction of Wrangler and Playwright with `bun.lock` and a tool update whose regenerated lock passes the frozen install. Validate the consumer against the actual shared Renovate baseline and require managed App access plus a Dashboard entry or update proposal for the scanner image. Record an unavailable updater as unmet or through a separately approved tracked residual. Review rendered text and network requests for deployment-specific addresses or credentials. Verify maintained documentation links and glossary terms. "Follow the installation guide to verify the signing key through an independent trusted channel before adding the repository" passes the signing-copy check. "Trust this downloaded key without verification" fails it. |
| AC-07 | **Static checks** run actionlint, validate official action inputs, read-only PR permissions, absence of PR Cloudflare inputs, successful-verification dependency, publication-flag/main conditions, independent site concurrency group and absence of package-tag/publish mutations. Desk-review the exact native `if:` and `needs` conditions against GitHub's documented contexts. PR verification runs read-only without Cloudflare inputs; a non-main ref, disabled flag or failed verification excludes deployment; successful verification on enabled main permits deployment. Compare the job-level verification cancellation and independent non-cancelling deployment groups with GitHub's documented semantics, requiring no workflow-level cancelling group and no extra live deployments. **Local checks** run the documented aggregate command, synthetic secret/error cases, source-restoration/stale-byte HTTP fixture with the package origin unavailable, exact restored bytes/media types and root-lockfile trigger coverage. The source-restoration proof is local. **Live cutover observation** is the one normal protected main dispatch already named in Design, including its actual verification/deployment jobs and public smoke; read the native GitHub environment policy then. **Independent re-observation** reads the public run/job/workflow and environment-policy records, repeats public HTTP/pkg checks and labels one-time operator actions as recorded evidence. Public criterion evidence holds the run/attempt, source SHA, optional opaque rollout revision and native deployment/version identifiers. The private Lab rollout reference is recorded outside the public criterion proof, in the private VitePress execution record, with its opaque revision in public evidence. |

## Tasks

Tasks follow owner acceptance.

## Open Questions

None. On 16 November 2026 the owner selected normal managed Renovate dependency handling after the static-hosting and official-action choices.

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
| 2026-11-16 | R-9 | spec | `7b9348cea8ccbaccc0333e4e73010d9491e4ccad` | claude-opus-5-5 | procedural | Four should-fix findings. First-party Opus assistant identity attested, with Haiku also listed separately in usage. Independent lint passed, fresh reported expected baseline change, and gate/repository checks were denied or unexecuted. Read-only snapshots matched. |
| 2026-11-16 | R-10 | spec | `e694ca001f65057698809d91c45d2355b47ded15` | claude-opus-5-5 | procedural | Five should-fix findings and one nit. First-party Opus assistant identity attested, with Haiku also listed separately in usage. Independent lint passed. Fresh exposed the broken R-9 table row. Planned/next and repository checks were denied or unexecuted. Read-only snapshots matched. |
| 2026-11-16 | R-11 | spec | `d085a9324db0b69784ee8f640a70971cf8c928b1` | claude-opus-5-5 | procedural | One blocking, three should-fix findings and one nit. First-party Opus assistant identity attested, with Haiku also listed separately in usage. Independent lint passed, fresh identified R-10 correctly, and gate/repository checks were denied or unexecuted. Read-only snapshots matched. |
| 2026-11-16 | R-12 | spec | `02486acf74f4365511121d1a61285cc41ea32b11` | claude-opus-5-5 | procedural | Two should-fix findings. Successful retry after an unrecorded failed DNS attempt. First-party Opus assistant identity attested, with Haiku also listed separately in usage. Independent lint passed; gate/repository checks were denied or unexecuted. Read-only snapshots matched. |
| 2026-11-16 | R-13 | spec | `0c525000fc391060e06900b0ab5496927a18dfb8` | claude-opus-5-5 | procedural | Three should-fix findings and one nit. First-party Opus assistant identity attested, with Haiku also listed separately in usage. Independent lint and diff check passed; gate/actionlint and other repository checks were denied or unexecuted. Read-only snapshots matched. |
| 2026-11-16 | R-14 | spec | `5efb35660b67d05a7123058947d9d7416f27629a` | claude-opus-5-5 | procedural | Three should-fix findings and one nit. First-party Opus assistant identity attested, with Haiku also listed separately in usage. Independent lint and diff check passed; gate/next/actionlint and other repository checks were denied or unexecuted. Private VitePress fetches returned 404. Read-only snapshots matched. |
| 2026-11-16 | R-15 | spec | `a6fa7c297a4815e50a0f5fc602cfae250ebdce6e` | claude-opus-5-5 | procedural | Three should-fix findings and one nit. First-party Opus assistant identity attested, with Haiku also listed separately in usage. Independent lint passed; gate/next/diff/actionlint and other repository checks were denied or unexecuted. The full return includes appended run notes. Read-only snapshots matched. |
| 2026-11-16 | R-16 | spec | `2d7d43bb6ec4c397125ea1b450e59ece14f0a186` | claude-opus-5-5 | procedural | Seven should-fix findings and one nit. First-party Opus assistant identity attested, with Haiku also listed separately in usage. Independent lint passed; gate/next/diff/actionlint and other checks were denied or unexecuted. Read-only snapshots matched. |

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

### R-9

TARGET: 7b9348cea8ccbaccc0333e4e73010d9491e4ccad

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Frontmatter covers lines 6-14, Owner summary line 47, Design (Pipeline and reuse) lines 241-244, Design (Browser and workflow checks) lines 268 and 273-277, Test Plan AC-01, AC-03, AC-07
EVIDENCE: The design puts the site suite at `tests/browser/packages.spec.mjs` (covers line 12) and says the PHP, native-browser, native-feed and publisher workflows "retain their current verification, triggers and source-proof contract" (line 241). The root `playwright.config.ts:4` sets `testDir: './tests/browser'` with no `testMatch` or `testIgnore`, so Playwright's default spec pattern also picks up `packages.spec.mjs`. The appliance run calls `bun x playwright test` with that root config and no grep (tests/appliance/browser.sh:50), and native-browser.yml runs that script on every pull request and main push (.github/workflows/native-browser.yml:3-7,37-40). So the homepage suite would run inside the appliance job against `baseURL: process.env.FIXTURE_APPLIANCE_URL` (playwright.config.ts:9). It would either fail native-browser on every change or quietly change what that check covers, even though no workflow file changed. Adding Wrangler to the shared `package.json` and `bun.lock` also changes what native-browser.yml installs (`bun install --frozen-lockfile`, line 33). `playwright.config.ts` and `tests/appliance/browser.sh` are not in `covers`. The AC-07 check "package workflow files retain their existing definitions" passes in this case, because it compares only workflow definitions. Tool record for this pass: `vh-adlc lint docs/specs/vhco-packages-landing-page.md --repo <clone> --plugin-pin 1ccf8f314575ece1f3fcc8e48c4fd804a1ca88ff` passed with no findings. `vh-adlc fresh` with the same arguments reported R-8 stale (`baseline-changed`), no implementation review (`no-review`) and a clean feature tree. The host permission mode denied `vh-adlc gate planned`, a combined lint/fresh/gate/next command, `git diff` against the R-8 commit and a final `git status`. Repository checks (PHP lint, phpcs, phpstan, phpunit, actionlint, Playwright) were not run. The other evidence came from reading files and from public documentation fetches. I used no live provider access.
PROPOSAL: Either keep the site suite out of the root config's collection (a separate directory or a root `testIgnore`), or list `playwright.config.ts` in `covers` and state the exclusion. Add an AC-07 check that the appliance Playwright run collects only its existing specs after the change.

FINDING: F-02
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Pipeline and reuse) line 226, Design (Browser and workflow checks) line 274, Owner summary line 46, Test Plan AC-04, AC-07
EVIDENCE: The pipeline's only post-deployment observation is "root and asset HTTP smoke check" (lines 226 and 274). The document does not say which URL it targets. workers.dev and preview URLs are disabled (line 152), so only the public routes remain. It also does not say what the check compares. One implementer would accept HTTP 200 from `/` and one asset. Another would compare the served bytes and media types with this run's checked-out `web/packages/public/` files, with a bounded retry for propagation. A status-only check passes when `versions deploy` did not take effect and the previous content is still served, or when a source restoration (line 235) left old bytes live. Both the AC-07 restoration proof and the shared standard's "Run a public HTTP smoke check after deployment" (Docs PR #46 at 2028365) would accept that result. The AC-04 row lists "root/assets smoke responses" without a pass condition.
PROPOSAL: State the smoke check's target URLs and pass condition: the root and each `_site/` asset must return the checked-out bytes and expected media types, within a stated retry bound. Add an AC-07 case where stale content is served after deployment and the smoke check must fail.

FINDING: F-03
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Pipeline and reuse) lines 209-212, Design (Browser and workflow checks) line 273, Test Plan AC-06, AC-07, Sources line 703
EVIDENCE: Line 210 says to "let the repository's updater discover the container pin". The repository has no updater configuration: no `renovate.json` and no `.github/dependabot.yml` (Grep over the tree finds only the stale `renovate.json` entry at docs/specs/native-encrypted-git-backup.md:26). The pinned delivery convention says every dependency must be discoverable by the update tool and "Adding a dependency includes confirming the updater will propose its next version" (conventions/delivery.md:153-160). The document leaves open how the image is referenced. Renovate's GitHub Actions manager reads `uses: docker://...` and job `container:` images, but not an image inside a `docker run` shell step. So one implementer would write a `docker run ghcr.io/gitleaks/gitleaks:<v>@sha256:...` step that never gets updates, and another would write a `uses: docker://` step. Both pass the AC-06 and AC-07 rows, because neither row checks updater discovery. The Gitleaks README also says the project is feature complete and future releases are security patches only, which makes receiving those updates more important. The rest of the scanner contract matches upstream: `gitleaks dir`, `--redact` defaulting to 100, `--no-banner`, exit code 1 for leaks or errors, the ghcr.io and Docker Hub images, and the MIT licence at v8.30.1.
PROPOSAL: Name the reference form for the Gitleaks image, for example `uses: docker://ghcr.io/gitleaks/gitleaks:<version>@sha256:<digest>`, and the updater that will track it. Add an AC-06 or AC-07 check that the updater lists the pin.

FINDING: F-04
KIND: judgement
SEVERITY: should-fix
WHERE: Owner summary line 29, Scope lines 115-117, Acceptance Criteria AC-07, Test Plan AC-07
EVIDENCE: The Owner summary says "The package artifact keeps its existing shared GitVersion version", and AC-07 requires page edits to deploy independently of "version calculation". The page source lives in the same repository and on the same `main` that the package tag job versions (.github/workflows/feed.yml:82-108, shared GitVersion action). The pinned convention makes commit subjects decide version intent: `feat` is minor, `fix` and `chore` are patch, and `docs`, `style`, `test` and `ci` do not normally bump (conventions/delivery.md:30-40). So a `feat(packages): add repository entry` or `fix(packages): correct link` page commit raises the next plugin package version even when no plugin bytes changed. Wrangler or Playwright `chore(deps)` updates do the same. Page deployment does not depend on version calculation, but version calculation does depend on page commits, and the document never says whether that is intended. Implementers and committers could follow either convention, and the AC-07 row has no check either way.
PROPOSAL: State whether page-only commits may change the package's next GitVersion number. If they should not, name the commit type page and site-tooling changes use and check it in AC-07. If they may, say so in the Owner summary.

### R-10

TARGET: e694ca001f65057698809d91c45d2355b47ded15

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Review Log table lines 334-345
EVIDENCE: Line 344 is blank, so the R-9 row at line 345 is no longer part of the Review Log table that starts at line 334. `vh-adlc fresh docs/specs/vhco-packages-landing-page.md --repo <clone> --plugin-pin 1ccf8f314575ece1f3fcc8e48c4fd804a1ca88ff` reported the latest spec review as `"review":"R-8","commit":"a19054e76b712b303c936efdf2d6558d3b40fe83"` with `baseline-changed`. It did not see R-9 at all. If the next row is appended after line 345, the binary will miss it too. `spec_review_fresh` and acceptance would then keep resolving to R-8, and the gate would read the document differently from its author. Tool record for this pass: `vh-adlc lint` with the same arguments passed with no findings. `fresh` reported R-8 stale (`baseline-changed`), `no-review` for implementation and a clean feature tree. The host permission mode denied a combined `cat` of convention pages, a combined lint/fresh/gate/next command, the separate `vh-adlc gate planned` and `vh-adlc next` calls, and `git diff` from the R-9 commit to the target. I did not attempt the repository checks (PHP lint, phpcs, phpstan, phpunit, actionlint, Playwright) after those refusals. I fetched public documentation for Wrangler worker commands, Cloudflare routes, Cloudflare versions and deployments, wrangler-action action.yml at 953926a, the Renovate github-actions manager, GitHub concurrency, and vhco-pro/docs at 1edeb5f and 2028365. The first Cloudflare routes fetch failed with a temporary router error ("Can't reach the API server ... ENOTFOUND"). The retry succeeded. No live provider access was used. Confirmed without finding: root `playwright.config.ts:4` collects only `./tests/browser`, and `tests/appliance/browser.sh:50-54` uses that root config, so `tests/packages/` stays out of the appliance run. The GitVersion statements at lines 29-31 and in the AC-07 row match conventions/delivery.md:30-40. `versions deploy --version-tag` and `--yes` exist. Exact-root routes do not match query URLs. The concurrency text matches GitHub's single-pending behaviour.
PROPOSAL: Remove the blank line 344 so that R-9 and every later row belong to the one Review Log table, then confirm that `vh-adlc fresh` names the latest review.

FINDING: F-02
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Pipeline and reuse) lines 223-237, Design (First cutover and infrastructure ownership) lines 189-190, Design (Independent hosting) line 154, Owner summary line 44, Test Plan AC-07
EVIDENCE: Line 233 fixes the smoke target as `https://pkg.vhco.pro/` and its `/_site/` assets. The AC-07 row requires the workflow to run "against an owned isolated deployment", to "Publish a changed page, then restore older page files" and to "Serve stale bytes after a synthetic deployment and require the public smoke check to fail". The site environment allows only `main` and carries the production Worker name (lines 189-190, 223-224), and workers.dev and preview URLs are disabled (line 154). The document therefore gives an isolated deployment no hostname, Worker, environment or way to point the smoke check at it. If the target stays hard-coded, the isolated run checks production instead. The restoration case then passes even when the isolated deployment did nothing, because production still serves the older bytes. The stale-bytes case cannot be injected without breaking production. One implementer would read the smoke URL from an environment input. Another would keep the literal URL, and the row cannot tell the two apart.
PROPOSAL: Make the smoke base URL an input supplied by the deployment environment, and name the owned isolated target used for AC-07 (its Worker, hostname, environment and credential). Require the restoration and stale-bytes cases to check that target and not production.

FINDING: F-03
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Pipeline and reuse) lines 211-217, frontmatter covers line 13, Test Plan AC-06
EVIDENCE: conventions/delivery.md:159-160 says "Adding a dependency includes confirming the updater will propose its next version", and delivery.md:113-116 says to keep existing coverage until managed App access is confirmed. Line 217 says App access could not be verified, and the repository has neither `renovate.json` nor `.github/dependabot.yml`. The AC-06 row checks local extraction and says to "record managed App/Dashboard visibility separately", so the row passes when no updater ever proposes a Gitleaks update. The Renovate page documents the `docker` depType for `uses: docker://alpine:3` but does not say that a `uses: docker://` reference with an `@sha256` digest gets digest updates. Only actual extraction or Dashboard listing shows that. Line 215 also adds the shared baseline `renovate.json` at the repository root without stating its scope. That config also enrols Composer, Bun and every existing package workflow pin. Under the patch policy at delivery.md:37-40, the resulting `chore(deps)` PRs change package workflow files and bump the package version. One implementer would adopt the full baseline. Another would limit it to the site workflow. That choice affects the lifecycle of the existing package workflows.
PROPOSAL: Make App access and a Dependency Dashboard entry (or proposed update) for the scanner image a pass condition of AC-06, or record its absence as a residual. Raise an Open Question on whether the new `renovate.json` covers the whole repository or only the site workflow and its tooling.

FINDING: F-04
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Pipeline and reuse) lines 208-209 and 255, Design (Browser and workflow checks) lines 284 and 291, frontmatter covers lines 9-10, Test Plan AC-07
EVIDENCE: Line 291 says "Page CI is scoped to the site source and its workflow/tests", and line 255 says "Its source paths and workflow select its own checks". Wrangler and Playwright, which the site build, deployment and browser suite depend on, are pinned in the root `package.json` and `bun.lock` (lines 208, 284; package.json:7-9). Both files are in `covers`. The document does not say whether changes to them trigger the site workflow. If they do not, a Wrangler or Playwright update PR merges without site CI, against delivery.md:120 ("Project CI still validates the proposed changes"). The next page deployment then runs an untested Wrangler. One implementer would include the root manifests in the path filter and another would not. The AC-07 row checks no trigger paths.
PROPOSAL: List the site workflow's exact trigger paths, including `package.json` and `bun.lock`. Add an AC-07 case where a lockfile-only change runs site verification.

FINDING: F-05
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Browser and workflow checks) lines 280-293, frontmatter covers line 7, Test Plan AC-01, AC-03, AC-07
EVIDENCE: The pinned conventions/frontend-testing.md:28-33 requires that "The repository's README and agent instructions name the commands to bootstrap, seed, run, verify and clean" and that there be a documented aggregate verification command. The repository AGENTS.md Verification section lists only PHP checks and actionlint. `README.md` is in `covers`, but the Design never says which site commands it gains: fixture start, the explicit `tests/packages/` Playwright config, the Gitleaks scan and the local Wrangler routing fixture. It also does not say whether AGENTS.md changes. No Test Plan row checks that these commands are documented and work, so an implementation that documents nothing passes.
PROPOSAL: Name the documented site fixture and verification commands and where they live. Raise the AGENTS.md verification-list change as an Open Question, and add a proof that runs the documented commands.

FINDING: F-06
KIND: judgement
SEVERITY: nit
WHERE: Context (Background and revision) line 71, Design (Pipeline and reuse) line 259, Sources lines 748 and 754
EVIDENCE: The repository pins vhco-pro/docs at 1edeb5f (AGENTS.md). The cited `conventions/cloudflare-static-sites.md` returns HTTP 404 at 1edeb5f but loads at 2028365, which is the revision the document cites. So an implementation review under the pinned revision does not route to that standard. The document restates its requirements, so nothing built changes.
PROPOSAL: Say that the document adopts the static-site standard at 2028365 by explicit reference, or note that the repository pin does not yet include it.

### R-11

TARGET: d085a9324db0b69784ee8f640a70971cf8c928b1

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Design (Pipeline and reuse) lines 217-222, Acceptance Criteria AC-06, Test Plan AC-06
EVIDENCE: Line 218 says "Enable only the `github-actions` and `npm` managers and include only `.github/workflows/packages-site.yml`, `package.json` and `bun.lock`". Line 219 says "That scope covers the site action/container refs and the root Wrangler/Playwright tooling." The repository locks its root tooling with Bun (bun.lock; .github/workflows/native-browser.yml:33 runs `bun install --frozen-lockfile --ignore-scripts`). Renovate's npm manager page lists only `package-lock.json`, `pnpm-lock.yaml` and `yarn.lock` as lock files and does not mention Bun. Renovate has a separate `bun` manager whose patterns are `/(^|/)bun\.lockb?$/` and `/(^|/)package\.json$/`, and that page says a `package.json` in bun results is "excluded from the `npm` manager results". With `bun` left out of the enabled managers, the npm manager takes `package.json` and has no lock file it can maintain. Wrangler and Playwright update PRs would then change `package.json` without `bun.lock`, and every frozen-lockfile install in the site and appliance jobs would reject them. So the claim at line 219 is false, and an implementer who follows lines 217-218 builds an updater config that cannot maintain the tooling. The AC-06 row checks extraction and the Dashboard only for the scanner image, so it passes anyway. This traces to this revision's repair of R-10 F-03. Tool record for this pass: `/home/m/.local/bin/vh-adlc lint docs/specs/vhco-packages-landing-page.md --repo /tmp/eg-packages-opus-r11.e4NG9L/source --plugin-pin 1ccf8f314575ece1f3fcc8e48c4fd804a1ca88ff` returned `"result":"pass"` with no findings at docs revision 1edeb5f. `vh-adlc fresh` with the same arguments reported the latest spec review as R-10 at e694ca0, stale with `baseline-changed`, `no-review` for implementation, and a clean feature tree. That confirms the R-10 F-01 Review Log continuity repair. The host permission mode denied a combined lint/fresh/gate/next command, the separate `vh-adlc gate planned` and `vh-adlc next` calls, `git diff --check` from the R-10 commit to the target, `actionlint`, and a final `git status --porcelain`. I did not attempt PHP lint, phpcs, phpstan, phpunit or Playwright after those refusals. The vendor dependencies and pinned core symbols were also absent. Public fetches that succeeded: vhco-pro/docs `conventions/cloudflare-static-sites.md` and `knowledge/managed-renovate.md` at 2028365, Renovate's bun and npm manager pages, wrangler-action `action.yml` at 953926a, Cloudflare's Wrangler worker commands page, worker-ci-action `scripts/verify.ts` at 5ef3cf6 and worker-deploy-action `scripts/activate.ts` at bcf1117. No fetch failed and I saw no router interruption. I used no provider control plane access.
PROPOSAL: Enable Renovate's `bun` manager for `package.json` and `bun.lock` in place of `npm`, or state the manager that actually maintains `bun.lock`. Extend the AC-06 proof so that actual extraction lists Wrangler and Playwright with the Bun lock file, not only the scanner image.

FINDING: F-02
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Pipeline and reuse) lines 217-222, Design (Browser and workflow checks) line 310, Owner summary lines 24-54, Open Questions line 354
EVIDENCE: R-10 F-03 proposed an Open Question on whether the new `renovate.json` covers the whole repository or only the site tooling. R-10 F-05 proposed an Open Question on the AGENTS.md verification change. This revision decides both in the Design (lines 217-218 and 310), and Open Questions says "None. The owner selected native static hosting and the official action". No owner decision on either choice is recorded. conventions/feature-documents.md:161-162 says "Every trade-off the document settles is an open question", and the reviewer instructions say a needed change to repository instructions is raised for an Open Question and never assumed. The narrow scope has consequences beyond the site. conventions/delivery.md:153 says "Every dependency must be discoverable by the repository's update tool". conventions/repository-security.md:63-68 treats a Renovate config file as a sign of Renovate, which keeps Dependabot security updates off for the whole repository. Composer (composer.lock) and the existing package workflow pins would then have no version updater from either tool. The `package.json` scope also enrols the appliance job's Playwright (native-browser.yml:33-34), so it reaches past "this feature's tooling" (line 217). Under delivery.md:37-40 each resulting `chore(deps)` PR also bumps the package's patch version. The Owner summary mentions neither the first updater config in the repository nor the AGENTS.md change.
PROPOSAL: Raise Open Questions for the Renovate scope, naming the coverage left for Composer and the existing workflow pins, and for the AGENTS.md verification-route change, or record the owner's decisions with their dates. Add the updater adoption and its consequences to the Owner summary.

FINDING: F-03
KIND: judgement
SEVERITY: should-fix
WHERE: Design (First cutover and infrastructure ownership) lines 185-189, 197-205, Design (Pipeline and reuse) lines 228 and 237-253, Context (Native hosting compatibility check) line 99, Test Plan AC-04, AC-07
EVIDENCE: Line 253 says "The real official-action deployment and public checks are verified during the authorised production cutover", and the AC-07 row says "Verify the actual normal Actions deployment, its native Cloudflare record and public smoke check at the authorised cutover." The cutover sequence never runs the site workflow. It goes from bootstrap `deploy` with a creation-capable credential (line 185), through the baseline check, routes, redirect and public responses, to the native package check (lines 197-201). Line 204 enables `PACKAGES_SITE_PUBLISH_ENABLED` "only after the initial cutover succeeds". The workflow's only triggers are pull requests and main pushes filtered by path (line 228), with no dispatch. So the first normal deployment happens at some later main push that touches site paths, outside the authorised cutover. That run's path is untested: the Editor credential, `versions upload` with assets, `versions deploy --version-tag` and the production smoke check against `CLOUDFLARE_SITE_URL`. The only observed Wrangler command was `wrangler deploy --dry-run` (line 99). The document defines no failure handling for that first routine run, for example `versions upload` succeeding while `versions deploy` or the smoke check fails. One implementer would add a dispatch or a deliberate site-path commit inside the cutover window, and another would wait for the next page edit. This traces to this revision's repair of R-10 F-02.
PROPOSAL: Name the cutover step that runs the normal site workflow deployment with the environment credential after the flag is enabled, and state its expected record and smoke result. State what is reported and restored when that first routine deployment or its smoke check fails, and align the AC-07 row with that step.

FINDING: F-04
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Pipeline and reuse) lines 213-218, Design (Browser and workflow checks) lines 310-317, Test Plan AC-07
EVIDENCE: The scanner pin lives only in the workflow as `uses: docker://ghcr.io/gitleaks/gitleaks:<released-version>@sha256:<digest>` (line 214). Line 313 says the local `bun run packages:verify` runs "the pinned redacted scanner", but the document names no local source for that pin and no container runtime among its dependencies. conventions/frontend-testing.md:32-33 requires the documentation to "State which dependencies and services are needed". conventions/delivery.md:149-151 forbids silently accepting a different preinstalled tool version and says "Store tool configuration once". One implementer would call a `gitleaks` binary from PATH, which breaks the pin rule. Another would copy the image reference into a script, and the Renovate include list at line 218 would never update that copy, so the two pins drift. frontend-testing.md:28-29 also requires a documented clean command. The design names only automatic cleanup and Ctrl+C (lines 315-316), while the AC-07 row asks to run "the README/AGENTS bootstrap, preview, aggregate and cleanup commands as documented".
PROPOSAL: State how the local aggregate obtains the same pinned scanner from a single authoritative location the updater tracks, and name the container runtime or other prerequisite. Name the cleanup command, or state that none exists beyond the aggregate's own cleanup, and match the AC-07 row to it.

FINDING: F-05
KIND: judgement
SEVERITY: nit
WHERE: Frontmatter covers line 12, Design (Content and visual structure) line 138, Test Plan AC-03
EVIDENCE: `docs/prototypes/vhco-packages/` is in `covers`, and production files move to `web/packages/public/` (line 154). The document never says whether the prototype is kept, frozen or removed. README.md links the logo notice at `docs/prototypes/vhco-packages/VHCO-LOGO-NOTICE.txt`, and line 138 places asset provenance in the prototype README. If the prototype is removed, those links break. If it is kept, two copies of the page can drift apart.
PROPOSAL: State the prototype's fate and, if it is removed, move the provenance and README notice link to `web/packages/`.

### R-12

TARGET: 02486acf74f4365511121d1a61285cc41ea32b11

FINDING: F-01
KIND: judgement
SEVERITY: should-fix
WHERE: Design (First cutover and infrastructure ownership) lines 217-222, Design (Pipeline and reuse) lines 247-249 and 276-279, Owner summary lines 41-53, Test Plan AC-07
EVIDENCE: Line 221 defines restoration only when the cutover dispatch "fails during upload, activation or smoke verification". Line 245 makes deployment depend on the verification job, which runs the secret scan and the Chromium/Firefox suite. If that job fails or flakes on the dispatch, deployment is skipped. The routes and redirect are then live with the bootstrap content and `PACKAGES_SITE_PUBLISH_ENABLED` is on. Line 220 says the cutover is not complete, but the document says nothing about the flag, the routes or a retry in that state. Lines 276-279 set the production group to `queue: single` with pending replacement. A site-path main push during the window, with the flag already enabled, can replace the dispatch's pending deployment job. In that case "the successful Actions run" at line 219 never comes from the dispatch. Line 247 lets "the authorised initial `workflow_dispatch` on `main`" deploy, but a workflow condition cannot tell the initial dispatch from a later one. Line 249 gives path filters only for pull requests and pushes. The document does not say whether the `workflow_dispatch` trigger stays after cutover, which would let any later main dispatch deploy, or is removed, which would change the workflow. One implementer will revert routes when verification fails and keep the trigger. Another will retry and remove the trigger. The Owner summary covers the Lab bootstrap but does not mention the publication flag, the one cutover dispatch or its restoration path. This traces to this revision's repair of R-11 F-03. Tool record for this pass: `/home/m/.local/bin/vh-adlc lint docs/specs/vhco-packages-landing-page.md --repo /tmp/eg-packages-opus-r12-retry.8pQj2q/source --plugin-pin 1ccf8f314575ece1f3fcc8e48c4fd804a1ca88ff` returned `"result":"pass"` with no findings at docs revision 1edeb5f. `vh-adlc fresh` with the same arguments returned local and remote SHA 02486acf74f4365511121d1a61285cc41ea32b11. It reported the latest spec review as R-11 at d085a93, stale with `baseline-changed`, `no-review` for implementation, and a clean feature tree. `.git/HEAD` read 02486acf74f4365511121d1a61285cc41ea32b11. The host permission mode denied a combined `cat` of the reviewer, protocol and request files, `vh-adlc gate planned`, and `git rev-parse HEAD`. Because of those denials I did not attempt `vh-adlc next`, `git diff --check`, PHP lint, phpcs, phpstan, phpunit, actionlint or Playwright. A WebFetch of https://bun.com/docs/runtime/yaml was denied. Fetches that succeeded: Renovate's bun manager page (patterns `/(^|/)bun\.lockb?$/` and `/(^|/)package\.json$/`, lock maintenance lists `bun.lock`), wrangler-action `action.yml` and README at 953926a (`packageManager` accepts `bun`, multiline `command`, and an existing installation is reused when `wranglerVersion` is unset), and GitHub's concurrency page (default `queue: single`, newer pending replaces older pending). I used no live provider control-plane access and made no writes.
PROPOSAL: Define the cutover outcome for a verification-stage failure and for a dispatch whose deployment is replaced while pending: flag state, route restoration or retry, and what is reported. State whether `workflow_dispatch` stays as a permanent main-only trigger or is removed after cutover. Align the AC-07 row and the Owner summary with that choice.

FINDING: F-02
KIND: judgement
SEVERITY: should-fix
WHERE: Open Questions line 380, Owner summary line 51, Context (Pre-existing maintenance observation) lines 81-87, Design (Pipeline and reuse) lines 235-238, Design (Browser and workflow checks) line 331
EVIDENCE: R-11 F-02 proposed either Open Questions or recorded owner decisions with dates for two choices: the site-only Renovate scope and the AGENTS.md verification-route change. This revision states both as design facts. Line 51 says "The feature adds its verification route to README/AGENTS and scopes managed updates to the introduced site refs and the shared Bun tooling". Lines 235-236 say "Enable only the `github-actions` and `bun` managers". Line 331 says "add its commands to the AGENTS.md verification route". The document does not attribute either choice to the owner. Every owner attribution it does give (lines 28, 41, 63, 74, 280, 380) covers other decisions. Open Questions says "None. The owner selected native static hosting and the official action on 16 November 2026", which does not cover these two choices. conventions/feature-documents.md:161-162 says "Every trade-off the document settles is an open question", and an answered question is folded in. The reviewer instructions say a needed change to repository instructions is raised for an Open Question and never assumed. The dispatch context says the root retained the site-only scope and the README/AGENTS routing. The document does not record that decision, its date or who made it, so a later reviewer or acceptance cannot tell an owner decision from an author choice. The coverage consequence is now disclosed at lines 53 and 83-87. That disclosure matches conventions/repository-security.md:63-68 and leaves Composer and the existing workflow refs with no updater.
PROPOSAL: Record the owner's decision on the site-only updater scope and on the AGENTS.md and README command routing, with its date, in the Owner summary or Context. If no such decision exists, raise each as an Open Question.

### R-13

TARGET: 0c525000fc391060e06900b0ab5496927a18dfb8

FINDING: F-01
KIND: judgement
SEVERITY: should-fix
WHERE: Design (First cutover and infrastructure ownership) lines 212-234, Design (Independent hosting) line 180, Owner summary lines 49 and 59-61, frontmatter covers lines 6-15, Test Plan AC-04, Test Plan AC-07
EVIDENCE: The AC-07 row now says "Exercise first-dispatch verification failure, skipped/cancelled/replaced deployment, upload/activation/smoke failure and unknown result in the owned fixture. Require flag disabling, restoration of the Pages routing baseline and an incomplete-cutover report." The AC-04 row likewise says "Inject failure in the owned cutover fixture and revert the site-specific routes and redirect". The document never says what this fixture is, where it lives, or which component it tests. Lines 214 and 220 assign the routes, the redirect and their reversion to "Lab's maintained infrastructure configuration". Line 231 states "Disable the publication flag, restore the site-specific routes and redirect" as an operator instruction and names no actor or tool. Line 225 makes `PACKAGES_SITE_PUBLISH_ENABLED` a repository variable. No path in `covers` (AGENTS.md, README.md, web/packages/, package.json, bun.lock, docs/prototypes/vhco-packages/, tests/packages/, renovate.json, .github/workflows/packages-site.yml) holds a cutover procedure or a component that reads a GitHub run state and acts on it. AGENTS.md says deployment-specific configuration belongs in vhco-pro/lab. So these fixture cases have nothing in this repository to test. One implementer would write a cutover orchestration script under tests/packages/ or web/packages/ that classifies run conclusions and calls the GitHub and Cloudflare APIs. That brings live-mutation code into this repository. Another would write a fixture that only simulates the classification and checks its own stubs. The second passes the row no matter how the real Lab procedure behaves. The row also cannot express states such as "pending replacement by another site run" or "unverified result" in a loopback fixture without a model of GitHub's run lifecycle, and the document does not define one. This revision expanded the case list in response to R-12 F-01. Tool record for this pass: `/home/m/.local/bin/vh-adlc lint docs/specs/vhco-packages-landing-page.md --repo . --plugin-pin 1ccf8f314575ece1f3fcc8e48c4fd804a1ca88ff` returned `"result":"pass"` with no findings at docs revision 1edeb5f32d868bbe761ef3221f350634cd6ff022. `vh-adlc fresh` with the same arguments returned local and remote SHA 0c525000fc391060e06900b0ab5496927a18dfb8. It reported the latest spec review as R-12 at 02486ac, stale with `baseline-changed`, `no-review` for implementation, and a clean feature tree. That confirms the R-12 row belongs to the Review Log table. The host permission mode denied a combined lint and fresh command, `vh-adlc gate planned`, a Bash grep of the pinned delivery pages (I used the Grep tool instead) and `actionlint`. `git diff --check 02486acf74f4365511121d1a61285cc41ea32b11 0c525000fc391060e06900b0ab5496927a18dfb8` produced no output. I did not attempt PHP lint, phpcs, phpstan, phpunit or Playwright after the actionlint denial. A final `git status --porcelain` was empty and `git rev-parse HEAD` returned the target. Public fetches that succeeded: vhco-pro/docs `knowledge/managed-renovate.md` at 2028365 (the baseline extends `config:recommended` and `helpers:pinGitHubActionDigests`, with `automerge: false` rules for github-actions majors and the `github-digest` datasource), Renovate's github-actions manager page, Renovate's config presets page, GitHub's concurrency page (`single` is the default `queue` value and allows at most one pending run), and the wrangler-action v4.1.3 release (tag at 953926a2e2182532811c01a25e53647d93bf07c0). The pinned cache has no `knowledge/managed-renovate.md`, so I read that page at the cited 2028365. I used no live provider access and made no writes.
PROPOSAL: Name the component that carries out the first-dispatch outcome handling and the cutover reversion, with its repository and path. If it lives in this repository, add it to `covers`. If it is a Lab procedure, replace the AC-04 and AC-07 fixture cases with a written manual procedure and pass conditions, or a reference to the Lab check that proves it. Also say which run states are simulated and which are observed live.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Context (Pre-existing maintenance observation) lines 91-95, Owner summary lines 54-57, Design (Pipeline and reuse) lines 247-250
EVIDENCE: Line 93 says "The owner-selected standard Renovate configuration covers repository dependencies through normal manager detection, including Bun, Composer and workflow refs." Line 249 says the GitHub Actions manager "tracks native action/container refs". The workflows contain pins that normal detection does not cover. First, .github/workflows/php.yml:26 fetches `https://github.com/opnsense/core.git e1020455a7bbb8a94ecdcec4fa94cd2ee3bdbbc1` inside a shell step. This is the "pinned core symbols" input that AGENTS.md makes part of local verification, and no Renovate manager extracts a SHA from a `run:` script. Second, php.yml:30 passes `php-version: '8.5.12'` to `vhco-pro/php-ci-action`, and that action is not in the github-actions manager's `uses-with` table. Third, php.yml:28 (`vhco-pro/php-ci-action@d60489c...`) and php.yml:47 (`vhco-pro/version-workflow/...@3b78b04...`) have no tag comment. conventions/delivery.md:124-127 says "A bare SHA without a recognized tracking comment may receive no updates." conventions/delivery.md:153-158 says a pin hardcoded in a script is invisible to Renovate and needs a custom manager. So the coverage claim is false for these pins. One implementer would take line 93 at face value and add custom managers or tag comments to the package workflows. That turns into the upgrade campaign the owner declined, and it changes workflow files that AC-07 says keep their existing definitions. Another implementer would add only the baseline file. The Owner summary repeats the broad coverage as the basis for the owner's choice.
PROPOSAL: Limit the coverage statement to what normal detection extracts. Name the core-symbol SHA, the PHP version input and the untagged reusable refs as pre-existing pins that stay outside this feature, consistent with the owner's no-campaign decision. If the owner wants them covered, raise that as an Open Question.

FINDING: F-03
KIND: judgement
SEVERITY: should-fix
WHERE: Acceptance Criteria AC-06, Test Plan AC-06, Design (Pipeline and reuse) lines 239-253
EVIDENCE: AC-06 requires "verified managed update coverage for its scanner/tooling". The row and line 251 require extraction only of the scanner image, its version and digest, and Wrangler and Playwright from `bun.lock`. The feature also adds `cloudflare/wrangler-action@953926a2e2182532811c01a25e53647d93bf07c0` with its `v4.1.3` comment (line 239) to a new workflow. Like the existing native-browser.yml:25-27, that workflow will need Bun installed, with a setup action and a Bun version pin. Renovate's github-actions manager extracts `oven-sh/setup-bun`'s `bun-version` through its `uses-with` depType. conventions/delivery.md:124-127 says an action SHA without a recognised tag comment may receive no updates. delivery.md:159-160 says "Adding a dependency includes confirming the updater will propose its next version". The site workflow's action refs and Bun runtime pin are not in the extraction proof, so the row passes when wrangler-action is pinned without a tracking comment or the Bun version sits where no manager reads it. The document also does not say how the site workflow installs Bun or that it reuses the shared Bun pin.
PROPOSAL: State how the site workflow installs Bun and pins its version. Extend the AC-06 extraction check to every ref the site workflow introduces, including wrangler-action with its version and digest and the Bun runtime version, not only the scanner image and the `bun.lock` packages.

FINDING: F-04
KIND: judgement
SEVERITY: nit
WHERE: Owner summary line 61, Design (Pipeline and reuse) lines 259-262
EVIDENCE: Line 259 says "an owner-authorised `workflow_dispatch` on `main` deploys", and line 61 calls the permanent trigger "ordinary owner-authorised redeployment". GitHub lets anyone with write access run `workflow_dispatch`. The design's controls are the publication flag, the main-only environment branch policy and successful verification (lines 261 and 268). None of them limits who can dispatch. A dispatch only redeploys the current `main`, which a merge to main can already do, so nothing built changes. But "owner-authorised" reads like an enforced control, and it is not one.
PROPOSAL: Describe the trigger as a main-only manual redeployment available to repository writers under the publication flag and environment policy, or name the native control that limits it to the owner.

### R-14

TARGET: 5efb35660b67d05a7123058947d9d7416f27629a

FINDING: F-01
KIND: judgement
SEVERITY: should-fix
WHERE: Design (First cutover and infrastructure ownership) lines 209-214 and 222-226, Design (Independent hosting) line 183, Scope line 139, Owner summary lines 48-49 and 59-61, frontmatter covers lines 6-15, Test Plan AC-04, Test Plan AC-07
EVIDENCE: Lines 209-210 say the operator procedure lives in `michielvha/vitepress` at `docs/internal/deployment/packages-homepage.md`. They also say "Write that procedure during implementation with the selected environment/Worker values, native GitHub run/variable commands and the Lab-owned route/redirect configuration under `vhco-pro/lab:cloudflare/packages-site/`." The sentence can mean two things. Either the procedure refers to the Lab configuration, or this feature's implementation also writes that configuration. The document does not say whether the Lab configuration already exists. It names no Lab or VitePress feature, tracker or approval for either deliverable. AGENTS.md puts deployment-specific configuration in vhco-pro/lab and Homelab procedures in michielvha/vitepress. It also says implementation and live changes "retain their separate design, review and owner approvals". `covers` lists only paths in this repository. So `vh-adlc fresh` and `feature_tree_clean` cannot see either external artifact. The pinned conventions/feature-documents.md Tasks section requires one commit per task naming the file it touches, and conventions/delivery.md:78 requires one PR per feature. Neither fits a commit in another repository. Even so, AC-04 can only pass after a review of "the named private manual cutover procedure against the Lab route/redirect plan" and a "later Lab infrastructure run". AC-07 depends on walking that procedure. Neither row says which external revision the evidence must pin. Unauthenticated fetches of https://github.com/michielvha/vitepress and of its raw `app/.vitepress/theme/style.css` both returned HTTP 404, so the procedure is reachable only with private access, and the document does not state that requirement for an implementation reviewer. One implementer would add cross-repository commits under this feature. Another would treat both artifacts as outside prerequisites and leave AC-04 unmet. The Owner summary has a related gap. Line 49 says Lab owns the setup, and lines 59-61 say "Any non-success result disables publication and restores the prior Pages routing baseline". It never says that this is a manual operator procedure kept in private VitePress, although the R-13 F-01 repair introduced that change. Tool record for this pass: `/home/m/.local/bin/vh-adlc lint docs/specs/vhco-packages-landing-page.md --repo . --plugin-pin 1ccf8f314575ece1f3fcc8e48c4fd804a1ca88ff` returned `"result":"pass"` with no findings at docs revision 1edeb5f32d868bbe761ef3221f350634cd6ff022. `vh-adlc fresh` with the same arguments returned local and remote SHA 5efb35660b67d05a7123058947d9d7416f27629a. It reported the latest spec review as R-13 at 0c525000fc391060e06900b0ab5496927a18dfb8, stale with `baseline-changed`, `no-review` for implementation, and a clean feature tree. `git diff --check 0c525000fc391060e06900b0ab5496927a18dfb8 5efb35660b67d05a7123058947d9d7416f27629a` produced no output. The host permission mode denied a combined lint/fresh/gate/next command, the separate `vh-adlc gate planned` and `vh-adlc next` calls, and `actionlint`. `vendor/bin` is absent, so I did not attempt PHP lint, phpcs, phpstan, phpunit or Playwright. A final `git status --porcelain` was empty and `git rev-parse HEAD` returned the target. These public fetches succeeded: the setup-bun v2.2.0 release (tag at 0c5077e51419868618aeaa5fe8019c62421857d6), the actions/checkout v7.0.1 release (tag at 3d3c42e5aac5ba805825da76410c181273ba90b1), Renovate's github-actions manager page (`docker` depType for `uses: docker://`, where digest handling is not stated; `uses-with` lists `oven-sh/setup-bun` `bun-version`; bare SHAs without a version comment are disabled), wrangler-action `action.yml` at 953926a (`packageManager` accepts bun, multiline `command`), and Cloudflare's Workers permissions page (Editor cannot create Workers, routes need Workers Routes Write, upload and deploy are allowed, workers.dev and preview settings are not named). The two VitePress fetches failed with HTTP 404. I used no live provider control plane and made no writes. Confirmed without finding: page.js has 45 lines, native-browser.yml:25-27 pins Bun 1.4.3 with setup-bun at 0c5077e, the feed.yml:45 group is `native-package-pages-publisher`, playwright.config.ts:4 collects only `./tests/browser`, the tree has no updater configuration, and the php.yml pins named at line 95 match php.yml:26-30 and 47.
PROPOSAL: Say whether the VitePress procedure and the Lab route/redirect configuration are deliverables of this feature or separate changes in those repositories under their own review and approval. Name their tracker or feature, and require the AC-04 and AC-07 evidence to record the exact external revisions reviewed. Add the manual private procedure and its owners to the Owner summary.

FINDING: F-02
KIND: judgement
SEVERITY: should-fix
WHERE: Test Plan AC-04, Test Plan AC-07, Design (Pipeline and reuse) lines 273-275 and 303-306, Design (First cutover and infrastructure ownership) lines 225-226 and 228-244, Context (Native hosting compatibility check) line 128
EVIDENCE: Line 275 says "The live cutover authorisation covers its first dispatch", and line 128 leaves edge behaviour to "the separately authorised cutover". AGENTS.md keeps separate approvals for live changes. Several proof items need live production or Lab actions, but the cutover sequence at lines 228-244 does not include them, and the rows do not say whether they are static, local or live. First, AC-04 says "Verify a later Lab infrastructure run preserves the pipeline-selected Worker content". That needs a live Lab apply after a pipeline deployment, and no cutover step or authorisation covers it. Second, AC-07 says "Walk the written operator procedure for a non-success initial dispatch and verify its flag, route-restoration and incomplete-cutover pass conditions against native interfaces". This could be a desk review, or a live drill that turns off the production flag and reverts routes on the real hostname. Third, AC-07 requires the site group to have "one running and one pending job, pending replacement and no running-job cancellation". The only job in that group is the flag-gated deployment job in the main-only production environment (lines 280-281, 303). So the behaviour can be observed only by queuing several real production deployments, unless it is a static check of the configuration against GitHub's documented semantics. Fourth, "Exercise an owned non-main rejection case" does not say whether that is the real production environment or a separate owned one. One implementer would run extra production deployments and a Lab apply under the cutover approval. Another would record config and document reviews. Each would claim the same rows. The R-13 F-01 repair asked which run states are simulated and which are observed live. This revision answered that only for the first-dispatch outcomes.
PROPOSAL: For each of these four items, state whether it is a static configuration or document check, a local simulation, or a live observation. Make every live item an explicit step of the authorised cutover procedure, or a named separately authorised action.

FINDING: F-03
KIND: judgement
SEVERITY: should-fix
WHERE: Scope lines 133 and 137, Design (Content and visual structure) line 156, Design (Browser and workflow checks) line 358, Owner summary lines 24-25, frontmatter covers line 7
EVIDENCE: The repository AGENTS.md "Project scope" says "This repository owns a reusable native OPNsense encrypted Git backup provider." The document adds a "generic homepage" at pkg.vhco.pro that lists VHCO package repositories (line 133, Owner summary line 24). It says "Additional entries are ordinary static content changes" (line 156) and keeps the page source "in this repository under `web/packages/`" (line 137). So other packages' entries would be maintained here too. AGENTS.md is in `covers`, but line 358 changes only its verification route. Every recorded owner decision (lines 31, 44 and 54) covers lifecycle, hosting or updater choices. None says that this repository's scope widens to host the shared package hub. The reviewer instructions raise a needed change to repository instructions as an Open Question and never assume it. One implementer would update the AGENTS.md Project scope paragraph. Another would leave it saying the repository owns only the provider.
PROPOSAL: Raise an Open Question on whether this repository's declared scope widens to own the shared pkg.vhco.pro hub, with AGENTS.md updated to match, or whether the hub stays here only for v1. Otherwise, record the owner's decision with its date.

FINDING: F-04
KIND: factual
SEVERITY: nit
WHERE: Sources line 981
EVIDENCE: The cited "[theme source](https://github.com/michielvha/vitepress/blob/main/app/.vitepress/theme/style.css)" is the source for the observed styling. An unauthenticated fetch of the repository and of the raw file both returned HTTP 404, consistent with the private repository that line 209 describes. A reader of this public document cannot open the citation. Nothing built changes.
PROPOSAL: Cite the public vhco.pro stylesheet or a sanitized excerpt, or mark the source as private.

### R-15

TARGET: a6fa7c297a4815e50a0f5fc602cfae250ebdce6e

FINDING: F-01
KIND: judgement
SEVERITY: should-fix
WHERE: Design (First cutover and infrastructure ownership) lines 213-222, Design (Pipeline and reuse) line 264, Owner summary lines 50-51, Acceptance Criteria AC-04, AC-06, AC-07, Test Plan AC-04, AC-06, AC-07
EVIDENCE: This revision makes `web/packages/README.md` a public deliverable. Line 213 says "This repository delivers the generic manual procedure in `web/packages/README.md`", and line 214 says it "names the operator steps, environment inputs, native GitHub run/variable commands, Cloudflare operations, baseline checks and restoration pass conditions". No acceptance criterion states this end state. AC-04 is about HTTP responses, AC-06 is about "The public page", and AC-07 is about independent page deployment. The procedure appears only as proof steps inside the AC-04 and AC-07 rows ("Review the owned public `web/packages/README.md` procedure", "Desk-review the owned public operator procedure"). Nothing bounds what the public procedure may contain. AGENTS.md says "Keep credentials, real configuration exports, private inventories ... outside this source repository", says "Use synthetic fixtures and sanitized evidence for public-facing documentation", and places "maintained Homelab procedures" in michielvha/vitepress. Line 221 sends "Homelab-specific inputs" to private VitePress, but the document never says which values count as generic and can appear in the README. Examples are the hostname, route patterns, variable and environment names, account or zone identifiers, Worker identity and the Lab path. The AC-06 privacy review covers only "rendered text and network requests" of the page. The blocking Gitleaks scan covers only "the actual `web/packages/public/` payload" (line 264), and `web/packages/README.md` sits outside that directory. So a README that publishes account or zone identifiers or other Homelab-specific inputs passes every row. One implementer would write a fully generic procedure. Another would include the live values the operator needs. This traces to this revision's repair of R-14 F-01. Tool record for this pass: `/home/m/.local/bin/vh-adlc lint docs/specs/vhco-packages-landing-page.md --repo . --plugin-pin 1ccf8f314575ece1f3fcc8e48c4fd804a1ca88ff` returned `"result":"pass"` with no findings at docs revision 1edeb5f32d868bbe761ef3221f350634cd6ff022. `vh-adlc fresh` with the same arguments returned local and remote SHA a6fa7c297a4815e50a0f5fc602cfae250ebdce6e. It reported the latest spec review as R-14 at 5efb35660b67d05a7123058947d9d7416f27629a, stale with `baseline-changed`, `no-review` for implementation, and a clean feature tree. A first combined `--version`/lint/fresh/gate/next command was denied by the host permission mode. The separate `vh-adlc gate planned` and `vh-adlc next` calls, `git diff --check 5efb356 a6fa7c2` and `actionlint` were also denied. Because of those refusals I did not attempt PHP lint, phpcs, phpstan, phpunit or Playwright. `git rev-parse HEAD` returned the target and `git status --short` was empty at the start. `git diff 5efb356 a6fa7c2` and `git show 1012715:docs/specs/vhco-packages-landing-page.md` succeeded. These public fetches succeeded: GitHub's REST pages for deployment branch policies and environments ("Anyone with read access to the repository can use this endpoint", and `deployment_branch_policy` with `protected_branches` and `custom_branch_policies` is returned). No fetch failed. I used no live provider access and made no writes.
PROPOSAL: Add a criterion with a new ID for the public generic cutover and restoration procedure. It should state its required steps and pass conditions and say that it holds no deployment-specific identifiers or Homelab inputs. List the values it may name and the values that stay in Lab or VitePress. Give it a proof row that also scans or reviews `web/packages/README.md`, and move the procedure checks out of the AC-04 and AC-07 rows into that row.

FINDING: F-02
KIND: judgement
SEVERITY: should-fix
WHERE: Design (First cutover and infrastructure ownership) lines 216-222 and 253, Owner summary line 51, Test Plan AC-04, Test Plan AC-07
EVIDENCE: The revision gives three different homes for cutover records. Line 51 says "Private deployment configuration and execution records remain with Lab and VitePress respectively". Line 221 says "The operator records Homelab-specific inputs and execution observations in private VitePress". Line 253 was not updated and still says "The first setup records the Worker identity, environment branch policy, disabled public preview settings and verified routes in Lab's deployment procedure". In this revision the procedure is no longer in Lab. It is in this repository's README (line 213). Line 217 says the Lab "approved rollout reference and exact reviewed commit are recorded before cutover", and line 218 says "Record the exact public procedure revision and the external Lab revision used for live evidence". Neither says where. The AC-04 row likewise says "Record actual observed cutover outcomes, source and external input revisions separately" without a location. The pinned standard requires evidence beneath each ticked criterion in this public document, and an implementation review gives `met` only for "executed evidence observed in this review". AC-04 and AC-07 are composite. They include private Lab inspection ("review its separately approved exact Lab inputs with authorised private access", "Inspect the exact reviewed Lab cutover configuration"), a native Cloudflare deployment record that needs account access, and one-time live cutover observations that a later reviewer cannot re-execute. The document does not say which items an implementation reviewer re-observes, such as public GETs to pkg.vhco.pro, native pkg fetches, or `gh` reads of the run and the environment policy (the environment endpoints allow any reader). It also does not say which items rest on recorded operator evidence, what access the reviewer needs, or how a reviewer without private Lab access rates the Lab item. Line 220 says "cross-repository freshness is reported separately" but names no report. One implementer would put sanitized run, deployment and revision identifiers in the AC evidence lines. Another would point the evidence at private VitePress, which a public reviewer cannot open. Under the second, AC-04 can only be `not verified` and `impl_review_clean` cannot pass. This traces to this revision's repair of R-14 F-01.
PROPOSAL: Choose one home for each record. Sanitized identifiers go in this document's evidence lines: run ID and attempt, Cloudflare version or deployment ID, response observations, public procedure SHA and Lab commit SHA. Homelab-specific values stay only in VitePress. Fix line 253 to match. In the AC-04 and AC-07 rows, name the items the implementation reviewer re-executes, the items accepted as recorded operator evidence, and the access each needs, including the verdict for the private Lab item when that access is absent.

FINDING: F-03
KIND: judgement
SEVERITY: should-fix
WHERE: Test Plan AC-07, Acceptance Criteria AC-07, Design (Pipeline and reuse) lines 280-283 and 318-322
EVIDENCE: The revision classified the four items R-14 F-02 named, but other AC-07 proof items still do not say whether they are static, local or live. "Check that PR verification has read-only GitHub permissions and can finish without a Cloudflare credential, failed verification prevents deployment, a disabled publication flag skips the deployment job and enabled successful main verification permits it" reads as executed behaviour. A later sentence in the same row, "Statically require the deployment job to depend on successful verification", says one of those checks is static, and the other three stay unlabelled. Observing the disabled-flag skip and the enabled main deployment needs real main runs. "Verify that successful source restoration serves the checked-out bytes and media types at the root and every asset URL" follows the local aggregate sentences, but AC-07 says "page rollback deploy[s] independently", and line 318 defines rollback as a new main commit through the production pipeline. So the item could be the local fixture, or a production rollback commit that no step of the authorised cutover includes. "Check that page publication does not invoke package tagging or publication while ordinary commit subjects retain their shared GitVersion meaning" names no method. One implementer would treat these as static or local checks. Another would push extra production deployments or a rollback commit to observe them. Each would claim the same row. This is the class R-14 F-02 raised, left open for these items.
PROPOSAL: Label each remaining AC-07 item as a static configuration check, a desk review, a local fixture run or a live observation. Tie every live item to a named step of the authorised cutover, or to a separately authorised action. State that source-restoration proof is local unless a production rollback is added to the cutover.

FINDING: F-04
KIND: judgement
SEVERITY: nit
WHERE: Owner summary lines 24-67, Context (Background and revision) line 73, Scope lines 140-141
EVIDENCE: Scope line 141 now says "Extend the AGENTS.md Project scope and verification route to name the v1 hub and its commands", and line 73 attributes the code home to the owner's 15 November decision at `1012715`. That record does say "The owner-selected v1 code home is the existing package-feed repository and publisher" and "The owner selected reuse of the existing publisher for v1". So the attribution is supported. That same decision bundled the code home with publisher reuse, which the 16 November direction replaced (line 75). The Owner summary mentions README and AGENTS commands (line 57) but not the change to the repository's declared Project scope. That scope change is the repository-instruction change R-14 F-03 raised. Nothing built changes.
PROPOSAL: Add one Owner summary sentence saying that AGENTS.md Project scope will name the v1 hub in this repository under the 15 November code-home decision, which the 16 November hosting change kept.

**Run notes:**
- **Checks that ran:** `vh-adlc lint` passed with no findings. `vh-adlc fresh` reported R-14 stale (`baseline-changed`), no implementation review and a clean feature tree.
- **Checks refused:** the host's don't-ask mode denied the combined command, `vh-adlc gate planned`, `vh-adlc next`, `git diff --check 5efb356 a6fa7c2` and `actionlint`. I did not attempt the PHP lint, phpcs, phpstan, phpunit or Playwright checks after those refusals.
- **Fetches:** both GitHub REST fetches (deployment branch policies and environments) succeeded. None failed.
- **Boundaries:** I made no writes to the repository, used no live provider access and gave no implementation verdicts.

### R-16

TARGET: 2d7d43bb6ec4c397125ea1b450e59ece14f0a186

FINDING: F-01
KIND: judgement
SEVERITY: should-fix
WHERE: Acceptance Criteria AC-08, Test Plan AC-08, Design (First cutover and infrastructure ownership) lines 225-227 and 260, Design (Pipeline and reuse) lines 272-274, Design (Browser and workflow checks) line 381, Test Plan AC-04, Test Plan AC-07
EVIDENCE: Line 227 says "Actual account/zone identifiers, live Worker identity, credentials, private hosts/inventories and deployment-specific inputs stay in Lab or private VitePress". AC-08 requires "synthetic examples under the existing repository secrecy policy". Only two checks enforce that. The first is the Gitleaks `dir --redact=100` scan of `web/packages/` (lines 272-274). It looks for credential patterns. It does not flag a Cloudflare account or zone ID (a bare 32-hex value), a Worker name or a private hostname. The second is the AC-08 desk review ("Apply the existing AGENTS.md secrecy rule to its synthetic examples"). A public reviewer cannot tell a real 32-hex account ID or a plausible Worker name from a synthetic one. The document defines no recognisable placeholder form, such as `<CLOUDFLARE_ACCOUNT_ID>` or a documented all-zero example, and the row lists no must-pass or must-fail examples. So a README that contains the live account ID, zone ID and Worker name passes every AC-08 check. The same gap applies to `web/packages/wrangler.toml`, which also sits under the scanned directory. A second public home gets no check at all. Line 260 and the AC-04 and AC-07 rows put "sanitized" response observations, run IDs and deployment/version IDs in this feature document's evidence lines. Nothing scans `docs/specs/` or defines what "sanitized" removes from a response observation. This revision added the secrecy bound (lines 225-227) and widened the scan in response to R-15 F-01. Tool record for this pass: `/home/m/.local/bin/vh-adlc lint docs/specs/vhco-packages-landing-page.md --repo . --plugin-pin 1ccf8f314575ece1f3fcc8e48c4fd804a1ca88ff` returned `"result":"pass"` with no findings at docs revision 1edeb5f32d868bbe761ef3221f350634cd6ff022. `vh-adlc fresh` with the same arguments returned local and remote SHA 2d7d43bb6ec4c397125ea1b450e59ece14f0a186. It reported the latest spec review as R-15 at a6fa7c297a4815e50a0f5fc602cfae250ebdce6e, stale with `baseline-changed`, `no-review` for implementation, and a clean feature tree. The host's don't-ask mode denied a combined `--version`/lint/fresh/gate/next command, the separate `vh-adlc gate planned`, `git diff --check a6fa7c2 2d7d43b` and `actionlint`. After those refusals I did not attempt `vh-adlc next`, PHP lint, phpcs, phpstan, phpunit or Playwright. `git rev-parse HEAD` returned the target, and `git status --porcelain` was empty at the start and at the end. `git diff a6fa7c2 2d7d43b`, `wc -l` of the prototype `page.js` (45 lines, matching line 27) and `ls web tests/packages renovate.json` (all absent) succeeded. Two public fetches succeeded: vhco-pro/docs `knowledge/managed-renovate.md` at 2028365, which the fetch tool returned only as a summary, and Renovate's github-actions manager page. A WebFetch of the public GitHub REST repository endpoint was denied by the host. I used no live provider or account access and made no writes.
PROPOSAL: Require the guide and `wrangler.toml` to use one documented placeholder form for account, zone, Worker and credential values. Add a local check that fails on any 32-hex identifier or unlisted hostname in `web/packages/` other than those placeholders and the allowed public URLs, and list its must-pass and must-fail examples in the AC-08 row. State what sanitizing removes from response observations before they are recorded in this document, and have the same check, or an explicit review step, cover the evidence lines.

FINDING: F-02
KIND: judgement
SEVERITY: should-fix
WHERE: Test Plan AC-04, Test Plan AC-07, Design (First cutover and infrastructure ownership) lines 218-222 and 260
EVIDENCE: The two rows give the private Lab review different roles. AC-04 says "External Lab review is rollout evidence reported separately; public behavior is verified through these actual reads without requiring private source access". AC-07 says "An unavailable private Lab review is reported as external rollout evidence not verified; it is not inferred from public-code checks". Line 222 says the evidence "distinguishes observed public checks from recorded Lab rollout review at its stated revision". The pinned standard defines `not verified` as a verdict on a whole criterion, and "A passing subset never upgrades a composite criterion". If the Lab review is part of the AC-07 proof, a reviewer without private access must return AC-07 as `not verified`, and `impl_review_clean` can never pass for a public reviewer. If it is not part of the proof, AC-07 can be `met` from public reads alone, as AC-04 says. One implementation reviewer would rate AC-07 `not verified` and another `met`. AC-04 also still says "reported separately" without naming where. The R-15 F-02 repair removed the matching phrase "cross-repository freshness is reported separately" from Design (old line 220) but kept it in the AC-04 row.
PROPOSAL: Say once, for both rows, whether the Lab review is part of the criterion's proof. If it is not, keep it as a recorded rollout reference with its Lab SHA and say that the AC-04 and AC-07 verdicts rest on the public re-observation. Name the one place the external rollout record is reported.

FINDING: F-03
KIND: judgement
SEVERITY: should-fix
WHERE: Owner summary lines 56-60, Context (Pre-existing maintenance observation) lines 95-102, Design (Pipeline and reuse) lines 275-286, Acceptance Criteria AC-06, Test Plan AC-06
EVIDENCE: Line 285, added in 2d7d43b, says "a read-only organization installation query returned no Renovate App, and the repository had no Dependency Dashboard issue". Line 286 says "Configuration and managed-bot activation remain implementation work". Installing the managed Renovate App is an organization-level GitHub change, not a file in `covers`. The document does not say who installs it, whether it covers selected repositories or all of them, or which approval applies. AGENTS.md:30-31 keeps implementation and live changes under separate owner approvals. An all-repository installation would also start onboarding in every vhco-pro repository. AC-06 cannot be met without that activation (line 282 and the AC-06 row), so the criterion depends on an action that no task, scope line or authorisation names. The Owner summary hides this. Line 60 says in the present tense that "Renovate proposes dependency PRs for supported, discoverable inputs", and the summary never says the App was found absent or that AC-06 waits on activating it. The line 285 claim cites no command or output, although the standard requires Design claims to cite one. The previous revision said the CLI token "could not verify App access". Listing organization installations needs organization admin read access, so a reader cannot tell whether the result was an authorised empty list. Line 102 says Dependabot security-update settings "were not inspected or changed". Pinned conventions/repository-security.md "Updaters and alerts" says "Where Renovate owns an ecosystem, leave Dependabot version updates and Dependabot security updates off" and says the Renovate App needs read access to Dependabot alerts for `vulnerabilityAlerts`. The design adds Renovate for every ecosystem but never checks those settings. The shared managed-renovate page at 2028365 also says a config file does not prove the App is installed.
PROPOSAL: Name App activation as an owner-approved organization action with its repository scope, outside this repository's commits, and make it a stated precondition or tracked residual for AC-06. Restate Owner summary line 60 as planned behaviour that depends on that activation. Cite the command and output behind line 285. Add a step that checks Dependabot security updates are off and Dependabot alerts are on when Renovate takes ownership.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Design (Pipeline and reuse) lines 321-326, Owner summary lines 52-53, Test Plan AC-07
EVIDENCE: AGENTS.md:40 says "Cancel superseded verification for the same PR or ref. Protected publication keeps its separate non-cancelling concurrency group." Line 326 makes that optional: "Read-only verification can cancel superseded work independently." It also leaves the placement open. GitHub's concurrency documentation, already cited in Sources, says a workflow-level group with `cancel-in-progress: true` cancels the whole in-progress run. If an implementer puts the verification group at workflow level, as the existing `native-browser.yml:9-11` does, a newer main push cancels a running deployment job. That contradicts line 324 ("the running site job finishes") and the non-cancelling publication rule. The AC-07 static checks cover an "independent site concurrency group" but not whether verification cancellation can reach the deployment job. One implementer would use job-level verification concurrency. Another would copy the workflow-level pattern or leave out cancellation entirely. Each would pass the row.
PROPOSAL: Require job-level concurrency for verification, keyed by PR number or ref with `cancel-in-progress: true`, and no workflow-level group. Add a static AC-07 check that no cancelling group applies to the deployment job.

FINDING: F-05
KIND: judgement
SEVERITY: should-fix
WHERE: Test Plan AC-07, Design (Pipeline and reuse) lines 287-292
EVIDENCE: The AC-07 row says "Evaluate the flag/main/verification condition cases locally against the workflow configuration". It names no method. GitHub has no native local evaluator for workflow `if:` expressions, and actionlint checks syntax and types without evaluating cases. One implementer would add an expression evaluator, a third-party runner such as `act`, or an npm expression package. That adds the extra dependency chain the owner scope excludes. Another would write a small custom interpreter that tests its own reading of the expressions and passes whatever the workflow says. A third would do a desk review. Each claims the same "local" item.
PROPOSAL: Label this item as a static or desk check of the exact `if:` expressions against GitHub's documented contexts, with the expected outcome listed for each case. Alternatively, name the existing tool that evaluates them and state that no new dependency is added.

FINDING: F-06
KIND: judgement
SEVERITY: should-fix
WHERE: Design (Independent hosting) lines 185-188, Design (First cutover and infrastructure ownership) lines 229-233 and 237, Design (Independent hosting) line 209, Context (Native hosting compatibility check) line 125
EVIDENCE: Line 125 records that the validated dry run used a configuration "with the proposed exact-root and `/_site/*` routes". Line 185 lists the contents of the generic `web/packages/wrangler.toml` (assets directory, `404-page`, workers.dev and preview disabled) but does not say whether routes are included or excluded. Line 229 has bootstrap run the official action's native `deploy` command. With routes in the config, `wrangler deploy` attaches them at bootstrap. That would activate public routes before the workers.dev and preview readback, contradicting line 209 ("Initial route activation follows the bootstrap's successful site upload and settings readback"). It would also give the routes two owners, the repository config and Lab's infrastructure configuration (lines 188 and 237). One implementer would copy the validated dry-run config with routes. Another would leave routes out. The routine `versions upload` and `versions deploy` path does not touch routes, so ordinary CI would not reveal the difference.
PROPOSAL: State that `web/packages/wrangler.toml` declares no routes and that only Lab creates them. Add a static AC-04 or AC-07 check that the config has no `route` or `routes` key, or else define the bootstrap ordering when routes are present.

FINDING: F-07
KIND: judgement
SEVERITY: should-fix
WHERE: Scope line 142, Owner summary lines 50 and 58, Design (First cutover and infrastructure ownership) lines 214-227
EVIDENCE: AGENTS.md:21-22 says "Deployment-specific configuration belongs in vhco-pro/lab and maintained Homelab procedures belong in michielvha/vitepress." The design keeps a maintained operator procedure for the production pkg.vhco.pro cutover, flag dispatch and restoration in this repository's `web/packages/README.md` (line 214). Its Homelab-specific values go to VitePress (line 258). Scope line 142 changes AGENTS.md only to "name the v1 hub and its commands". It does not say whether AGENTS.md will state that a generic, placeholder-only deployment procedure may live here. Owner summary line 58 records the code-home decision, not this split. The reviewer instructions treat a needed change to repository instructions as a judgement finding for an Open Question and say it is never assumed. One implementer would leave AGENTS.md:21-22 unchanged, and the README would then read as conflicting with it. Another would add a carve-out that no owner decision records.
PROPOSAL: Record the owner's decision, with its date, that the generic cutover procedure lives in this repository and that AGENTS.md Project scope will say so. Otherwise raise that as an Open Question.

FINDING: F-08
KIND: factual
SEVERITY: nit
WHERE: Acceptance Criteria AC-08, frontmatter status_description line 3
EVIDENCE: AC-08 says "The already included public generic guide", and status_description says "the existing generic guide made verifiable". `ls web` at the target reports "No such file or directory", so `web/packages/README.md` does not exist yet. The words mean "already in scope", but they read as a file that already exists. Nothing an implementer builds changes.
PROPOSAL: Write "The public generic guide in `web/packages/README.md`" in AC-08 and drop "existing" from status_description.

## Sources

- [GitHub artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations) documents digest-bound provenance and workflow/source identity.
- [Native attestation generation](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations) documents the producing job, native action and required OIDC/attestation permissions.
- [GitHub CLI verification](https://cli.github.com/manual/gh_attestation_verify) documents verification of the downloaded artifact and signer restrictions.
- [Verified Bun setup action](https://github.com/oven-sh/setup-bun/tree/0c5077e51419868618aeaa5fe8019c62421857d6) provides the native `bun-version` installation input at verified v2.2.0.
- [Verified checkout action](https://github.com/actions/checkout/tree/3d3c42e5aac5ba805825da76410c181273ba90b1) is the selected v7.0.1 source checkout.
- [Official Wrangler action metadata](https://github.com/cloudflare/wrangler-action/blob/953926a2e2182532811c01a25e53647d93bf07c0/action.yml) declares the Bun package manager and multiline native command inputs.
- [Worker CI source](https://github.com/vhco-pro/worker-ci-action/blob/5ef3cf6b375c6247a28fffb7c19b8d6c5aae97c3/scripts/verify.ts) rejects static assets in its single-module profile.
- [Worker deploy source](https://github.com/vhco-pro/worker-deploy-action/blob/bcf11171c29a610971f45a867daba8c684c7d198/scripts/activate.ts) verifies exact tag and module release inputs.
- [Shared static-site standard](https://github.com/vhco-pro/docs/blob/2028365d39ff0bebf7698fff975ae04d0dac133e/conventions/cloudflare-static-sites.md) records the merged official-action default and visibility-based CI policy.
- [Native Worker commands](https://developers.cloudflare.com/workers/wrangler/commands/workers/) document upload and deployment through native version annotations.
- [Workers permissions](https://developers.cloudflare.com/workers/authorization/workers/) documents existing-Worker Editor access and separate route-write permissions.
- [GitHub concurrency](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency) documents separate group names, the default single-pending replacement and running-job cancellation.
- [GitHub reruns](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs) documents the 30-day window, 50-attempt limit and original actor/source identity.
- [Gitleaks upstream CLI and images](https://github.com/gitleaks/gitleaks) documents free native directory scans and the official container. Its [MIT licence](https://github.com/gitleaks/gitleaks/blob/v8.30.1/LICENSE) permits this use.
- [Renovate Bun manager](https://docs.renovatebot.com/modules/manager/bun/) documents joint `package.json` and `bun.lock` maintenance.
- [Bun YAML API](https://bun.com/docs/runtime/yaml) documents the built-in parser used to read the single workflow scanner pin.
- [Renovate GitHub Actions manager](https://docs.renovatebot.com/modules/manager/github-actions/) documents native `uses: docker://` extraction. The [shared updater baseline](https://github.com/vhco-pro/docs/blob/2028365d39ff0bebf7698fff975ae04d0dac133e/knowledge/managed-renovate.md) defines consumer configuration and live App-access verification.
- [Worker subdomain settings API](https://developers.cloudflare.com/api/resources/workers/subresources/scripts/subresources/subdomain/) documents native workers.dev and preview-access readback and updates.
- [Cloudflare static assets](https://developers.cloudflare.com/workers/static-assets/) documents native static hosting and its deployed asset versions.
- [Cloudflare routes](https://developers.cloudflare.com/workers/configuration/routing/routes/) documents path matching, query-string behaviour and the proxied-host requirement.
- [Cloudflare Single Redirect settings](https://developers.cloudflare.com/rules/url-forwarding/single-redirects/settings/) documents static targets and query-string removal.
- [Cloudflare redirect rules](https://developers.cloudflare.com/rules/url-forwarding/) documents native redirects, their execution and availability across plans.
- [Wrangler configuration](https://developers.cloudflare.com/workers/wrangler/configuration/) documents the static-assets and route configuration used by the local dry run.
- [Cloudflare Direct Upload](https://developers.cloudflare.com/pages/how-to/use-direct-upload-with-continuous-integration/) documents publishing a static directory through native tooling.
- [VHCO homepage](https://vhco.pro/) supplies the public visual reference. The [private VitePress theme source](https://github.com/michielvha/vitepress/blob/main/app/.vitepress/theme/style.css) was read through authorised local access and is unavailable to unauthenticated readers.
- [Company mark](https://vhco.pro/landing/vhco-github.png) is the existing VH & Co logo.
- [Current installation guide](../installation.md) documents version calculation, off-host native package preparation, signing and client trust.
- [Prototype asset provenance](../prototypes/vhco-packages/README.md#asset-sources) records the logo and font sources and notices.
