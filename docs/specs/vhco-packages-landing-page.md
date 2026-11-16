---
status: draft
status_description: "R-5 owner choices recorded; technical revision and logo notice prepared for review."
issue: null
goal: "Visitors to pkg.vhco.pro can identify VHCO package repositories and reach their setup and signing instructions."
covers:
  - README.md
  - web/packages/
  - docs/prototypes/vhco-packages/
  - scripts/feed-pages-assets.mjs
  - scripts/feed-site.mjs
  - scripts/feed-inventory.mjs
  - tests/package/feed-inventory-test.mjs
  - scripts/publish-feed.sh
  - scripts/feed-dispatch.sh
  - scripts/feed-recovery.sh
  - scripts/feed-close.sh
  - scripts/feed-preflight.sh
  - scripts/feed-retirement.sh
  - scripts/feed-journal-generation.jq
  - scripts/feed-history.jq
  - scripts/feed-bundles.sh
  - scripts/retain-feed-bundles.sh
  - tests/package/feed-http-inputs.mjs
  - tests/package/feed-preflight-test.sh
  - tests/package/feed-publisher-http.mjs
  - tests/package/hosted-feed-content.sh
  - tests/browser/packages.spec.mjs
  - tests/browser/packages.config.mjs
  - .github/workflows/php.yml
  - .github/workflows/feed.yml
  - .github/workflows/feed-fixture.yml
---

# VHCO Packages landing page

## Context

### Owner summary

Give `pkg.vhco.pro` a VHCO-branded homepage listing its package repositories and setup guides.
The first entry is the published OPNsense repository and encrypted Git backup plugin.
Use the actual company logo, Inter font, brand gradient and light/dark themes.
A logo-specific rights notice accompanies the company mark.
The static page supports reading and links through HTML, with theme selection and URL copying as browser enhancements.

The existing protected publisher carries the page in its approved candidate and recovery archives.
A reviewed homepage-only update reuses the approved package and tag, preserving its version.
Public byte, content-type and HTTP status checks join native package verification before closure.
An explicit 404 document preserves the package clients' missing-path behaviour.

Recovery restores the prior served page and catalogue and verifies metadata for the recovery attempt.
Replay uses the original predecessor, including after a lost closure response.
An empty predecessor is verified as an empty site.
A predecessor serving a bootstrap recovery page is verified as that page with an empty catalogue.
Completed catalogue withdrawals carry forward with `authorize_retirement=false` for page-only updates.

Complete pagination replaces the current 25-deployment and single-page journal read limits.
Incomplete, inconsistent or changing inventories hold publication.
GitHub's separate 1,000-assets-per-release quota remains a capacity limit, with a hold before further feed publication when required retention exceeds it.
Approved public-file provenance, the existing Gitleaks checks and a final payload review cover public content.
The protected job verifies page commits against main and their successful source-CI run.
Its required environment approval records manual review of the exact run's bundle inputs.
Retained page-source metadata stays inside the archives, and publication mode is bound into the approval and submission record.

The committed prototype passed 38 local Chromium/Firefox scenarios.
Production assembly, paginated inventory, native recovery and live Cloudflare checks remain planned implementation proof.
The specification stays draft for independent review and final owner acceptance.

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
The current reader holds on a journal next-page link or 100 journal records and accepts one Pages inventory page of at most 25 deployments (`scripts/publish-feed.sh:61-67,164-174`).
GitHub documents deployment-list page parameters and next-page links, while Cloudflare documents page parameters and result pagination metadata.
The pagination design below replaces these single-page restrictions.

### Prototype verification

The 38 focused prototype scenarios passed locally with the repository's locked Playwright 1.59.1 in Chromium and Firefox.
The checks exercised six viewport sizes in both themes, keyboard access, theme persistence, URL copying, denied clipboard/storage access, explicit missing-route HTTP 404 responses, independent-channel signing guidance and reading with JavaScript disabled.
The R-1 copy-state, signing-text and missing-route regressions first failed against the original prototype, then passed after correction.
Their failing output remains under ignored `work/packages-preview-r1-red-host/`.
The logo-notice regression also failed in both engines before the notice and link were added, then passed in the complete 38-case run.
Its initial output remains under ignored `work/packages-preview-logo-red/`.
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
The logo uses the owner-selected `VHCO-LOGO-NOTICE.txt`, reserving VH & Co's logo rights and permitting display and redistribution with this project when that notice is retained.
The source, preview and published asset sets retain this notice with `vhco.png`.
Inter retains its `INTER-LICENSE.txt` notice and both assets retain their provenance.
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
It validates the explicit asset list, `VHCO-LOGO-NOTICE.txt`, `INTER-LICENSE.txt` and top-level `404.html` and rejects collisions with existing package, catalogue and publication metadata paths.
The same preparation step places the approved recovery page assets into the recovery directory before either archive is retained.
Both archives are independently downloaded and digest-verified through the existing retention commands.

The helper also provides a loopback-only static serving command for the staged production directory.
`tests/browser/packages.config.mjs` starts that server with Playwright's webServer facility, and `tests/browser/packages.spec.mjs` exercises the staged files.
The read-only `.github/workflows/feed-fixture.yml` runs that focused Chromium/Firefox suite with the existing locked browser dependency, plus the inventory HTTP fixtures in `tests/package/feed-inventory-test.mjs`.
Its existing caller in `php.yml` provides public PR/main coverage.
The design prototype retains its own focused test configuration.

### Public content checks

Assembly copies only the explicitly approved public files from the reviewed page commit, byte-for-byte, and verifies their SHA-256 values in the staged site.
The repository's existing pinned Gitleaks job scans the source history.
For each new page-source commit, the retained `site.json` records the exact `ci_run` and `ci_attempt` for a successful main-push `.github/workflows/php.yml` run.
The site adds exact file-list and source-provenance checks to that established secret-checking path.
Retained metadata and private source files fail the served-manifest allowlist.
The protected job fetches that run/attempt from GitHub and requires the expected repository, page SHA, main branch, push event, workflow path and success conclusion, plus a successful required `php` job that includes the adopted PHP/Gitleaks checks.
Missing, failed, skipped, mismatched or unavailable CI proof holds before feed publication.
The same proof is required for a new page-bearing bootstrap recovery source.
An established page-bearing recovery retains its previously approved source and CI metadata from the selected baseline.

A reviewer inspects every final text asset and the page's request URLs for deployment-specific addresses, credentials, configuration exports and private key material before approving the protected publication job.
The existing required `signed-feed-production` environment approval, associated with the exact workflow run and its fixed candidate/recovery input digests, is the manual payload-review record.
GitHub enforces that approval before the job executes.
Dispatch binds it to the retained bytes by checking the run inputs against the downloaded archives and their digests before effects.
The signing paragraph directs readers to the maintained guide's independent trusted-channel check.

### Publication and recovery

Candidate and recovery bundles include `index.html`, top-level `404.html`, styles, browser script, company logo, font, logo notice and font licence whenever they carry a page.
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
Site verification is part of candidate verification, `verify_recovery` and `verify_unchanged_feed`.
For an open ordinary candidate, a site-byte, media-type or status mismatch follows native verification failure: authorised recovery may run; otherwise the attempt holds.
A successful Pages deployment with incorrect site responses is a verification failure.
For a confirmed terminal recovery, a site mismatch makes `verify_recovery` fail and uses the existing one-identical-byte-retry-per-separately-authorised-dispatch rule.
A lost or ambiguous deployment state, wrong marker, consumed retry authorisation or failure on an already closed generation holds.
For rejection closure and failed-candidate closure, a failed site check in `verify_unchanged_feed` prevents closure and holds for diagnosis.
The retirement-finalisation branch keeps its existing verification hold: site failure prevents trust finalisation or closure and cannot itself authorise restoration of a withdrawn trust state.
Candidate site verification runs before entering any new trust-finalisation step.
For an established predecessor, unchanged-feed closure checks the actual prior served site's retained bytes and routes.
For a bootstrap predecessor with `canonical_deployment == null`, `verify_unchanged_feed` requires that empty provider state and HTTP 404 at the root, an unknown path and every catalogue alias.
It applies that empty-state check to rejection closure and failed-candidate closure even when the proposed bootstrap recovery archive contains a homepage.
That recovery archive's page-byte check runs after a recovery deployment becomes live.
A prior closure may also refer to a deployed empty-catalogue bootstrap recovery.
That predecessor has a live deployment and may serve the homepage with HTTP 200, while catalogue aliases return HTTP 404 and its retained archive has no `release.json`.
`verify_unchanged_feed` selects this branch from the digest-verified selected archive's catalogue shape and its journal provenance, independently of whether the prior deployment ID is empty.
It checks the actual retained page and absent catalogue responses.
Subsequent recovery construction retains that page and its provenance, omits `release.json` and all catalogue aliases, and generates the current recovery marker and Pages manifest.
The distinction is between no prior deployment, a deployed catalogue-absent archive, and an archive with an authenticated catalogue.
Every closure path verifies the site state appropriate to the selected shape and actual deployment.
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
The protected `publish` dispatch adds `page_source`, `page_only` and a conditional bootstrap `recovery_page_source` input.
`page_source` is the approved 40-character page commit SHA for a page-bearing candidate, separate from the package source.
The protected job fetches the repository's main ref, verifies that commit exists and is an ancestor of the fetched main commit, and compares it with the candidate's retained `site.json` source.
It passes the expected page SHA to `feed-dispatch.sh` and `feed-preflight.sh` for independent metadata equality checking before submission.
For a page-bearing candidate, a missing, malformed, unreachable or mismatched page SHA holds.
An original retained pre-homepage submission may replay with its legacy input shape and artifact pair, using the verified legacy root HTTP 404 expectation.
For a page-bearing bootstrap recovery, `recovery_page_source` supplies its separately approved SHA for the same main-ancestry and retained-metadata checks.
Established recovery is checked against the selected prior archive's approved provenance; legacy recovery uses its verified pre-homepage archive.
Bundle preparation checks out that exact page source and records it with the complete site asset list in `site.json`, which is retained inside the bundle.
`site.json` contains the approved page source SHA, its verified `ci_run`/`ci_attempt`, and an explicit map of served site paths, SHA-256 values and expected media types.
It is retained archive metadata and is excluded from the Pages manifest.
Candidate preflight validates the source SHA and every listed file's bytes and media type.
The Pages paths must equal the union of those listed site paths and the approved native package, catalogue and publication-metadata paths.
That native set is derived from the verified release manifest, retained advertised-package history, existing catalogue aliases and generation marker.
Preflight rejects unlisted paths, missing entries, collisions and any attempt to publish `site.json` itself.
Established recovery retains the prior served page source and assets, checked against the actual served baseline selected below.
A page-bearing bootstrap recovery uses its explicitly approved page SHA.
Each role's approved bundle digest binds its own source metadata and bytes.
The source is provenance for the static page and does not change package release identity.
New retained approvals and `submission-started` records include the boolean `page_only` mode alongside the page source and candidate/recovery digests.
Reconciliation derives mode from that approved submission record and checks that the dispatch input agrees before any upload, journal append or retirement action.
A mismatch holds in both directions, including on a retirement release.
Older pre-homepage package submissions use their original approval schema and implicit `page_only=false`; replay preserves that schema's existing hash and fields.
A new submission always records its mode explicitly.
Carried-forward withdrawal recognition requires the recorded page-only mode, the verified native-byte identity and the completed journal evidence.

The new candidate archive contains the approved page and the currently verified catalogue and package files.
The recovery archive contains the prior complete served page and catalogue, plus every package byte required by retained history.
For a page-only update the advertised package history union remains identical and the package generation marker retains its existing meaning.
The candidate and recovery archive digests, submission attempt and correlated Pages deployment distinguish the publication.
Public site readback prevents an unchanged package marker from being treated as proof of the new page.
The content-addressed archives are retained under the existing release tag using fresh digest names.
Existing release assets are preserved and their retained digests are verified independently.
A page update requires neither a new package build nor a moved tag.
The protected workflow uses its reviewed operational scripts for the updated verification contract and separately checks the existing package identity.

### Completed catalogue withdrawals

A page-only dispatch requires `authorize_retirement=false`; `true` holds before submission.
For a new submission it proves that the native catalogue, package bytes and release identity match the selected predecessor archive and its live deployment.
Replay uses the original submission's pinned predecessor archive and original inputs for that proof.
The predecessor's verified `withdrawn` path is carried into the new closure and its withdrawn aliases must remain HTTP 404.

If the reused release manifest includes a completed retirement plan, the publisher checks the earlier journal prefix for its completion evidence.
The same retirement attempt must have a `trust-finalization-pending` row whose `scope` matches the canonical retirement-plan digest and a `verified-closure` whose `withdrawn` matches that plan's path.
The pending row's deployment and source must match that closure.
This lookup traverses earlier verified generations, because a later submission resets the reducer's current retirement field.
Missing, ambiguous or conflicting completion evidence holds.

Both the new-submission and reconciliation branches recognise this proved carried-forward case.
They validate its completed evidence and withdrawal responses while requiring no new retirement authorisation or trust-finalisation row for the page-update attempt.
The `retirement == {}` guard, the non-empty-plan authorisation branch and the `verify_retirement` reconciliation branch all distinguish this case from a new retirement operation.
A new, changed or incomplete retirement under page-only mode holds and requires the regular separately authorised retirement path.
The package-publication retirement path uses its native approval and operator-evidence checks.

### Selecting predecessor history and recovery bytes

`.github/workflows/feed.yml` delegates history-input preparation to `scripts/feed-dispatch.sh`.
Under the existing workflow concurrency lock, dispatch reads the complete validated journal and uses the same selection rule as `publish-feed.sh`.
For a new candidate it selects the last verified closure after confirming that any latest submission is resolved.
For replay, when the latest submission matches the requested candidate digest, it selects the closure named by that submission's `predecessor`, even when the submission itself already has a closure.
An empty recorded predecessor selects the original bootstrap checkpoint.
The replay also validates the submitted candidate/recovery pair and approved source identities against the original record; a mismatch holds.
That original predecessor is the baseline for history, recovery-archive provenance and page-only native-byte comparisons throughout replay.
Preparation of a new bundle selects the current closed baseline; replay validates its already retained pair against its own original predecessor.
The replay's actual live deployment may be its own candidate or recovery, and reconciliation verifies that recorded deployment.
It never requires the original predecessor to remain live after the replayed submission has deployed.
For an established feed it downloads `history-<closure.history>.json` from the release named by that closure, verifies its SHA-256 and supplies those bytes to preflight and `FEED_HISTORY`.
The fixed-name `advertised-packages.json` remains the initial seed for a feed with no predecessor closure, subject to the existing bootstrap/checkpoint validation.
An established dispatch never supplies that old seed in place of the selected predecessor history.
`publish-feed.sh` independently rereads the complete journal and verifies that its selected predecessor and retained checkpoint match the dispatch selection before effects.
A changed or unresolved predecessor holds the dispatch.
A replay after the closure POST committed but its response was lost therefore supplies the original parent history, retains the existing attempt and reconciles its existing closure.

For an unchanged page-only history union, the desired successor digest equals the independently verified predecessor history digest.
The publisher may reuse an existing `history-<digest>.json` only when it matches those verified predecessor bytes exactly.
It still retains and independently reads back a new approval asset binding the new candidate/recovery digests, predecessor attempt, package marker and history digest before submission.
An existing successor history without its matching approval remains a hold whenever it differs from the verified closed predecessor history.
An absent or conflicting predecessor, changed history bytes, lost approval readback or unresolved journal read also holds.
Existing asset files and immutable tags are preserved.

`feed-dispatch.sh` provides a read-only preparation entry point for new bundles that resolves the currently closed baseline and downloads its retained archives using the operator's existing GitHub CLI login.
It replays the journal prefix through the selected closure to find the initiating submission and its pinned candidate/recovery digest pair.
A closure with no recovery sequence selects the candidate archive.
A closure with a valid recovery sequence whose deployment differs from `recovery-required.source` selects the pinned recovery archive.
Conflicting or incomplete journal relationships hold preparation.
The archive is downloaded from the submission's retained release and digest-verified.
`feed-site.mjs` uses that selected archive when assembling the proposed recovery bundle.

Preparation's archive selection uses GitHub journal and release reads.
For a new submission, the protected publish job repeats the selection and checks provider correlation and the actual live predecessor using its existing Pages environment credential.
For a replay it verifies recovery provenance and page-only byte identity against the original predecessor, then reconciles its own recorded live deployment.
Both paths use the paginated inventory reader below.
Incomplete inventory, ambiguous correlation, missing archives or mismatched pinned identities hold before effects.

The recovery comparison requires exact equality of the prior served site's asset set and bytes and its retained `site.json` page-source metadata.
For the native catalogue it compares the presence and bytes of `meta.conf`, `meta.pkg`, `meta.txz`, `packagesite.pkg`, `packagesite.txz`, `data.pkg` and `data.txz` at the root and every retained catalogue path.
Required absent aliases and withdrawn catalogue paths stay absent.
`release.json`, `generation.json` and `pages-manifest.json` have their publication roles and are verified separately from that byte-equality set.
For a baseline with an authenticated catalogue, the recovery's `release.json` describes its version, package and catalogue hashes, signing identity and any retained predecessor catalogue; native verification checks those identities against the recovered bytes.
That manifest is constructed from the selected baseline's verified release information under the existing recovery schema.
For a selected catalogue-absent bootstrap recovery, the new recovery has no `release.json` and verifies the retained page, catalogue HTTP 404 responses and required advertised package bytes.
When the predecessor closed on its candidate, the new recovery uses its own recovery marker and manifest alongside that candidate's exact page and native catalogue.
When the predecessor closed on its recovery, the new recovery likewise keeps that archive's exact page and native catalogue and constructs metadata for the current recovery attempt.
In both cases `generation.json` uses the current recovery's approved marker, and `pages-manifest.json` is rebuilt for its complete asset and required-package set.
Advertised package files are checked separately against the full required history, so the recovery archive can also retain package bytes advertised by a failed candidate.
When a recovered predecessor serves a catalogue, the page-only approval pins the package source and release identity authenticated by that catalogue, independently of the failed candidate's version.
Previously advertised failed-candidate packages remain in retained history.
The candidate's package marker and the recovery's attempt marker retain their existing distinct roles and are verified through their respective existing contracts.
An older bundle without a page uses the legacy root HTTP 404 rule above.
A prior closure that ended on recovery is tested through this same archive-selection path.

### Complete inventory reads

`scripts/feed-inventory.mjs` owns journal, Pages-deployment and release-asset inventory reads used by dispatch, publication and the retention commands.
It uses Node's existing HTTP runtime and the credentials already available to each caller.
Read-only preparation obtains GitHub access through the existing CLI login, and the protected job supplies its repository token and Pages environment credential.
Requests stay on the configured API origin and selected journal, Pages project or release-asset collection with its repository/project and environment scope.

The GitHub reader requests up to 100 journal records per page and follows the advertised next-page links through the terminal page.
It accepts a full terminal page of exactly 100 rows when no next link exists.
It validates every page as an array, rejects repeated page URLs or duplicate record IDs, and preserves the complete authoritative record set for the existing journal reducer.
Next-page links must retain the configured API origin and resource/filter scope.

The Pages reader requests 25 production deployments per page and reads every numbered page reported by `result_info`.
It validates page numbers, page size, counts, total pages and total count across the traversal, including an empty inventory.
The accumulated unique deployment count must match the advertised total.
The page size sets request size and the total inventory may span multiple pages.

The APIs provide separate responses for each page.
In the protected job, the reader obtains two complete views under the existing single-writer lock and requires identical authoritative journal records and identical Pages deployment identities/correlation metadata.
Read-only preparation performs its consistency reads outside that workflow lock; its selection is advisory until the protected job repeats and verifies it.
Pages stage progress is read fresh for the normal reconciliation outcome check.
The protected job then checks the actual canonical deployment before effects.
Changes between views, missing or malformed pages, inconsistent pagination, duplicate identities, rate-limit or request failures and the existing job deadline hold the run.
An incomplete response never becomes a shorter accepted inventory.
The reader performs GET requests and returns validated data to the existing publication flow.

### Retained release assets and capacity

The release-asset reader resolves the selected release ID and traverses its asset-list pages through the GitHub API's terminal page.
It requires unique asset IDs and names and keeps the complete mapping for digest-named archives, history and approval records.
`feed-bundles.sh`, `retain-feed-bundles.sh` and the publisher resolve names against that complete inventory, download by the selected asset identity and verify the expected content bytes or SHA-256.
Assets beyond the first list page receive the same checks.

GitHub permits at most 1,000 assets per release.
Before each retention phase uploads new files, it counts the missing names required by that phase against the complete asset inventory.
The archive-retention phase accounts for candidate and recovery archives; the protected publisher accounts for any missing approval and history assets before submission.
An existing exact asset is read back and verified for reuse.
Insufficient capacity or an upload failure holds feed publication and reports the release, observed count and required missing names.
A partial retention failure preserves completed immutable uploads for an identical-byte retry, while the active feed keeps its existing generation.
Capacity handling preserves retained history and tags; a storage or retention redesign requires its own reviewed decision.
The owner selected this quota hold for v1.

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
- [ ] AC-05: Package and page-only publication and recovery verify their approved page/catalogue state, reconcile the recorded publication mode, traverse multi-page inventories and carry completed withdrawals without new retirement authorisation under the single-writer contract.
- [ ] AC-06: The public page contains repository information without private deployment inputs or credentials, uses its glossary terms consistently and links to maintained package version information and the installation guide's independent trusted-channel verification of signing fingerprints.

## Test Plan

| Criterion | Proof |
| --- | --- |
| AC-01 | `scripts/feed-site.mjs` stages `web/packages/`; the dedicated packages Playwright configuration starts its loopback server in `feed-fixture.yml`. Playwright opens that staged page, checks the actual repository identifier and URL, follows the local setup anchor and validates each public reference's final route and expected document. A two-entry synthetic fixture verifies that an additional authored repository can be represented without another origin. |
| AC-02 | Chromium and Firefox exercise light/dark at 320×568, 390×844, 844×390, 768×1024, 1280×720 and 1440×900. Assert horizontal containment, heading readability, 44-pixel buttons, focus visibility and setup reachability. Inspect representative mobile and desktop captures. Exercise reduced motion and retain an actual 200-percent browser-zoom procedure with its effective viewport. |
| AC-03 | In Chromium and Firefox copy the repository URL, verify the clipboard result and status, choose a theme, reload and verify preference persistence. Run clipboard-denied, storage-denied and JavaScript-disabled contexts. The denied clipboard case after a successful copy selects the actual URL, resets the button label and explains manual copying beside the control. |
| AC-04 | Extend `tests/package/feed-publisher-http.mjs`, `feed-http-inputs.mjs`, `feed-preflight-test.sh` and the hosted feed fixture to assemble, upload and read back HTML, CSS, JS, PNG, WOFF2 and licence bytes. Assert declared uploader media types separately from served bytes, media types and HTTP status. The Pages adapter redirects `/index.html` to `/`; verification compares root HTTP 200 to `index.html` and an unmatched HTTP 404 body to `404.html`. Wrong error-page bytes must fail. Inject wrong media types, wrong bytes, missing assets, incomplete page sets, unlisted extra HTML, a public `site.json`, collisions and homepage fallback for missing paths and require failure before closure. An ordinary successful candidate deployment with wrong site bytes/headers/status enters authorised recovery or holds without that authority. A confirmed terminal recovery with a site mismatch admits only its eligible identical-byte retry per separately authorised dispatch. For an established predecessor, rejection/failed-candidate closure holds on a wrong previously served site. For a bootstrap predecessor with no live deployment and a page-bearing proposed recovery, both closure types verify canonical null and root/unknown/catalogue HTTP 404 without demanding a served recovery page. The page-bearing recovery verifies its bytes after actual deployment. Repeat rejection, failed-candidate and recovery cases with a live predecessor that closed on a page-bearing empty-catalogue recovery: verify its HTTP 200 page and catalogue HTTP 404s with no `release.json`. A predecessor with an authenticated catalogue must fail if its required manifest is missing. An already closed generation or retirement-finalisation verification failure holds. Unknown paths, absent catalogue aliases and a withdrawn catalogue return HTTP 404. Run native pkg catalogue authentication and exact package fetch before and after a homepage generation. At a separately authorised live publication run the same readback against the actual Cloudflare custom domain and retain its results before closure. |
| AC-05 | The existing publisher/controller fixture exercises candidate publication, established recovery and empty-catalogue bootstrap recovery with complete approved page assets and HTTP 404 responses. Run the input-preparation entry point used by `feed.yml` against a tag with an existing closed generation, its original empty fixed-name seed and its non-empty retained closed history. A page-only update uses that closed history, the same package source, tag, version, catalogue/package hashes and package marker, with a changed page SHA and fresh archive digests. Reusing the verified unchanged history succeeds with a fresh approval; a mismatched/orphan successor, missing or mismatched approval readback and changed predecessor hold before submission. Repeat after both candidate and recovery predecessor closures. Preparation selects through the GitHub journal using existing CLI access; the protected job independently correlates the provider deployment. Assert exact page and named native catalogue bytes and separately validate the constructed recovery release manifest, recovery marker and rebuilt Pages manifest. Inventory fixtures accept at least 26 Pages deployments and 101 journal rows across pages, plus exact page boundaries and empty inventories. They reject missing/malformed pages, repeated next links, duplicate IDs, cross-resource links, inconsistent totals, changing complete views and API failures before publication. Replay both a package and a page-only publication after their closure POST committed but its response was lost. Use the original predecessor for history, recovery-source provenance, complete recovery-archive comparison and page-only native identity, while reconciling the submission's own live candidate or recovery. Preserve its existing attempt/closure and create no extra deployment. Repeat with a pre-homepage retained submission's legacy input shape. Exercise a completed catalogue retirement with a reused non-empty retirement manifest: require `authorize_retirement=false`, verify the earlier matching pending-scope/closed-withdrawal evidence, preserve HTTP 404, and assert no new trust-finalisation row in submission or reconciliation. A `true` retirement flag or absent/conflicting completion evidence holds. Mode changes on replay hold before effects in both directions; test a page-only retirement-release replay with `page_only=false`, a package replay with `true`, and legacy package-mode records retaining their original approval hash. A new or conflicting retirement plan under page-only mode holds. Check missing/ambiguous baseline, extra page files, missing/malformed/mismatched/unreachable page-source SHA against fetched main, a main-reachable page SHA with absent/failed/skipped/mismatched source CI, unapproved protected-job entry, concurrent dispatch exclusion, interrupted/lost responses and duplicate-correlation holds. Release-asset fixtures find and verify an expected archive beyond the first 100 assets, reject duplicate/partial listings, accept capacity up to the 1,000-asset quota and hold before submission when required new names would exceed it. An interrupted upload retains verified files for an identical-byte retry. A pre-homepage baseline verifies the initial root HTTP 404 observation and recovery HTTP 404 with its retained error-page bytes when present. `hosted-feed-content.sh` supplies native signed client proof for the controller cases. |
| AC-06 | Verify the staged public asset list and SHA-256 values against the explicit reviewed source files and run the existing pinned Gitleaks checks. The approved HTML, CSS, script, logo, font, `VHCO-LOGO-NOTICE.txt` and `INTER-LICENSE.txt` must pass. Missing either required notice fails assembly. Both new page sources and bootstrap recovery sources require their exact successful `php.yml` run/attempt and required PHP/Gitleaks job; absent or failed CI holds. The protected environment must require approval for the exact run inputs, and dispatch must reject an archive/digest mismatch against those inputs. A served `.env`, `config.xml`, private-key file or retained `site.json` entry must fail the explicit file-list check; altered staged bytes must fail source-provenance comparison. Record the final text-asset and request-URL review through that protected environment approval after inspecting the bundle for deployment-specific addresses, credentials, exports and private key material. Check repository/package terminology and public reference routes. For signing copy, "Follow the installation guide to verify the signing key through an independent trusted channel before adding the repository" must pass. "Compare the public key's fingerprint with the release notes before trusting it" and "Trust this downloaded key without verification" must fail. Reading the page needs no credentials. |

## Tasks

None yet; written after owner acceptance.

## Open Questions

None.
The owner selected publisher reuse, independent page-only updates and public byte/header verification on 15 November 2026.
The owner then accepted the actually served recovery baseline, explicit HTML response routes and retained-only provenance metadata with a complete public-file list.
On 16 November 2026 the owner accepted generated and verified recovery metadata, site failures under the existing recovery/retry/hold contract, GitHub CLI preparation with protected-job Cloudflare checks, and independent protected verification of the explicit page-source commit.
Following continuation, the R-4 recommendations were applied to the draft.
The owner then explicitly selected the logo-specific rights notice and accepted all four R-5 delivery recommendations: the deployed empty-catalogue baseline, recorded replay mode, successful page CI with protected-job manual review, and complete release-asset listing with a quota hold.
Whole-spec acceptance remains pending.

## Review Log

| Date | Review | Kind | Commit | Model | Isolation | Outcome |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-11-15 | R-1 | spec | `1012715422c73c326c0d3061e62dbc2c9e83c334` | claude-opus-5-5 | procedural | One blocking, four should-fix and two nits. Read-only checkout preservation verified. |
| 2026-11-15 | R-2 | spec | `23d22b463fb22cc41c8362557def8624ff05dbd7` | claude-opus-5-5 | procedural | One blocking and four should-fix. Read-only source and Git preservation verified. Shell execution was denied to this static reviewer. |
| 2026-11-15 | R-3 | spec | `340d9014f0b9671257bf6594270681967f82b6b7` | claude-opus-5-5 | procedural | Seven should-fix findings. Static source review, with read-only source and Git preservation verified. |
| 2026-11-16 | R-4 | spec | `e7056a8df471b467d140b965cbc08540373a6fe2` | claude-opus-5-5 | procedural | Five should-fix findings. Static review with matched read-only source/Git snapshots. Reviewer shell execution was denied. |
| 2026-11-16 | R-5 | spec | `30ef9f29d39e7771fffecf406db7b4c23228a7fc` | claude-opus-5-5 | procedural | Six should-fix findings and two nits. Independent pinned lint passed. Static source/Git snapshots matched; PHP/actionlint checks were unexecuted. |

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

## Sources

- [GitHub release limits](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases#storage-and-bandwidth-quotas) documents the 1,000-asset limit for each release.
- [GitHub release-asset API](https://docs.github.com/en/rest/releases/assets#list-release-assets) documents paginated asset listing and asset-ID downloads.
- [GitHub deployment listing](https://docs.github.com/en/rest/deployments/deployments#list-deployments) documents the repository/environment filters and deployment-list page parameters.
- [GitHub REST pagination](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api) documents next-page links and terminal-page handling.
- [Cloudflare Pages deployment listing](https://developers.cloudflare.com/api/resources/pages/subresources/projects/subresources/deployments/methods/list/) documents `page`, `per_page` and result pagination metadata.
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
