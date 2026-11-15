---
status: in-progress
branch: docs/merged-implementation-status
status_description: "The revised submission contract is accepted. Targeted native fixture verification passed and implementation review is pending."
issue: https://github.com/vhco-pro/opnsense-encrypted-git-backup/issues/1
goal: "Administrators configure, run and recover encrypted Git configuration backups through a native OPNsense provider with verifiable delivery and safe migration."
covers:
  - Makefile
  - pkg-descr
  - src/
  - tests/
  - docs/installation.md
  - docs/recovery.md
  - docs/compatibility.md
  - composer.json
  - composer.lock
  - phpcs.xml.dist
  - phpstan.neon
  - phpunit.xml.dist
  - .github/workflows/
  - playwright.config.ts
  - package.json
  - bun.lock
  - psalm.xml
  - scripts/
  - renovate.json
  - .semgrepignore
---

# Plan: Native encrypted Git backup provider

## Context

### Owner summary

Build an installable OPNsense backup provider with its own package and settings in the existing Backups screen.
PHP is the native choice for the provider interface, configuration model and encrypted-export library.
Use OPNsense's standard configuration and scheduling interfaces, with Git and OpenSSH as transport tools.
The project owns reusable behavior, while deployment configuration and the maintained Homelab guides belong in their existing repositories.
The owner selected the current supported stable OPNsense release as the first runtime target, protected external credential files and a signed package repository for the first release.
An older production appliance needs a separately reviewed upgrade and migration path.

The owner selected a separate provider after reviewing upstream feedback.
Earlier encryption work on the existing Git plugin was declined because encrypted snapshots lose readable Git diffs.
Upstream maintainers suggested a separate provider, and a newer request remains open.
We can prepare a focused BSD-2-Clause contribution, with acceptance decided by upstream maintainers.

The provider encrypts the complete configuration before it enters its Git working tree or new history.
Reuse the native encrypted-export format so administrators can restore through the normal OPNsense recovery interface.
Encrypted commits preserve snapshot versions, while readable configuration diffs remain available through native local configuration history.
Randomized ciphertext increases repository growth, so capture cadence and capacity must be explicit.
The initial proposal uses scheduled latest-configuration snapshots with manual runs, reusing the native daily cadence.

Expose remote-success state and clear failure reasons, and retain encrypted pending commits for safe retry.
An independent freshness monitor uses non-secret remote receipt metadata to detect a stopped firewall or scheduler. When authenticated native attempt status matches the configured target, report a newer failure alongside the age and identity of the retained remote receipt. When native status is unavailable or unassociated, report attempt status unknown and keep remote freshness visible.
The reusable provider supports SSH-accessible Git hosts, with deployment-specific monitor configuration owned by its deployment.

Migration preserves both existing remote history and unpublished local history.
Stop the legacy plaintext writer at a verified checkpoint before accepting new credentials into persistent configuration.
Retain independently recoverable encrypted history and verify a separate native encrypted export of the current pre-cutover configuration before saving new credentials. That export remains the recovery point until the first encrypted delivery is verified.
Shared PHP conventions now define typing, small effect boundaries, PSR-12, secure resources and explicit development checks.
The implementation must pass style, static analysis and behavior tests with recorded coverage of owned files.
Development tools are kept in the build/test environment.
The owner selected an owner-dispatched GitHub Actions workflow for a signed Cloudflare Pages feed. The selection authorizes fixture verification. Production dispatch, signing material, Pages credentials, hostname and publication require separate owner approval.
The installed fixture demonstrated signed package installation, key rotation for backup encryption and native restoration. Independent R-51 observed the earlier manual dispatch and native promotion and rollback fixtures. On 2026-11-15, the owner selected “Use simpler single-record contract (Recommended)” for F-07. The publisher may repeat staging from retained approved assets after a complete journal read confirms no submission record. The revision removes the separate prepared state. [Owner decision](../reviews/opus-5-5-follow-up.md#owner-selected-the-single-record-contract-for-f-07). The publisher independently reads back and checks the exact submission record before any create. An incomplete journal blocks restaging. A crash or failed read-back after the record may require manual investigation even if no create request was sent. The [candidate loopback checks](../reviews/opus-5-5-follow-up.md#single-record-verification) passed at the R-55 commit. The [native feed fixture](https://github.com/vhco-pro/opnsense-encrypted-git-backup/actions/runs/43704991458) passed the recovery cases. Independent implementation review is pending. Production validation and publication require separate authorization. Keeping every advertised v1 package increases storage and file count over time. If complete bundles exceed Pages limits, publication stops with the current feed intact. The owner allows one retry per separately authorized dispatch when the recovery deployment is confirmed live, its request has finished, and native checks fail. The retry reuses the exact approved files, and newer releases wait for verified recovery. Terminal recovery failure with passing native checks leaves publication on hold for manual diagnosis. An unresolved production submission leaves publication on hold, potentially indefinitely, and prevents further feed changes by the publisher. An already submitted request may still take effect, including on first publication. [Manual fixture run](https://github.com/vhco-pro/opnsense-encrypted-git-backup/actions/runs/43677265727)
The pinned PHP action and shared GitVersion dry run passed consumer CI. A native fixture confirmed that the exact-source package and signed catalogue report the same derived version. After separate release authorization, the shared workflow owns automatic tags and the feed dispatch verifies and consumes them. Required scans must cover the declared inputs, and findings require a fix or an independently reviewed owner disposition. The Python advisory remains open in tracker #4. The historical owner disposition covers only repository integration and the identified disposable fixture. The revision retains prior proof and residuals in the historical review records. The revised implementation still needs criterion verification. [Scoped Python advisory disposition](../security/cve-2025-15367.md)

### Verified upstream behavior

The source review on 2026-11-14 used core commit `d20f63c7f7e73c062a623953690c0668070a8d94` and plugins commit `5cca317cdc3e1a979a60b6935428f76de8d08d2b`.
Core `BackupFactory.php:43-58` discovers providers in its own library directory through `IBackupProvider`.
That interface supplies configuration fields, validation/save, provider name, backup execution and enabled state.
Core `diag_backup.php:183-187,374-395` renders discovered fields and dispatches the selected provider's setup/test action.
The remote backup runner dispatches enabled providers and the native scheduler already invokes it.
At that core revision, the remote runner catches each provider's ordinary exception, continues subsequent providers and reports aggregate failure after the loop.
Older release behavior must be assessed separately through the compatibility matrix.
Core `Backup/Base.php` provides encrypted export and decryption, while `opnsense-crypt` calls that same implementation.

The current Git provider is 1.1_5, with its latest directory change on 2026-09-08.
Its PHP provider and configuration-change capture hook form separate paths.
The capture hook continues recording plaintext while remote pushing is disabled.
An encrypted provider must prevent that concurrent legacy path from capturing new credentials during migration.
The current Git provider still builds a `master:<target branch>` push refspec, so the new transport must choose its source ref explicitly.

Upstream encryption request https://github.com/opnsense/plugins/issues/5833 remains open.
Earlier https://github.com/opnsense/plugins/pull/3574 was closed without merge after maintainers suggested a separate provider.
The current contribution guide requires BSD-2-Clause, a discussion before a new plugin submission, a small initial contribution and disclosure of AI tool/model use.


## Scope

Deliver a separate PHP provider with native settings, package lifecycle, scheduling integration, complete encrypted snapshots, SSH Git transport, health evidence and guarded migration.
Include a signed package repository and documented client trust bootstrap in the first release.
Provide native installation, upgrade, removal and recovery procedures with synthetic fixtures and disposable-appliance tests.
Use OPNsense's XML model format and native interfaces for externally defined configuration.
The provider's runtime dependencies are OPNsense's existing PHP/core libraries, Git, OpenSSH and OpenSSL.

Readable encrypted-file Git diffs, secret redaction, additional storage backends and automatic destructive history repair are outside this first feature.
Deployment-specific credentials, real configuration exports, external-monitor credentials and production inventories stay in their deployment's protected storage.

## Design

### PHP quality and compatibility

Follow the shared [PHP convention](https://github.com/vhco-pro/docs/blob/1edeb5f32d868bbe761ef3221f350634cd6ff022/conventions/php.md), pinned by AGENTS.md.
That revision incorporates the security requirements merged in [shared docs PR #38](https://github.com/vhco-pro/docs/pull/38).
Use OPNsense's PSR-12 style and preserve its exact provider/model interface signatures.
Use native types and strict typing for owned implementation where compatible with those signatures and actual framework callers.
Validate model/XML/request input before conversion and confine unavoidable dynamic types to tested integration boundaries.
Keep configuration, Git and filesystem effects explicit and avoid parallel service containers or generic abstraction layers.

Configure PHP_CodeSniffer, PHPStan and PHPUnit as pinned development-only dependencies.
The quality target for owned source and tests is PHPStan's maximum supported rule level, with exact platform symbols and precise stubs where required.
Any measured interoperability gap needs a narrow documented exception and independent review, with the affected paths and checks visible.
An empty analysis target, missing framework symbols, broad baseline or suppressed runtime failure cannot satisfy quality acceptance.
Record actual interpreter/extension versions, tool versions, source/test inclusions and exact commands in the repository after observing them.
Native package contents exclude developer dependencies and private fixtures.
Run syntax and style checks, static analysis, behavior tests, Composer auditing, PHP security analysis and secret scanning in CI. Run native package auditing and integration tests on a compatible disposable OPNsense/FreeBSD environment. Resolve security findings or record an independently reviewed, owner-approved disposition. Scanner failure or unexpectedly empty coverage leaves verification incomplete.
Native browser settings and status pages also follow the pinned frontend-testing standard.
Provide owned repeatable synthetic appliance fixtures and an automated Playwright suite for settings/setup, reload persistence, success/failure status and permission boundaries.
Run Chromium journeys and Firefox for authentication, redirects and state-sensitive flows, plus the applicable responsive, keyboard, zoom and supported-theme checks.
Keep fixture preparation and cleanup scoped to disposable test appliances and out of normal package installation.
Browser tooling and its lock file remain developer-only inputs.

Resolve and pin the exact current stable release, PHP runtime and FreeBSD ABI from official release/package metadata before implementation starts.
Legacy-release support is limited to an assessed migration path.
The production firewall upgrade belongs in the Lab rollout and its own bounded maintenance approval.

### Provider and ownership

Create a distinct provider implementing `OPNsense\Backup\IBackupProvider` and reusing `OPNsense\Backup\Base` encryption and validation helpers.
Use a unique provider filename in the directory scanned by `BackupFactory` and a separate settings model mount.
The package owns only its own provider, models, status interface, configd registration and version metadata.
Package coexistence must permit disabled migration preparation without replacing core files or the existing Git provider's files.
Enabling encrypted delivery requires proof that the legacy plaintext capture path is inactive.

The Backups screen remains the configuration and setup/test entry point.
The standard provider field contract has no dedicated read-only health field type.
Use a small authenticated status view/API for last attempt, last verified success, remote commit and sanitized failure category, sharing the provider's recorded state.
Use the existing native model/ACL framework for that surface.
Confirm provider-screen privilege handling on every supported release, including read-only users.

```mermaid
flowchart LR
    UI["Native Backups screen"] --> P["PHP encrypted Git provider"]
    C["Native scheduler / configd"] --> P
    F["Consistent full configuration snapshot"] --> P
    P --> E["Native encryption and round-trip verification"]
    E --> G["Encrypted Git working tree"]
    G --> R["SSH Git destination"]
    R --> V["Verify retained commit and export"]
    V --> S["Success receipt and native status"]
    S -.-> M["Optional independent freshness monitor"]
```

### Scheduling and failure isolation

The native provider is callable through setup/test and the existing Remote Backup command.
Reuse native Remote Backup scheduling and verify that an earlier provider's ordinary exception allows this provider to execute while the shared run reports failure.
Assign the existing daily job as scheduling owner and verify it through native cron regeneration and package upgrade.
Any older runtime target must prove equivalent behavior or return through design review before adding a separate scheduling path.
Keep overlap locking and bounded execution in the provider, including manual versus scheduled calls.
The plugin supplies no background daemon or external management-service prerequisite.

### Configuration and secret handling

Settings cover enabled state, SSH repository destination, branch, host trust, deployment identity, encryption credential reference and freshness threshold.
Require SSH host verification and reject credentials embedded in repository URLs.
Validate branch/ref inputs and use safe process argument handling for native Git/OpenSSH commands.
Mandatory encryption prevents a missing or unreadable credential from creating a plaintext backup.
An independent recovery copy must exist before activation, and credentials must never be emitted in status, logs, command arguments or receipt metadata.
Store SSH private keys and unattended encryption passwords in root-owned protected files outside the native XML model.
The model stores validated references and non-secret settings.
Reprovision these files from independently held credentials after native XML restoration.
Use authenticated native UI/API actions and privileged configd operations for provisioning and use, with explicit read-only-user rejection.
Ensure native complete configuration exports exclude those external files, while the separately retained recovery material remains usable independently.

Use one versioned key identifier in each encrypted snapshot's metadata.
Credential rotation retains access to earlier snapshots and verifies the newly retained artifact before declaring the rotation complete.
Avoid silent key replacement during repeated setup or package upgrades.
Full configuration remains complete, including recoverable application secrets, inside its encrypted container.

### Snapshot and Git consistency

Capture one consistent complete configuration through the native snapshot/configuration interfaces.
Encrypt through the native library and verify the decrypted bytes against that captured input before staging.
Use a private umask and temporary storage outside the Git working tree.
Permit only encrypted snapshots and explicitly defined non-secret metadata among newly staged backup paths.
Treat native plaintext configuration history on the firewall separately from the provider's encrypted Git storage promise.

Use an explicit source ref such as `HEAD:refs/heads/<configured branch>` and preserve remote history through normal descendant commits.
Reconcile a changed remote before retry and reject divergent or unexpected state with an actionable failure category.
Preserve pending encrypted commits when upload fails.
Record remote success only after an independent read confirms the expected commit and encrypted artifact.
Retries and lost responses must reconcile completed effects before attempting another write.

Record encrypted-artifact hash, captured revision, timestamp, key identifier and verified remote commit with an explicitly documented metadata-privacy boundary.
An independent monitor must check the expected branch and validated receipt schema.
It must distinguish a recent failed attempt from a retained successful export.
Scheduled unchanged configurations still need a remote-verifiable observation without producing a full randomized encrypted blob on every no-op run.
Document storage-growth estimates from measured fixtures and the difference between artifact time and verified source freshness.

The deployment-owned monitor associates the authenticated native status endpoint and independently fetched remote receipt with the same configured backup target. The authenticated native status reports a non-secret target identifier captured with the attempt and bound to its destination and branch. Older attempts without an identifier are unassociated. Compare it with the expected identifier for the configured receipt target, including after a target change. It uses the native attempt outcome and timestamp and verifies remote commit, artifact and observation age independently. A newer failed attempt and a fresh retained export are separate results. An unavailable or unassociated native response leaves attempt status unknown while remote freshness is still evaluated.

### Guarded migration and recovery

Migration is explicit and remains separate from ordinary enablement.
Prepare a preliminary complete legacy Git bundle, encrypt it outside Git and verify an independent retained copy.
Use supported package administration to stop the legacy provider and its config-change hook, then wait for already-running writers to finish.
Capture its final tip, archive it again and verify that exact tip plus the previous remote ancestor through an independent retrieval/decryption path.
Reject a writer or changing tip after the checkpoint.
Before saving new credentials, independently retrieve and decrypt the retained current native export and compare the complete configuration with the source. Bind the export digest and source configuration digest to a version 2 cutover checkpoint alongside the verified legacy archive evidence. A version 1 checkpoint with a legacy entry preserves history evidence but cannot authorize legacy credential save. Regenerate the checkpoint after fresh verification. Update the installation and recovery walkthroughs when implementing this transition. Reject missing or invalid evidence and repeat verification if the source configuration changes before credential save. Compare the required revision and persist settings within the same native configuration-write boundary, or use a native conditional write that rejects a changed revision. A separate check before an unconditional save does not protect the checkpoint. On fresh installations without legacy history, a version 1 checkpoint with a null legacy entry authorizes fresh setup after verifying the writer is absent. The migration export and version 2 checkpoint apply to legacy cutover. Persist activation and its checkpoint identifier in the same native save as settings. After restart, the saved activation identifies completed cutover, and delivery status stays pending until the remote receipt is verified. First delivery, retries and later rotation recheck writer absence and current settings and credentials. The historical pre-cutover digest gates the initial save only. Bind saved activation to the exact destination, branch and verified checkpoint digest, including the legacy parent. Same-target rotation can change credential references under native validation. A new destination, changed branch or different checkpoint requires fresh activation verification and must not reuse pending state from the previous target. On the same target, reuse pending commits only after independently verifying that the committed pending ancestry includes the newly verified parent and can advance the observed remote tip without rewriting it. For a verified null legacy parent, require no legacy ancestry. A verified absent remote permits a pending initial push only when the target has no established branch and no unresolved earlier creation. Before attempting creation, persist the exact pending commit and target as an outstanding creation. If the response is lost and the branch is absent at read-back or after restart, hold that pending commit without recreating the branch. Persist verified delivery before clearing the outstanding attempt. Hold imported version 1 pending work if the branch is absent and the creation outcome is unknown. A definitive rejection can clear the outstanding attempt after confirming the branch remains absent. Branch absence after a verified receipt or when a legacy parent is required holds pending work for explicit recovery. For a present branch, an observed ancestor permits fast-forward, and an exact remote tip equal to the pending commit permits verified delivery without another push. Use an expected-old-ref condition at the remote update boundary for both a fast-forward and authorized initial creation. Never overwrite divergent history. If the older provider cannot enforce the applicable branch condition, keep delivery paused after downgrade. A distinct descendant is an external advance and is held without push or receipt, as is unrelated history. Hold divergence and other incompatible pending work for explicit recovery.
Keep the previous verified archive and local recovery data through the transition.

For a repository containing old plaintext history, preserve that history and remove the plaintext snapshot from the new active tree through a normal descendant commit.
Use a no-checkout migration so historical plaintext is never populated into the new active working tree.
Every new configuration snapshot must be encrypted before staging or upload.
Package removal retains backup data and protected recovery material until an explicit data-retirement action.
Activation, checkpoint replacement, rotation and rollback must exclude delivery through the same lock or a durable paused state established while holding it. Delivery must read or revalidate settings, checkpoint and credentials after acquiring that lock before any push. An upgrade must preserve validated settings, key identifiers and pending Git state. Before replacing version 1 inputs, capture the compatible checkpoint and provider settings from one stable state under the transition lock. Bind the retained pair to the native settings revision being replaced and verify independent read-back of both. Require that revision at the replacement write boundary and stop or recapture if it changes. Document retrieval for rollback. Hold delivery on enabled legacy version 1 installations without a saved activation until the operator obtains and verifies version 2 evidence and commits the activation through the native save boundary. For enabled null-legacy version 1 installations without saved activation, require the native activation save with their verified null-legacy checkpoint before resuming. An interrupted upgrade keeps the applicable hold repeatable. If reverting before or after activation save, restore the independently retained compatible version 1 checkpoint and matching settings before enabling the old encrypted provider. Verify the original destination, branch and pending ancestry against that checkpoint. If those checks fail, keep delivery paused with all work retained. Keep the plaintext writer disabled throughout. Before reinstalling the old provider, disable admission through both native delivery entry points across interruption and drain admitted work, including calls that passed checkpoint verification before taking the delivery lock and withhold the active checkpoint so the old provider also rejects delivery during an interrupted rollback. Restore the active checkpoint only after verifying matching settings and pending ancestry. Keep entry points quiesced until then.

Recover a full snapshot through native OPNsense decrypt/import using an independently held credential and reachable Git or offline storage.
Use an isolated appliance with production identities and network services contained during restore testing.
Backup delivery and retrieval require no management platform, external vault or additional backup server.
Loss of the deployment key can be handled by issuing a replacement after recovery.

After new credentials are saved, keep the legacy plaintext writer disabled during rollback and package removal. After draining the legacy writer and before saving new credentials, independently retain a native encrypted export of the current configuration. Prove native restoration on an isolated appliance using a complete synthetic export. Keep the legacy Git checkpoint for history and use the verified export for configuration recovery until the first verified delivery. Keep the saved native configuration and separately provisioned credentials on the appliance for retry. If they are lost, restore the independently verified native export and reapply the provider settings and credentials from independent operator records. Report the first delivery as pending or failed until its receipt is verified. Recover through the verified archive and native encrypted restoration path. Reprovision external credentials independently as needed under the existing guarantee against writing new credentials to legacy history.

### Packaging and contribution

Build a proper FreeBSD `.pkg` using pinned OPNsense plugin tooling on a compatible disposable build environment.
Expose the package through normal OPNsense package administration.
The first release includes a signed third-party package repository with native client trust configuration and Firmware-GUI discovery/update verification.
Generate catalogue metadata and signatures through the compatible native pkg tooling and publish immutable versioned package artifacts.
Clients verify the configured repository trust before accepting catalogue updates and verify artifact integrity against that trusted metadata.
Distribute the initial trusted key/fingerprint through a separately verified release identity, then document key rotation and revocation.
Keep signing private keys outside source and package artifacts, with independently retained recovery material.
Publish a complete validated repository generation. For an established feed, preserve a usable previous generation through interrupted publication. For initial publication, prohibit further publisher mutations while a first activation is unresolved, whether the catalogue remains absent or the outstanding request takes effect. Before recording verified bootstrap recovery, check HTTP 404 at each catalogue and metadata path requested by the pinned native client through its configured client-facing feed URL. Through the same URL, verify package retrieval and authentication for clients holding the first catalogue.
Choose compatible release/ABI channels explicitly and refuse an incompatible package on the target.
Use managed Cloudflare Pages static public hosting for the signed feed.
The owner requires managed serverless/static hosting and wants no instance-maintenance responsibility.
The Cloudflare Pages feed serves static catalogue, signature and package files over managed HTTPS.
Its publication pipeline and signing-key lifecycle remain project responsibilities.
Validate response behavior and native client compatibility before selecting the final feed configuration. Before any activation, check complete candidate, recovery and retirement bundles against the selected Pages limits. Report an over-limit bundle without submitting or dropping previously advertised package files.
Retain every immutable package version advertised by a v1 catalogue across promotion and recovery and test an update during catalogue/artifact retrieval.
Record artifact version, source revision, dependencies, integrity and authenticity checks and supported OPNsense/PHP/FreeBSD combinations.
Native package installation alone does not establish compatibility with an arbitrary older appliance.
Define package file ownership and test install/upgrade/remove before any live rollout.

Keep the source layout and BSD-2-Clause notices suitable for a focused contribution to `opnsense/plugins`.
Revisit existing discussions before proposing a new upstream issue and request owner approval for its exact public text.
Separate generic upstream changes from private deployment instructions and custom distribution infrastructure.
Upstream acceptance remains an external decision.

### GitVersion and release preparation

Use the shared `version-workflow` to calculate the checked source's version and retain dry-run CI evidence. Map stable SemVer directly into the native package version. Map numbered alpha, beta and release candidate labels to FreeBSD's dotted prerelease form. Reject other labels and ambiguous tag/source identities before building. The prepared package and signed catalogue must advertise that exact mapped version. Keep fixture versions separate from release versions.

The shared [version-workflow at `3b78b04`](https://github.com/vhco-pro/version-workflow/blob/3b78b04df802ea1592cbe19338d7a882d1888389/.github/workflows/version.yml) calculates the version for the exact checked source. When separately authorized for release, it delegates tag creation to [gitversion-tag-action at `8cf5869`](https://github.com/michielvha/gitversion-tag-action/blob/8cf5869816cf71437052ac97d086e00526bf2d89/action.yml) under the shared branch policy: default branch or configured preview label. Feature CI keeps dry-run enabled. The owner clarified in response to R-8 F-02 that shared automatic versioning and tagging remain in force. The owner dispatch applies to signed-feed promotion. The publisher uses the successful shared calculation and the matching immutable remote tag. Its access to source refs is read-only.

The shared `gh-release-workflow` assumes that its tag is the released artifact. This plugin instead requires a verified native package and signed catalogue. The dry-run workflow therefore calculates the version without tagging, and the native preparation command consumes that result to build the artifact. Remote release and feed publication require separate approval.

### Signed-feed promotion (Q1)

The owner selected an owner-dispatched GitHub Actions workflow on 2026-11-14. That selection authorizes fixture verification. Production dispatch, signing material, Pages credentials, hostname and first publication require separate owner approval.

The versioning caller retains a release identity record binding the repository, run and attempt, pinned shared workflow, full source SHA, version and matching immutable remote tag. When the record is unavailable, recover it from a successful shared calculation for the same reviewed SHA and the current matching remote tag. An empty pushed-tag output on a rerun is compatible with an existing tag. The shared branch and preview-label policy controls tag creation. A later label change does not change the identity of an existing immutable tag. Current owner approval for the feed dispatch authorizes publication of the reviewed identity, and GitVersion output alone confers no publication authority. If neither a retained record nor a successful shared calculation is available, report missing release evidence and stop before build or signing. Retain the approved publication record while the generation remains supported or an activation is unresolved.

Acquire exclusive ownership of the Pages project before reconciling its activation record or performing any feed effect. Use one GitHub Actions concurrency group for all workflows that can mutate that project, without cancellation of the active holder. Reconcile under that ownership. The durable record continues to hold unresolved work after runner loss.

The workflow uses these steps:

1. Load the verified release identity record for either the original or reconciled shared run. Verify the recorded run and attempt, calculated version, full source SHA and immutable remote tag against the reviewed source before building. Verify the tag version and derive the native version from that run. Reject a mismatched tag, SHA, run or version before preparing artifacts.
2. Build against the pinned native inputs. Record the ABI, native version and package SHA-256 in a release manifest alongside the tag, commit and GitVersion result. Create and sign a complete feed generation and record its catalogue and generation digests in the manifest. Verify the package hash and version against the signed catalogue.
3. Stage the exact generation for native client verification. Record the staged deployment and current production deployment identities before promotion. Verify trust, upgrade, and package retrieval during a generation change. Before any submission that could serve a new catalogue, durably record its package URLs and digests with the retained release manifest. Before attempting the append, durably bind the approved manifest and bundle digests to the expected prior history checkpoint in the activation record. Retain those records independently of the history being validated and require their latest committed checkpoint before submission. Before submission, commit the manifest reference and its updated integrity checkpoint as one durable state transition in the append-only feed history. On an authorized restart, derive the exact successor from the durable approval and the independent prior checkpoint. Append if the history is still at that checkpoint. If the exact successor is already committed, advance the independent checkpoint idempotently before submission. Hold if approval is missing or the history is neither the expected prior checkpoint nor its exact successor. Hold on missing or mismatched history. Retain that history and all referenced manifests for the life of the v1 feed across closure and recovery. Verify the history against its retained integrity checkpoint, including membership and order, and verify each referenced manifest before submission. Use these manifests across dispatches, including for candidates that may have served a catalogue before failing. In every candidate, recovery and retirement bundle preserve the original URL and digest of every previously advertised v1 package, including files advertised only by retired catalogues.
4. For an update, stage a recovery generation containing the previous signed catalogue and the same retained package set as the candidate, including packages needed by any cached catalogue previously served by the v1 feed. For first publication, stage a recovery generation with no catalogue, a top-level Pages 404 page to prevent SPA fallback, and all packages advertised by the first catalogue. Verify catalogue and metadata 404 responses and cached-client package authentication in staging before first activation. Before initial activation, verify that the feed advertises no catalogue. The bootstrap recovery generation keeps package URLs available to clients that received the first catalogue, while returning absence for new catalogue requests.
   For a single-key `pubkey` feed, use separate immutable catalogue URLs during rotation. Keep the predecessor URL pinned to the previous verified generation while clients move to the successor URL and key together. Pre-stage and approve the successor-signed recovery catalogue for the successor URL over the last verified package set. On failed promotion, restore that catalogue on the successor URL while preserving the predecessor URL until its clients migrate. Serve both paths from one Pages project. Serialize changes across that entire deployment, including concurrent rotation work. Keep both paths in every approved bundle during overlap. After migration verification retire predecessor trust and remove its catalogue under the same durable activation and final verification rules. If retirement reached terminal success but withdrawal checks fail, keep the overlap trust arrangement available for recovery and hold newer work. Retry only the read-only checks. Once withdrawal passes under the final verification rule, durably record trust finalization pending. Keep newer work blocked until predecessor trust retirement is verified and the retirement record closes. Deployment operators own client trust changes under their separately approved deployment procedures. Before withdrawal, record the approved client scope and expected before and after trust states in the retirement record. The publisher only verifies operator evidence. Require current observations of the expected trust state for every approved client, authenticated to the authorized operator and bound to the retirement record. Deployment operators obtain fresh verification of the expected live deployment and predecessor catalogue withdrawal before proceeding with or resuming trust changes. Missing or failed verification halts their procedure. A later authorized dispatch rechecks live identity and client-facing withdrawal before accepting completion evidence. Unreachable clients, incomplete evidence or conflicting trust keep retirement open. Close only when withdrawal and retirement are verified. Before submitting retirement, approve a recovery bundle of the last verified overlap generation and retain its client trust arrangements until retirement is verified. Treat a uniquely correlated terminally failed retirement confirmed live under the same durable recovery-required rule as a failed live candidate. Recovery after verified retirement preserves catalogue withdrawal and immutable predecessor package paths for the life of the v1 feed.

5. Activate the same verified candidate as a Cloudflare Pages production deployment. Check the served manifest, catalogue and native package retrieval. Use the ordered rules below to select recovery for either live-candidate outcome. Resume a recorded recovery decision with its approved bundle. Record the approved candidate and recovery digests before activation. Before each activation, record the observed source deployment identity and digest, or record the absence of a deployment for first publication. Record an activation attempt identifier before submitting and include it in the Pages deployment commit message for correlation. Send one create request per recorded attempt and disable HTTP client retries for it. Conflicting matches leave the record open. Recognize successful activation only when the uniquely correlated Pages deployment reports a successful deploy stage and its production identity and digest are verified. Treat a correlated terminal failure or cancellation as failure only when Pages identifies the deployment as finished. An intermediate successful stage, an unclassified response, connection interruption or timeout does not resolve the attempt. Accept definitive create rejection only when the provider response unambiguously rejects the request without creating a deployment. On an ambiguous response, query Pages production deployment records for that identifier, then verify the live deployment ID and served digest. Verified live deployment identity and served digest permit resuming validation even before Pages reports a terminal outcome. Keep the record open and disallow further feed mutations until Pages reports a correlated terminal outcome or the submission receives definitive rejection. Verified live identity alone permits read-only validation. Apply the eligibility rules below to every follow-up create and to closure.

### Activation reconciliation and retry eligibility

Apply these rules in order under exclusive project ownership:

1. Unknown or conflicting submission or live state stays open for read-only reconciliation. A matching live identity and digest without a correlated terminal result permits read-only validation. Neither elapsed time nor an empty deployment list clears the hold.
2. A recorded recovery already live is governed exclusively by Q3 for any further create. On 2026-11-14 the owner selected one retry per separately authorized dispatch when the uniquely correlated recovery is confirmed live with the approved digest, the request is terminal and fresh native package checks fail. Use the same verified recovery bytes and a new attempt identifier. Persist consumption atomically with submission-started, keyed to the dispatch run ID across all reruns. Retain every consumed dispatch ID for as long as it can be replayed against the recovery record. This condition also applies after definitive rejection of a follow-up create. Terminal recovery failure with passing native checks stays open for manual diagnosis with no further mutations.
3. Outside the live-recovery case, retry a rejected or terminally failed create only after definitive rejection or unique correlated terminal failure and verification that the recorded source is unchanged. A candidate failure may close without retry after verification of the exact pre-candidate state, including catalogue absence at first publication. A rejected recovery leaves recovery-required active if the failed candidate is still served.
4. An existing recovery-required decision takes precedence over candidate closure, even if later candidate checks pass. Resume only the recorded recovery under the applicable owner authorization and verified live and submission conditions above. Successful closure requires correlated terminal deployment success and fresh verification of the same live identity, approved served digest and applicable native checks. Newer releases wait until closure. For a candidate confirmed live after terminal failure or failing native checks after terminal success, or a retirement confirmed live after terminal failure, persist recovery-required and the approved recovery digest before any recovery submission. Early validation does not commit recovery or close the record.

The Q3 design decision grants no publication permission.

Before any signing, upload, retirement or other feed change, every dispatch must reconcile the durable activation record for the entire Pages project using read-only operations. Apply the reconciliation and eligibility rules above. For bootstrap recovery both catalogue absence and cached-client package retrieval and verification must pass through the configured client-facing feed URL before closure. Persist and independently verify a submission-started record before making any Pages create request. A later authorized dispatch may repeat pre-submission staging from the same retained approved assets after a complete journal read shows no submission record. After a submission-started record exists, apply Pages reconciliation even if the runner exited before making the request. An unresolved activation can persist indefinitely. Discover unresolved attempts even after runner loss or cancellation and prevent any newer generation from submitting until the earlier attempt is resolved. Require production environment approval from the authorized owner before any production signing or deployment step. Give fixture execution access only to fixture keys and owned staging resources. Serialize promotions per feed. A retry must recover the same approved manifest and artifacts, or resume verification of an already deployed matching generation. Stop on a different digest for an existing version or generation, or an unexpected live deployment. Keep exact candidate and recovery bundles in durable release storage indexed by their approved digests, independently of runner temp files and Pages staging. Retrieve both approved bundles independently from durable storage and verify their digests before entering submission-started. Verify digests before reuse and retain bytes for all previously advertised v1 packages and unresolved activations. If bytes are missing or mismatched, stop with the current live generation intact. Keep the approval and deployment records so a retry after an ambiguous response can distinguish completion from a conflict.

Prove the same workflow sequence with fixture keys and owned synthetic staging using free CI tools, including missing version-run evidence after a tag push, an empty tag output on rerun, an ineligible preview version, wrong identity, conflicting digest, interrupted first activation and lost responses after candidate and recovery activation. No persistent publisher host is required.

## Acceptance Criteria

- [ ] AC-01: The package installs and upgrades on the selected supported releases, exposes its provider in the native Backups screen and preserves core and unrelated provider behavior.
- [ ] AC-02: Complete encrypted exports restore through the native OPNsense interface on an isolated appliance, while all newly created provider Git snapshots and staging exclude plaintext configuration and synthetic secrets.
- [ ] AC-03: Validated configuration and secret custody survive the documented restore/upgrade paths, enforce the selected privilege boundary and permit recovery and credential rotation independently of management services.
- [ ] AC-04: Manual and scheduled runs produce consistent Git state under overlap, rejection, interrupted response, retry and divergent-remote cases, with success reflecting independently verified remote retention.
- [ ] AC-05: Native scheduling survives regeneration and upgrade, failure of another provider cannot silently suppress the selected scheduling path, and native status plus independent freshness checking expose stale or failed delivery.
- [ ] AC-06: Migration preserves the verified final legacy history and previous remote ancestor off the firewall, prevents new credentials entering the legacy plaintext capture path and remains recoverable after interruption.
- [ ] AC-07: A second operator can install, configure, observe and recover the provider from versioned documentation and verified package inputs, with supported versions, diff/storage trade-offs and distribution/contribution limits explicit.
- [ ] AC-08: Owned PHP source and tests pass the selected runtime syntax checks, PSR-12 style, declared static-analysis checks and behavior tests, with visible coverage and reviewed narrow exceptions. Required security scans and native audits complete with expected coverage and any findings resolved or given an independently reviewed, owner-approved disposition. The runtime package excludes development tooling and private fixtures.
- [ ] AC-09: The signed repository supports verified native installation and updates on the selected runtime, rejects untrusted catalogues, modified packages and incompatible targets, and preserves recoverable trust and a usable prior generation for established feeds through failed publication and signing-key rotation. An unresolved first activation prohibits further publisher mutations while the pending request may still become live. Bootstrap recovery withdraws the first catalogue and retains its packages for cached clients. A terminal live recovery that fails native validation permits one retry of the same approved files per separately authorized dispatch. Newer releases stay blocked until recovery is verified. Production signing and deployment require owner approval, and fixture execution has access only to owned staging and fixture keys.
- [ ] AC-10: The native settings and status interfaces pass reproducible automated browser journeys for setup, reload persistence, success/failure states and permissions on owned disposable fixtures, with the applicable responsive and accessibility checks and developer tooling excluded from the runtime package.

## Test Plan

| Criterion | Proof |
| --- | --- |
| AC-01 | On each selected release, build/install the package, inspect provider discovery and native form rendering, exercise setup/test, upgrade and remove/reinstall. Compare core/unrelated file ownership and backup behavior. |
| AC-02 | Use synthetic complete configurations with nested secrets and malformed/encryption-failure inputs. Inspect every newly staged/tracked snapshot, perform native decrypt/import in an isolated appliance and verify the restored fields. Compare a real deployment export only during its separately approved deployment test. |
| AC-03 | Test administrator, read-only and unauthorized access. Verify secret persistence and filesystem modes under the selected custody contract, recovery with independent credentials, failed/complete rotation and old/new snapshot retrieval. After native configuration restore and again after package upgrade, verify persisted settings, credential references, key identifiers and protected file modes. Reprovision external credentials independently where required and prove successful delivery after each transition. Start upgrade with enabled legacy version 1 settings and pending Git state. For the enabled null-legacy version 1 upgrade, attempt delivery with pending work before activation save and require no push or pending-state loss. Save the verified activation, restart and verify delivery. Interrupt and revert before and after saving activation. Verify the documented hold or safe old-plugin resume with matching version 1 inputs and preserved pending ancestry. Start with only the active version 1 inputs. Inject missing and mismatched read-back and a concurrent settings change during capture and a native save after final comparison but before replacement. Require no replacement until a stable pair is verified. Then complete documented independent retention, remove the active copies and recover through the rollback procedure. Interrupt rollback and reactivate while a delivery has read old settings but is waiting for the lock. Exercise both old-package entry points throughout interrupted rollback, including a call that already passed checkpoint verification. Require admission blocked and admitted work drained before replacing inputs. Reopen admission only after the compatible pair and remote ancestry are verified and the old provider enforces the required ref protection. With an older provider that lacks it, invoke both entry points after interruption with the active checkpoint restored and require zero pushes, including when the remote changes after observation. Require no stale push and preserve pending work. Verify same-target rotation continues and a changed destination, branch or checkpoint cannot inherit activation. After same-target checkpoint replacement, exercise compatible and incompatible ancestry, including a never-created branch eligible for initial push, a previously verified or legacy branch that disappears and must remain unmodified, and an already-retained pending commit after loss of the push response. Accept an initial push, lose its response, delete the branch before read-back and restart. Require no branch recreation and preserve the pending commit. Interrupt after successful read-back but before receipt persistence, delete the branch, and verify the same hold after restart. Upgrade version 1 state with a pending commit, an absent branch and no trustworthy attempt or receipt, and verify no push or loss. Separately delete the branch after observation and before push and verify the failed condition does not recreate it. Require no repeat push for the exact retained tip and no push or receipt for a distinct descendant or unrelated tip. Inspect browser/API/log/process outputs for synthetic secret leakage. |
| AC-04 | Inject concurrent manual/cron calls, rejected push, completed push with lost response, process termination and remote branch advance/divergence. Verify exact remote objects, retained pending state, no false success and repeatable recovery. Test non-master local branches and invalid destinations/refs. |
| AC-05 | Regenerate native cron and upgrade the package, then observe a real scheduled run. Make an earlier provider throw an ordinary exception. Verify that the encrypted provider runs and the native runner reports aggregate failure. Exercise normal, stale, unchanged-source and stopped-scheduler receipts with matching pass/fail expectations. Through the deployment-owned monitor, pair an independently verified fresh remote receipt with a newer authenticated native failure for the same configured target and require both to remain visible. Record a native attempt for target A, read it through the real authenticated endpoint with A’s independently verified receipt, then change settings to B without another run and repeat with B’s independently verified receipt. Require the same A identifier and timestamp in both responses, failure reported for A and unknown attempt status for B. With native status unreachable, bound to A or lacking a target identifier, report attempt status unknown while evaluating remote freshness independently. Verify the deployment's owner notification delivery separately. |
| AC-06 | Exercise an old hook appending during the preliminary archive, then stop/drain it and verify the final independently downloaded bundle against the checkpoint tip and remote ancestor. Interrupt each cutover stage and repeat safely. Restart immediately after saving a synthetic new credential. Verify that the persisted activation permits first delivery despite the expected configuration change. Reject or interrupt that delivery. Verify the failed or pending status, simulate a stale legacy tip and restore the independently verified current pre-cutover export, reapply provider settings and reprovision external credentials independently, and verify delivery with legacy capture disabled and no new credential in legacy history. Require rejection before new secrets are saved when the old hook is active or export evidence is missing, invalid or stale. Attempt the documented cutover with a version 1 checkpoint and require fresh verification. Inject a concurrent native change after the final comparison and before persistence. Require serialization or rejection without a credential save against a stale checkpoint. |
| AC-07 | Follow the native install/setup/recovery guide from a fresh compatible disposable appliance using only retained package provenance and independent recovery material. With the null-legacy version 1 checkpoint and no plaintext writer, save fresh settings and verify the first delivery. Verify package authenticity, document measured repository growth and reproduce upgrade/removal behavior. |
| AC-08 | On the pinned target interpreter, run syntax checks, PHP_CodeSniffer PSR-12, PHPStan at the declared maximum-level target with platform symbols/stubs, and PHPUnit over actual owned source/tests. Run `composer audit --locked` including developer and transitive dependencies, Semgrep CE on owned PHP source and tests, Psalm taint analysis on owned source with pinned framework symbols, and fully redacted Gitleaks scans over complete HEAD history and owned PHP source paths. Exercise synthetic findings and scanner errors in CI. Run native `pkg audit` on the installed disposable target and record its package inventory and advisory database identity. Record resolved versions, scanned files, exclusions and any independently reviewed exception. Scanner errors and unexpectedly empty coverage leave the criterion open. Resolve findings or record their independently reviewed, owner-approved disposition before marking the criterion met. Inspect the built package for development dependencies and private fixtures. Verify real platform interfaces separately through AC-01 to AC-07. |
| AC-09 | Carry an exact branch-push SHA and GitVersion output through native build, manifest, signed catalogue and client upgrade. Verify native prerelease ordering, reject moved or conflicting tags and mismatched source or version, and use a synthetic tag in the isolated fixture. Bootstrap repository trust on a fresh compatible appliance, install through native firmware/package administration and update a version. Reject an unsigned/wrong-key catalogue, a changed artifact and incompatible ABI. Execute the owner-dispatched workflow against owned staging with fixture keys. Verify the durable version-run handoff and recover a missing record after tag push using a successful pinned shared calculation with empty tag output and a matching immutable remote tag. Carry the recovered identity through the same pre-build checks of run and attempt, version, SHA and tag. Reject missing tags and expired evidence without recovery. Verify that a tag with unchanged SHA and calculated version still verifies after its preview label is removed. Require current owner approval for production dispatch even when the tag and calculation match. Reject a shared preview tag whose version is ineligible before building or signing. Verify real catalogue and metadata 404 responses and cached-client package authentication on the staged recovery bundle. Exercise first publication from an empty feed and verify that a fresh client receives HTTP 404 at each native catalogue and metadata path through the configured client-facing feed URL before bootstrap recovery is marked verified. Exercise that hostname, routing and cache behavior in the owned fixture. Verify that a client holding the first catalogue can still retrieve and authenticate its package, including after an ambiguous recovery response. Break cached-package retrieval while catalogue requests return 404 and require recovery to remain open. Interrupt established-feed promotion and recovery deployment separately, exercise ambiguous responses both before and after the production state changes for candidate and recovery activation, including first activation from no deployment. Start two dispatches against an empty record and instrument both and require zero signing, staging uploads, production submissions or retirement actions from the dispatch without ownership. After correlated terminal candidate success, fail native validation and kill the runner after it durably selects recovery but before submission and verify a subsequent dispatch completes the recorded recovery while newer work waits, even when the candidate checks now pass. Exercise both continued catalogue absence and delayed first activation. Require the record to remain open until terminal evidence and the applicable live checks. Verify duplicate attempt matches cause zero follow-up mutations. Verify an early validation failure cannot commit recovery and a committed recovery decision keeps its approved bytes through reconciliation. Interrupt pre-submission staging before the submission-started record commits. Verify zero Pages create requests, then verify a later authorized dispatch reads the complete journal and resumes from the retained approved assets. For an incomplete or truncated journal read, verify a hold with zero repeated staging and zero Pages create requests. For candidate and recovery submissions, test both a failed independent read-back and a successful read that returns a mismatched record after the submission record commits. Verify zero Pages create requests and require a later authorized dispatch to hold under Pages reconciliation if there is no correlated create. Terminate a runner immediately after recording submission-started and before sending the request, and separately simulate delayed activation after sending it. Require the same hold while either outcome is unknown. Delete the original runner workspace and temporary artifacts, then recover and verify the retained byte-identical bundles. Require zero feed mutations while the submission outcome is unknown. Block newer generations until correlated terminal success plus final live identity, digest and native checks, or definitive candidate failure with verified pre-candidate served state. Inject early validation followed by terminal failure. If the failed candidate is confirmed live, persist the recovery decision and terminate before submitting. Require a later dispatch to restore the same approved bundle and verify the prior catalogue while newer work waits. If a different or unverifiable deployment is live, require no mutation. Through the production response parser test intermediate stage success, final deploy success and failure, and ambiguous create responses. For candidate and recovery, require unclassified structured create errors to leave the attempt open with zero follow-up creates. Use definitive rejection as a control. Count create requests under candidate and recovery timeouts and require one per attempt. Once recovery is permitted, allow only the exclusive holder to submit the recorded recovery bundle. Fail before submission on interrupted retention or missing or corrupt bundles. Verify recovery with only durable copies available. Exercise unchanged-source retry only outside the live-recovery branch of the ordered rules, after definitive rejection or correlated terminal failure. Separately exercise a live recovery with failed native checks after terminal deployment success and after terminal failure. Require zero creates without separate retry authorization, and exactly one create with the same approved bytes and a new attempt identifier per authorized dispatch. Keep newer work blocked if that retry fails. In a separate Q3 case stop the runner immediately after persisting submission-started and before sending. Independently read the durable record and require both the submission-started attempt and consumed dispatch run ID. Inject interruption or persistence failure at each durable write boundary of that transition, including between writes if exposed. Require independent read-back to show either the previous state or the complete pair, with zero requests before the pair is durable. Definitively reject the authorized create and rerun the same workflow run with a new run attempt. Require zero additional creates. Authorize a second dispatch with persisting failed checks, consume its retry and reject it, then rerun the first dispatch and require zero creates. After rejection, make fresh checks pass on the still-live terminally failed recovery. Require zero creates even with fresh authorization. Report terminal failure and passing checks for manual diagnosis and keep recovery open. For unknown, uncorrelated or conflicting states, require zero creates even with retry authorization. Close a successful activation or recovery only after terminal success, final verified live identity and digest, and passing native checks. Exercise candidate rejection or terminal failure separately under the exact pre-candidate state closure rule. For both candidate and recovery, complete early read-only validation with matching live identity before a terminal status arrives. Prove that the record stays open and later work cannot mutate the feed until the correlated terminal outcome. Separately hold a submission with neither kind of evidence and reject conflicting digests. Verify terminal closure after a definitive candidate rejection and after a correlated candidate terminal failure at the pre-candidate state, including first-publication absence. Separately reject a recovery request while a failed candidate is still live and verify recovery-required persists and blocks newer work until verified recovery. Require unauthorized dispatch to fail before production effects and prove fixture execution cannot access production keys or deployments. Verify the previous catalogue still installs after rollback. Fetch the older catalogue before promotion and retrieve its package afterward, then fetch the newer catalogue before rollback and retrieve its package afterward. Verify retrieval after recovery using a third, cached catalogue previously served by the v1 feed whose package neither adjacent catalogue advertises. Exercise signing-key rotation and failed promotion before and after predecessor retirement. During overlap verify simultaneous refresh and recovery from separate predecessor and successor paths and serialize concurrent rotation actions. Verify predecessor catalogue and metadata withdrawal through the configured client-facing URL. After terminal retirement success inject stale catalogue content. Require zero production mutations, retained overlap trust arrangement and newer work blocked. After withdrawal passes, interrupt with trust finalization pending. Interrupt separately before any trust change, after a partial change and after the last change before closure. Verify fresh live identity and withdrawal on restart, exercise at least two fixture clients and hold on missing, stale or conflicting retirement-bound evidence, including an unreachable client after partial retirement and block newer work until withdrawal and retirement are both verified. Exercise the operator handoff after partial retirement with a stale predecessor catalogue or a mismatched live deployment, and require no further fixture trust changes, closure or newer submission until fresh verification passes. Interrupt after recording recovery-required for a terminally failed live retirement. Require the next authorized dispatch to restore the approved overlap bundle with both trust paths usable before newer work proceeds. Verify that recovery for subsequent releases after verified retirement preserves withdrawal and package retrieval. After retirement verify cached predecessor package retrieval, successor recovery and revoked-key rejection. Compare all original advertised package URLs and digests across candidate, recovery and retirement bundles. Test a fitting candidate with an over-limit recovery bundle and separately an over-limit retirement bundle. Require zero production submissions and verify the current catalogue and package URLs remain intact. Interrupt each write boundary of the history append and checkpoint transition before submission. On restart with the original workspace gone, require a complete prior or updated history linked to the exact durable approval and require the next authorized dispatch to complete the append or reuse the committed entry and reach eligible submission with complete history. Interrupt after append and before the independent checkpoint advances. Verify exact successor reconciliation and reject missing or conflicting approval linkage. After an activation closes, remove a historical manifest while retaining package bytes. Separately remove its reference without changing the retained history checkpoint. Also restore an older internally valid history and checkpoint after a newer catalogue was served, leaving the independent activation evidence intact. Require zero production submissions in all three cases. Lose the runner after a candidate first serves a catalogue, then recover and promote a later generation using only durable manifests and bytes. Verify each cached package from the failed candidate still has its original URL and digest. Use independent signing and recovery material without exposing keys. |
| AC-10 | Prepare and repeat owned synthetic appliance fixtures without duplicating users or triggering external effects. Run Playwright through native settings/setup, reload persistence, normal/failed status and administrator/read-only/unauthorized cases. Exercise applicable Chromium/Firefox, responsive, keyboard, zoom and supported-theme coverage through real UI actions, with retained screenshots and console checks. Verify cleanup ownership and package exclusion of browser tools and private fixtures. |

## Tasks

- [x] T1 `docs/compatibility.md` - resolve the stable release and hotfix to immutable platform and builder inputs and verify the provider, scheduler and restore contracts at those revisions (Design)
  - Evidence: peeled the three upstream 26.7.9 tags with `git ls-remote`, checked the core hotfix with `git diff --name-only`, and inspected the package catalogue and native contracts recorded in `docs/compatibility.md`.
- [x] T2 `composer.json`, `composer.lock`, `phpcs.xml.dist`, `phpstan.neon`, `phpunit.xml.dist`, `tests/` - install the locked development tools and observe contract and credential-validation tests fail against the absent provider (AC-01, AC-03, AC-08)
  - Evidence: on PHP 8.5.12, Composer 2.11.2 installed the locked tools and passed `check-platform-reqs`. `vendor/bin/phpunit` reported six expected failures because the provider and settings classes were absent. Baseline output is retained in ignored `work/tools/t2-baseline.log`.
- [ ] T3 `src/`, `tests/` - pass native adapter, XML model, protected credential reference and legacy-writer rejection tests (AC-01, AC-03, AC-06)
  - Evidence: PHPUnit exercised native interface discovery and credential identifier validation. Native form, credential file and legacy-drain integration remain open.
- [ ] T4 `src/`, `tests/` - pass tests for complete native encryption, exact round-trip verification, input failures and staging allowlists (AC-02)
  - Evidence: Snapshot tests verified complete input, rejection of a mismatched round trip and rejection of a document type. Native restore and inspection of staged objects remain open.
- [ ] T5 `src/`, `tests/` - pass integration tests for Git reconciliation, bounded SSH execution, overlap, rejected pushes, lost responses and verified remote receipts (AC-04, AC-05)
  - Evidence: Local Git tests verified a retained commit, unchanged-source deduplication and subprocess argument handling and timeout. Local fixtures also verified rejection and retry, overlapping runs, a lost push response and read-back receipts. Real SSH and end-to-end monitoring remain open.
- [ ] T6 `src/`, `tests/` - pass migration tests for verified off-appliance archives, interrupted cutover, post-activation rollback with legacy capture disabled, encrypted restore and credential reprovisioning, and no-checkout preservation of remote history (AC-06)
- [ ] T7 `src/`, `tests/` - verify native ACLs, sanitized status, freshness checks and recovery across credential rotation (AC-03, AC-05, AC-10)
- [ ] T8 `Makefile`, `pkg-descr`, `tests/` - build native install and upgrade artifacts and verify package contents, ownership and removal behavior on the pinned appliance (AC-01, AC-07, AC-08)
- [ ] T9 `.github/workflows/`, `scripts/`, `tests/`, `docs/installation.md`, `docs/recovery.md` - verify native signed-feed generation, trusted installation, negative trust and ABI cases, retained generations and key rotation in isolated scope. Verify dispatch authorization, fixture isolation, bootstrap, unresolved attempts across dispatches, idempotent retry, one authorized retry per dispatch for a terminal live recovery, replay rejection across distinct dispatches, manual-diagnosis holds, conflict rejection and recovery for all catalogues previously served by the v1 feed (AC-07, AC-09)
- [ ] T10 `tests/`, `playwright.config.ts`, `package.json`, `bun.lock` - run synthetic appliance journeys in Chromium and Firefox and retain responsive and accessibility evidence (AC-10)
- [ ] T11 `tests/`, `docs/compatibility.md`, `docs/installation.md`, `docs/recovery.md`, `.github/workflows/` - reproduce installation, native restore and scheduling, record measured growth and tool coverage, and verify that CI runs the declared checks (AC-01, AC-02, AC-03, AC-05, AC-07, AC-08)

- [x] T12 `tests/security/`, `.github/workflows/`, `docs/compatibility.md` - verify scanner coverage and exits and disposition the installed native audit findings (AC-08)
  - Evidence: [Supplemental independent AC-08 review](../security/cve-2025-15367.md#supplemental-independent-ac-08-evidence-review) verified the pinned scanner runs and probe exits. The installed audit exited 1 and the owner accepted the tracked residual for the documented scope.
- [ ] T13 `scripts/`, `tests/package/` - verify the shared run, attempt, version, exact SHA and immutable tag handoff and reconciliation, native ordering and eligibility, signed catalogue identity and client upgrade with the prepared artifact (AC-01, AC-07, AC-09)

- [x] T14 `scripts/publish-feed.sh`, `scripts/feed-recovery.sh`, `tests/package/feed-publisher-http.mjs` - verify the revised pre-submission staging retry and durable record reconciliation contract without a live deployment (AC-09)
  Evidence: Public PR run [43704991458](https://github.com/vhco-pro/opnsense-encrypted-git-backup/actions/runs/43704991458) at `adf9107df0e9bbb9d1637317bfbf52388651b41f` passed the loopback and FreeBSD native-verifier jobs. The fixture exercised incomplete-journal hold, retained-asset restaging, and candidate and recovery 404 or mismatched record read-backs with zero creates and later hold. It used synthetic packages and owned mock endpoints. Production jobs were skipped.

## Open Questions

None.

## Review Log

| Date | Review | Kind | Commit | Model | Isolation | Outcome |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-11-14 | R-1 | spec | `fe017181fab3d0a407d53708757f720adb32b947` | unknown | procedural | Blocking current-core scheduling claim corrected; model identity not attested. |
| 2026-11-14 | R-2 | spec | `60850674d58ac855a509af22132174201972ffd2` | unknown | procedural | NO FINDINGS; model identity not attested. |
| 2026-11-14 | R-3 | spec | `ab93ef6d9f5a6dcd9c47f1b452cc978665adc027` | unknown | procedural | Blocking strict-typing clarification and missing browser proof identified; model identity not attested. |
| 2026-11-14 | R-4 | spec | `30e0b629bfdc280f80404cf6fbd6af993ba287ca` | unknown | procedural | NO FINDINGS; authoritative PHP guidance and browser proof rechecked, model identity not attested. |
| 2026-11-14 | R-5 | spec | `bd68964bd5f20998d28af78743413123b24f6f01` | unknown | procedural | NO FINDINGS; merged guidance and managed-feed clarification rechecked, model identity not attested. |
| 2026-11-14 | R-5 | spec | `bd68964bd5f20998d28af78743413123b24f6f01` | n/a | n/a | accepted by owner |
| 2026-11-14 | R-6 | implementation | `8cb6b119deb5802952c3ffc0cd3ab49a308bae0b` | unknown | procedural | Diagnostic review of partial implementation. |
| 2026-11-14 | R-7 | spec | `1783b18c72a3c05bb70eda97c037691989e7dc86` | unknown | procedural | Blocking baseline and proof findings. |
| 2026-11-14 | R-8 | spec | `d928920e85a0c2af0f8e2216b3eb5fc123741c08` | unknown | procedural | Blocking workflow baseline finding; model identity not attested. |
| 2026-11-14 | R-9 | spec | `f7d56c1437b4a2bb7ca8db5a48b7cc55f43b897d` | unknown | procedural | Blocking first-publication finding; model identity not attested. |
| 2026-11-14 | R-10 | spec | `931c6dfdd900745e89ff2fddea563cf18632e545` | unknown | procedural | Three factual findings; model identity not attested. |
| 2026-11-14 | R-11 | spec | `980450cc27a2276a35e494566f51c92e83a36c60` | unknown | procedural | Blocking release identity inconsistency; model identity not attested. |
| 2026-11-14 | R-12 | spec | `38a0a1df891ba4612b6e4b7df1394ced4c715677` | unknown | procedural | Five findings; model identity not attested. |
| 2026-11-14 | R-13 | spec | `0bad45f5c71de1baadc28ed8bba59b50e95da126` | unknown | procedural | Four factual findings; model identity not attested. |
| 2026-11-14 | R-14 | spec | `ebc90f76ed2af137eaca9cdefe7f0317a8343752` | unknown | procedural | Four factual findings; model identity not attested. |
| 2026-11-14 | R-15 | spec | `4a8a7f1f7f2305b05b8f652acf8ae30de246212c` | unknown | procedural | Six findings; model identity not attested. |
| 2026-11-14 | R-16 | spec | `9502001ba142c12bce5346b957ab26267ffb9a85` | unknown | procedural | Four factual findings; model identity not attested. |
| 2026-11-14 | R-17 | spec | `a46fdb26bdd1d9b706d022ae604e808ee720d20a` | unknown | procedural | Two blocking and three other factual findings; model identity not attested. |
| 2026-11-14 | R-18 | spec | `b165c3379ded4ab9e424283c91fdf89eb673e154` | unknown | procedural | Five factual findings; model identity not attested. |
| 2026-11-14 | R-19 | spec | `ad643cb262da47c5004cb2a855d375688cff95db` | unknown | procedural | Four factual findings, one blocking; model identity not attested. |
| 2026-11-14 | R-20 | spec | `e17f96257ef151037980640219601b2d8a8f8952` | unknown | procedural | Five factual findings, one blocking; model identity not attested. |
| 2026-11-14 | R-21 | spec | `b3aa9cae1ce1c97c1a1cd424bb173907f621cb33` | unknown | procedural | Five factual findings; model identity not attested. |
| 2026-11-14 | R-22 | spec | `8e8c38d1aafe2706f13a19782fae1b42b7e7bfc3` | unknown | procedural | Five factual findings, one blocking; model identity not attested. |
| 2026-11-14 | R-23 | spec | `e2ea78873676b80d2b50b37c8a4baaba681a7e9b` | unknown | procedural | Five factual findings, two blocking; model identity not attested. |
| 2026-11-14 | R-24 | spec | `6df8d124366c182dc3f132486d196e32560614dd` | unknown | procedural | Six factual findings, three blocking; model identity not attested. |
| 2026-11-14 | R-25 | spec | `83fe3c3caeb6eb11a41a67ee65c72af5e69e018f` | unknown | procedural | Two blocking and one other factual finding; model identity not attested. |
| 2026-11-14 | R-26 | spec | `6915b5de4d1cbf45f5990393aff0e0dc7c016938` | unknown | procedural | Four findings, two blocking; model identity not attested. |
| 2026-11-14 | R-27 | spec | `f9d4132ec907c1d810b9d247592a67740c0b04ee` | unknown | procedural | Two factual findings; model identity not attested. |
| 2026-11-14 | R-28 | spec | `d6f87e7102f0ac6da2b132b4ec6560a42a7cfe68` | unknown | procedural | Blocking recovery retry judgement; model identity not attested. |
| 2026-11-14 | R-29 | spec | `6a55dcaf2057d03ada292fe94c0d25d6d4c5f785` | unknown | procedural | Blocking dispatch replay finding and one authority boundary finding. |
| 2026-11-14 | R-30 | spec | `57e4899296b8f6c07400a3831cb24ebf5a259722` | unknown | procedural | Two factual retry findings, one blocking. |
| 2026-11-14 | R-31 | spec | `85222f3897eb51037604ce38a601d7090f8bebd6` | unknown | procedural | One factual Q3 verification finding. |
| 2026-11-14 | R-32 | spec | `65c859ede56b21753aa8357895f6954b5f5d7d91` | unknown | procedural | Three factual findings, one blocking. |
| 2026-11-14 | R-33 | spec | `99fada4eb1ed5d7dd890ca559230efafb7843c88` | unknown | procedural | Two factual findings. |
| 2026-11-14 | R-34 | spec | `85516818ee89f5415d611970113337ffe41460ea` | unknown | procedural | One factual restart proof finding. |
| 2026-11-14 | R-35 | spec | `c376ffb4b2f65cb2227fd055b6d19d8b05e0d4d5` | unknown | procedural | Two findings on catalogue retention and freshness proof. |
| 2026-11-14 | R-36 | spec | `4b64428fb258cff50aac2145138c3439b3043c01` | unknown | procedural | Five factual findings, one blocking. |
| 2026-11-14 | R-37 | spec | `a310f1894619c5c94e643d772dce99bf6cd15f9c` | unknown | procedural | Four factual verification findings and one nit. |
| 2026-11-14 | R-38 | spec | `20c69daec0bff68c8105350855c98aab4f386597` | unknown | procedural | Three factual findings and two nits. |
| 2026-11-14 | R-39 | spec | `f4da7316ade801be91c68ea7179a4129db060b2e` | unknown | procedural | Three factual findings and one nit. |
| 2026-11-14 | R-40 | spec | `c44e1905e8afb600ab86f306e7ff3c35b9553be9` | unknown | procedural | Two factual findings and one nit. |
| 2026-11-14 | R-41 | spec | `533cefead22e6d3e66ac47d09f151b4e83838434` | unknown | procedural | Two factual findings and one nit. |
| 2026-11-14 | R-42 | spec | `a6f611f73f581b6349b1178c06585c30fc2e46bb` | unknown | procedural | Five findings on durable history and client trust. |
| 2026-11-14 | R-43 | spec | `6c591c39289456ab2c9c5328c6193d14822116af` | unknown | procedural | Three factual findings and one nit. |
| 2026-11-14 | R-44 | spec | `e6ca4fe4b22f0f7559c21df660d4f8d1a2bed74e` | unknown | procedural | NO FINDINGS; model identity not attested. |
| 2026-11-14 | R-44 | spec | `e6ca4fe4b22f0f7559c21df660d4f8d1a2bed74e` | n/a | n/a | accepted by owner |
| 2026-11-14 | R-45 | implementation | `3b785d386e59d55ba3211ab0cbe96b6287a2e315` | unknown | procedural | Three findings and no criteria met. Model identity was not attested. |
| 2026-11-14 | R-46 | implementation | `3fc566d4800e9d325c96dbae53c5f18ff42d04a9` | unknown | procedural | Two findings. AC-08 not met and nine criteria not verified. Model identity was not attested. |
| 2026-11-14 | R-47 | implementation | `ba5307c14a1b2e51fa80ba919989a19445f272d6` | unknown | procedural | Three criteria met and four findings. Model identity was not attested. The host added one capture ref during review. |
| 2026-11-14 | R-48 | implementation | `bf4108dc240e2b149c392cfd5d0ab47dac43d058` | unknown | procedural | Five criteria met, four not verified and one not met. Two blocking findings. Model identity was not attested. |
| 2026-11-15 | R-49 | implementation | `0888a750d3eefde56458f196f7acb8e7e91dde5b` | unknown | procedural | Six criteria met, three not verified and one not met. Two blocking findings. Model identity was not attested. An added Git ref prevented full ref preservation. |
| 2026-11-15 | R-50 | implementation | `bebe5f5b9388eb0e89d62ec668747a8908fc431e` | unknown | procedural | Eight criteria met. Manual fixture dispatch remains unverified and the installed audit finding remains open. Source and Git metadata were read-only, with all refs preserved. Model identity was not attested. |
| 2026-11-15 | R-51 | implementation | `bf75a27f49f29a8e86648d47dc6c06ce66a3a15d` | unknown | procedural | Nine criteria met. The approved manual feed fixture passed and the installed Python finding remains open. Source and Git metadata were read-only and preserved. Model identity was not attested. |
| 2026-11-15 | R-52 | spec | `6bbbb910c6892f0dade9dd302dafe7994ba4284e` | unknown | procedural | Refreshed default-branch context. One summary nit. The accepted baseline is unchanged. Source and Git metadata were read-only and preserved. Model identity was not attested. |
| 2026-11-15 | R-53 | spec | `6d00f2f78a8006173c4855cf9eeea693a702ec1e` | claude-opus-5-5 | structural | Three should-fix findings and one nit. Verified first-party Claude Code model and read-only source and Git mounts. |
| 2026-11-15 | R-54 | spec | `1ffa659919eea42a6de0b7ad89543f29586c805f` | claude-opus-5-5 | structural | One should-fix and two nits. Verified first-party Claude Code model and read-only source and Git mounts. |
| 2026-11-15 | R-55 | spec | `c21c21bc36bd57e6ebed2495745a1c07ac0ab67d` | claude-opus-5-5 | structural | Two documentation nits. No blocking or should-fix findings. Verified first-party model and read-only source and Git mounts. |
| 2026-11-15 | R-55 | spec | `c21c21bc36bd57e6ebed2495745a1c07ac0ab67d` | n/a | n/a | accepted by owner |

### R-1

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Context / Verified upstream behavior; Design / Scheduling and failure isolation; Test Plan / AC-05
EVIDENCE: At reviewed commit fe017181fab3d0a407d53708757f720adb32b947, the spec attributes possible suppression of later providers to the cited current core and conditionally proposes a dedicated configd scheduling action. I fetched src/opnsense/scripts/system/remote_backup.php at the cited core commit d20f63c7f7e73c062a623953690c0668070a8d94. Its provider loop wraps each backup() call in try/catch(Exception), accumulates errors, continues subsequent providers and returns failure after the loop. Ordinary provider exceptions therefore have isolation in this version. The spec's premise could lead to an unnecessary second scheduling path.
PROPOSAL: Describe the current runner's observed exception isolation and identify any older-release behavior separately. Reuse native Remote Backup scheduling for the current baseline, with regression proof for an earlier provider throwing an exception. Retain a dedicated scheduling action only if a supported release or a specifically reproduced failure requires it.

### R-2

NO FINDINGS

### R-3

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Adopted conventions/php.md / Types and input boundaries; Design / PHP quality and compatibility
EVIDENCE: The adopted PHP guideline at revision 66582497a21a2181521e7d77200608af597dcc89, lines 27-31, discusses parameter, property and return declarations, then states that strict typing is selected by the calling file. This omits the distinction for scalar return checks. The implemented PHP RFC https://wiki.php.net/rfc/scalar_type_hints_v5, sections Parameter type declarations and Return type declarations, establishes that scalar argument checking follows the calling file, while scalar return checking follows the file defining the function. The cited PHP manual also demonstrates strict return checking. Applying the broad statement to framework integration would produce incorrect coercion expectations and tests.
PROPOSAL: Qualify the caller-file rule as applying to scalar argument checks and state the definition-file rule for scalar return checks. Preserve explicit input validation and actual framework-call compatibility tests. Update the adopted immutable documentation revision after correcting the authoritative guideline.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Design / PHP quality and compatibility; Design / Provider and ownership; Acceptance Criteria and Test Plan
EVIDENCE: At reviewed plugin commit ab93ef6d9f5a6dcd9c47f1b452cc978665adc027, the feature adds native settings and a browser status view, but its verification design and criteria cover PHP checks, package tests and native form inspection without an automated browser suite. The adopted shared AGENTS.md at revision 66582497a21a2181521e7d77200608af597dcc89, lines 14-15, routes every browser frontend to conventions/frontend-testing.md. That standard requires reproducible owned fixtures and automated Playwright journeys, including browser actions, persistence, permission states and responsive verification. Existing proofs could pass while those required browser behaviors remain untested.
PROPOSAL: Add the applicable frontend-testing requirement to the feature design and observable proof. Use synthetic state on a disposable appliance to exercise settings/setup, reload persistence, successful and failed status, and access permissions through the real browser interface. Include the resulting owned browser test paths in covers and retain the existing boundary between disposable tests and live deployment.

### R-4

NO FINDINGS

### R-5

NO FINDINGS

### R-6

CRITERION: AC-01 The package installs and upgrades on the selected supported releases, exposes its provider in the native Backups screen and preserves core and unrelated provider behavior.
VERDICT: not verified
EVIDENCE: Inspected the package preparation script, provider adapter and pinned core Backups form at 8cb6b119deb5802952c3ffc0cd3ab49a308bae0b. The adapter implements the native provider contract, and the GitVersion mapping fixture passed. Native build, installation, upgrade and ownership comparisons were not observed for this commit.

CRITERION: AC-02 Complete encrypted exports restore through the native OPNsense interface on an isolated appliance, while all newly created provider Git snapshots and staging exclude plaintext configuration and synthetic secrets.
VERDICT: not verified
EVIDENCE: Inspected `NativeRun`, `Snapshot`, `GitDelivery` and the snapshot tests. The delivery path calls native encryption and checks the decrypted bytes before staging the artifact. Neither native import nor inspection of staged and retained objects was observed for this commit.

CRITERION: AC-03 Validated configuration and secret custody survive the documented restore/upgrade paths, enforce the selected privilege boundary and permit recovery and credential rotation independently of management services.
VERDICT: untested
EVIDENCE: Inspected the native provider, configd actions, credential checks and installation guide. The provider rejects read-only settings changes and validates references to protected files. The checked-in tests do not cover restore and upgrade custody, authenticated read-only provisioning denial, or old and new snapshot retrieval after rotation.

CRITERION: AC-04 Manual and scheduled runs produce consistent Git state under overlap, rejection, interrupted response, retry and divergent-remote cases, with success reflecting independently verified remote retention.
VERDICT: not verified
EVIDENCE: Inspected `GitDeliveryTest.php` and `GitDelivery.php`. The suite contains local Git fixtures for lock contention, rejected push and retry, lost push response and remote divergence. PHP was unavailable in the review shell, and no native manual-versus-cron run was observed.

CRITERION: AC-05 Native scheduling survives regeneration and upgrade, failure of another provider cannot silently suppress the selected scheduling path, and native status plus independent freshness checking expose stale or failed delivery.
VERDICT: not verified
EVIDENCE: Inspected the pinned core remote backup command, the plugin status implementation and the freshness tests. The core command catches ordinary provider exceptions inside its provider loop. Cron regeneration, an upgraded appliance's scheduled run and end-to-end freshness checks were not observed for this commit.

CRITERION: AC-06 Migration preserves the verified final legacy history and previous remote ancestor off the firewall, prevents new credentials entering the legacy plaintext capture path and remains recoverable after interruption.
VERDICT: not verified
EVIDENCE: Ran `tests/package/verify-legacy-bundle.sh` from the exact commit against an encrypted two-commit synthetic bundle in temporary storage. It accepted the final tip and its ancestor and rejected the reversed ancestry. Inspected the hook and checkpoint checks. Independent storage retrieval, legacy writer drain, credential exclusion and interrupted cutover were not observed on an appliance.

CRITERION: AC-07 A second operator can install, configure, observe and recover the provider from versioned documentation and verified package inputs, with supported versions, diff/storage trade-offs and distribution/contribution limits explicit.
VERDICT: untested
EVIDENCE: Inspected `docs/installation.md`, `docs/recovery.md` and `docs/compatibility.md`. The guides describe the native workflow, credential recovery and fixture trust setup. No second-operator run with verified package inputs from this commit or measured storage comparison was observed.

CRITERION: AC-08 Owned PHP source and tests pass the selected runtime syntax checks, PSR-12 style, declared static-analysis checks and behavior tests with visible file coverage and reviewed narrow exceptions, while the runtime package excludes development tooling and private fixtures.
VERDICT: not verified
EVIDENCE: Ran `actionlint .github/workflows/php.yml` successfully on the exact commit's temporary export. Inspected the PSR-12, maximum-level PHPStan and PHPUnit configurations and the package script's source allowlist. PHP was unavailable in the review shell, and the resulting native package manifest was not inspected.

CRITERION: AC-09 The signed repository supports verified native installation and updates on the selected runtime, rejects untrusted catalogues, modified packages and incompatible targets, and preserves recoverable trust and a usable repository generation through failed publication and signing-key rotation.
VERDICT: not verified
EVIDENCE: Inspected `tests/package/build-feed.sh`, the trust instructions and the package preparation script. The helper stages and signs a local catalogue before moving it into place. Native trust and ABI rejection, update, publication interruption and signing-key recovery were not observed with artifacts from this commit.

CRITERION: AC-10 The native settings and status interfaces pass reproducible automated browser journeys for setup, reload persistence, success/failure states and permissions on owned disposable fixtures, with the applicable responsive and accessibility checks and developer tooling excluded from the runtime package.
VERDICT: not met
EVIDENCE: Ran Playwright `test --list` on the exact commit's temporary export. It discovered two journeys in each of Chromium and Firefox. Source inspection showed anonymous denial, disabled-settings persistence and one mobile view of a seeded failed attempt with a prior successful receipt. The suite omits enabled setup, live success and read-only journeys. The browser journeys and native package inspection were not run.

### R-7

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Frontmatter / status and covers; Design / GitVersion and release preparation; Test Plan / AC-08; Review Log / R-5
EVIDENCE: `vh-adlc fresh` reports `baseline-changed` for R-5 at `bd68964bd5f20998d28af78743413123b24f6f01`. The GitVersion design, scanner proof and coverage paths changed after that acceptance, while the document remains `in-progress`. The pinned `conventions/feature-documents.md:70-73` requires a return to draft, independent review and renewed acceptance for those changes.
PROPOSAL: Reopen the document as draft through the pinned lifecycle and record renewed acceptance against the revised baseline before resuming implementation.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Design / PHP quality and compatibility; Acceptance Criteria / AC-08; Test Plan / AC-08; Tasks / T8 and T11
EVIDENCE: The revised AC-08 proof asks for scanner runs, synthetic findings and errors, and a native audit inventory. AC-08 does not state a security outcome, and its proof gives no pass condition for an advisory, scanner error or unexpectedly empty scan. `docs/compatibility.md:50-56` records that the installed target's `pkg audit` returned exit 1 with an upstream Python advisory. Recording the run and its inventory would satisfy the literal proof even though that result remains unresolved. The pinned PHP convention requires explicit failure policy, findings and dispositions.
PROPOSAL: Define the required security outcome and proof per scanner, including failure or incomplete status for scanner errors and unexpectedly empty coverage. Require findings to be resolved or explicitly dispositioned through the applicable review and owner decision process, and assign that proof to a task.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Design / Packaging and contribution and GitVersion and release preparation; Acceptance Criteria and Test Plan / AC-01, AC-07 and AC-09; Tasks / T8 and T9
EVIDENCE: The new design requires exact checked-source identity, native version mapping and agreement between the package manifest and signed catalogue. The existing acceptance and proof can pass using fixture versions without demonstrating any of those requirements. The exact commit has separate checks in `tests/package/version-test.sh` and `tests/package/verify-feed-version.sh`, and `docs/installation.md:23-27` identifies the branch-push run as the source of the release input because a pull-request run uses a synthetic merge commit. The normative proof does not bind these checks to a single artifact or source revision.
PROPOSAL: Add observable release preparation proof that carries the exact branch-push revision and GitVersion output through the native build, manifest, signed catalogue and client upgrade. Require native version ordering and rejection of mismatched source, tag or version identities.

FINDING: F-04
KIND: judgement
SEVERITY: should-fix
WHERE: Design / Packaging and contribution and GitVersion and release preparation; Test Plan / AC-09; Open Questions
EVIDENCE: The GitVersion revision preserves separate release approval and requires immutable package versions and a usable previous generation during publication failure. It leaves the approved release path undefined after dry run, including how the exact source tag, signed generation and Pages promotion are bound and what happens on a retry after one of those effects succeeds. `scripts/prepare-native-package.sh:12-24` prepares a local artifact, and `tests/package/build-feed.sh:20-43` stages a local generation. Neither establishes the publication sequence required by the pinned `conventions/delivery.md:65-66,85-89`.
PROPOSAL: Resolve who owns the release and define the approved sequence, including how a retry reuses the verified inputs, how a conflicting existing version is handled, and how an interrupted promotion preserves or restores a usable generation. Exercise that sequence on an isolated feed before publication is authorized.

FINDING: F-05
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary; Design / PHP quality and compatibility and GitVersion and release preparation; Test Plan / AC-08
EVIDENCE: The owner summary retains the earlier style, static analysis and behavior test description and says implementation follows acceptance. It omits the revised scanner and installed-target proof, the exact-source native version design and the split between dry-run preparation and separately approved publication. The pinned `conventions/feature-documents.md:80-88` requires the summary to reflect material changes to scope, proof and decisions since acceptance.
PROPOSAL: Refresh the summary with the new security and package-version requirements. Distinguish observed fixture results, remaining proof and the decisions reserved for release approval.

FINDING: F-06
KIND: factual
SEVERITY: should-fix
WHERE: Context / Verified upstream behavior; Design / Scheduling and failure isolation; Acceptance Criteria and Test Plan / AC-05
EVIDENCE: The design requires the encrypted provider to execute after an earlier provider throws an ordinary exception and the shared runner to report aggregate failure. The AC-05 row also accepts the encrypted provider being skipped if its independent health check visibly fails. That alternative can pass with the exact scheduling regression the design requires the test to catch.
PROPOSAL: Require both encrypted-provider execution and the shared runner's aggregate failure in the ordinary-exception scenario. Keep stopped-scheduler and stale-receipt detection as separate observations.

### R-8

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Design / Packaging and contribution and GitVersion and release preparation, Resolved Decisions / Q1, Test Plan / AC-09
EVIDENCE: The Q1 revision puts the promotion sequence and fixture-only authorization in a new `Resolved Decisions` section. The pinned feature-document rules include Scope, Design, Acceptance Criteria, Test Plan and `covers` in the normative baseline. AC-09 now references the workflow, but a later edit to the authorization boundary, promotion sequence or retry rules in `Resolved Decisions` could leave an acceptance current.
PROPOSAL: Fold the approved workflow, fixture-only authorization and production approval boundary into the normative sections. Keep the decision history separately if needed.

FINDING: F-02
KIND: judgement
SEVERITY: should-fix
WHERE: Context / Owner summary, Design / Packaging and contribution and GitVersion and release preparation, Resolved Decisions / Q1, Test Plan / AC-09, Open Questions
EVIDENCE: Q1 now starts by resolving an approved tag. `.github/workflows/php.yml:41-48,68-69` runs versioning in dry-run mode and checks that the tag output is empty. The reviewed repository has no local tags, and the design leaves the first tag's creation and approval outside the workflow without naming an owner or sequence. The fixture proof can pass with a precreated tag while leaving the first release's input path undefined.
PROPOSAL: Resolve who creates the exact tag, when it may be created and how fixture validation supplies its tag without production effects. Include a moved-tag or conflicting-tag rejection in the workflow proof.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Design / Packaging and contribution, Acceptance Criteria and Test Plan / AC-09, Tasks / T9, Resolved Decisions / Q1 steps 3 and 4
EVIDENCE: The Q1 revision carries old packages forward into the new generation, then restores the previous deployment if verification fails. A client can fetch the new catalogue before rollback and request a newly advertised package after rollback, when the previous deployment lacks that file. AC-09 checks that an older catalogue can retrieve its package during promotion and that the previous generation installs after rollback. Both checks can pass while the client holding the new catalogue fails.
PROPOSAL: Define package availability for catalogues served immediately before and after rollback. Exercise both directions with a catalogue fetch followed by a package fetch across the deployment change.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Design / Packaging and contribution and GitVersion and release preparation, Acceptance Criteria and Test Plan / AC-09, Tasks / T9 and T13, Resolved Decisions / Q1
EVIDENCE: The Q1 revision requires an owner-dispatched workflow and fixture promotion with interruption, replay and conflicting digests. T9 covers native signed-feed verification and T13 covers version and source identity. Neither names the release workflow, its permission checks or its promotion and recovery tests. AC-09 also gives no pass condition for an unauthorized dispatch or fixture execution attempting to access production credentials or deployments.
PROPOSAL: Assign the workflow and fixture proof to a task and make the dispatch authority and production isolation observable in AC-09. Prove that an unauthorized request cannot publish and that fixture execution cannot reach production signing or deployment resources.

FINDING: F-05
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary and Verified upstream behavior, Design / PHP quality and compatibility, Acceptance Criteria and Test Plan / AC-08, Tasks / T8, T11 and T12, Sources
EVIDENCE: The spec describes `d59008a3d135dfac17e93033a854dc67065d7a40` as the PHP convention pinned by AGENTS.md. AGENTS.md pins `1edeb5f32d868bbe761ef3221f350634cd6ff022`, whose PHP convention adds the Security checks section. The revised AC-08 proof requires scanner coverage and disposition of findings, while the criterion still describes syntax, style, static analysis and behavior tests without an explicit security outcome.
PROPOSAL: Cite the actual pin and align the design and AC-08 with its security requirements. Keep the existing distinction between incomplete checks, unresolved findings and independently reviewed owner dispositions.

FINDING: F-06
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary and Verified upstream behavior, Design / PHP quality and compatibility and GitVersion and release preparation, Test Plan / AC-08 and AC-09, Resolved Decisions / Q1
EVIDENCE: The owner summary still says the owner approved implementation after the Pages clarification and that this phase produces an installation and recovery design. It omits the latest workflow decision and its fixture-only authorization. The revised security and versioning paragraph sits under `Verified upstream behavior`, and the summary does not distinguish the earlier native fixture observations in `docs/compatibility.md` from the pending workflow proof.
PROPOSAL: Update the summary with the owner-dispatched workflow, the fixture-only authorization and the production decisions still reserved to the owner. Summarize the revised security and versioning requirements alongside their observed and pending proof.

FINDING: F-07
KIND: factual
SEVERITY: should-fix
WHERE: Design / Configuration and secret handling and Guarded migration and recovery, Acceptance Criteria and Test Plan / AC-03, Tasks / T7 and T11
EVIDENCE: AC-03 requires validated configuration and secret custody to survive restore and upgrade. Its proof asks for secret persistence, modes, independent recovery and rotation, but does not require checking those properties after a native restore and after a package upgrade. AC-01 and AC-02 check upgrade and configuration import separately, so both can pass while credential references, permissions or key identifiers break across either transition.
PROPOSAL: Add explicit restore and upgrade scenarios that verify settings, credential references, key identifiers, protected file handling and successful delivery after independent reprovisioning where required.

### R-9

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Design / GitVersion and release preparation and Signed-feed promotion (Q1), steps 1 and 2 and retry paragraph; Test Plan / AC-09; Tasks / T9 and T13
EVIDENCE: The R-8 F-02 revision assigns tag creation to the shared workflow and requires the feed dispatch to verify its output. The pinned workflow exposes `tag` and `version` as workflow outputs, and the tag action returns an empty pushed tag when the remote tag already exists. The spec does not say how a later dispatch retrieves the original run's outputs or recovers them if the tag push succeeds before the output is recorded. The AC-09 fixture can pass with a synthetic tag and supplied version without exercising that handoff. [Pinned version workflow](https://github.com/vhco-pro/version-workflow/blob/3b78b04df802ea1592cbe19338d7a882d1888389/.github/workflows/version.yml#L37-L59), [pinned tag action](https://github.com/michielvha/gitversion-tag-action/blob/8cf5869816cf71437052ac97d086e00526bf2d89/scripts/tag.sh#L17-L26).
PROPOSAL: Define a durable record from the approved shared run that binds the repository, workflow run and attempt, source SHA, version and tag, and require the feed dispatch to verify it. Exercise the handoff on isolated inputs, including a tag created before output recording fails and a rerun with an empty tag output.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Design / GitVersion and release preparation and Signed-feed promotion (Q1), step 1; Test Plan / AC-09; Tasks / T13
EVIDENCE: The R-8 F-02 revision names default-branch and configured preview-label tagging while the native mapper accepts only stable versions and numbered alpha, beta and rc versions. `docs/installation.md:29` records a branch-named GitVersion preview that the mapper rejects, and `.github/workflows/php.yml:68-74` deliberately skips native version preparation for that class of preview. AC-09 can pass with a supported synthetic tag without showing how dispatch handles a valid shared tag whose version is ineligible for the feed.
PROPOSAL: State that feed eligibility requires a supported native version mapping and prove that a valid shared branch-preview tag with an unsupported label is rejected before build or signing.

FINDING: F-03
KIND: factual
SEVERITY: blocking
WHERE: Design / Packaging and contribution and Signed-feed promotion (Q1), steps 3 through 5; Acceptance Criteria and Test Plan / AC-09; Tasks / T9
EVIDENCE: The R-8 F-03 repair requires a recovery generation containing the previous signed catalogue and packages advertised by both catalogues. Step 4 requires that generation before promotion, but Packaging and contribution identifies this as the first feed release. The spec supplies no bootstrap path when no previous signed catalogue or production deployment exists. An established two-generation fixture can pass AC-09 while the first publication cannot follow the specified sequence.
PROPOSAL: Define first publication from an empty feed, including the recovery state before any catalogue has been served and package availability if a client has already fetched the first catalogue. Exercise initial publication, interrupted activation and retry separately from an update to an established feed.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Design / Packaging and contribution and Signed-feed promotion (Q1), steps 4 and 5 and retry paragraph; Test Plan / AC-09; Tasks / T9
EVIDENCE: The R-8 F-03 repair prepares and stages a distinct recovery generation. The retry paragraph covers a matching deployed generation or an unexpected live deployment, and the fixture proof covers a lost response after forward promotion. It leaves the case where recovery activation succeeds but its response is lost undefined. Cloudflare Pages rollback targets must be prior production deployments, so the staged recovery generation also needs a defined production activation path. [Cloudflare Pages rollback documentation](https://developers.cloudflare.com/pages/configuration/rollbacks/).
PROPOSAL: Define how the staged recovery generation is activated in production and how retry recognizes its exact deployment and digest after an interrupted or ambiguous recovery. Add an AC-09 case that verifies package retrieval from both catalogues after that retry.

FINDING: F-05
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary; Design / PHP quality and compatibility, GitVersion and release preparation and Signed-feed promotion (Q1); Acceptance Criteria and Test Plan / AC-08 and AC-09
EVIDENCE: The R-8 F-06 repair identifies fixture-only authorization and the outstanding feed tests. After the F-02 revision, the summary still omits that the shared workflow owns automatic tagging after separate authorization and that the owner dispatch only verifies and consumes its result for feed promotion. It mentions the Python advisory but omits AC-08's required scanner coverage and disposition rule. It also omits the earlier exact-source package and signed-catalogue agreement recorded in `docs/compatibility.md:56`. The pinned `conventions/feature-documents.md:80-88` requires the summary to reflect material decisions and distinguish observed proof from planned checks.
PROPOSAL: Update the summary to explain shared tag ownership, review-time dry run and the feed dispatch boundary. Include the scanner acceptance condition and distinguish the observed package/catalogue agreement from pending workflow and promotion proof.

### R-10

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary; Design / GitVersion and release preparation and Signed-feed promotion (Q1), release identity paragraph and step 1; Test Plan / AC-09; Tasks / T9 and T13
EVIDENCE: The R-9 F-01 repair allows a successful rerun with an empty tag output to establish release identity from the calculated version and the current remote tag target. The pinned workflow exports the version even when its branch or dry-run gate disables tagging. The pinned tag script also returns an empty output for any existing remote tag with the expected name. A successful calculation and a matching tag target therefore do not establish that the shared release workflow created the tag. AC-09 can pass without exercising a matching tag created outside the approved release path. [Pinned version workflow](https://github.com/vhco-pro/version-workflow/blob/3b78b04df802ea1592cbe19338d7a882d1888389/.github/workflows/version.yml#L37-L102) [Pinned tag script](https://github.com/michielvha/gitversion-tag-action/blob/8cf5869816cf71437052ac97d086e00526bf2d89/scripts/tag.sh#L17-L26)
PROPOSAL: Require evidence that binds the existing immutable tag to the approved shared release path during reconciliation. Exercise rejection of a matching tag with unverified origin and keep the feed publisher read-only on source refs.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Design / Packaging and contribution and Signed-feed promotion (Q1), steps 3 through 5 and retry paragraph; Acceptance Criteria and Test Plan / AC-09; Tasks / T9
EVIDENCE: The R-9 F-03 and F-04 repairs define a bootstrap recovery generation and recognize the candidate and recovery digests after an ambiguous deployment response. Step 5 stops if neither digest matches, which also covers a request that failed before changing production. On first activation, the unchanged state may have no production deployment or manifest. On an established feed, the unchanged state may be the recorded previous generation. AC-09 can pass by simulating lost responses only after the candidate or recovery went live.
PROPOSAL: Define how retry recognizes the recorded pre-activation state, including the absence of a first production deployment, and when it may resubmit the same approved bytes. Exercise ambiguous requests with and without a production change for both candidate and recovery deployment.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Design / Packaging and contribution and Signed-feed promotion (Q1), steps 4 and 5; Acceptance Criteria and Test Plan / AC-09; Tasks / T9
EVIDENCE: The R-9 F-03 repair requires bootstrap recovery to keep first-generation package URLs available while returning catalogue absence to new clients. AC-09 checks retrieval using a cached first catalogue across bootstrap recovery, but it does not require a fresh client to observe catalogue absence afterward. A recovery deployment that continues advertising the first catalogue can pass the stated proof.
PROPOSAL: Verify both outcomes after bootstrap recovery, including after an ambiguous recovery response. Require a fresh client to observe catalogue absence and a client holding the first catalogue to retrieve and verify the advertised package.

### R-11

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Design / GitVersion and release preparation; Design / Signed-feed promotion (Q1), release identity paragraph and step 1; Test Plan / AC-09
EVIDENCE: The R-10 revision defines recovery through an approved successful rerun, its version and source SHA, and the matching immutable remote tag. The pinned tag script at `8cf5869:scripts/tag.sh:17-26` confirms that an existing tag yields an empty `pushed-tag` output. Step 1 still requires resolving the tag emitted by the shared workflow. A publisher following that step cannot proceed in the empty-output case that AC-09 requires it to recover.
PROPOSAL: Make the verified release identity record the input to step 1 for both initial publication and reconciliation. Require AC-09 to carry the recovered identity through the same pre-build checks using the approved run and attempt, calculated version, full source SHA and immutable remote tag.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Design / Packaging and contribution, interrupted publication; Design / Signed-feed promotion (Q1), steps 3 through 5, retry paragraph and fixture proof; Test Plan / AC-09; Tasks / T9
EVIDENCE: The R-10 F-02 correction records the pre-activation state and permits retry only once the original request is no longer in flight. Step 5 directs the publisher to query the live deployment but leaves unspecified how it identifies the intended production deployment after losing the create response or establishes that an earlier request has finished while the source state is still live. AC-09 can pass with a fixture that makes those states immediately knowable. The R-10 F-03 correction is present in AC-09, which now checks both catalogue absence for a fresh client and package verification for a client holding the first catalogue after ambiguous bootstrap recovery. [Cloudflare Pages deployment creation](https://developers.cloudflare.com/api/resources/pages/subresources/projects/subresources/deployments/methods/create/index.html) [Cloudflare Pages deployment listing](https://developers.cloudflare.com/api/resources/pages/subresources/projects/subresources/deployments/methods/list/)
PROPOSAL: Specify the evidence that correlates a production deployment with the recorded activation attempt and establishes when retry from the unchanged source is safe. Exercise a delayed activation while the source still appears unchanged, and require the publisher to stop when the original request's status remains unknown.

### R-12

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary; Design / GitVersion and release preparation; Design / Signed-feed promotion (Q1), release identity paragraph, step 1 and fixture proof; Test Plan / AC-09; Tasks / T9 and T13
EVIDENCE: The R-11 F-01 revision gives the original run and the reconciled rerun the same pre-build checks. The remaining ambiguity is what qualifies a rerun for the approved release path. The pinned version workflow calculates a version when its tag gate is closed and exposes the same empty tag output as a tag-eligible run that finds an existing tag. Its reusable outputs do not expose the gate decision or skip reason. A preview rerun can therefore succeed with the same SHA, version and remote tag after the PR loses its preview label or closes. Those values alone cannot establish whether that attempt met the intended release policy. [Pinned version workflow](https://github.com/vhco-pro/version-workflow/blob/3b78b04df802ea1592cbe19338d7a882d1888389/.github/workflows/version.yml#L37-L102)
PROPOSAL: Specify the trusted evidence the publisher uses to distinguish an approved reconciliation attempt from ordinary dry-run CI, including how a changed preview gate affects reconciliation. Exercise two attempts with identical SHA, version and remote tag but different release authorization.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Design / Packaging and contribution, interrupted publication; Design / Signed-feed promotion (Q1), steps 3 through 5, retry paragraph and fixture proof; Acceptance Criteria and Test Plan / AC-09; Tasks / T9
EVIDENCE: The R-11 F-02 revision correlates Pages records with a recorded activation attempt and withholds resubmission while that attempt is unresolved. The hold is stated for a retry of the same activation. The spec does not require a later dispatch for a different generation to discover and honor the unresolved attempt before recording its own source state. If the first runner exits after sending a request and Pages has yet to list it, serializing workflow runs still allows the later dispatch to treat the old source as current while the earlier request can complete. AC-09 exercises resubmission of identical inputs and can pass without exercising this case. [GitHub Actions concurrency](https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency)
PROPOSAL: Require every production dispatch to reconcile outstanding attempts for the feed from records persisted before submission, including after cancellation or runner loss. Test a fresh dispatch for a different generation while an earlier candidate or recovery request is delayed, and require zero production submissions until the earlier attempt is resolved.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Design / GitVersion and release preparation; Design / Signed-feed promotion (Q1), release identity paragraph, step 1, retry paragraph and fixture proof; Test Plan / AC-09; Tasks / T9 and T13
EVIDENCE: The release identity recovery path depends on a retained workflow artifact or an approved rerun. GitHub permits reruns only within 30 days of the initial run, and workflow artifacts expire according to repository retention settings. The spec gives no publication or recovery boundary for an approved tag whose evidence has expired and whose run can no longer be rerun. AC-09 can pass with immediate recovery while a later owner dispatch has no defined outcome. [GitHub workflow rerun window](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs) [GitHub artifact retention](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#configuring-the-retention-period-for-checks-workflow-runs-commit-statuses-artifacts-and-logs-in-your-repository)
PROPOSAL: Define how long the release evidence must remain independently retrievable and what the publisher reports when neither the record nor an eligible rerun is available. Test the expired-evidence case with the canonical tag still present.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Design / Packaging and contribution, immutable artifacts and cached catalogues; Design / Signed-feed promotion (Q1), steps 3 through 5; Acceptance Criteria and Test Plan / AC-09; Tasks / T9
EVIDENCE: Candidate staging carries forward packages needed by older cached catalogues, while the recovery generation explicitly requires only packages advertised by the current and candidate catalogues. Across three generations, a package can still be needed by a client holding the oldest catalogue even though neither of the two newest catalogues advertises it. A recovery generation can drop that package and still pass AC-09 because the proof checks clients holding only the two catalogues adjacent to the activation.
PROPOSAL: Apply the same cached-catalogue retention rule to candidate and recovery generations. Exercise a third, still-supported cached catalogue whose package is absent from both adjacent catalogues and verify retrieval after recovery.

FINDING: F-05
KIND: judgement
SEVERITY: should-fix
WHERE: Context / Owner summary, migration and recovery; Design / Provider and ownership; Design / Guarded migration and recovery; Acceptance Criteria and Test Plan / AC-01, AC-03 and AC-06; Open Questions
EVIDENCE: The design preserves encrypted archives and recovery material, and AC-06 tests interruption during cutover. It leaves rollback after new credentials have been saved undefined. Re-enabling the legacy capture hook at that point can write the complete configuration into plaintext Git history, defeating the migration guarantee. Package removal retaining backup data does not determine which writer may run or which configuration can safely be restored.
PROPOSAL: Put the post-activation rollback policy to the owner, with keeping the legacy plaintext writer disabled as the recommended default. Verify rollback after a synthetic new credential has been saved, proving that recovery remains available and the credential never enters legacy plaintext history.

### R-13

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary; Design / Guarded migration and recovery; Acceptance Criteria / AC-03 and AC-06; Test Plan / AC-03 and AC-06; Tasks / T6
EVIDENCE: The R-12 F-05 revision keeps the legacy writer disabled after credentials are saved and directs rollback through the verified archive and native encrypted restore. The final archive precedes the credential save. The pinned Backups handler saves configuration before calling the provider, and the first backup can fail. The spec does not say which state rollback must recover in that interval, and the test can exercise rollback after a successful first backup. [Pinned native Backups handler](https://github.com/opnsense/core/blob/d20f63c7f7e73c062a623953690c0668070a8d94/src/www/diag_backup.php#L391-L398)
PROPOSAL: Define the recoverable configuration and credential state after save and before the first verified encrypted delivery. Exercise an interrupted or rejected first delivery in that interval and verify recovery with the legacy writer disabled.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Design / Packaging and contribution; Design / Signed-feed promotion (Q1), steps 3 through 5; Acceptance Criteria and Test Plan / AC-09; Tasks / T9
EVIDENCE: Step 4 requires the recovery generation to serve the previous signed catalogue. If the failed promotion also rotates the signing key and clients have already revoked the previous key, those clients reject that catalogue even though its packages remain available. AC-09 can pass by testing rollback and key revocation separately.
PROPOSAL: Define which catalogue and trust configuration a client uses to recover after a failed rotation at each trust transition. Exercise recovery with a client that has already removed trust in the previous key.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Design / Signed-feed promotion (Q1), steps 3 through 5 and retry paragraph; Test Plan / AC-09; Tasks / T9
EVIDENCE: The R-12 F-02 revision requires a durable activation record before submission and holds later dispatches while an attempt is unresolved. A runner can exit after writing that record but before sending the request. In that case Pages will never report a matching deployment or terminal outcome, and the spec supplies no recovery path for the feed. AC-09 covers runner loss with a delayed request but does not exercise loss before submission.
PROPOSAL: Define how the operator can resolve an attempt that was never submitted while preserving the hold when submission remains uncertain. Test runner loss on both sides of submission and verify that a later dispatch proceeds only after the earlier attempt is safely resolved.

FINDING: F-04
KIND: factual
SEVERITY: nit
WHERE: Test Plan / AC-09
EVIDENCE: The release identity revision at `docs/specs/native-encrypted-git-backup.md:264` permits recovery from a successful shared calculation for the reviewed SHA and its matching immutable remote tag. The proof still calls that calculation an approved shared rerun, although the same row separately requires current owner approval for production dispatch.
PROPOSAL: Describe the rerun as a successful pinned shared calculation and keep the owner approval requirement on the production dispatch.

### R-14

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Design / Signed-feed promotion (Q1), step 5 and activation record; Test Plan / AC-09; Tasks / T9
EVIDENCE: The R-13 F-03 repair makes a terminated runner's `prepared` attempt safe to discard. A runner can still terminate after persisting `submission-started` and before sending the Pages request. In that case Pages has no deployment to report, and the rules at lines 274 and 276 leave the feed indefinitely blocked. AC-09 tests loss in `prepared` and loss with a delayed request, so both tests can pass while this window remains.
PROPOSAL: Define an authoritative way to resolve the no-request case while preserving the hold for a request that could still land. If there is no such mechanism, make indefinite suspension an explicit owner decision and test the crash immediately after `submission-started` is persisted.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Design / Packaging and contribution; Design / Signed-feed promotion (Q1), steps 3 through 5 and retry; Acceptance Criteria and Test Plan / AC-09; Tasks / T9
EVIDENCE: The R-13 F-02 repair provides predecessor-signed and successor-signed recovery catalogues, but step 5 promotes one set of recovery bytes to a single production feed. Lines 271 through 276 give no selection rule or client routing during a mixed-trust rollout. The documented `pubkey` fixture uses a single configured key, so separately testing recovery before and after retirement can pass while clients with different trust configurations cannot both refresh the same production feed. [Native pkg signing modes](https://github.com/freebsd/pkg/blob/main/docs/pkg-repo.8)
PROPOSAL: Define the supported client trust states, the condition for switching the served recovery catalogue, and the approved recovery digest for each transition. Exercise failed promotion with clients in every trust state allowed to coexist.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary; Design / Guarded migration and recovery; Acceptance Criteria / AC-03 and AC-06; Test Plan / AC-06; Tasks / T6
EVIDENCE: The R-13 F-01 repair identifies the pre-cutover checkpoint as the guaranteed remote recovery point. Lines 206 through 211 define the checkpoint by the final legacy Git tip and previous remote ancestor, and `docs/recovery.md:9-15` verifies those objects and archive integrity. Neither establishes that the final tip contains a complete, restorable pre-cutover configuration. AC-06 can pass with a fixture where the tip happens to contain the expected configuration, leaving the recovery guarantee unproven when legacy capture lagged or missed a save.
PROPOSAL: State which configuration the checkpoint guarantees and verify that exact restore input from independently retained material before saving new credentials. Exercise a stale legacy tip and reflect the verified recovery point and first-delivery gap in the owner summary.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Design / Signed-feed promotion (Q1), release identity retention, steps 2 through 5 and retry; Test Plan / AC-09; Tasks / T9
EVIDENCE: Lines 264 and 276 retain approval and deployment records, while retry requires the same approved manifest and artifacts. The spec gives no retention or recovery rule for the actual candidate and recovery bytes across dispatches. A staged deployment or workflow artifact can disappear while an activation remains unresolved. A digest identifies the required bytes but cannot recover them, and the immediate retry cases in AC-09 can pass without covering their loss.
PROPOSAL: Define how later dispatches retrieve and verify the exact approved candidate and recovery bytes for as long as either may still be needed. Test loss of the original runner and its temporary artifacts before recovery is required.

### R-15

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary; Design / Signed-feed promotion (Q1), steps 2 through 5 and activation record; Acceptance Criteria / AC-09; Test Plan / AC-09; Tasks / T9
EVIDENCE: The R-14 F-01 revision tests the crash before the request is sent. Lines 274-276 withhold resubmission and newer production activations, but give no ordering rule that holds signing, staging uploads, URL changes or retirement until reconciliation. AC-09 checks zero submissions, so a dispatch can pass while making other feed changes during the hold.
PROPOSAL: Require read-only reconciliation before any feed effect and verify that retry and newer dispatches perform zero feed mutations while an earlier submission remains unresolved.

FINDING: F-02
KIND: judgement
SEVERITY: should-fix
WHERE: Context / Owner summary; Design / Signed-feed promotion (Q1), step 5 and activation record; Test Plan / AC-09; Tasks / T9; Open Questions
EVIDENCE: The R-14 F-01 revision safely holds an attempt after a crash between recording submission-started and sending the request. Lines 274-276 leave that hold without a time limit, but refer to authoritative confirmation of non-submission without defining an accepted source or the transition it permits. The owner summary omits the possibility that publication remains suspended indefinitely, and Open Questions says None.
PROPOSAL: State that the owner-directed hold can remain in force indefinitely when no qualifying evidence arrives, and define any accepted evidence of non-submission and the transition it permits consistently in the design and proof.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Design / Packaging and contribution; Design / Signed-feed promotion (Q1), steps 3 through 5 and activation record; Acceptance Criteria / AC-09; Test Plan / AC-09; Tasks / T9; docs/installation.md
EVIDENCE: The R-14 F-02 revision assigns separate catalogue URLs and pins the predecessor during overlap. Lines 272-276 leave their Pages deployment relationship and retirement transition undefined. If the paths share a production deployment, successor activation and rollback can replace both paths, while a record keyed by catalogue URL can serialize them independently. AC-09 checks simultaneous client use but can pass without testing concurrent actions against a shared deployment or a client with a supported predecessor catalogue after URL retirement.
PROPOSAL: Define the Pages deployment boundary, serialize changes at that boundary, and specify how each approved bundle preserves both paths and their package URLs for the supported cache lifetime. Exercise concurrent rotation actions and package retrieval from a cached predecessor catalogue across retirement.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary; Design / Provider and ownership; Design / Guarded migration and recovery; Acceptance Criteria / AC-03 and AC-06; Test Plan / AC-06; Tasks / T3 and T6; docs/installation.md; docs/recovery.md
EVIDENCE: The R-14 F-03 revision adds a current native export, but lines 205-211 still permit secret persistence immediately after checking the legacy Git tip. Line 224 places the export requirement separately and mixes verification of the exact configuration with restoration using synthetic data. The checkpoint described in docs/recovery.md and required by docs/installation.md binds only the legacy bundle and Git identities. The stale-tip recovery test can pass even if activation accepts a missing, stale or unverified export.
PROPOSAL: Define what independently verifies the actual retained export, how it is bound to the cutover checkpoint, and how a configuration change between export and credential save invalidates that checkpoint. Require rejection before secret persistence for missing, stale or invalid export evidence.

FINDING: F-05
KIND: factual
SEVERITY: should-fix
WHERE: Design / Signed-feed promotion (Q1), release identity retention, steps 2 through 5 and activation record; Test Plan / AC-09; Tasks / T9
EVIDENCE: The R-14 F-04 revision requires durable bundles and tests loss of temporary artifacts. Lines 269-276 do not require independent read-back of both approved bundles before a request can enter submission-started. A runner can stage both bundles, submit the candidate and die before durable retention finishes. A later dispatch would stop on the missing recovery bundle and could leave a failed candidate live. AC-09 can pass if the workspace is deleted only after both bundles happen to be retained.
PROPOSAL: Make durable read-back and digest verification of the approved candidate and recovery bundles a prerequisite for submission-started. Prove that interrupted retention and missing or corrupt bundles prevent activation, then verify recovery after loss of all runner and staging copies.

FINDING: F-06
KIND: factual
SEVERITY: should-fix
WHERE: Design / Signed-feed promotion (Q1), step 5 and activation record; Acceptance Criteria / AC-09; Test Plan / AC-09; Tasks / T9
EVIDENCE: Lines 274-276 distinguish a matching live deployment from successful native validation, but only block newer generations until the earlier attempt is resolved. A dispatch could treat the matching deployment as resolved and release the feed before validation or recovery completes. A later rollback could then overwrite a newer promotion. AC-09 separately checks the unknown-submission hold and resumed validation, leaving that handoff untested.
PROPOSAL: Keep the activation record exclusive through successful native validation or verified recovery, and test a newer dispatch arriving after the candidate becomes live but before either terminal outcome.

### R-16

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Design / Signed-feed promotion (Q1), steps 2 through 5 and activation record; Acceptance Criteria and Test Plan / AC-09; Tasks / T9
EVIDENCE: The R-15 F-01 and F-06 revision requires read-only reconciliation before signing or uploading and keeps the activation record exclusive through validation or recovery. At lines 269-276, signing and staging precede the prepared activation record, and the design does not say when a dispatch acquires exclusive ownership of the Pages project. Two dispatches can both observe an empty record and start signing or staging. The AC-09 cases that start a second dispatch after an unresolved record already exists do not prove that this initial race is closed.
PROPOSAL: Require exclusive project ownership before the first feed effect and make the reconciliation result valid under that ownership. Test two dispatches starting against an empty record and verify that only the owner can sign, upload or proceed to activation.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Design / Signed-feed promotion (Q1), steps 4 and 5 and activation record; Acceptance Criteria and Test Plan / AC-09; Tasks / T9
EVIDENCE: The R-15 F-06 revision keeps the record exclusive until native validation or verified recovery. Lines 274-276 specify what to do when the candidate is live and what to record before submitting recovery, but leave the durable handoff between failed candidate validation and recovery unspecified. If a runner terminates in that interval, a later dispatch can revalidate and accept the candidate after a transient failure clears, even though step 5 requires publishing the approved recovery bytes on verification failure. AC-09 covers interrupted deployments and lost responses without requiring this handoff to survive runner loss.
PROPOSAL: Define when a validation failure commits the attempt to recovery and which durable state a later dispatch resumes. Test runner loss after that decision and before recovery submission, with a newer generation waiting.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary; Design / Provider and ownership; Design / Guarded migration and recovery; Acceptance Criteria and Test Plan / AC-03, AC-06 and AC-07; Tasks / T3, T6 and T11; docs/installation.md:9; docs/recovery.md:7-17
EVIDENCE: The R-15 F-04 revision makes independent retrieval and verification of the current native export a prerequisite for saving new credentials. The installation procedure still sends the operator to a version 1 checkpoint that records only the legacy bundle digest and Git identities. Activation.php:51-82 confirms that the existing parser has no export evidence fields. The feature does not specify how existing checkpoints are treated, and the AC-07 documentation walkthrough uses a fresh appliance without requiring the documented legacy cutover.
PROPOSAL: Require the migration procedure and checkpoint transition to carry the independently verified export and source digests, and define how existing version 1 checkpoints are handled before credential save. Exercise the documented legacy procedure with a version 1 checkpoint and require fresh verification before accepting it for cutover.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary; Design / Packaging and contribution; Design / Signed-feed promotion (Q1), steps 4 and 5 and activation record; Acceptance Criteria and Test Plan / AC-09; Tasks / T9
EVIDENCE: The R-15 F-02 revision explicitly permits an indefinite hold, and AC-09 tests both a crash before request transmission and a delayed request. The owner summary says the current live feed remains available during that hold. On first publication, step 4 requires the feed to start without a catalogue. If submission becomes ambiguous before any deployment appears, there is no previously verified feed to serve, and the hold can leave initial installation unavailable indefinitely.
PROPOSAL: State that the hold preserves whatever is already served, including catalogue absence before the first publication, and verify that initial absence persists while a first submission remains unresolved.

### R-17

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Design / Signed-feed promotion (Q1), step 5 and activation record; Test Plan / AC-09; Tasks / T9
EVIDENCE: The R-16 F-02 repair at lines 276 and 307 requires a subsequent dispatch to publish the approved recovery bundle after the original runner dies with recovery-required recorded. Line 307 also requires zero feed mutations on a retry while the earlier attempt is unresolved, explicitly including the interval before verified recovery. The required recovery upload occurs in that interval, so the proof can fail a correct implementation.
PROPOSAL: Require zero mutations while a submission outcome is unknown, and block newer generations until the earlier attempt is terminal. Separately require the exclusive holder to submit only the recorded recovery bundle when reconciliation permits recovery.

FINDING: F-02
KIND: factual
SEVERITY: blocking
WHERE: Context / Owner summary; Design / Packaging and contribution; Design / Signed-feed promotion (Q1), steps 4 and 5 and activation record; Acceptance Criteria and Test Plan / AC-09; Tasks / T9
EVIDENCE: The R-16 F-04 repair correctly states at line 65 that an ambiguous first submission can leave catalogue absence in place indefinitely. Lines 273 and 307 also require bootstrap recovery to serve no catalogue to fresh clients while preserving package retrieval for cached clients. Lines 235 and 292 still require a usable previous or preserved repository generation through failed publication without qualifying first publication, where there is no previous installable catalogue. The stated proof requires the first-publication state that the criterion fails to allow.
PROPOSAL: State the required outcomes for established feeds and first publication in AC-09 and the packaging design. Keep the existing proof of catalogue absence, cached package retrieval after bootstrap recovery, and the hold while the first submission outcome is unknown.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Design / Signed-feed promotion (Q1), project ownership and steps 2 through 5; Test Plan / AC-09; Tasks / T9
EVIDENCE: The R-16 F-01 repair at line 266 places exclusive ownership before any feed effect. The empty-record race proof at line 307 says only the holder can mutate the feed, which can be read as checking Pages changes alone. Under that reading, a dispatch can use the signing key and produce a signed catalogue before acquiring ownership and still pass the proof.
PROPOSAL: Instrument both dispatches in the empty-record race and require the dispatch without ownership to perform zero signing, staging uploads, production submissions and retirement actions.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary; Design / Provider and ownership, Configuration and secret handling, and Guarded migration and recovery; Acceptance Criteria and Test Plan / AC-03, AC-06 and AC-07; Tasks / T3, T6 and T11
EVIDENCE: The R-16 F-03 repair at line 210 requires a new checkpoint when source configuration changes before credential save, and line 304 tests a change between export verification and save. The design leaves open how the final digest comparison and save are serialized with concurrent native configuration writes. The existing call sequence in EncryptedGit.php:93-112 shows the boundary the pending work must address: a separate privileged check returns before model serialization and Config::save(). A proof that changes the configuration before the final check can pass while a write after that check still leaves the retained export stale at save time.
PROPOSAL: Specify how the checked configuration revision remains valid through persistence, or require the save to fail when that revision changes. Inject a concurrent configuration write after the final digest check and before persistence.

FINDING: F-05
KIND: factual
SEVERITY: should-fix
WHERE: Design / Provider and ownership and Guarded migration and recovery; Acceptance Criteria and Test Plan / AC-03, AC-06 and AC-07; Tasks / T3, T6 and T11
EVIDENCE: The R-16 F-03 repair at line 210 bars version 1 checkpoints from authorizing credential save, but defines version 2 only alongside verified legacy archive evidence. The existing checkpoint contract in docs/recovery.md:15 and Activation.php:51-68 also covers fresh installations with legacy set to null. The revised baseline does not say which checkpoint version or export evidence a fresh installation needs. AC-06 tests version 1 only during legacy cutover, and AC-07 can pass under either interpretation.
PROPOSAL: Specify the checkpoint version and required evidence when there is no legacy repository. Add that expectation to the fresh-install walkthrough proof and keep the legacy version 1 rejection case.

### R-18

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Design / Provider and ownership and Guarded migration and recovery; Test Plan / AC-06 and AC-07; Tasks / T3, T6 and T11
EVIDENCE: The R-17 F-05 repair at line 210 requires a version 1 checkpoint with a null legacy entry for fresh activation. The same paragraph says without qualification that version 1 checkpoints cannot authorize credential save and makes persistence follow the checkpoint checks. AC-07 can verify that the version 1 file exists, but the unconditional ban prevents that file from authorizing the fresh setup the walkthrough requires.
PROPOSAL: State explicitly that version 1 with a null legacy entry authorizes fresh activation after the writer-absence check, and that version 1 with a legacy entry cannot authorize legacy cutover. Have AC-07 require a successful save and verified first delivery using the fresh checkpoint.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary; Design / Configuration and secret handling and Guarded migration and recovery; Acceptance Criteria and Test Plan / AC-03, AC-04 and AC-06; Tasks / T3, T5, T6, T7 and T11
EVIDENCE: The R-17 F-04 repair at line 210 binds the pre-cutover digest comparison to the native save boundary. The save itself changes the configuration, and NativeRun.php:22 currently calls the same Activation::check() used by the setup check. The revised baseline leaves unclear how a successful cutover is recognized after a crash between save and first delivery, or whether subsequent runs and credential rotation recheck the pre-cutover digest. Applying that comparison to every run would reject the expected post-save configuration.
PROPOSAL: Define how persisted state distinguishes a completed cutover from one that still needs verification. Specify the checks for first delivery, retries and later settings changes, and test restart immediately after persistence without requiring the source to match the pre-cutover digest.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Design / Signed-feed promotion (Q1), step 5 and activation record; Test Plan / AC-09; Tasks / T9
EVIDENCE: The R-17 F-01 repair separates an unknown submission from a permitted recovery upload. AC-09 now blocks newer generations until successful native validation or verified recovery. Step 5 also permits retry after definitive rejection or correlated terminal failure with the original live state unchanged. It leaves unclear how the owner can retire a conclusively failed candidate without reactivating it, and whether verifying the unchanged source satisfies the AC-09 release condition.
PROPOSAL: Define how the holder closes a definitively failed attempt when the original served state is verified, including catalogue absence on first publication. Test that transition separately from the indefinite hold for an unknown outcome.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary; Design / Packaging and contribution and Signed-feed promotion (Q1), steps 4 and 5; Acceptance Criteria and Test Plan / AC-09; Tasks / T9
EVIDENCE: The R-17 F-02 repair requires catalogue absence after bootstrap recovery. The proof does not specify how to distinguish an absent catalogue from a failed refresh against invalid content or an unavailable endpoint. Pages can serve the root response for missing assets when the deployment lacks a top-level 404 page. [Cloudflare Pages serving behavior](https://developers.cloudflare.com/pages/configuration/serving-pages/)
PROPOSAL: Define the expected response at each native catalogue endpoint after bootstrap recovery. Check those responses at the configured feed URL and independently verify that a client holding the first catalogue can still retrieve and authenticate its package.

FINDING: F-05
KIND: factual
SEVERITY: should-fix
WHERE: Review Log / R-6, AC-09
EVIDENCE: The R-17 F-02 repair also changed the historical R-6 criterion at line 430. The criterion at R-6's reviewed commit, 8cb6b119deb5802952c3ffc0cd3ab49a308bae0b, ends with the requirement to preserve a usable repository generation through failed publication and key rotation. The stored record now attributes the later bootstrap and catalogue-absence requirements to that review. The pinned feature-document convention requires stored review records to remain verbatim.
PROPOSAL: Restore the exact R-6 record from the parent commit and retain the revised requirements in the current baseline.

### R-19

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Context / Owner summary, line 65. Design / Packaging and contribution, line 235, and Signed-feed promotion (Q1), step 5 and activation record, lines 276-278. Acceptance Criteria and Test Plan / AC-09. Tasks / T9.
EVIDENCE: The R-18 F-03 correction permits closure after definitive failure if the original served state is verified. Step 5 records the live deployment before each submission, so the recorded source for a recovery submission can be the candidate that already failed native validation. If Pages definitively rejects recovery, that candidate can still be live and match the recorded source. The new closure rule permits releasing the project in that state, even though the prior usable catalogue or first-publication absence has yet to be restored. AC-09 exercises closure after rejection but does not distinguish candidate rejection from recovery rejection.
PROPOSAL: Allow closure without recovery only after verifying the served state from before candidate promotion. Test definitive recovery rejection while a failed candidate is still live, and require the recorded recovery decision to remain active and block newer work until recovery is verified.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary, lines 58-60. Design / Provider and ownership, line 135, and Guarded migration and recovery, lines 205-217 and 224. Acceptance Criteria and Test Plan / AC-01, AC-03, AC-06 and AC-07. Tasks / T3, T6, T8 and T11.
EVIDENCE: The R-18 F-01 and F-02 corrections give fresh setup and new legacy cutover distinct checkpoint rules and persist an activation identifier on save. Existing enabled installations can have a legacy version 1 checkpoint and no persisted activation identifier, as shown by Activation.php:51-68 and EncryptedGit.php:93-112. The upgrade promise at line 217 preserves settings, key identifiers and pending Git state, but gives no rule for continuing delivery, requiring re-verification or failing closed on this existing state. AC-03 tests delivery after an upgrade without requiring that starting state.
PROPOSAL: Specify how an already-enabled legacy version 1 installation transitions on upgrade and what happens if the upgrade is interrupted or reverted. Start a proof from the old configuration and pending Git state, then verify delivery or the documented hold and recovery path.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Design / Provider and ownership, lines 131-141, Configuration and secret handling, lines 167-180, Snapshot and Git consistency, lines 191-195, and Guarded migration and recovery, lines 209-210 and 224. Acceptance Criteria and Test Plan / AC-03, AC-04 and AC-06. Tasks / T3, T5, T6 and T7.
EVIDENCE: The R-18 F-02 correction says saved activation identifies completed cutover and that later runs recheck current settings. Activation.php:27-32 and 54-64 bind the existing checkpoint to the destination and branch, and NativeRun.php:22 uses the checkpoint to obtain the expected legacy parent. The revised design leaves open which settings changes invalidate the saved activation and whether the legacy parent comes from the checkpoint identified by that save or a replacement checkpoint. The restart, restore and rotation proofs can pass without changing the target or replacing the checkpoint.
PROPOSAL: Define the settings and evidence bound to persisted activation, and specify when a target change or checkpoint replacement requires fresh verification. Test that credential rotation on the same target continues while an unverified target or mismatched checkpoint cannot inherit the prior activation.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary, line 65. Design / Packaging and contribution, lines 235-242, and Signed-feed promotion (Q1), steps 3-5. Acceptance Criteria and Test Plan / AC-09. Tasks / T9.
EVIDENCE: The R-18 F-04 correction requires HTTP 404 at native catalogue and metadata URLs and separately checks cached-client package retrieval. The proof does not say to use the configured feed URL or to verify absence there before closing recovery. The design uses both staged deployments and a production URL, and Cloudflare documents that a proxied custom-domain cache can continue serving stale content after a deployment. A staging check can therefore pass while the configured feed URL still serves the withdrawn catalogue. [Cloudflare Pages serving behavior](https://developers.cloudflare.com/pages/configuration/serving-pages/#caching-and-performance)
PROPOSAL: Require the 404 and cached-package checks through the configured client-facing feed URL before recording verified recovery. Exercise the same hostname and cache behavior in the isolated fixture.

### R-20

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Design / Guarded migration and recovery, lines 210, 217 and 224. Acceptance Criteria / AC-01, AC-03, AC-06 and AC-07. Test Plan / AC-03 and AC-06. Tasks / T6, T8 and T11.
EVIDENCE: The R-19 F-02 revision permits resuming delivery after reverting to the old encrypted provider. The required transition replaces the legacy version 1 checkpoint with version 2 evidence. The old provider reads the active checkpoint on every run, and Activation.php:20-32 and 54-64 reject any version other than 1. Verifying the previous destination and pending ancestry cannot make that provider accept a version 2 checkpoint. AC-03 allows an interrupted-upgrade rollback test to pass before the version 2 activation has been saved.
PROPOSAL: Define the rollback state after a successful version 2 activation, including when the older provider can safely resume and what checkpoint it must use. Exercise rollback both before and after the activation save, with pending Git state retained and the plaintext writer disabled.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Design / Guarded migration and recovery, lines 210 and 217. Acceptance Criteria / AC-01, AC-03 and AC-07. Test Plan / AC-03 and AC-07. Tasks / T3, T8 and T11.
EVIDENCE: The R-19 F-02 revision defines the upgrade hold for enabled version 1 installations with legacy history. Activation.php:51-68 also accepts a version 1 checkpoint with a null legacy entry, and EncryptedGit.php:93-112 can save enabled settings for that case without a persisted activation identifier. The new baseline defines how to authorize a fresh save and how to hold a legacy upgrade, leaving the existing enabled null-legacy installation undefined. AC-03 starts with legacy history and AC-07 starts with a fresh installation.
PROPOSAL: Specify whether an enabled null-legacy installation continues delivery or requires a new activation save on upgrade. Add an upgrade case from that existing state with pending work.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Design / Snapshot and Git consistency, lines 191-195, and Guarded migration and recovery, lines 210 and 217. Acceptance Criteria / AC-03, AC-04 and AC-06. Test Plan / AC-03, AC-04 and AC-06. Tasks / T3, T5 and T6.
EVIDENCE: The R-19 F-03 revision binds activation to the checkpoint digest and legacy parent, and requires re-verification when the checkpoint changes. It prohibits reuse of pending state from a previous target, but leaves pending work undefined when only the checkpoint changes and the destination and branch stay the same. GitDelivery.php:44-53 binds existing pending state to destination and branch, and lines 116-125 check the expected legacy parent only when there is no pending HEAD. AC-03 can pass by rejecting inherited activation before the new save, without checking which pending commits become eligible after that save.
PROPOSAL: Define when pending commits can be reused after checkpoint replacement on the same destination and branch, including a replacement with a different verified parent. Test the first delivery after reactivation with an existing pending commit.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary, line 65. Design / Packaging and contribution, lines 235 and 242, and Signed-feed promotion (Q1), steps 3-5 and the activation record at lines 273-278. Acceptance Criteria / AC-09. Test Plan / AC-09. Tasks / T9.
EVIDENCE: The R-19 F-04 revision explicitly gates verified bootstrap recovery on HTTP 404 checks through the configured client-facing URL. It does not explicitly gate closure on a client holding the first catalogue retrieving and verifying its package through that same URL. AC-09 can therefore pass a test that records recovery and releases the project after the 404 checks, then checks cached-client retrieval separately. A custom domain can serve cached responses before requests reach Pages. [Cloudflare Pages serving behavior](https://developers.cloudflare.com/pages/configuration/serving-pages/#caching-and-performance)
PROPOSAL: Require both the fresh-client absence checks and cached-client package verification through the configured client-facing feed URL before closing bootstrap recovery. Exercise a fixture where the catalogue checks pass while the cached client's package request fails.

FINDING: F-05
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary, line 65. Design / Signed-feed promotion (Q1), step 5 and the activation record at lines 276-278. Test Plan / AC-09. Tasks / T9.
EVIDENCE: The R-19 F-01 revision correctly distinguishes candidate rejection from recovery rejection and keeps recovery-required active when a rejected recovery leaves the failed candidate live. Step 5 permits retry after either a definitive candidate rejection or a correlated terminal failure, but only explicitly allows closure without retry after candidate rejection. AC-09 still permits closure after definitive failure with the original state verified, without limiting that clause to candidate rejection or resolving the candidate terminal-failure case.
PROPOSAL: State whether a correlated terminal failure of the candidate may close without retry after the pre-candidate served state is verified. Align AC-09 with that rule and preserve the separate requirement to verify recovery after candidate validation has failed.

### R-21

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Design / Guarded migration and recovery, lines 210, 217 and 224. Test Plan / AC-03, AC-06 and AC-07. Tasks / T6, T8 and T11.
EVIDENCE: The R-20 F-01 revision requires an independently retained version 1 checkpoint and matching settings at rollback, but gives no pre-upgrade step that retains and verifies those inputs before the active checkpoint can be replaced. The existing recovery guide retains the archive and password independently and writes the checkpoint to the active path. The revised proof can supply a compatible version 1 file directly from the fixture without proving that the operator can recover it after replacement.
PROPOSAL: Require independent retention and read-back verification of the compatible version 1 checkpoint and matching provider settings before replacing either. Exercise rollback with the active version 1 inputs gone and recover the required inputs through the documented operator procedure.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Design / Guarded migration and recovery, lines 210 and 217. Test Plan / AC-03 and AC-07. Tasks / T3, T8 and T11.
EVIDENCE: The R-20 F-02 revision requires an activation save before an already-enabled null-legacy installation can resume. AC-03 says to test that upgrade separately and verify the documented hold or safe old-plugin resume. It does not require an attempted delivery on the upgraded provider before the save, so a provider that silently keeps delivering can pass the upgrade and rollback proof.
PROPOSAL: For the enabled null-legacy upgrade, attempt a run with pending work before the activation save and require a hold with no push and no loss of pending state. Save the verified null-legacy activation, restart and verify resumed delivery.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Design / Snapshot and Git consistency, lines 191 to 195, and Guarded migration and recovery, lines 210 and 217. Test Plan / AC-03 and AC-04. Tasks / T3 and T5.
EVIDENCE: The R-20 F-03 revision requires pending ancestry to include the verified parent after same-target checkpoint replacement. A verified null-legacy version 1 checkpoint has no parent, as Activation.php lines 65 to 68 show. The rule leaves it unclear whether a pending commit with a null parent can be reused when the remote already contains that commit after a lost response. AC-03 only names compatible and incompatible ancestry, and AC-04 exercises lost responses without checkpoint replacement.
PROPOSAL: Define pending commit eligibility when the replacement checkpoint has no parent, including an absent remote tip and an already-delivered pending tip. Exercise the applicable cases after reactivation and verify that reconciliation records an already-completed delivery without pushing again.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary, line 65. Design / Signed-feed promotion (Q1), step 5 and activation record, lines 276 to 280. Test Plan / AC-09. Task / T9.
EVIDENCE: Step 5 permits validation to resume when the approved deployment is live after an ambiguous submission. The activation record then requires an unresolved hold whenever there is no correlated terminal outcome. AC-09 exercises resuming validation of the exact activated generation, but does not say what happens when its deployment identity and served digest are verified while Pages has yet to report a terminal outcome. One implementation can resume validation while another remains on hold for the same observed state.
PROPOSAL: State whether independently verified live identity and served digest permit validation before a correlated terminal outcome arrives, and test that case separately from an ambiguous submission with no verified matching deployment.

FINDING: F-05
KIND: factual
SEVERITY: nit
WHERE: Design / Packaging and contribution, line 235, and Signed-feed promotion (Q1), lines 273 and 278. Acceptance Criteria / AC-09. Test Plan / AC-09.
EVIDENCE: The R-20 F-04 revision establishes both closure checks through the configured client-facing URL in the activation record and adds a negative cached-package case to AC-09. The packaging summary still says to check HTTP 404 and “preserves package access for clients that already received it,” leaving a broken verb and an unclear antecedent.
PROPOSAL: Describe both pre-closure checks in the packaging summary and refer explicitly to clients that already received the first catalogue.

### R-22

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Context / Owner summary, line 65. Design / Signed-feed promotion (Q1), steps 4 and 5 and activation record, lines 273 and 276 to 280. Acceptance Criteria and Test Plan / AC-09. Tasks / T9.
EVIDENCE: The R-21 F-04 revision permits read-only validation when the exact live identity and digest are verified before a terminal outcome. Line 276 requires reconciliation before any further mutation, but line 278 and AC-09 allow successful native validation or verified recovery to release ownership without explicitly requiring that same evidence. A dispatcher could close the record after validation while the prior submission can still change production, then allow a newer dispatch to bypass the mutation hold.
PROPOSAL: Specify which evidence rules out a delayed write and require it before closing the record or permitting another mutation. Exercise early successful validation for both candidate and recovery, and verify that newer work remains blocked until the closure condition is met.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Design / Scheduling and failure isolation, line 162, Snapshot and Git consistency, lines 191 to 195, and Guarded migration and recovery, lines 209 to 210, 217 and 224. Test Plan / AC-03, AC-04, AC-06 and AC-07. Tasks / T3, T5, T6, T8 and T11.
EVIDENCE: The R-21 F-01 and F-02 revisions preserve rollback inputs and require a hold before activation, but do not define how rollback or reactivation excludes a delivery already in flight. NativeRun.php lines 22 to 27 resolve the checkpoint and credentials before GitDelivery.php line 41 takes the delivery lock. A run could therefore enter delivery using the superseded target, checkpoint or credentials after settings have changed or rollback has begun. The proof overlaps manual and scheduled runs, but does not overlap delivery with a settings or checkpoint transition.
PROPOSAL: Define how transitions quiesce or synchronize with delivery, including a run that has already read the old settings but has yet to acquire the delivery lock. Add an interrupted rollback and a reactivation test with an in-flight run and check for stale pushes and pending-state loss.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Design / Guarded migration and recovery, lines 210, 217 and 224. Test Plan / AC-03 and AC-07. Tasks / T3, T8 and T11.
EVIDENCE: The R-21 F-01 revision requires independent retention and read-back before either version 1 input is replaced. AC-03 removes the active inputs and recovers from the retained copy, but does not exercise retention and read-back as a prerequisite to replacement. A fixture that provides the copy in advance, or a procedure that can replace an input after failed read-back, could pass the listed proof.
PROPOSAL: Start with only the active version 1 checkpoint and settings, run the documented retention procedure, and inject missing or mismatched read-back before replacement. Then complete the procedure, remove the active copies and recover the retained inputs through the operator guide.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Design / Snapshot and Git consistency, lines 191 to 195, and Guarded migration and recovery, lines 210 and 217. Acceptance Criteria and Test Plan / AC-03 and AC-04. Tasks / T3 and T5.
EVIDENCE: The R-21 F-03 revision allows delivery to be recorded without another push when the remote retains the pending commit, but does not define whether retention includes a remote tip that descends from that commit. The new proof covers a retained pending commit without requiring a distinct descendant tip. GitDelivery.php lines 121 to 126 currently rejects that descendant as divergence, while the revised wording can be read to accept it.
PROPOSAL: Define separate outcomes for an exact remote tip, a descendant retaining the pending commit and unrelated history. For any descendant case that records success, specify which commit and artifact the receipt verifies, and exercise all three cases after same-target checkpoint replacement.

FINDING: F-05
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary, line 65. Design / Packaging and contribution, line 235, and Signed-feed promotion (Q1), steps 3 to 5 and activation record, lines 272 to 278. Acceptance Criteria and Test Plan / AC-09. Tasks / T9.
EVIDENCE: The R-21 F-05 revision makes both client-facing closure checks explicit, but the workflow still first requires the bootstrap recovery bundle to demonstrate native catalogue 404s and cached-client package retrieval after that bundle becomes production. Cloudflare Pages can apply SPA fallback to missing paths without a top-level 404 page, so omitting catalogue files alone does not establish the required response. [Cloudflare Pages serving behavior](https://developers.cloudflare.com/pages/configuration/serving-pages/)
PROPOSAL: Specify how the approved bootstrap recovery bundle produces real catalogue and metadata 404s. Verify both absence and cached-client package authentication on the staged recovery bundle before first activation, then repeat both checks through the configured client-facing URL before closure.

### R-23

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Context / Owner summary, line 65. Design / Packaging and contribution, line 235, and Signed-feed promotion (Q1), lines 276-280. Acceptance Criteria and Test Plan / AC-09. Tasks / T9.
EVIDENCE: The R-22 F-01 repair adds the hold and an explicit early-validation test for both candidate and recovery. Step 5 still allows any correlated terminal outcome to end the hold, while the activation record and AC-09 still name successful native validation or verified recovery as standalone release conditions. Neither defines what happens when validation passes early and the final outcome reports failure or the live deployment changes. The owner summary also says the hold preserves the served state, although Pages can still apply the outstanding request during the hold.
PROPOSAL: Use one closure rule throughout. Require correlated terminal deploy success and final confirmation of the same live deployment, served digest and applicable native checks for successful closure, and test early validation followed by terminal failure or a changed live deployment.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Design / Signed-feed promotion (Q1), lines 266 and 276-280. Test Plan / AC-09. Tasks / T9.
EVIDENCE: The R-22 F-01 repair assumes one Pages submission per recorded attempt. Cloudflare's create-deployment API documents commit_message as metadata and provides no documented idempotency guarantee for it. The official TypeScript client retries connection failures, timeouts and several HTTP errors by default. A terminal record for one request cannot settle a duplicate request still in flight. [Pages deployment API](https://developers.cloudflare.com/api/resources/pages/subresources/projects/subresources/deployments/methods/create/) [Cloudflare client retry behavior](https://github.com/cloudflare/cloudflare-typescript#retries)
PROPOSAL: Require one production create request per recorded attempt, including at the HTTP client layer, and keep the record open on conflicting matches. Count outbound create requests under injected timeouts for candidate and recovery.

FINDING: F-03
KIND: factual
SEVERITY: blocking
WHERE: Design / Scheduling and failure isolation, line 162, Snapshot and Git consistency, lines 191-195, and Guarded migration and recovery, lines 210, 217 and 224. Acceptance Criteria and Test Plan / AC-03, AC-04, AC-06 and AC-07. Tasks / T3, T5, T6, T8 and T11.
EVIDENCE: The R-22 F-02 repair allows either a shared lock or a durable pause during rollback. The rollback target at this revision takes delivery.lock in GitDelivery.php:35-55 and proceeds without checking a durable pause. NativeRun.php:22-37 also reads activation, credentials and configuration before that lock. A pause enforced only by the replacement provider cannot prevent the older provider from running against partially restored inputs after the old package is installed. AC-03 tests a stale run waiting for the lock but does not require invoking the older provider during the interrupted rollback.
PROPOSAL: Require a delivery hold that also binds the older provider across any interruption in package and input replacement. Exercise both native entry points after restoring only one rollback input and resume only after the matching pair and pending ancestry are verified.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary, lines 58-60. Design / Guarded migration and recovery, lines 210, 217 and 224. Test Plan / AC-03, AC-06 and AC-07. Tasks / T3, T6, T8 and T11.
EVIDENCE: The R-22 F-03 repair adds missing and mismatched read-back cases before input replacement, followed by recovery through the rollback procedure. The design requires the retained checkpoint and settings to match, but does not require reading them from one stable configuration state or verifying the retained settings against the exact active revision being replaced. A concurrent settings change can produce a readable checkpoint and a readable settings export from different states. AC-06 exercises a native configuration race at activation save, after the independent rollback copy could already be wrong.
PROPOSAL: Bind the retained pair to the settings revision being replaced and verify both inputs together before replacement. Inject a settings change during retention and require the transition to stop or recapture the pair.

FINDING: F-05
KIND: factual
SEVERITY: should-fix
WHERE: Design / Snapshot and Git consistency, lines 191-195, and Guarded migration and recovery, lines 208-210 and 217. Acceptance Criteria and Test Plan / AC-03, AC-04 and AC-06. Tasks / T3, T5 and T6.
EVIDENCE: The R-22 F-04 repair distinguishes exact, descendant and unrelated remote tips and exercises each outcome. The same paragraph still allows a verified absent remote to trigger an initial push without distinguishing a branch that never existed from a branch that disappeared after verified delivery or was required by the legacy checkpoint. The null-parent initial-push test can pass while the implementation silently recreates a deleted branch on an established target.
PROPOSAL: Define when branch absence authorizes an initial push and when it requires an explicit recovery decision. Test a never-created branch separately from a branch that disappears after a verified receipt or legacy checkpoint.

### R-24

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Context / Owner summary, line 65. Design / Packaging and contribution, line 235, and Signed-feed promotion (Q1), lines 273 and 276-278. Acceptance Criteria and Test Plan / AC-09, lines 292 and 307. Tasks / T9, line 325.
EVIDENCE: The R-23 F-01 repair correctly requires terminal success and fresh live verification for successful closure. The Packaging section and AC-09 still require preserving catalogue absence during unresolved first activation. The owner summary correctly says that an outstanding create request can take effect during the hold. The proof checks absence only when no deployment appeared, so it can pass without testing what the publisher does when the outstanding request first becomes live.
PROPOSAL: Define the hold as a prohibition on further publisher mutations. Test both continued absence and delayed first activation, and require the record to stay open until the applicable terminal and live checks pass.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Design / Signed-feed promotion (Q1), lines 274 and 276-280. Acceptance Criteria and Test Plan / AC-09, lines 292 and 307. Tasks / T9, line 325.
EVIDENCE: The R-23 F-01 repair says to discard early results on terminal failure or changed live deployment. Step 5 also requires a persisted recovery-required decision after failed validation and says later validation cannot supersede it. The design does not say whether that durable decision survives when the early result that triggered it is discarded. AC-09 injects early validation followed by terminal failure and changed live state, but gives no expected disposition for an already persisted recovery decision.
PROPOSAL: Specify when an early validation failure can commit a recovery decision and how reconciliation handles that decision when the terminal or live evidence changes. Assert the retained decision and allowed effects in AC-09.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Design / Signed-feed promotion (Q1), lines 266 and 276-280. Test Plan / AC-09, line 307. Tasks / T9, line 325.
EVIDENCE: The R-23 F-02 repair requires one create request per attempt, disables HTTP retries and holds conflicting matches. Step 5 still says to withhold resubmission until a terminal outcome arrives or the intended deployment can be verified. The same step permits only read-only validation on a verified live match without terminal evidence. AC-09 counts requests under timeouts but does not explicitly require the hold when multiple production deployment records match the attempt identifier.
PROPOSAL: Give resubmission one predicate throughout the design: definitive rejection or one correlated terminal failure with the recorded source still live. Test duplicate matches independently of digest conflicts and require zero follow-up mutations.

FINDING: F-04
KIND: factual
SEVERITY: blocking
WHERE: Design / Scheduling and failure isolation, lines 158-163, and Guarded migration and recovery, lines 217 and 224. Acceptance Criteria / AC-03, AC-06 and AC-07. Test Plan / AC-03, AC-06 and AC-07. Tasks / T3, T6, T8 and T11.
EVIDENCE: The R-23 F-03 repair adds a downgrade hold the old provider can observe. The only new old-package test invokes both entry points after restoring settings alone. It can pass simply because the checkpoint is absent, even if a configd run that already passed the checkpoint check survives the transition. At the reviewed revision, NativeRun.php:22-37 reads the checkpoint and other inputs before GitDelivery.php:35-55 acquires the delivery lock. The test does not require an old-package call in that interval or verify that quiescence survives interruption and prevents another call from entering while the active checkpoint is restored.
PROPOSAL: Define how rollback blocks new admission and drains already admitted native and configd work across interruption, up to release of the restored compatible pair. Exercise both entry points during that window and include an old-package call that has already passed checkpoint validation.

FINDING: F-05
KIND: factual
SEVERITY: should-fix
WHERE: Design / Guarded migration and recovery, lines 210 and 217. Test Plan / AC-03 and AC-06, lines 301 and 304. Tasks / T3, T6 and T11.
EVIDENCE: The R-23 F-04 repair binds the retained rollback pair to the native settings revision and checks for a change during capture. It does not bind the comparison to the replacement itself. A native save can land after successful read-back and the final comparison but before replacement. Line 210 explicitly closes this race for activation save. AC-06 tests that activation boundary, while AC-03 can pass with a change injected only during capture.
PROPOSAL: Make the retained revision a precondition of input replacement at the write boundary. Inject a native save after read-back and final comparison, and require the transition to retain the existing inputs or capture and verify a new pair.

FINDING: F-06
KIND: factual
SEVERITY: blocking
WHERE: Context / Owner summary, lines 54-55. Design / Snapshot and Git consistency, lines 191-195, and Guarded migration and recovery, lines 210 and 217. Acceptance Criteria / AC-03, AC-04 and AC-06. Test Plan / AC-03, AC-04 and AC-06. Tasks / T3, T5 and T6.
EVIDENCE: The R-23 F-05 repair holds a branch that is already absent when checked after verified delivery or when a legacy parent is required. The design leaves the check-to-push race open. A branch can disappear after the provider observes an ancestor and before the push starts. GitDelivery.php:115-130 and 217-233 show the existing sequence of observing the ref, then issuing an ordinary push that can create the now-absent ref. The revised proof deletes the branch before reconciliation and can pass while this race still recreates it. The downgrade checks also omit the remote-ref condition before resuming the old writer.
PROPOSAL: Require each remote update to match the observed old ref or authorized absence at the update boundary while preserving the fast-forward rule. Test deletion between observation and push, and require a delivery hold on downgrade if the older provider cannot enforce the applicable branch protection.

### R-25

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Context / Owner summary, lines 54-55. Design / Snapshot and Git consistency, lines 191-195, and Guarded migration and recovery, line 210. Acceptance Criteria / AC-04 and AC-06. Test Plan / AC-03, AC-04 and AC-06. Tasks / T5 and T6.
EVIDENCE: The R-24 F-06 revision protects an individual push with an expected old ref. It leaves initial creation ambiguous across retries. An initial push can succeed, lose its response, and have its branch deleted before read-back. The next run sees an absent ref, no verified receipt and no legacy parent. The spec allows creation when there is no evidence of an established branch, and an expected-absence check would succeed again. AC-03 tests deletion before push and a lost response with the commit still retained, but skips their combination.
PROPOSAL: Define the durable evidence that distinguishes a never-attempted creation from an earlier creation with an unknown outcome, and hold the latter if the branch is absent. Test an accepted initial push with a lost response, deletion before read-back and a restarted retry that leaves the branch absent and retains the pending commit.

FINDING: F-02
KIND: factual
SEVERITY: blocking
WHERE: Design / Scheduling and failure isolation, lines 158-162, Snapshot and Git consistency, lines 191-195, and Guarded migration and recovery, lines 210, 217 and 224. Acceptance Criteria / AC-03, AC-04, AC-06 and AC-07. Test Plan / AC-03, AC-04, AC-06 and AC-07. Tasks / T3, T5, T6, T8 and T11.
EVIDENCE: The R-24 F-04 and F-06 revision adds a downgrade hold when the old provider lacks the required remote ref protection. AC-03 still permits a safe old-plugin resume and directs the tester to reopen admission after validating the compatible pair and remote ancestry. Those checks can pass with the old package at the reviewed commit, whose GitDelivery.php:115-130 and 217-233 observes the remote separately and uses an ordinary push. The proof can therefore reopen a writer that the design requires to remain paused. It also does not explicitly test admission after interruption with the active checkpoint restored and the pause still required.
PROPOSAL: Keep both delivery entry points paused when the old provider lacks the required ref protection, even after restoring and verifying the compatible pair. Exercise both entry points with the active checkpoint present after interruption and assert zero pushes, including after a remote change following observation.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary, line 65. Design / Signed-feed promotion (Q1), lines 276-280. Acceptance Criteria and Test Plan / AC-09, lines 292 and 307. Tasks / T9.
EVIDENCE: The R-24 F-02 and F-03 revision makes terminal Pages evidence decisive for recovery and retry, but the spec does not identify which API results establish a terminal deployment outcome. Pages reports a stage name and a separate stage status. A successful intermediate stage can therefore be mistaken for terminal success. AC-09 distinguishes early validation from a terminal result, but a fixture that supplies a generic terminal flag can pass without checking the production API mapping. [Cloudflare Pages deployment API](https://developers.cloudflare.com/api/resources/pages/subresources/projects/subresources/deployments/methods/create/index.html)
PROPOSAL: Specify which correlated Pages responses establish terminal deployment success, terminal failure or definitive rejection, and keep unclassified responses on hold. Exercise a successful intermediate stage and an ambiguous create response through the same response parser used for publication.

### R-26

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Design / Snapshot and Git consistency, lines 191-195, and Guarded migration and recovery, lines 210 and 217. Acceptance Criteria / AC-03, AC-04 and AC-06. Test Plan / AC-03, AC-04 and AC-06. Tasks / T5 and T6.
EVIDENCE: The R-25 F-01 fix covers a lost initial push response followed by branch deletion and restart once the new attempt record exists. The upgrade path also admits enabled null-legacy version 1 installations with pending work after activation save. The previous writer uses an ordinary push and records verified.json only after reconciliation returns. Its attempt.json contains a timestamp and outcome without the target ref or commit. An accepted first push followed by branch deletion before read-back can therefore leave a pending commit with neither a verified receipt nor the new outstanding-creation record. The revised AC-03 proof can pass entirely on new-format state while an upgraded installation still recreates the deleted branch. See GitDelivery.php lines 70-99 and 217-233 at the target commit.
PROPOSAL: Define how upgrade classifies a pre-existing pending commit with no trustworthy creation record and an absent branch. Exercise the upgrade from that exact version 1 state and require the branch and pending commit to remain untouched until the outcome is established or explicit recovery is authorized.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Design / Snapshot and Git consistency, lines 191-195, and Guarded migration and recovery, lines 210 and 217. Acceptance Criteria / AC-04 and AC-06. Test Plan / AC-03 and AC-04. Tasks / T5 and T6.
EVIDENCE: The R-25 F-01 fix requires persisting the outstanding creation before pushing but leaves its successful retirement undefined. An implementation can clear the outstanding record after read-back and before recording verified delivery. If the process exits between those writes and the branch disappears, retry again sees the conditions for initial creation. The new AC-03 scenario deletes the branch before read-back and misses this interval.
PROPOSAL: Require every durable state after submission to retain either the outstanding creation or established-branch evidence. Inject interruption between successful read-back and receipt persistence, delete the branch, and require restart to hold the pending commit without recreating the ref.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Context / Owner summary, line 65. Design / Signed-feed promotion (Q1), lines 276-280. Acceptance Criteria / AC-09. Test Plan / AC-09. Tasks / T9.
EVIDENCE: The R-25 F-03 fix identifies a successful deploy stage, keeps intermediate success open, and routes those cases through the publication parser. Failure and cancellation still depend on Pages identifying the deployment as finished, without specifying the response fields or combinations that establish that fact. Definitive create rejection similarly depends on an unambiguous rejection without defining which structured responses prove no deployment was created. These classifications control whether another create request is allowed. The proof names deploy failure and ambiguous creation but does not require the parser to distinguish a definite rejection from an API error that leaves creation uncertain. [Cloudflare Pages deployment API](https://developers.cloudflare.com/api/resources/pages/subresources/projects/subresources/deployments/methods/create/index.html)
PROPOSAL: Define the correlated response shapes that establish terminal failure, cancellation and definite rejection, with all other shapes held open. Exercise those classifications through the production parser and assert the resulting create-request count.

FINDING: F-04
KIND: judgement
SEVERITY: blocking
WHERE: Context / Owner summary, line 65. Design / Packaging and contribution, line 235, and Signed-feed promotion (Q1), lines 273 and 276-280. Acceptance Criteria / AC-09. Test Plan / AC-09. Tasks / T9.
EVIDENCE: Step 5 permits recovery only after terminal candidate success, while candidate failure permits retry or closure only when the recorded pre-candidate state is still served. AC-09 explicitly injects terminal failure with changed live state but gives that case no recovery pass condition. If a uniquely correlated terminally failed candidate is confirmed to be serving an unusable catalogue, the previous generation cannot be restored through the specified workflow. This leaves the established-feed recovery promise unmet even if every named check passes.
PROPOSAL: Resolve whether a uniquely correlated terminally failed candidate that is confirmed live authorizes the recorded recovery deployment or requires a separate owner-approved recovery path. Specify the required live evidence and test restoration of the prior usable generation in that case.

### R-27

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Design / Signed-feed promotion (Q1), lines 276 and 278. Test Plan / AC-09, line 307. Tasks / T9, line 325.
EVIDENCE: R-26 F-03 is addressed in the design. An unclassified response leaves either submission open, and definitive rejection requires evidence that Pages did not create a deployment. AC-09 specifies parser coverage for intermediate success, final deploy outcomes and ambiguous creation. Its create-request count is explicit for timeouts only. The proof can pass even if the parser treats an unfamiliar structured provider error as definitive rejection and permits a second request. [Cloudflare Pages deployment API](https://developers.cloudflare.com/api/resources/pages/subresources/projects/subresources/deployments/methods/create/index.html)
PROPOSAL: Through the production response parser used for candidate and recovery, exercise an unfamiliar structured response and require the attempt to remain open with zero follow-up create requests. Use a supported definitive rejection as a control. Leave the response mapping to implementation.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Design / Signed-feed promotion (Q1), lines 276 and 278. Test Plan / AC-09, line 307. Tasks / T9, line 325.
EVIDENCE: The R-26 F-04 revision authorizes recovery with the already approved bytes when the uniquely correlated terminally failed candidate is confirmed live. Step 5 explicitly requires persisting the recovery decision for the terminal-success path followed by failed native validation. The new terminal-failure path says it triggers recovery without explicitly carrying forward that durable decision requirement. AC-09 can pass its restart test through the first path and its terminal-failure test without an interruption.
PROPOSAL: Make the existing durable recovery decision apply to both triggers. In the terminal-failure case, interrupt after recovery is selected and before submission, then verify that a later authorized dispatch resumes with the same approved recovery bytes while newer work waits.

### R-28

FINDING: F-01
KIND: judgement
SEVERITY: blocking
WHERE: docs/specs/native-encrypted-git-backup.md, Context / Owner summary, line 65. Design / Packaging and contribution, line 235. Design / Signed-feed promotion (Q1), lines 273-278. Acceptance Criteria / AC-09, line 292. Test Plan / AC-09, line 307. Tasks / T9, line 325.
EVIDENCE: The R-27 revision covers both requested repairs. AC-09 sends unclassified structured errors through the production parser for candidate and recovery creates, with a definitive rejection as a control and zero follow-up creates for unclassified errors. It also interrupts the terminally failed candidate path after the recovery decision is durable and requires a later dispatch to restore the same approved bundle. Pinned vh-adlc lint reports pass. A separate gap remains when the recovery deployment itself becomes live and either finishes with terminal failure or finishes successfully but persistently fails native verification. The retry rule requires the recorded source to remain live, and closure requires terminal success plus passing native checks. The special recovery trigger applies to the candidate. AC-09 can pass by leaving a live recovery deployment open when cached package retrieval fails, even if the publisher has no authorized way to restore a usable feed.
PROPOSAL: Resolve what an authorized operator can do when the exact recovery deployment is confirmed live but cannot be verified, while preserving the hold on unknown or conflicting state. Extend AC-09 to prove the chosen path and its closure checks, or explicitly narrow the recovery guarantee and test the resulting hold.

### R-29

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: docs/specs/native-encrypted-git-backup.md, Owner summary line 65, Signed-feed promotion line 276, Retry of a live recovery deployment lines 280 and 282, AC-09 lines 296 and 311, and T9 line 329.
EVIDENCE: The R-28 revision adds the owner-authorized path for retrying a terminal recovery that is confirmed live and fails native checks. The pinned lint passes. The existing unchanged-source rule still permits a retry after definitive rejection or correlated terminal failure. If Pages rejects the Q3 create, the failed recovery remains live as the retry's recorded source. The workflow can then submit again under the unchanged-source rule even though the dispatch has already used its one retry. The durable record tracks deployment attempts without requiring it to track consumption of the dispatch's authorization. AC-09 checks the first retry and that newer work stays blocked, but does not replay the same authorization after a definitive rejection or a workflow rerun. GitHub permits reruns using the original actor's privileges and the original SHA and ref. [GitHub Actions rerun behavior](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs)
PROPOSAL: Apply the Q3 limit across both retry rules and durably record consumption of the dispatch's authorization when recording submission-started. In AC-09, reject the authorized retry, replay the same dispatch through a workflow rerun, and require zero additional creates until a separate dispatch is authorized for the same approved bytes.

FINDING: F-02
KIND: judgement
SEVERITY: should-fix
WHERE: docs/specs/native-encrypted-git-backup.md, Owner summary line 65, Retry of a live recovery deployment lines 280 and 282, AC-09 lines 296 and 311, and T9 line 329.
EVIDENCE: The R-28 revision covers terminal failure with failed native checks. If Pages reports terminal failure but the exact approved recovery deployment is confirmed live and fresh native checks pass, neither Q3 retry nor verified closure applies. The spec does not say whether this known state should remain on hold indefinitely or go through a separately authorized recovery path. AC-09 covers terminal failure with failed native checks and successful closure after terminal success, leaving this state untested.
PROPOSAL: Obtain an owner decision for a terminally failed recovery whose approved bytes are confirmed live and pass fresh native checks. Specify and test the resulting hold or separately authorized action while preserving the existing terminal-success requirement for verified closure.

### R-30

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: docs/specs/native-encrypted-git-backup.md, Owner summary line 65, Signed-feed promotion line 276, Retry of a live recovery deployment lines 280 and 282, AC-09 lines 296 and 311, and T9 line 329.
EVIDENCE: The R-29 revision consumes authorization atomically with submission-started, keys consumption to the dispatch run ID across reruns, and adds a test for immediate replay after definitive rejection. Pinned lint passed. The generic unchanged-source rule still leaves a path around Q3 on a fresh dispatch. If Pages definitively rejects the Q3 create, the previous recovery remains live as the recorded source. If fresh native checks now pass, line 280 requires a hold when that live recovery was terminally failed. Line 276 still permits retrying the rejected create from the unchanged source, and the new dispatch has no consumed authorization entry. The AC-09 row tests rejection replay and passing checks separately, so both cases can pass without exercising this sequence.
PROPOSAL: Make Q3 eligibility govern every further create while the recorded recovery deployment remains live, including after definitive rejection and under a fresh dispatch. Extend AC-09 to reject an authorized Q3 create, make fresh native checks pass on the still-live terminally failed recovery, and require zero additional creates and no closure even under a fresh dispatch.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: docs/specs/native-encrypted-git-backup.md, Retry of a live recovery deployment lines 280 and 282, AC-09 lines 296 and 311, and T9 line 329.
EVIDENCE: The R-29 revision tests rerunning a consumed dispatch immediately after rejection. A durable activation record that keeps only the most recent consumed run ID passes that proof. If dispatch A consumes its retry and is rejected, then separately authorized dispatch B does the same, rerunning A can create again after B replaces A's entry. GitHub preserves the original run ID across reruns and increments the run attempt. [GitHub Actions variables reference](https://docs.github.com/en/actions/reference/workflows-and-actions/variables)
PROPOSAL: Retain each consumed authorization for as long as its dispatch can be replayed against the recovery record. Add an AC-09 case that reruns A after B consumes its own retry and verifies zero additional creates.

### R-31

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: docs/specs/native-encrypted-git-backup.md, Design / Retry of a live recovery deployment, lines 280 and 282. Acceptance Criteria / AC-09, line 296. Test Plan / AC-09, line 311. Tasks / T9, line 329.
EVIDENCE: The pinned lint passed. The revision addresses the R-29 and R-30 retry paths in the design. Q3 governs every further create while the recorded recovery is live, all consumed dispatch IDs survive for the life of the recovery record, and terminal failure with passing native checks requires the owner-confirmed manual hold. The proof covers immediate replay after rejection, replay after a second dispatch consumes its authorization, and zero creates under fresh authorization when native checks pass. The generic interruption case at submission-started does not exercise Q3 authorization consumption. An implementation that records consumption only after a create response can pass the rejection and replay cases, and the generic interruption case can pass because the unresolved submission itself blocks another create. That leaves the required atomic transition unverified.
PROPOSAL: In the existing AC-09 fixture, interrupt a Q3 dispatch immediately after persisting submission-started and before sending the request. Read the durable record independently and require it to contain both the submission-started attempt and the consumed dispatch ID.

### R-32

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: docs/specs/native-encrypted-git-backup.md, Signed-feed promotion step 5 line 276, Activation reconciliation and retry eligibility rule 4 line 285, Acceptance Criteria AC-09 line 303, and Test Plan AC-09 line 318.
EVIDENCE: Pinned lint passed. Step 5 describes persisting recovery-required only after correlated terminal success and failed final native validation. Rule 4 also requires that decision when the uniquely correlated candidate finishes in terminal failure and is confirmed live. AC-09 exercises the latter path and requires a later dispatch to recover the same bundle. An implementer using step 5 as the gate can leave a failed candidate live and fail that proof.
PROPOSAL: Make the ordered reconciliation rules the sole authority for selecting recovery. Have step 5 refer to those rules for both live-candidate outcomes.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: docs/specs/native-encrypted-git-backup.md, Signed-feed promotion step 5 line 276, Activation reconciliation and retry eligibility rules 1 through 4 lines 282 through 285, and Test Plan AC-09 line 318.
EVIDENCE: The consolidation limits unchanged-source retry to cases outside live recovery, but the corresponding proof still describes unchanged live state without that qualification. The proof also says to release the hold only after terminal success and later requires closure after definitive candidate rejection or correlated candidate failure with the pre-candidate state verified. Those cases exercise different dispositions, and the proof leaves their boundaries implicit.
PROPOSAL: Key the assertions to the ordered rules. Exercise unchanged-source retry outside live recovery, require Q3 eligibility for every further create while recovery is live, and state the distinct closure conditions for verified activation or recovery and for candidate rejection or failure with the exact pre-candidate state verified.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: docs/specs/native-encrypted-git-backup.md, Activation reconciliation and retry eligibility rule 2 line 283, durable attempt lifecycle line 289, Test Plan AC-09 line 318, Tasks T9 line 336, and Review Log R-31 F-01 lines 1213 through 1218.
EVIDENCE: The new R-31 case stops the Q3 runner before the request and independently checks that both the attempt and the consumed dispatch ID are durable. This catches consumption deferred until after a create response. Separate durable writes can still pass if both complete before the fixture stops the runner. Runner loss between the writes can leave submission-started without consumption, or consume authorization without recording the attempt.
PROPOSAL: Keep the independent pre-request read and add an interruption or persistence failure during the transition. Require an independent reader to observe either the previous state or the complete attempt and consumption pair, with zero requests before the pair is durable.

### R-33

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: docs/specs/native-encrypted-git-backup.md, Signed-feed promotion step 5 line 276, Activation reconciliation and retry eligibility rule 4 line 285, Acceptance Criteria AC-09 line 303, Test Plan AC-09 line 318.
EVIDENCE: Pinned lint passed. The R-32 F-01 correction makes step 5 refer to the ordered rules for both recovery triggers. It also removes the explicit instruction to honor a recorded recovery decision even if a later validation passes. Step 5 still says to resume that decision, while rule 4 permits successful closure on fresh passing checks without first checking for a recorded recovery decision. After a terminally successful candidate fails native checks and the runner records recovery-required, a restart with passing checks can therefore either restore the approved bundle or close the candidate. AC-09 checks that the decision keeps its approved bytes, but can pass without exercising that change in validation result.
PROPOSAL: Make an existing recovery-required decision take precedence over candidate closure, subject to the existing correlation, live-state and owner-approval requirements. In AC-09, restart after recording recovery-required and before submitting recovery, make the candidate checks pass, and require the approved recovery to complete before newer work proceeds.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: docs/specs/native-encrypted-git-backup.md, Activation reconciliation and retry eligibility rule 2 line 283 and durable attempt lifecycle line 289, Test Plan AC-09 line 318, Tasks T9 line 336.
EVIDENCE: The R-32 F-03 correction adds independent read-back after a persistence failure and requires either the previous state or the complete pair. The proof leaves the injection point unspecified. An implementation that writes submission-started and the consumed run ID separately can pass if the injected failure occurs before the first write, while the existing pre-request interruption happens after both writes.
PROPOSAL: Exercise each durable write boundary in the Q3 transition, including runner loss between writes if the implementation can expose that state. Keep the independent read-back and require zero Pages create requests before the complete pair is durable.

### R-34

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: docs/specs/native-encrypted-git-backup.md, Signed-feed promotion step 5 line 276, Activation reconciliation and retry eligibility rule 4 line 285, Acceptance Criteria AC-09 line 303, Test Plan AC-09 line 318, Tasks T9 line 336.
EVIDENCE: Pinned lint passed. The planned gate reports spec_review_fresh and accepted against the previous baseline. The R-33 revision explicitly gives the recorded recovery decision precedence over candidate closure. It also closes R-33 F-02 by requiring fault injection at each durable write boundary, independent read-back, and zero requests before the attempt and consumed dispatch ID are both durable. The restart proof for R-33 F-01 still leaves the candidate's terminal result unspecified. A fixture can select recovery after terminal deployment failure, make native checks pass on restart, and pass the proof even if the implementation wrongly closes a terminally successful candidate whose checks fail before restart and pass afterward.
PROPOSAL: In the AC-09 restart case, make the live candidate reach correlated terminal deployment success, fail native validation, and durably select recovery. Stop before recovery submission, make the candidate's native checks pass, and require the next authorized dispatch to complete the recorded recovery before newer work can proceed.

### R-35

FINDING: F-01
KIND: judgement
SEVERITY: should-fix
WHERE: docs/specs/native-encrypted-git-backup.md, Packaging and contribution line 242, Signed-feed promotion steps 3 and 4 lines 272-274, durable bundle retention line 289, Acceptance Criteria AC-09 line 303, Test Plan AC-09 line 318, Tasks T9 line 336, Open Questions lines 343-345.
EVIDENCE: The design retains packages for still-supported cached catalogues and allows predecessor package removal after the supported cache lifetime. It defines neither which catalogues qualify nor when their support expires. AC-09 checks retrieval from a third supported catalogue and retrieval after predecessor retirement, but leaves both checks without a rule for choosing the oldest supported catalogue or determining when removal is permitted. Two implementations can pass the fixture and retire the same package at different times.
PROPOSAL: Obtain the owner's decision on the cached-catalogue support and retirement policy, including when its lifetime starts. Use that policy to test retrieval at the support boundary across promotion, recovery and key retirement.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: docs/specs/native-encrypted-git-backup.md, Owner summary lines 54-56, Provider and ownership lines 137-140, Snapshot and Git consistency lines 194-201, Acceptance Criteria AC-05 line 299, Test Plan AC-05 line 314, Tasks T7 line 334.
EVIDENCE: The design requires the independent monitor to distinguish a recent failed attempt from a retained successful export. The AC-05 proof lists normal, stale, unchanged-source and stopped-scheduler receipts. It never pairs a still-fresh remote receipt with a newer failed attempt. The remote checker at tests/package/check-freshness.php:9-28 receives only metadata, commit, artifact and age. It can report healthy for the older receipt until the age limit expires. The native status API supplies separate attempt information as documented in docs/installation.md:11.
PROPOSAL: Specify how the independent monitor combines native attempt status with remote freshness and what it reports when native status is unreachable. Add a test where a recent failed attempt and a still-fresh retained export coexist and require the monitor to report both facts.

### R-36

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Packaging and contribution line 242, Signed-feed promotion steps 3 and 4 lines 272-274, Activation reconciliation and retry eligibility line 289, AC-09 lines 303 and 318, Tasks T9 line 336.
EVIDENCE: The R-35 F-01 revision requires retention of every package advertised by a v1 catalogue across promotion and recovery. The rotation paragraph still retains predecessor package paths only until the supported cache lifetime has elapsed. The durable storage rule still refers to supported catalogues. Both phrases leave room for expiry even though the owner selected no removal of advertised v1 packages. The single retrieval check after predecessor retirement can pass before a later deployment removes those paths.
PROPOSAL: Apply the same v1 retention rule to candidate, recovery and retirement bundles and the durable package bytes needed to build them. Make AC-09 verify that each bundle preserves the original URL and digest of every previously advertised package, including packages advertised only by retired catalogues.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Owner summary lines 54-56, Provider and ownership lines 137-153, Snapshot and Git consistency lines 197-201, AC-05 lines 299 and 314, Tasks T5 and T7 lines 331-334.
EVIDENCE: The R-35 F-02 revision adds both missing test cases and describes the intended behavior in the Owner summary. The Design still says only to distinguish a recent failure from a retained export. It leaves the authoritative inputs, their association with the same backup target, and the result when native status is unavailable implicit. The fixture checker at tests/package/check-freshness.php:9-28 validates only remote receipt inputs. The native endpoint supplies separate attempt and verification data through StatusController.php and can return unavailable. AC-05 can pass with a canned fixture that pairs those signals without verifying their association in the actual monitor.
PROPOSAL: Define how the deployment-owned monitor relates authenticated native attempt status to the independently verified receipt for the configured target. Require AC-05 to exercise that path with a newer native failure and a fresh receipt, then with native status unavailable while remote freshness remains independently visible.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Packaging and contribution lines 235-242, Signed-feed promotion steps 2 through 4 lines 271-274, AC-09 lines 303 and 318.
EVIDENCE: The revised retention rule makes the package set grow across v1 releases. The spec calls for checking artifact limits before selecting the feed configuration, but leaves the behavior undefined when a later complete candidate or recovery bundle exceeds the selected Pages limits. A small fixture can pass AC-09 while later production behavior depends on which bundle uploads first or whether the publisher omits retained files. [Cloudflare Pages limits](https://developers.cloudflare.com/pages/platform/limits/#files)
PROPOSAL: Require a capacity check on the complete candidate, recovery and rotation bundles before activation. Exercise an over-limit generation and verify that publication stops with the current feed and all advertised package URLs intact.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Packaging and contribution lines 232-235, Signed-feed promotion step 4 line 274, Activation reconciliation and retry eligibility line 289, AC-09 lines 303 and 318, Tasks T9 line 336.
EVIDENCE: AC-09 checks cached predecessor package retrieval, successor recovery and revoked-key rejection after retirement. Those checks can all pass while the configured predecessor URL still serves its old signed catalogue, for example from a custom-domain cache. The design requires that catalogue to be removed. Bootstrap recovery already checks catalogue absence through the configured client-facing URL, but retirement has no equivalent proof. [Cloudflare Pages caching behavior](https://developers.cloudflare.com/pages/configuration/serving-pages/#caching-and-performance)
PROPOSAL: Verify through the configured predecessor feed URL that its catalogue and native metadata are withdrawn while its immutable packages remain retrievable. Exercise the check with stale catalogue content and require retirement to remain unverified until withdrawal is observed.

FINDING: F-05
KIND: factual
SEVERITY: nit
WHERE: Owner summary lines 64-66.
EVIDENCE: The separate native provider is consistent with the repository's scope. The baseline calls for complete native encrypted exports, independent restore, guarded migration and verified Git delivery. The revised Owner summary omits the v1 package retention decision and its cumulative storage cost. Pinned lint passed. The planned gate reports spec_review_fresh and accepted as failing because the normative baseline changed. This read-only pass did not rerun the appliance or release fixtures.
PROPOSAL: Include the v1 retention decision and its storage implications in the Owner summary alongside the publication and recovery rules.

### R-37

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Packaging and contribution lines 243-244, Signed-feed promotion steps 3-5 lines 274-278, Activation reconciliation and retry eligibility line 291, AC-09 and its Test Plan row lines 305 and 320, Tasks T9 line 338.
EVIDENCE: The R-36 F-01 revision requires all three bundle types to preserve historical package URLs and digests, and it requires durable retention of package bytes. It leaves the source of truth for the historical URL-to-digest mapping undefined. If a candidate serves a new catalogue and then fails, a client can cache that catalogue before recovery withdraws it. After runner loss and recovery, neither the current catalogue nor its predecessor necessarily identifies those URLs. AC-09 can pass using a fixture that supplies the historical mapping directly, even if the publisher loses that mapping during reconciliation.
PROPOSAL: Define the durable record of package URLs and digests, when it is persisted relative to any submission that could advertise them, and how it is carried through recovery and retirement. Exercise runner loss after a candidate first serves a catalogue, then verify that recovery and a later generation preserve the cached catalogue's package URLs using only durable state.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Signed-feed promotion steps 4-5 lines 275-278, Activation reconciliation and retry eligibility lines 282-291, AC-09 and its Test Plan row lines 305 and 320, Tasks T9 line 338.
EVIDENCE: The R-36 F-04 revision adds client-facing withdrawal checks and a stale-cache case. The activation rules define candidate and recovery closure, but the retirement paragraph leaves the next action undefined when the retirement deployment succeeds and the predecessor catalogue is still served. AC-09 requires retirement to remain unverified, yet permits a publisher that starts a newer release in that state. The design also leaves implicit whether recovery after verified retirement must preserve catalogue withdrawal. Pages documents that custom caching can serve stale assets. [Cloudflare Pages serving and caching](https://developers.cloudflare.com/pages/configuration/serving-pages/#caching-and-performance)
PROPOSAL: Apply the durable activation and closure rules explicitly to retirement. Specify when later mutations may resume while withdrawal is unverified, and require post-retirement recovery to preserve predecessor catalogue withdrawal and package retrieval.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Owner summary line 55, Provider and ownership lines 137-153, Snapshot and Git consistency lines 197-203, AC-05 and its Test Plan row lines 301 and 316, Tasks T5 and T7 lines 333-336.
EVIDENCE: The R-36 F-02 revision names the authenticated native endpoint and independently verified receipt, and specifies the outcome for an unavailable or unassociated response. The Test Plan exercises a matching pair and an unreachable endpoint, so a monitor that accepts every reachable native response can pass. StatusController.php:15-19 exposes attempt and verification without a separate target field, and tests/package/check-freshness.php:9-28 only checks receipt inputs. The specification leaves open how the monitor recognizes an authenticated response for a different target after the firewall's destination changes.
PROPOSAL: Define the observable association between native attempt status and the configured receipt target, including after a destination or branch change. Add a reachable, authenticated wrong-target case and require attempt status unknown while remote freshness remains visible.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Owner summary line 65, Packaging and contribution lines 243-244, Signed-feed promotion steps 2-4 lines 273-276, AC-09 Test Plan row line 320, Tasks T9 line 338.
EVIDENCE: The R-36 F-03 revision requires checking complete candidate, recovery and retirement bundles before activation. The Test Plan exercises only one unspecified over-limit bundle. A workflow that checks the candidate alone can pass that case and activate a candidate whose approved recovery bundle cannot be deployed. Pages enforces both deployment file-count and individual asset-size limits. [Cloudflare Pages limits](https://developers.cloudflare.com/pages/platform/limits/#files)
PROPOSAL: Exercise a candidate that fits while its recovery bundle exceeds the selected limits, and separately exercise an over-limit retirement bundle. Require zero production submissions and verify the active catalogue and previously advertised package URLs remain intact.

FINDING: F-05
KIND: factual
SEVERITY: nit
WHERE: Owner summary lines 64-66 and Review Log R-36.
EVIDENCE: The R-36 F-05 correction is present. The summary now states the v1 retention decision, cumulative storage and file-count costs, and the publication hold at the configured limits. Pinned lint and git diff --check passed. The planned gate failed on spec_review_fresh, spec_review_clean and accepted because the stored R-36 has a blocking finding and the normative baseline changed since acceptance. This read-only pass did not execute appliance or release fixtures.
PROPOSAL: Preserve the retention and capacity explanation when updating the summary after the next revision.

### R-38

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Owner summary line 65, Packaging and contribution lines 243-244, Signed-feed promotion steps 3-5 lines 274-278, Activation reconciliation and retry eligibility lines 282-291, AC-09 and its Test Plan row lines 305 and 320, Tasks T9 line 338.
EVIDENCE: The R-37 F-02 revision requires newer work to wait while predecessor withdrawal remains unverified and requires recovery after verified retirement to preserve withdrawal. It applies the general activation rules to retirement, but those rules only define recovery selection and closure for candidates and recoveries. If a retirement deployment becomes live and then reports terminal failure, the source is no longer unchanged and the spec does not say which approved bundle to serve next. The stale-catalogue test can pass without exercising that state.
PROPOSAL: Specify the recovery decision for a terminally failed retirement that became live, including which approved bundle and trust state apply if the runner exits before recovery. Exercise that restart and require newer work to remain blocked until the recorded transition is resolved.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Owner summary line 65, Packaging and contribution lines 243-244, Signed-feed promotion steps 2-5 lines 273-278, Activation reconciliation and retry eligibility line 291, AC-09 Test Plan row line 320, Tasks T9 line 338.
EVIDENCE: The R-37 F-01 revision records package URLs and digests before a submission can advertise them and exercises their recovery after runner loss. It explicitly retains package bytes, but leaves the lifetime and completeness check for the manifests undefined. If an older failed candidate's manifest disappears while its package bytes remain, a later workflow can omit its original URL and still pass the restart case with all fixture manifests present.
PROPOSAL: Require the durable URL-to-digest records to survive for the life of the v1 feed and require the publisher to establish their completeness before submission. Exercise a missing historical record and require zero production submissions.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Owner summary line 55, Provider and ownership lines 137-142, Snapshot and Git consistency lines 197-203, Guarded migration and recovery lines 212 and 219, AC-05 and its Test Plan row lines 301 and 316, Tasks T5 and T7 lines 333-336.
EVIDENCE: The R-37 F-03 revision binds native attempt status to the destination and branch used for that attempt. The wrong-target proof can be satisfied with a prepared API response, which does not establish that an attempt for target A retains its identity after native settings change to target B. The existing GitDelivery.php records attempt time and outcome without a target, and StatusController.php exposes the recorded attempt. An implementation that adds the identifier from current settings when serving status can misattribute a retained failure, including one recorded before upgrade.
PROPOSAL: Require the identifier to be captured with the attempt and treat older records without it as unassociated. Produce a real attempt for A, change settings to B without another run, and verify through the native endpoint that the monitor reports attempt status unknown while continuing to evaluate B's remote receipt.

FINDING: F-04
KIND: factual
SEVERITY: nit
WHERE: Owner summary line 55, Snapshot and Git consistency line 203, AC-05 Test Plan row line 316.
EVIDENCE: The R-37 F-03 revision adds the reachable wrong-target case to the design and proof. The Owner summary still says available authenticated status is reported and mentions only an unreachable endpoint as a reason for unknown status.
PROPOSAL: State that reporting attempt status requires a target match and that remote freshness remains visible when native status is unavailable or unassociated.

FINDING: F-05
KIND: factual
SEVERITY: nit
WHERE: Owner summary lines 64-66, Packaging and contribution lines 243-244, AC-09 Test Plan row line 320, Review Log R-37.
EVIDENCE: The R-37 F-04 revision adds separate over-limit recovery and retirement cases with zero production submissions and preservation of the live feed. The retention and capacity explanation noted in R-37 F-05 is present. Pinned lint and git diff --check passed. The planned gate failed on spec_review_fresh and accepted because the normative baseline changed. Appliance and release fixtures were not executed in this read-only pass.
PROPOSAL: Preserve the capacity explanation and the separate recovery and retirement cases in the next revision.

### R-39

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Signed-feed promotion step 4, line 276. Activation reconciliation rule 4, line 287. AC-09 and its Test Plan row, lines 305 and 320. Task T9, line 338.
EVIDENCE: The R-38 F-01 revision names the approved overlap bundle and requires a restart test for a terminally failed retirement that became live. A second case remains ambiguous. If Pages reports terminal success and the client-facing withdrawal check fails, step 4 says to hold newer work, while rule 4 requires a recovery decision when a live candidate fails native checks after terminal success. The stale-catalogue test checks the hold but leaves recovery submission behavior unspecified.
PROPOSAL: Define which rule governs terminally successful retirement with failed withdrawal checks, including the transition after a later check passes. Make AC-09 assert the permitted production submissions and the client trust state in that case.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Owner summary, lines 64-65. Packaging and contribution, lines 243-244. Signed-feed promotion, lines 266 and 273-278. Activation reconciliation, line 291. AC-09 Test Plan row, line 320. Task T9, line 338.
EVIDENCE: The R-38 F-02 revision retains manifests for the life of the v1 feed and tests a missing manifest with its package bytes intact. Step 3 checks manifest presence only for entries still referenced by the durable activation history. The history itself has no explicit lifetime or rule requiring a durable manifest reference before a catalogue can first be served. A publisher can prune a resolved activation entry and silently omit the only URL for a historical package. The missing-manifest test can pass with that defect when the fixture leaves the reference intact.
PROPOSAL: Require durable references to every potentially advertised manifest before submission and preserve them across closure, recovery, retirement and runner loss for the life of the v1 feed. Make the fixture verify the completeness check after the original activation has closed, including loss of a historical reference.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Owner summary, line 55. Provider and ownership, lines 137-142. Snapshot and Git consistency, lines 197-203. AC-05 and its Test Plan row, lines 301 and 316. Tasks T5 and T7, lines 333 and 335.
EVIDENCE: The R-38 F-03 and F-04 revisions require capture-time identity, specify how to treat older records and correct the Owner summary. The A-to-B case expects unknown attempt status, which is also the expected result when the identifier is absent. The test requires use of the real endpoint after the switch but does not explicitly assert that it still returns A's identifier. The same-target check does not explicitly use the same persisted attempt and endpoint before the switch. A provider that drops the identifier after a settings save could pass those checks.
PROPOSAL: Use one persisted failed attempt and the real authenticated endpoint before and after switching from A to B without another run. Assert that the endpoint returns the same A identifier and attempt timestamp both times, and that the monitor reports the failure for A and unknown attempt status for B while evaluating each remote receipt independently.

FINDING: F-04
KIND: factual
SEVERITY: nit
WHERE: Owner summary, lines 64-66. Review Log R-38. AC-09 Test Plan row, line 320.
EVIDENCE: The R-38 F-05 capacity explanation and separate over-limit recovery and retirement cases remain present. At the target commit, pinned lint returned pass and git diff --check passed. The planned gate returned fail on spec_review_fresh and accepted because the normative baseline changed. This read-only pass made no repository changes and did not execute appliance or release fixtures.
PROPOSAL: Preserve the capacity coverage and obtain a fresh independent review and owner acceptance against the final normative baseline before moving the draft to planned.

### R-40

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Signed-feed promotion step 3, line 274. Activation reconciliation, line 291. AC-09 Test Plan, line 320. Task T9, line 338.
EVIDENCE: The R-39 F-02 correction requires a durable manifest reference before submission and retains the append-only history for the life of the feed. It also tests deletion of a historical reference against an unchanged checkpoint. The revision leaves the append and checkpoint update undefined across runner loss. If the runner stops after either write, the next dispatch sees a mismatch. The spec gives it no way to distinguish an interrupted append from the loss of a previously committed historical reference. The existing deletion fixture exercises only the latter case.
PROPOSAL: Define how a history append and its checkpoint become durable together, or how a later dispatch can safely reconcile an interrupted append. Inject interruption at each write boundary and prove that a later dispatch can proceed with complete history while still rejecting deletion of a committed reference.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Signed-feed promotion step 4, line 276. Activation reconciliation rule 4 and dispatch preflight, lines 287 and 291. AC-09 and its Test Plan, lines 305 and 320. Task T9, line 338.
EVIDENCE: The R-39 F-01 correction makes terminal success with failed withdrawal checks read-only, retains overlap trust and tests zero production mutations. It then places predecessor trust finalization after activation closure. Rule 4 releases newer work at closure, and dispatch preflight reconciles the activation record. If the runner stops after closure and before trust finalization, the spec does not say how the next dispatch discovers the unfinished step or whether a newer release can proceed. The proof exercises the uninterrupted sequence.
PROPOSAL: Define the durable state for pending trust finalization and when newer work may proceed. Interrupt immediately after closure and verify that the next dispatch handles the unfinished trust step under the specified rule.

FINDING: F-03
KIND: factual
SEVERITY: nit
WHERE: AC-05 and AC-09 Test Plan, lines 316 and 320. Review Log R-39, lines 392 and 1405 onward.
EVIDENCE: The AC-05 revision meets R-39 F-03. It uses the same persisted failed attempt and authenticated endpoint before and after switching from A to B, checks the same A identifier and timestamp, and evaluates each remote receipt independently. The separate over-limit recovery and retirement cases from R-39 F-04 remain. Pinned lint and git diff --check passed. The planned gate failed on spec_review_fresh and accepted because the normative baseline changed. Open Questions is empty. This read-only pass made no repository writes and did not execute appliance or release fixtures.
PROPOSAL: Preserve the AC-05 and capacity proofs. Resolve the two remaining findings before seeking a fresh independent review and owner acceptance for the planned gate.

### R-41

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Signed-feed promotion step 3, line 274. Activation reconciliation preflight, line 291. AC-09 Test Plan, line 320. Task T9, line 338.
EVIDENCE: The R-40 F-01 correction makes the manifest reference and checkpoint one durable transition. The interruption proof accepts either complete state after restart and prohibits premature submission. It never requires the authorized dispatch to finish an interrupted append or reuse an append that committed before runner loss. A publisher that permanently holds the release after either interruption can pass the new check. The separate missing-manifest and deleted-reference cases still cover genuine history loss.
PROPOSAL: Define how a later authorized dispatch completes the append from the prior state or reuses the committed entry for the same manifest. Require both restart cases to reach an eligible submission with complete history and retain the refusal cases for missing history.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Signed-feed promotion step 4, line 276. Activation reconciliation rules 1 and 4 and dispatch preflight, lines 284, 287 and 291. AC-09 and its Test Plan, lines 305 and 320. Task T9, line 338.
EVIDENCE: The R-40 F-02 correction keeps the record open while trust finalization is pending and requires a later authorized dispatch to resume it. The fixture interrupts with finalization pending but does not require interruption after trust has changed and before completion is recorded. The spec does not say how to recognize already completed or partially completed trust changes or whether a resumed dispatch must recheck client-facing withdrawal before changing any remaining trust. A fixture that only interrupts before the first trust change can pass while replay or a stale withdrawal result leaves retirement unsafe or stuck.
PROPOSAL: Define the read-back and resume behavior for untouched, partially retired and already retired trust, and require fresh live identity and withdrawal checks before any remaining trust change. Exercise interruption after a trust change and before closure, and require newer work to remain blocked until both trust retirement and feed withdrawal are verified.

FINDING: F-03
KIND: factual
SEVERITY: nit
WHERE: Owner summary, lines 64-66. AC-05 and AC-09 Test Plan, lines 316 and 320. Review Log R-40.
EVIDENCE: The R-40 F-03 checks remain present. AC-05 uses the same persisted attempt across the target switch, and AC-09 retains separate over-limit recovery and retirement cases. Pinned lint and the target commit's whitespace check passed. The planned gate failed on spec_review_fresh and accepted. Open Questions is empty. This read-only review did not execute appliance or release fixtures.
PROPOSAL: Preserve those checks, resolve F-01 and F-02, and obtain a fresh independent review and owner acceptance before moving the draft to planned.

### R-42

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Signed-feed promotion steps 2, 3 and 5, lines 273-274 and 278. Activation reconciliation preflight, line 291. AC-09 Test Plan, line 320. Task T9, line 338.
EVIDENCE: The R-41 F-01 correction requires a restarted dispatch to complete the append or reuse the committed entry. The design still leaves the order between recording the approved release and committing the history append unspecified. It also leaves the restart without an explicit durable link between the exact manifest and the expected prior history state. A restart after the append commits can therefore encounter a valid history with no durable record tying that entry to the interrupted promotion. The positive proof can pass if the fixture hands the restarted dispatch the missing context.
PROPOSAL: Before attempting the append, durably bind the approved manifest and bundle digests to the expected prior history checkpoint. Restart with the original workspace gone and prove that the dispatch can complete or reuse the exact append from durable records alone and holds if the linkage is missing or conflicts.

FINDING: F-02
KIND: judgement
SEVERITY: should-fix
WHERE: Owner summary, lines 64-66. Packaging and contribution, line 235. Signed-feed promotion step 4, line 276. Activation reconciliation rule 4 and dispatch preflight, lines 287 and 291. AC-09 and its Test Plan, lines 305 and 320. Task T9, line 338.
EVIDENCE: The R-41 F-02 correction requires read-back of each approved trust change but leaves the affected client set, approved before and after states, and retirement authority undefined. The repository assigns deployment-specific configuration to Lab, while the spec tells the publisher to apply remaining changes. With native `pubkey` trust configured per repository on each client, a release job can replay its own record and pass a single-appliance fixture while deployed clients still trust the predecessor. [FreeBSD pkg.conf(5)](https://man.freebsd.org/cgi/man.cgi?n=1&query=pkg.conf&sektion=5)
PROPOSAL: Resolve who changes client trust and what durable, independently readable evidence defines the approved client scope and completed retirement. Bind that evidence to the retirement record before withdrawal and prove that an unreachable or conflicting client keeps the record open.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Signed-feed promotion step 4, line 276. Activation reconciliation rules 1 and 4 and dispatch preflight, lines 284, 287 and 291. AC-09 and its Test Plan, lines 305 and 320. Task T9, line 338.
EVIDENCE: The R-41 F-02 correction adds interruptions before, during and after trust changes, and the proof calls for fresh checks after restart. The stale-catalogue case runs before trust finalization. An implementation that reads fresh withdrawal results on restart but continues remaining trust changes when those results fail can pass the named restart cases.
PROPOSAL: After partial trust retirement, restart with a stale predecessor catalogue or mismatched live deployment. Require zero further trust changes, no closure and no newer submission until fresh checks pass, then verify that the dispatch applies only the remaining approved changes.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Owner summary, lines 64-66. Signed-feed promotion step 3, line 274. AC-09 Test Plan, line 320. Task T9, line 338.
EVIDENCE: The history proof deletes a manifest or removes a reference while leaving the checkpoint unchanged. Restoring an older complete history and its matching checkpoint also passes a check that only compares those two records. The restored history can omit a generation that served a catalogue, allowing a future bundle to drop a package still referenced by a cached client.
PROPOSAL: Specify how reconciliation detects rollback to an older valid history and checkpoint using a durable record that survives that rollback. Add a fixture that restores the older pair after a catalogue has been served and requires the publisher to hold.

FINDING: F-05
KIND: factual
SEVERITY: nit
WHERE: Repository AGENTS.md, Verification. PHP quality and compatibility, lines 105-106.
EVIDENCE: The repository instructions cite shared docs PR #37 as the adopted PHP guidance. The specification identifies the same pinned docs revision as incorporating the security additions from PR #38. The revision itself is consistent across both and supplies the rules used by this review.
PROPOSAL: Clarify that PR #37 introduced the PHP guidance and the pinned revision includes the later security requirements.

### R-43

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Signed-feed promotion steps 3 and 5, lines 274 and 278. Activation reconciliation preflight, line 291. AC-09 Test Plan, line 320. Task T9, line 338.
EVIDENCE: The R-42 F-01 and F-04 fixes bind the approved manifest and bundle to the prior checkpoint, retain independent activation evidence, and add a rollback fixture. Step 3 still leaves the transition that advances the independent committed checkpoint undefined. A restart after the history append commits but before the independent checkpoint advances sees a mismatch. The spec permits reusing an exact committed entry and also requires a hold on mismatched history, with no rule distinguishing this legitimate intermediate state from a rollback or conflicting append. The restart proof also lacks a case with missing or conflicting approval linkage.
PROPOSAL: Define how reconciliation derives and verifies the exact successor from the durable approval, advances the independent checkpoint idempotently, and distinguishes an interrupted append from rollback or conflict. Exercise interruption between the two durable updates and require a hold when the approval linkage is missing or conflicts.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Signed-feed promotion step 4, line 276. Activation reconciliation rule 4 and dispatch preflight, lines 287 and 291. AC-09 and its Test Plan, lines 305 and 320. Task T9, line 338.
EVIDENCE: The R-42 F-02 fix gives deployment operators authority over client trust and records the approved scope and expected states before withdrawal. It leaves the evidence contract undefined. Operator-provided verification can be reused across attempts or cover only part of the approved scope unless the verifier checks its provenance, current applicability and coverage. The proof permits a single-appliance fixture and covers missing or conflicting evidence without requiring an unreachable client in a partially completed scope.
PROPOSAL: Require independently verifiable evidence bound to the specific retirement record, with current observations for every approved client and its expected final trust state. Exercise a scope with at least two clients and require an unreachable or conflicting client to keep retirement open and block newer work.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: Signed-feed promotion step 4, line 276. Activation reconciliation rule 4 and dispatch preflight, lines 287 and 291. AC-09 and its Test Plan, lines 305 and 320. Task T9, line 338.
EVIDENCE: The R-42 F-03 fix adds a restart proof requiring zero further fixture trust changes after withdrawal or live identity verification fails. The R-42 F-02 authority change gives those mutations to deployment operators. The normative text requires fresh checks before the publisher accepts completion evidence and holds closure and newer submissions. It leaves the separately operated trust procedure without a rule that prevents it from continuing a partially completed retirement after those checks fail.
PROPOSAL: Specify the verification result the deployment procedure must obtain before resuming client trust changes and how it handles a missing or failed result. Run the restart proof through that operator handoff.

FINDING: F-04
KIND: factual
SEVERITY: nit
WHERE: Repository AGENTS.md, Verification. PHP quality and compatibility, lines 105-106. Review Log.
EVIDENCE: R-42 F-05 is resolved by the updated attribution to PR #37 and PR #38. Pinned lint and the target commit's whitespace check passed. The planned gate failed on spec_review_fresh and accepted. No appliance or release fixtures were executed in this read-only spec review.
PROPOSAL: Resolve the remaining specification findings, then record a fresh review and renewed owner acceptance before moving the draft to planned.

### R-44

NO FINDINGS

## Sources

- [Shared PHP convention](https://github.com/vhco-pro/docs/blob/1edeb5f32d868bbe761ef3221f350634cd6ff022/conventions/php.md) supplies the implementation and verification rules, with primary-source links for each subject.
- [Shared browser verification standard](https://github.com/vhco-pro/docs/blob/1edeb5f32d868bbe761ef3221f350634cd6ff022/conventions/frontend-testing.md) supplies the owned-fixture and automated browser proof requirements.
- [Cloudflare Pages static hosting](https://developers.cloudflare.com/pages/framework-guides/deploy-anything/) and [limits](https://developers.cloudflare.com/pages/platform/limits/) describe the proposed managed hosting model and the limits to verify before feed publication.
- [FreeBSD pkg repository tooling](https://man.freebsd.org/cgi/man.cgi?query=pkg-repo&sektion=8&format=html) defines native catalogue creation/signing and repository metadata.

- [Core provider discovery](https://github.com/opnsense/core/blob/d20f63c7f7e73c062a623953690c0668070a8d94/src/opnsense/mvc/app/library/OPNsense/Backup/BackupFactory.php) and [provider interface](https://github.com/opnsense/core/blob/d20f63c7f7e73c062a623953690c0668070a8d94/src/opnsense/mvc/app/library/OPNsense/Backup/IBackupProvider.php) define discovery and provider entry points.
- [Current remote backup runner](https://github.com/opnsense/core/blob/d20f63c7f7e73c062a623953690c0668070a8d94/src/opnsense/scripts/system/remote_backup.php) isolates ordinary provider exceptions and reports aggregate failure after processing enabled providers.
- [Core Backups screen](https://github.com/opnsense/core/blob/d20f63c7f7e73c062a623953690c0668070a8d94/src/www/diag_backup.php) defines form rendering, setup/test and native decrypt/import.
- [Native backup encryption](https://github.com/opnsense/core/blob/d20f63c7f7e73c062a623953690c0668070a8d94/src/opnsense/mvc/app/library/OPNsense/Backup/Base.php) and [opnsense-crypt](https://github.com/opnsense/core/blob/d20f63c7f7e73c062a623953690c0668070a8d94/src/sbin/opnsense-crypt) define the reusable encryption implementation.
- [Existing Git provider](https://github.com/opnsense/plugins/tree/77648fd1a9ed4f9e99a4997336e30bc33949e629/sysutils/git-backup) supplies current transport/capture behavior and its 1.1_5 package metadata.
- [SFTP provider](https://github.com/opnsense/plugins/tree/5cca317cdc3e1a979a60b6935428f76de8d08d2b/sysutils/sftp-backup) demonstrates native encryption and credential configuration.
- [Plugin framework](https://github.com/opnsense/plugins/blob/5cca317cdc3e1a979a60b6935428f76de8d08d2b/Mk/plugins.mk) defines package build and file ownership tooling.
- [Plugin development](https://docs.opnsense.org/development/examples/helloworld.html) covers PHP, XML models, API, configd and packaging structure.
- [Firmware plugins](https://docs.opnsense.org/manual/firmware.html) describes package administration and plugin discovery.
- [Upstream contribution rules](https://github.com/opnsense/plugins/blob/5cca317cdc3e1a979a60b6935428f76de8d08d2b/CONTRIBUTING.md) govern licensing, proposal discussion, initial scope and AI disclosure.
- [Existing encryption request](https://github.com/opnsense/plugins/issues/5833), [previous encryption PR](https://github.com/opnsense/plugins/pull/3574) and [redaction discussion](https://github.com/opnsense/plugins/pull/4558) establish maintainer feedback and limits on contribution claims.

### R-45

CRITERION: AC-01 The package installs and upgrades on the selected supported releases, exposes its provider in the native Backups screen and preserves core and unrelated provider behavior.
VERDICT: not verified
EVIDENCE: Inspected the package preparation, provider contract and lifecycle fixtures at 3b785d386e59d55ba3211ab0cbe96b6287a2e315. Exact-source package installation, upgrade and ownership comparisons were not observed. The requested reviewer cache path was absent, so canonical instructions were read from the local vh-adlc Git tag v0.20.0. The pinned conventions were read at 1edeb5f32d868bbe761ef3221f350634cd6ff022.

CRITERION: AC-02 Complete encrypted exports restore through the native OPNsense interface on an isolated appliance, while all newly created provider Git snapshots and staging exclude plaintext configuration and synthetic secrets.
VERDICT: not verified
EVIDENCE: Inspected NativeRun.php, Snapshot.php, GitDelivery.php and the native restore fixture at 3b785d386e59d55ba3211ab0cbe96b6287a2e315. Encryption requires byte-for-byte round-trip verification before staging. Exact-source native restoration and inspection of retained appliance objects were not observed.

CRITERION: AC-03 Validated configuration and secret custody survive the documented restore/upgrade paths, enforce the selected privilege boundary and permit recovery and credential rotation independently of management services.
VERDICT: not met
EVIDENCE: Source inspection at 3b785d386e59d55ba3211ab0cbe96b6287a2e315 establishes that GitDelivery.php checks the checkpoint parent against the remote only when local HEAD is absent. Existing pending history bypasses validation against a replacement checkpoint's required parent. Finding F-01 describes the reachable mismatch. Native restore, upgrade and rotation checks were not executed during this review.

CRITERION: AC-04 Manual and scheduled runs produce consistent Git state under overlap, rejection, interrupted response, retry and divergent-remote cases, with success reflecting independently verified remote retention.
VERDICT: not verified
EVIDENCE: Independently retrieved the successful exact-source PHP job log from CI run 43619581606. PHPUnit reported 26 tests and 93 assertions, including Git delivery tests for overlap, rejection, divergence, lost push response and deleted branches. Inspected their implementation at 3b785d386e59d55ba3211ab0cbe96b6287a2e315. Native manual-versus-scheduled execution and the complete interruption matrix were not observed.

CRITERION: AC-05 Native scheduling survives regeneration and upgrade, failure of another provider cannot silently suppress the selected scheduling path, and native status plus independent freshness checking expose stale or failed delivery.
VERDICT: not met
EVIDENCE: Inspected NativeRun.php, GitDelivery.php, run.php and the status endpoint at 3b785d386e59d55ba3211ab0cbe96b6287a2e315. Activation and credential failures occur before attempt recording. The entry point returns a generic error without updating persisted status, leaving an earlier verified outcome visible after a failed delivery invocation. Finding F-02 describes this path. Exact-source cron regeneration, upgrade and deployment-owned monitoring were not observed.

CRITERION: AC-06 Migration preserves the verified final legacy history and previous remote ancestor off the firewall, prevents new credentials entering the legacy plaintext capture path and remains recoverable after interruption.
VERDICT: not verified
EVIDENCE: Inspected Activation.php, the native configuration-lock boundary, migration fixtures and recovery instructions at 3b785d386e59d55ba3211ab0cbe96b6287a2e315. The code rejects a present legacy hook and requires version 2 legacy checkpoints with export and configuration digests. Independent off-firewall archive retrieval, writer drain and interrupted cutover were not executed during this review.

CRITERION: AC-07 A second operator can install, configure, observe and recover the provider from versioned documentation and verified package inputs, with supported versions, diff/storage trade-offs and distribution/contribution limits explicit.
VERDICT: not verified
EVIDENCE: Read installation.md, recovery.md, compatibility.md and the package preparation scripts at 3b785d386e59d55ba3211ab0cbe96b6287a2e315. A second-operator walkthrough using verified exact-source package inputs and independently retained recovery material was not observed.

CRITERION: AC-08 Owned PHP source and tests pass the selected runtime syntax checks, PSR-12 style, declared static-analysis checks and behavior tests, with visible coverage and reviewed narrow exceptions. Required security scans and native audits complete with expected coverage and any findings resolved or given an independently reviewed, owner-approved disposition. The runtime package excludes development tooling and private fixtures.
VERDICT: not verified
EVIDENCE: Independently confirmed CI runs 43619581606 and 43619586476 succeeded for 3b785d386e59d55ba3211ab0cbe96b6287a2e315. Read the push-run PHP log showing PHP 8.5.12, passing syntax/style checks, PHPStan without errors, PHPUnit passing 26 tests with 93 assertions, Psalm without errors, a clean Composer audit, Semgrep covering 34 owned PHP files and Gitleaks scanning 198 commits without leaks. Independently counted 34 owned PHP files. Local actionlint, shell and JavaScript syntax checks, git diff --check and vh-adlc lint passed. PHP was unavailable locally. A current native package audit, applicable finding disposition and exact-source runtime package inspection were not observed.

CRITERION: AC-09 The signed repository supports verified native installation and updates on the selected runtime, rejects untrusted catalogues, modified packages and incompatible targets, and preserves recoverable trust and a usable prior generation for established feeds through failed publication and signing-key rotation. An unresolved first activation prohibits further publisher mutations while the pending request may still become live. Bootstrap recovery withdraws the first catalogue and retains its packages for cached clients. A terminal live recovery that fails native validation permits one retry of the same approved files per separately authorized dispatch. Newer releases stay blocked until recovery is verified. Production signing and deployment require owner approval, and fixture execution has access only to owned staging and fixture keys.
VERDICT: not verified
EVIDENCE: Independently inspected the exact-source workflow and native-verifier job log from run 43619581606. The FreeBSD signed-feed fixture passed its publication, recovery, cached-client and trust-transition assertions. Source inspection shows hosted-feed-content.sh builds synthetic packages with an empty payload, while feed-verify-native.sh verifies catalogue queries and package fetching. Actual plugin installation, native updates and firmware-interface behavior were not established by that job. Production publication jobs were skipped. The complete accepted scenario matrix was not independently observed.

CRITERION: AC-10 The native settings and status interfaces pass reproducible automated browser journeys for setup, reload persistence, success/failure states and permissions on owned disposable fixtures, with the applicable responsive and accessibility checks and developer tooling excluded from the runtime package.
VERDICT: untested
EVIDENCE: Inspected the complete browser suite, Playwright configuration and CI workflows at 3b785d386e59d55ba3211ab0cbe96b6287a2e315. Chromium and Firefox journeys cover setup, reload persistence, permissions and rejected delivery. The suite lacks the required zoom, reduced-motion, theme and responsive geometry coverage, and CI does not invoke it. Finding F-03 describes the missing coverage. Browser journeys and runtime package inspection were not executed during this review.

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: src/opnsense/mvc/app/library/OPNsense/EncryptedGitBackup/GitDelivery.php:125
EVIDENCE: At 3b785d386e59d55ba3211ab0cbe96b6287a2e315, the required checkpoint parent is compared with the remote only when HEAD is null. With existing pending work, reconciliation checks only whether the observed remote is an ancestor of HEAD. After same-target checkpoint replacement, a remote rewind to an ancestor of the old pending work can therefore permit delivery even when the newly verified parent is absent from that work. The accepted design explicitly requires pending ancestry to include the replacement checkpoint's parent. This finding follows source control flow and was not dynamically reproduced.
PROPOSAL: Validate existing pending ancestry against the active checkpoint before any push or receipt. Cover compatible and incompatible replacement parents, including a remote change after checkpoint verification.

FINDING: F-02
KIND: factual
SEVERITY: blocking
WHERE: src/opnsense/mvc/app/library/OPNsense/EncryptedGitBackup/NativeRun.php:23
EVIDENCE: At 3b785d386e59d55ba3211ab0cbe96b6287a2e315, activation, credential-file and configuration checks precede GitDelivery::recordDelivery(), which owns attempt recording. run.php:15 catches failures and emits a generic error without persisting them. After a successful delivery, removing a credential or invalidating activation leaves the status endpoint reporting the earlier verified attempt. The deployment monitor consequently cannot expose that newer failure through authenticated native status. Persisted failures also carry no sanitized failure category. This finding follows source control flow and was not dynamically reproduced.
PROPOSAL: Record target-associated attempts and sanitized failure categories across delivery preconditions while preserving the last verified receipt. Add regression coverage for credential and activation failures after a successful delivery.

FINDING: F-03
KIND: factual
SEVERITY: should-fix
WHERE: tests/browser/native.spec.ts:45
EVIDENCE: At 3b785d386e59d55ba3211ab0cbe96b6287a2e315, the browser suite exercises a 390 by 844 status view and keyboard navigation. It contains no zoom, reduced-motion, supported-theme or responsive geometry assertions. Neither checked CI workflow invokes Playwright. The pinned frontend-testing standard requires these applicable checks and automated browser verification before merge, so passing current CI leaves those interface requirements uncovered.
PROPOSAL: Add the applicable viewport, geometry, zoom, motion and theme checks, and run the browser suite against an owned disposable appliance in the verification workflow. Retain and inspect representative screenshots from the reviewed source.

### R-46 criterion evidence

- AC-01 remains unchecked. R-46 returned not verified.
- AC-02 remains unchecked. R-46 returned not verified.
- AC-03 remains unchecked. R-46 returned not verified.
- AC-04 remains unchecked. R-46 returned not verified.
- AC-05 remains unchecked. R-46 returned not verified.
- AC-06 remains unchecked. R-46 returned not verified.
- AC-07 remains unchecked. R-46 returned not verified.
- AC-08 remains unchecked. R-46 returned not met.
- AC-09 remains unchecked. R-46 returned not verified.
- AC-10 remains unchecked. R-46 returned not verified.

### R-46

CRITERION: AC-01 The package installs and upgrades on the selected supported releases, exposes its provider in the native Backups screen and preserves core and unrelated provider behavior.
VERDICT: not verified
EVIDENCE: Confirmed clean HEAD 3fc566d4800e9d325c96dbae53c5f18ff42d04a9. Read the canonical reviewer and pinned conventions at 1edeb5f32d868bbe761ef3221f350634cd6ff022. Independently inspected package preparation, provider discovery and lifecycle assertions. Sanitized r45.log output identifies the exact-source alpha8 package, SHA-256 2b2976fcf211b16b6ac8709c01605f62e8c052a7ed3a7324821e8f28f61411c4, and successful installation and remove/reinstall markers. Appliance execution and complete core/unrelated-provider comparisons were not independently observed during this review.

CRITERION: AC-02 Complete encrypted exports restore through the native OPNsense interface on an isolated appliance, while all newly created provider Git snapshots and staging exclude plaintext configuration and synthetic secrets.
VERDICT: not verified
EVIDENCE: At 3fc566d4800e9d325c96dbae53c5f18ff42d04a9, inspected Snapshot.php, NativeRun.php, GitDelivery.php and restore-smoke.php. Encryption requires byte-for-byte native decryption verification before staging. The Git migration test asserts an encrypted-only active tree and absence of a checked-out plaintext configuration. Retrieved exact-source CI showing all 26 PHPUnit tests passed. Historical native restoration markers were inspected, and Git comparison confirmed Snapshot.php is unchanged from those sources. Complete restoration and inspection of every newly retained Git object were not independently executed.

CRITERION: AC-03 Validated configuration and secret custody survive the documented restore/upgrade paths, enforce the selected privilege boundary and permit recovery and credential rotation independently of management services.
VERDICT: not verified
EVIDENCE: At 3fc566d4800e9d325c96dbae53c5f18ff42d04a9, inspected configuration validation, credential permissions, ACLs, activation and rollback. R-45 F-01 is addressed in source by requiring the active checkpoint parent to be an ancestor of existing pending HEAD before reconciliation can push or verify delivery. The corresponding regression is included in the successful exact-source PHPUnit job. Retained native logs cover rotation, restoration, admitted-worker draining and changed-settings recovery at earlier identified sources. The complete restore/upgrade/rotation matrix was not independently executed against this target.

CRITERION: AC-04 Manual and scheduled runs produce consistent Git state under overlap, rejection, interrupted response, retry and divergent-remote cases, with success reflecting independently verified remote retention.
VERDICT: not verified
EVIDENCE: Retrieved the successful PHP job from push CI run 43621893604 for 3fc566d4800e9d325c96dbae53c5f18ff42d04a9, reporting 26 tests and 105 assertions. Inspected delivery tests covering locking, rejected-push retry, divergence, lost push responses, missing branches and retained receipts. Source uses expected-old-ref push conditions and remote read-back. Native manual-versus-scheduled overlap and the full accepted interruption matrix were not independently executed.

CRITERION: AC-05 Native scheduling survives regeneration and upgrade, failure of another provider cannot silently suppress the selected scheduling path, and native status plus independent freshness checking expose stale or failed delivery.
VERDICT: not verified
EVIDENCE: At 3fc566d4800e9d325c96dbae53c5f18ff42d04a9, inspected native entry points, status recording, Freshness.php and native fixtures. R-45 F-02 is addressed for the reviewed activation, credential and configuration failure paths by persisting sanitized target-associated failed attempts while preserving verified.json. Exact-source CI exercises the status-writing assertions. Sanitized r45.log markers report NATIVE_PRECONDITION_STATUS_OK, R45_EXACT_STATUS_EXIT=0 and successful post-upgrade cron delivery. Historical logs report sibling-provider failure isolation. Appliance execution, deployment-owned monitoring and notification delivery were not independently observed.

CRITERION: AC-06 Migration preserves the verified final legacy history and previous remote ancestor off the firewall, prevents new credentials entering the legacy plaintext capture path and remains recoverable after interruption.
VERDICT: not verified
EVIDENCE: At 3fc566d4800e9d325c96dbae53c5f18ff42d04a9, inspected Activation.php, native configuration locking, migration fixtures and recovery procedures. Legacy activation requires version 2 checkpoint evidence and matching configuration digest, while delivery checks writer absence and saved activation. The retained migration fixture verifies its archive inside the disposable guest. Independent off-firewall retrieval, concurrent legacy-writer draining and the complete interrupted-cutover recovery procedure were not independently executed.

CRITERION: AC-07 A second operator can install, configure, observe and recover the provider from versioned documentation and verified package inputs, with supported versions, diff/storage trade-offs and distribution/contribution limits explicit.
VERDICT: not verified
EVIDENCE: At 3fc566d4800e9d325c96dbae53c5f18ff42d04a9, read installation.md, recovery.md, compatibility.md and the feature design. They describe runtime selection, external credential recovery, native setup, rollback and distribution boundaries. A second-operator walkthrough using verified package inputs was not observed. The Test Plan's measured repository-growth evidence was not located in the installation or compatibility documentation.

CRITERION: AC-08 Owned PHP source and tests pass the selected runtime syntax checks, PSR-12 style, declared static-analysis checks and behavior tests, with visible coverage and reviewed narrow exceptions. Required security scans and native audits complete with expected coverage and any findings resolved or given an independently reviewed, owner-approved disposition. The runtime package excludes development tooling and private fixtures.
VERDICT: not met
EVIDENCE: Independently confirmed successful push run 43621893604 and PR run 43621899215 for 3fc566d4800e9d325c96dbae53c5f18ff42d04a9. Retrieved PHP-job results showing PHP 8.5.12, passing syntax/style checks, PHPStan and Psalm without errors, PHPUnit passing 26 tests with 105 assertions, clean Composer auditing, Semgrep coverage of all 36 owned PHP files and Gitleaks scanning 204 commits without leaks. Security probes passed. Locally executed actionlint, syntax checks for 58 shell scripts and three JavaScript modules, git diff --check and vh-adlc lint successfully. Retained native audit output reports python313-3.13.18 and exit 1. The documented advisory remains without an owner-approved disposition, so the security requirement remains unmet. PHP was unavailable locally, and exact-package contents were not independently inspected.

CRITERION: AC-09 The signed repository supports verified native installation and updates on the selected runtime, rejects untrusted catalogues, modified packages and incompatible targets, and preserves recoverable trust and a usable prior generation for established feeds through failed publication and signing-key rotation. An unresolved first activation prohibits further publisher mutations while the pending request may still become live. Bootstrap recovery withdraws the first catalogue and retains its packages for cached clients. A terminal live recovery that fails native validation permits one retry of the same approved files per separately authorized dispatch. Newer releases stay blocked until recovery is verified. Production signing and deployment require owner approval, and fixture execution has access only to owned staging and fixture keys.
VERDICT: not verified
EVIDENCE: At 3fc566d4800e9d325c96dbae53c5f18ff42d04a9, independently executed six package fixture scripts and the loopback HTTP publisher test successfully using temporary state and an environment excluding credentials. Retrieved the successful exact-source FreeBSD native-verifier job and inspected its fixture construction. It uses signed synthetic packages with empty payloads and mocked publication services. Historical logs establish actual plugin installation and upgrade through a local signed feed at earlier sources. Exact-plugin installation/update through the complete promotion path, Firmware GUI behavior and the full accepted native scenario matrix were not independently established. Production publication jobs were skipped.

CRITERION: AC-10 The native settings and status interfaces pass reproducible automated browser journeys for setup, reload persistence, success/failure states and permissions on owned disposable fixtures, with the applicable responsive and accessibility checks and developer tooling excluded from the runtime package.
VERDICT: not verified
EVIDENCE: At 3fc566d4800e9d325c96dbae53c5f18ff42d04a9, inspected browser scenarios and retained logs reporting ten successful setup/access/layout tests, two successful rejection tests and eight successful tests per supported theme. Inspected representative Chromium and Firefox screenshots. Separate zoom scripts use actual browser zoom interfaces, with retained measurements showing width changing from 800 to 400 CSS pixels and DPR from 1 to 2. R-45 F-03's responsive, reduced-motion, theme and zoom evidence gaps have been substantially addressed. Its CI integration gap remains. Browser execution and runtime-package exclusion were not independently verified during this review.

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: .github/workflows/php.yml:11; .github/workflows/feed.yml; tests/browser/native.spec.ts
EVIDENCE: At 3fc566d4800e9d325c96dbae53c5f18ff42d04a9, neither checked workflow invokes Playwright or provisions the native OPNsense browser fixture. Independently inspected exact-source CI jobs confirm PHP, versioning, package-plan and feed-fixture execution, with no native browser job. The pinned frontend-testing standard requires applicable automated browser verification before merge. This is the remaining CI portion of R-45 F-03.
PROPOSAL: Add the native browser journeys to the pre-merge verification path using an owned compatible disposable fixture and retain their results.

FINDING: F-02
KIND: factual
SEVERITY: blocking
WHERE: docs/specs/native-encrypted-git-backup.md Acceptance Criteria AC-08; docs/compatibility.md:54; docs/compatibility.md:58
EVIDENCE: Retained native console output reports python313-3.13.18 with CURRENT_NATIVE_AUDIT_EXIT=1 and NEXT_AUDIT_EXIT=1. At the reviewed target, compatibility.md records the unresolved CVE-2025-15367 audit finding and the need for a supported fix or independently reviewed owner disposition. The supplied evidence map confirms no owner waiver. AC-08 requires that disposition or resolution before completion.
PROPOSAL: Obtain a supported dependency fix and passing native audit, or retain an independently reviewed, owner-approved disposition with its measured exposure limits.

### R-47 criterion evidence

- AC-01 returned met in R-47.
- AC-02 returned met in R-47.
- AC-03 returned not met in R-47.
- AC-04 returned not verified in R-47.
- AC-05 returned not verified in R-47.
- AC-06 returned not verified in R-47.
- AC-07 returned not met in R-47.
- AC-08 returned not met in R-47.
- AC-09 returned not met in R-47.
- AC-10 returned met in R-47.

### R-47

CRITERION: AC-01 The package installs and upgrades on the selected supported releases, exposes its provider in the native Backups screen and preserves core and unrelated provider behavior.
VERDICT: met
EVIDENCE: Independently built and installed the exact source on the owned OPNsense 26.7.9_1, FreeBSD 15.1-RELEASE-p6, PHP 8.5.12 guest. Native Backups journeys, lifecycle.sh, feed-client.sh and firmware-feed.sh established provider discovery, removal/reinstallation, signed installation and upgrades through synthetic versions alpha91 to alpha94. Plugin integrity checks passed, other backup-provider file hashes remained unchanged, and the native runner continued encrypted delivery after a synthetic sibling provider failed. Evidence is retained in /tmp/eg-independent.lIu2R6/native.log.

CRITERION: AC-02 Complete encrypted exports restore through the native OPNsense interface on an isolated appliance, while all newly created provider Git snapshots and staging exclude plaintext configuration and synthetic secrets.
VERDICT: met
EVIDENCE: On the owned exact-source guest, rotation-smoke.sh restored old and rotated exports through the native restore implementation. Independently retrieved a remote encrypted snapshot, matched its SHA-256 to snapshot metadata, and completed the documented browser upload, decryption and full restore. gui-restore.log records REVIEW_NATIVE_GUI_FULL_RESTORE_OK. Independent inspection verified ten retained snapshots, their digests, native decryption, encrypted-only trees and staging, and absence of the checked plaintext configuration and synthetic password markers. Snapshot validation and round-trip failure tests also passed in exact-source hosted execution.

CRITERION: AC-03 Validated configuration and secret custody survive the documented restore/upgrade paths, enforce the selected privilege boundary and permit recovery and credential rotation independently of management services.
VERDICT: not met
EVIDENCE: Native privilege journeys, package transitions, credential rotation and old/new restoration passed against the reviewed source. However, independently executing hold, verify and resume, followed by a normal configuration save and another hold, returned ROLLBACK_HOLD: The prepared rollback pair no longer matches. The completed operation leaves rollback-pair.json active and prevents the next documented recovery cycle. native.log records REVIEW_REPEATED_ROLLBACK_HOLD_EXIT=1. See F-01.

CRITERION: AC-04 Manual and scheduled runs produce consistent Git state under overlap, rejection, interrupted response, retry and divergent-remote cases, with success reflecting independently verified remote retention.
VERDICT: not verified
EVIDENCE: Exact-source hosted PHPUnit execution passed 26 tests and 105 assertions, including locking, rejected-push retry, divergence, lost responses, branch deletion and remote read-back. Independently observed native scheduled delivery, rejected browser delivery preserving the previous receipt, and subsequent reconciliation. The complete native overlap and process-termination matrix was not executed. These passing subsets do not establish the composite criterion.

CRITERION: AC-05 Native scheduling survives regeneration and upgrade, failure of another provider cannot silently suppress the selected scheduling path, and native status plus independent freshness checking expose stale or failed delivery.
VERDICT: not verified
EVIDENCE: Independently executed post-upgrade-cron.sh after actual signed package upgrades. Regenerated cron advanced the remote and recorded its matching receipt. provider-failure.sh confirmed aggregate failure while encrypted delivery continued. Native activation and credential failures produced target-associated sanitized attempts while preserving the previous receipt. Exact-source freshness tests passed. Deployment-owned monitoring, authenticated target-change scenarios through that monitor, stopped-scheduler handling and owner notification delivery were not independently executed.

CRITERION: AC-06 Migration preserves the verified final legacy history and previous remote ancestor off the firewall, prevents new credentials entering the legacy plaintext capture path and remains recoverable after interruption.
VERDICT: not verified
EVIDENCE: Independently executed migration-smoke.sh against a separate fixture remote. Stale export evidence was rejected and cutover preserved the legacy parent with an encrypted-only new tree. Retrieved the encrypted legacy archive off the guest, matched its checkpoint digest, decrypted and imported its complete bundle independently, and verified checkpoint ancestry. Removed the temporary plaintext recovery material afterward. This fixture used the same legacy tip and remote ancestor; concurrent writer draining, distinct unpublished legacy history and the complete interrupted-cutover recovery matrix remain unverified.

CRITERION: AC-07 A second operator can install, configure, observe and recover the provider from versioned documentation and verified package inputs, with supported versions, diff/storage trade-offs and distribution/contribution limits explicit.
VERDICT: not met
EVIDENCE: Independently followed the versioned installation, signed-feed, configuration and encrypted browser-restore procedures using verified fixture inputs. Inspected the supported runtime, measured-growth guidance, encrypted-diff trade-off and distribution boundaries. The documented rollback procedure fails on its next cycle after successful resume and a normal configuration save. The guide supplies no supported retirement or renewal procedure for the stale rollback-pair.json. See F-01.

CRITERION: AC-08 Owned PHP source and tests pass the selected runtime syntax checks, PSR-12 style, declared static-analysis checks and behavior tests, with visible coverage and reviewed narrow exceptions. Required security scans and native audits complete with expected coverage and any findings resolved or given an independently reviewed, owner-approved disposition. The runtime package excludes development tooling and private fixtures.
VERDICT: not met
EVIDENCE: Independently retrieved successful exact-source PHP run 43632105195 and its job logs: PHP 8.5.12, passing syntax, PSR-12, PHPStan, PHPUnit with 26 tests and 105 assertions, Psalm, Composer audit, Semgrep over all 36 owned PHP files, and redacted history/source scans. Local actionlint, 63 shell syntax checks, JavaScript syntax checks, feature lint and git diff --check passed. Inspected the native package file list and verified plugin integrity. Final native pkg audit returned exit 1 for python313-3.13.18 and CVE-2025-15367. The advisory database SHA-256 was 0b17cc23a3098cf795947b8016ed8b714bd40d632ea59703c45c6e0718d35011. No owner-approved disposition was supplied. See F-02.

CRITERION: AC-09 The signed repository supports verified native installation and updates on the selected runtime, rejects untrusted catalogues, modified packages and incompatible targets, and preserves recoverable trust and a usable prior generation for established feeds through failed publication and signing-key rotation. An unresolved first activation prohibits further publisher mutations while the pending request may still become live. Bootstrap recovery withdraws the first catalogue and retains its packages for cached clients. A terminal live recovery that fails native validation permits one retry of the same approved files per separately authorized dispatch. Newer releases stay blocked until recovery is verified. Production signing and deployment require owner approval, and fixture execution has access only to owned staging and fixture keys.
VERDICT: not met
EVIDENCE: Independently passed six package fixture scripts and the loopback publisher test. Inspected successful exact-source hosted FreeBSD feed verification, whose payloads are synthetic. Independently installed and upgraded actual plugin payloads through signed pkg catalogues and the native Firmware launcher, including wrong-key rejection. A separate loopback probe returned a definitive structured HTTP 403 without creating a deployment. The publisher retained submission-started, then rejected reconciliation with unresolved Pages create, with no supported rejection closure or retry path. See F-03. The full accepted scenario matrix and release-eligible GitVersion-to-native-client chain were not independently established; the current branch calculation emits an ineligible feature preview.

CRITERION: AC-10 The native settings and status interfaces pass reproducible automated browser journeys for setup, reload persistence, success/failure states and permissions on owned disposable fixtures, with the applicable responsive and accessibility checks and developer tooling excluded from the runtime package.
VERDICT: met
EVIDENCE: Exact-target hosted browser runs 43632104879 and 43632109710 completed successfully. Independently downloaded the push artifact and matched GitHub's SHA-256 a897f6b3e9804898a6efadef1f8491d8a5471a1728dbb735087d2cbe833b13b2. Logs establish ten main checks, two dark-theme checks, two rejection checks, real 200 percent zoom in both engines and encrypted repository growth. Inspected representative screenshots. The independently executed local full driver exited 1 on Chromium ERR_NETWORK_CHANGED; its failures remain retained. Subsequent focused journeys and both unmodified zoom scripts passed on the owned guest, measuring 800 to 400 CSS pixels and DPR 1 to 2 without horizontal overflow. Native package inspection excluded browser tooling and private fixtures. The owned guest was powered off and its QEMU process exited.

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: src/opnsense/scripts/encryptedgit/rollback.php:98-102 and 241-245; docs/recovery.md:32-40; Design / Guarded migration and recovery; Acceptance Criteria AC-03 and AC-07
EVIDENCE: Independently reproduced against the exact-source installed package. hold, verify and resume succeeded. After a normal browser-theme configuration save, another hold failed with The prepared rollback pair no longer matches. Successful resume restores activation.json but leaves rollback-pair.json containing the completed operation's revision. A subsequent hold compares current state against that obsolete record instead of capturing a new operation. The versioned recovery guide provides no supported way to renew it.
PROPOSAL: Retire or durably close the completed rollback record and allow a later operation to capture a fresh pair without weakening interrupted-operation checks. Cover successive recovery cycles separated by configuration changes.

FINDING: F-02
KIND: factual
SEVERITY: blocking
WHERE: Acceptance Criteria and Test Plan / AC-08; docs/compatibility.md / Installed runtime audit and CVE-2025-15367 disposition
EVIDENCE: Independently executed the final installed-runtime audit after package lifecycle verification. pkg audit returned exit 1 with python313-3.13.18 affected by CVE-2025-15367. Final inventory SHA-256 was fe5daf13ec05c7c68ced9e844f44180a22f559d6b13ca6aee195429bbe912ef2. The current [FreeBSD advisory](https://vuxml.freebsd.org/freebsd/6d3488ae-2e0f-11f1-88c7-00a098b42aeb.html) still lists python313 as affected. The supplied documentation explicitly leaves the finding unresolved, without an owner-approved disposition.
PROPOSAL: Obtain a supported fix and passing native audit, or record an independently reviewed, owner-approved disposition with its measured exposure limits before completing AC-08.

FINDING: F-03
KIND: factual
SEVERITY: blocking
WHERE: scripts/publish-feed.sh:16, 110 and 256-258; scripts/feed-recovery.sh:40-43; Design / Signed-feed promotion and Activation reconciliation and retry eligibility; Test Plan / AC-09
EVIDENCE: The independent loopback probe in /tmp/eg-independent.lIu2R6/feed-rejection-probe.mjs returned structured HTTP 403 authentication rejection and created zero deployments. The exact publisher exited on HTTP failure without durably classifying rejection. Its next invocation required a matching Pages deployment and failed with unresolved Pages create. The journal remained submission-started despite the definitive rejection and unchanged bootstrap state. Recovery submission uses the same response handling and subsequent mandatory correlation. The accepted definitive-rejection control and permitted reconciliation paths are therefore not implemented.
PROPOSAL: Durably distinguish definitive create rejection from ambiguous submission results, then apply the accepted unchanged-source closure or retry rules. Preserve fail-closed handling for unclassified responses and cover candidate and recovery rejection paths.

FINDING: F-04
KIND: factual
SEVERITY: should-fix
WHERE: Review execution / source-ref isolation
EVIDENCE: Baseline and final source-ref inventories differ by the added refs/codex/turn-diffs/captures/1794684825149/0423a039-7872-4dd4-9da9-9c2478d97ee7/base ref. It points to an object already referenced by the initial Codex checkpoint. No review command explicitly created it, and no corrective ref mutation was attempted. HEAD, branch refs, tracked index contents and index SHA-256 remained unchanged, and the source worktree remained clean. Complete ref immutability was therefore not preserved by the surrounding host.
PROPOSAL: Suppress host capture-ref creation or enforce a read-only source mount for future runs requiring unchanged refs. Retain this execution's procedural isolation limitation.

### R-48 criterion evidence

- AC-01 returned met in R-48.
- AC-02 returned met in R-48.
- AC-03 returned not verified in R-48.
- AC-04 returned met in R-48.
- AC-05 returned not verified in R-48.
- AC-06 returned not verified in R-48.
- AC-07 returned met in R-48.
- AC-08 returned not met in R-48.
- AC-09 returned not verified in R-48.
- AC-10 returned met in R-48.

### R-48

TARGET: bf4108dc240e2b149c392cfd5d0ab47dac43d058

CRITERION: AC-01 The package installs and upgrades on the selected supported releases, exposes its provider in the native Backups screen and preserves core and unrelated provider behavior.
VERDICT: met
EVIDENCE: At bf4108d, built and installed actual plugin packages on the owned FreeBSD 15.1-RELEASE-p6, OPNsense 26.7.9_1, PHP 8.5.12 guest. Native Firmware launcher installation and upgrade passed with synthetic alpha93 and alpha94. Signed pkg installation and upgrade, native Backups discovery, package integrity and sibling-provider failure isolation passed. Compared all 21 owned alpha94 payload files with the reviewed Git source and inspected package ownership. The unchanged earlier native ownership proof was checked against source equivalence. lifecycle.sh failed twice at configd startup, followed by successful direct delivery and integrity checks. See F-02. Logs and retained packages are under /tmp/eg-r48.MeZX1G/native/.

CRITERION: AC-02 Complete encrypted exports restore through the native OPNsense interface on an isolated appliance, while all newly created provider Git snapshots and staging exclude plaintext configuration and synthetic secrets.
VERDICT: met
EVIDENCE: At bf4108d, rotation-smoke.sh restored old and rotated complete exports through the native restore implementation. Independently verified eleven provider snapshots, encrypted-only trees and staging, metadata digests, native decryption and checked synthetic secret exclusion. Downloaded remote commit 1a8803a67a6baf22fb8d6feb23d6cdc9e9a21656 over the owned loopback SSH fixture and matched ciphertext SHA-256 faa8ee864ebea5908e22f8e002f7dc628c727af5aab6ec484d1491946fc650f6. Native browser decrypt/import completed and subsequent delivery passed. gui-restore.log and gui-restore.png retain the result. The failed serial checksum transfer and initial 30-second browser navigation timeout remain retained. The successful browser retry used a bounded 120-second timeout.

CRITERION: AC-03 Validated configuration and secret custody survive the documented restore/upgrade paths, enforce the selected privilege boundary and permit recovery and credential rotation independently of management services.
VERDICT: not verified
EVIDENCE: At bf4108d, independently passed operator-repeat.sh, interrupted closing/resume, admitted-worker drain, changed-settings restoration, native privilege journeys, package transitions, credential rotation and delivery after native browser restoration. The rotated credential remained root-owned, mode 0600, with one link. The complete accepted version 1 upgrade, checkpoint replacement and older-provider interruption matrix was not executed. Capacity termination also required filesystem repair and rebuilding the exact-source fixture after guest-state loss. The interruption, failed state recovery and exact-source rebuild are retained in native/reboot-console.log.

CRITERION: AC-04 Manual and scheduled runs produce consistent Git state under overlap, rejection, interrupted response, retry and divergent-remote cases, with success reflecting independently verified remote retention.
VERDICT: met
EVIDENCE: At bf4108d, delivery-interrupt.sh independently passed on the installed native package. A blocked loopback pre-receive hook, queued second configd call and termination of the identified first worker preserved the exact pending commit, remote ref and previous receipt. Retry retained that pending commit and verified delivery. Native admitted-worker drain and scheduled delivery also passed. Inspected exact-target hosted PHPUnit execution with 26 tests and 105 assertions covering rejected pushes, divergence, lost response, overlap, explicit refs, remote read-back and branch disappearance. Independently retrieved and verified a retained remote object. Evidence is in native/console.log, native/reboot-console.log and ci-php.log under /tmp/eg-r48.MeZX1G/.

CRITERION: AC-05 Native scheduling survives regeneration and upgrade, failure of another provider cannot silently suppress the selected scheduling path, and native status plus independent freshness checking expose stale or failed delivery.
VERDICT: not verified
EVIDENCE: At bf4108d, post-upgrade-cron.sh passed after actual signed package upgrades and native cron regeneration. provider-failure.sh confirmed continued encrypted delivery with aggregate failure. stopped-scheduler.sh passed after regenerating the initially stopped fixture cron service. Authenticated target A/B endpoint reads preserved the same failed A attempt and timestamp after the settings-only switch to B. Independent Git object reads produced fresh/failed for A and fresh/unknown for B, unreachable status and unassociated status. The local notification sink passed. Deployment-owned monitoring and actual owner notification delivery remain unexecuted. Evidence is in native/monitor-host.log, status-a.json, status-b.json and the native console logs.

CRITERION: AC-06 Migration preserves the verified final legacy history and previous remote ancestor off the firewall, prevents new credentials entering the legacy plaintext capture path and remains recoverable after interruption.
VERDICT: not verified
EVIDENCE: At bf4108d, independently executed migration-smoke.sh --unpublished. Observed active-writer rejection, preliminary retention, completion of an admitted synthetic legacy writer, quiesce/drain, stale-checkpoint refusal, rejected first encrypted delivery with pending retention and exact retry. Retrieved the encrypted legacy archive off the guest and matched SHA-256 377fd7e706f85c2a025882f80047eeb0e8b2cf3f1a78490473003f7de81c906a. Independently decrypted/imported it and verified distinct unpublished tip 207735f8e73bbba1344bbb1de84b40796283f9db and remote ancestor 903a37c8c74979f27014ca2a75dbccf1fc13c04e, ancestry and checked credential exclusion. Removed the plaintext verification material. The full interrupted-cutover and independently retained pre-cutover-export recovery matrix remains unexecuted.

CRITERION: AC-07 A second operator can install, configure, observe and recover the provider from versioned documentation and verified package inputs, with supported versions, diff/storage trade-offs and distribution/contribution limits explicit.
VERDICT: met
EVIDENCE: At bf4108d, independently followed the versioned fixture installation, trust-bootstrap, configuration, observation and recovery procedures using retained verified inputs. Fresh null-legacy version 1 activation and delivery passed. Actual signed package and Firmware installation/upgrade passed. Documented repeated rollback, scoped settings restoration, independent ciphertext retrieval and native browser restoration passed. Inspected supported runtime, measured storage-growth guidance, encrypted-diff trade-offs and distribution/contribution limits. The earlier native growth proof has equivalent source outside the independently retested rollback change. Retained the lifecycle fixture startup failures in F-02.

CRITERION: AC-08 Owned PHP source and tests pass the selected runtime syntax checks, PSR-12 style, declared static-analysis checks and behavior tests, with visible coverage and reviewed narrow exceptions. Required security scans and native audits complete with expected coverage and any findings resolved or given an independently reviewed, owner-approved disposition. The runtime package excludes development tooling and private fixtures.
VERDICT: not met
EVIDENCE: At bf4108d, inspected successful exact-target push run 43638799939 and its previously retrieved PHP logs. PHP 8.5.12 syntax, PSR-12, PHPStan, PHPUnit with 26 tests and 105 assertions, Psalm taint analysis, Composer audit, Semgrep over 37 owned PHP files and redacted history/source scans passed. Local actionlint, 69 shell syntax checks, seven JavaScript syntax checks, feature lint and diff checks passed. Verified exact package payloads and exclusion of development tooling/private fixtures. Independently ran native pkg audit against VuXML SHA-256 0b17cc23a3098cf795947b8016ed8b714bd40d632ea59703c45c6e0718d35011. It returned exit 1 for python313-3.13.18 and CVE-2025-15367. Inventory SHA-256 is fe5daf13ec05c7c68ced9e844f44180a22f559d6b13ca6aee195429bbe912ef2. Feature lint used the supplied vh-adlc 0.26.0 binary, docs pin 1edeb5f32d868bbe761ef3221f350634cd6ff022 and plugin pin 1ccf8f314575ece1f3fcc8e48c4fd804a1ca88ff. The advisory remains unwaived. See F-01.

CRITERION: AC-09 The signed repository supports verified native installation and updates on the selected runtime, rejects untrusted catalogues, modified packages and incompatible targets, and preserves recoverable trust and a usable prior generation for established feeds through failed publication and signing-key rotation. An unresolved first activation prohibits further publisher mutations while the pending request may still become live. Bootstrap recovery withdraws the first catalogue and retains its packages for cached clients. A terminal live recovery that fails native validation permits one retry of the same approved files per separately authorized dispatch. Newer releases stay blocked until recovery is verified. Production signing and deployment require owner approval, and fixture execution has access only to owned staging and fixture keys.
VERDICT: not verified
EVIDENCE: At bf4108d, independently inspected the exact-target hosted actual-controller native-verifier execution and its source assertions for definitive candidate rejection, authorized recovery rejection, genuinely empty bootstrap, manual-diagnosis hold and consumed-dispatch Q3 replay. The passing job used real FreeBSD pkg, synthetic package content and mocked platform APIs. Locally executed all six package fixture scripts and the loopback publisher test. On the owned native guest, actual plugin signed installation/upgrade, wrong-key rejection, Firmware launcher installation/upgrade and native prerelease ordering passed. The branch-push calculation emitted the ineligible 0.1.0-feat-native-encrypted-git-backup.1 preview. The full accepted publication/interruption/trust-finalization matrix and release-eligible exact-target version-to-client chain remain unverified. Fixture effects used owned loopback resources and fixture keys.

CRITERION: AC-10 The native settings and status interfaces pass reproducible automated browser journeys for setup, reload persistence, success/failure states and permissions on owned disposable fixtures, with the applicable responsive and accessibility checks and developer tooling excluded from the runtime package.
VERDICT: met
EVIDENCE: At bf4108d, independently executed Chromium and Firefox journeys on the installed owned fixture. Ten main checks passed, followed by two dark-theme checks and two rejected-delivery checks. Verified authentication, unauthorized/read-only boundaries, native setup, reload persistence, success/failure status, retained receipt, keyboard interaction, reduced motion and widths 1280/640/390/320. Both real 200-percent zoom scripts passed with viewport 800 to 400 CSS pixels, DPR 1 to 2 and no horizontal overflow. Inspected light/dark, zoom and restored-state screenshots. Package inspection excluded browser tooling and private fixtures. Results are in browser-light.log, remaining-ui-after-recovery.log, browser-light/, browser-dark/, browser-rejected/ and zoom/ under /tmp/eg-r48.MeZX1G/. The owned guest shut down cleanly and its serial helper stopped. The overlay and failure artifacts are retained.

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Acceptance Criteria and Test Plan / AC-08; docs/compatibility.md / Installed 26.7.9_1 runtime audit and CVE-2025-15367 disposition
EVIDENCE: The independently executed installed-runtime pkg audit returned exit 1 with python313-3.13.18 affected by CVE-2025-15367. The full retained VuXML snapshot has SHA-256 0b17cc23a3098cf795947b8016ed8b714bd40d632ea59703c45c6e0718d35011. The installed inventory has SHA-256 fe5daf13ec05c7c68ced9e844f44180a22f559d6b13ca6aee195429bbe912ef2. The accepted criterion requires resolved findings or an independently reviewed, owner-approved disposition. No such disposition applies. The native console and retained inventory establish this result directly.
PROPOSAL: Resolve the flagged appliance dependency through a supported fix and repeat the audit, or obtain and record an independently reviewed owner-approved disposition before completing AC-08.

FINDING: F-02
KIND: factual
SEVERITY: blocking
WHERE: tests/native/lifecycle.sh:17-20; Test Plan / AC-01
EVIDENCE: Two independent executions of the unmodified lifecycle.sh on the owned exact-source TCG guest failed immediately after service configd restart. Both printed configd socket missing, then the fixture attempted to decode empty output and exited 255 with JsonException. Subsequent direct delivery and package integrity checks passed. The fixture invokes delivery before establishing configd readiness, so this automated lifecycle proof fails the working installed package under the supported disposable execution path. The failures remain in native/reboot-console.log and native/lifecycle-retry.log.
PROPOSAL: Wait for a bounded native configd readiness check before invoking delivery after restart. Preserve a distinct startup failure when readiness never arrives, then rerun the unchanged lifecycle assertions.

### R-49 criterion evidence

- AC-01 returned met in R-49.
- AC-02 returned met in R-49.
- AC-03 returned not verified in R-49.
- AC-04 returned met in R-49.
- AC-05 returned not verified in R-49.
- AC-06 returned met in R-49.
- AC-07 returned met in R-49.
- AC-08 returned not met in R-49.
- AC-09 returned not verified in R-49.
- AC-10 returned met in R-49.

### R-49

TARGET: 0888a750d3eefde56458f196f7acb8e7e91dde5b

CRITERION: AC-01 The package installs and upgrades on the selected supported releases, exposes its provider in the native Backups screen and preserves core and unrelated provider behavior.
VERDICT: met
EVIDENCE: Built and installed exact-source packages on FreeBSD 15.1-RELEASE-p6, OPNsense 26.7.9_1 and PHP 8.5.12. Actual signed-plugin installation, wrong-key rejection, upgrade and Firmware launcher installation passed. Native Backups setup, persistence, removal/reinstallation, package integrity and sibling-provider failure isolation passed. Inspected installed file inventory and unique package paths. Logs: /tmp/eg-r49-independent.bi8d4arh/native-remaining/, native-broad/, fresh-v1/ and browser/. The bounded readiness check resolved the previously observed lifecycle startup failure.

CRITERION: AC-02 Complete encrypted exports restore through the native OPNsense interface on an isolated appliance, while all newly created provider Git snapshots and staging exclude plaintext configuration and synthetic secrets.
VERDICT: met
EVIDENCE: Independently executed native rotation and full-export recovery. Old and rotated exports passed native decrypt/import, independently retrieved pre-cutover recovery succeeded and encrypted delivery resumed. The fresh-install inspector verified all five remote snapshots, native decryption, ciphertext hashes, encrypted-only trees, synthetic-secret exclusion and Git staging. Snapshot and GitDelivery behavior tests passed. Logs: /tmp/eg-r49-independent.bi8d4arh/native-remaining/, preliminary-restart/, fresh-v1/ and php-quality.log. Inputs were synthetic.

CRITERION: AC-03 Validated configuration and secret custody survive the documented restore/upgrade paths, enforce the selected privilege boundary and permit recovery and credential rotation independently of management services.
VERDICT: not verified
EVIDENCE: Independently passed all three checkpoint-replacement cases, off-guest rollback-pair recovery, concurrent-save replacement rejection, both v1 reversal boundaries, older-provider entry-point holds, absent-ref upgrade, ref fault cases, credential rotation, native restoration and browser privilege checks. Results are indexed in /tmp/eg-r49-independent.bi8d4arh/case-evidence.json. The enabled legacy-entry v1 checkpoint upgrade and complete already-admitted older-provider interruption matrix were not independently executed in this pass. Composite coverage remains incomplete; retained R-48 history does not establish these missing executions.

CRITERION: AC-04 Manual and scheduled runs produce consistent Git state under overlap, rejection, interrupted response, retry and divergent-remote cases, with success reflecting independently verified remote retention.
VERDICT: met
EVIDENCE: PHP 8.5.12 PHPUnit execution passed 26 tests and 105 assertions. Installed delivery-interrupt.sh passed blocked loopback transport, queued second request, identified worker termination, unchanged pending/remote/receipt assertions and exact retry. Native scheduled delivery passed. Independent overlays passed initial response loss, branch deletion, deletion before push, receipt-persistence interruption and exact versus descendant/unrelated read-back. Logs: /tmp/eg-r49-independent.bi8d4arh/php-quality.log, native-remaining/ and the indexed ref cases. My first interruption invocation omitted its required helper argument; that failure remains in native-broad/. The corrected fresh-overlay execution passed.

CRITERION: AC-05 Native scheduling survives regeneration and upgrade, failure of another provider cannot silently suppress the selected scheduling path, and native status plus independent freshness checking expose stale or failed delivery.
VERDICT: not verified
EVIDENCE: Native cron regeneration and a real scheduled delivery passed. A throwing sibling provider preserved encrypted delivery while reporting aggregate failure. Stopped-scheduler and unchanged-source checks verified artifact reuse, stale remote evidence and a synthetic notification sink. Authenticated browser success/failure status checks passed. Logs: /tmp/eg-r49-independent.bi8d4arh/native-broad/ and browser/. The complete authenticated target-A/target-B association scenarios and deployment-owned monitoring/owner-notification delivery were not independently executed in this pass.

CRITERION: AC-06 Migration preserves the verified final legacy history and previous remote ancestor off the firewall, prevents new credentials entering the legacy plaintext capture path and remains recoverable after interruption.
VERDICT: met
EVIDENCE: Fresh overlays passed interrupted preliminary writer shutdown, writer drain, drained/final-archive activation holds, missing/v1 export-evidence rejection, save interruption after validation and concurrent-save serialization. Independently retrieved and read back both encrypted artifacts and verified legacy tip/remote ancestry. Export SHA-256: 9fb6ff6f62b9467e17fd52970d4482a032bb7e99651585146c495ba5217c938e. Archive SHA-256: 7981ff9153ac5846498636ee54ceaa77f0fa938c3278078b75048ec4fec3a3c5. Native recovery preserved rejected pending ancestry and resumed delivery with legacy capture disabled and the new password excluded from legacy history. Logs: /tmp/eg-r49-independent.bi8d4arh/preliminary-restart/, cutover-stages/ and cutover-restart/.

CRITERION: AC-07 A second operator can install, configure, observe and recover the provider from versioned documentation and verified package inputs, with supported versions, diff/storage trade-offs and distribution/contribution limits explicit.
VERDICT: met
EVIDENCE: Independently followed versioned installation, synthetic trust-bootstrap, activation and recovery procedures using exact-source packages and off-guest recovery material. Fresh null-legacy v1 activation delivered successfully. Signed installation/upgrade, Firmware installation, removal/reinstallation, rollback-pair recovery and native restoration passed. Measured three new 53,648-byte encrypted artifacts and repository growth from 216 to 432 KiB. Inspected supported versions, storage/diff guidance and distribution/contribution limits. Logs: /tmp/eg-r49-independent.bi8d4arh/fresh-v1/, native-remaining/, offguest/ and preliminary-restart/.

CRITERION: AC-08 Owned PHP source and tests pass the selected runtime syntax checks, PSR-12 style, declared static-analysis checks and behavior tests, with visible coverage and reviewed narrow exceptions. Required security scans and native audits complete with expected coverage and any findings resolved or given an independently reviewed, owner-approved disposition. The runtime package excludes development tooling and private fixtures.
VERDICT: not met
EVIDENCE: Native pkg audit returned exit 1 for python313-3.13.18 and CVE-2025-15367. VuXML SHA-256: 0b17cc23a3098cf795947b8016ed8b714bd40d632ea59703c45c6e0718d35011. Inventory SHA-256: cc2027945b8e8d8e48bc54207418a24dc1c3c79490e29dc3375469d05d337395. The finding remains unwaived. Native syntax, development-image PSR-12, maximum-level PHPStan, PHPUnit and Psalm taint checks passed. PHPUnit reported one deprecation; Psalm reported eight informational issues. The initial native development-tool failure from missing tokenizer/xmlwriter remains retained. Gitleaks scanned 245 HEAD-history commits without findings. Actionlint, 80 shell syntax checks, seven JavaScript syntax checks and pinned feature lint passed. Full Composer/Semgrep coverage was not re-executed. Runtime inventory excluded development/private inputs. Logs: /tmp/eg-r49-independent.bi8d4arh/audit/, php-quality.log, replacement-retained/ and gitleaks-history.log.

CRITERION: AC-09 The signed repository supports verified native installation and updates on the selected runtime, rejects untrusted catalogues, modified packages and incompatible targets, and preserves recoverable trust and a usable prior generation for established feeds through failed publication and signing-key rotation. An unresolved first activation prohibits further publisher mutations while the pending request may still become live. Bootstrap recovery withdraws the first catalogue and retains its packages for cached clients. A terminal live recovery that fails native validation permits one retry of the same approved files per separately authorized dispatch. Newer releases stay blocked until recovery is verified. Production signing and deployment require owner approval, and fixture execution has access only to owned staging and fixture keys.
VERDICT: not verified
EVIDENCE: The actual dispatch/controller suite passed independently in 154.3 seconds using real pkg, synthetic package content, fresh SSH fixture keys and simulated loopback endpoints. It exercised history approval/successor read-back, durable-write loss, ambiguous/intermediate/terminal outcomes, recovery/Q3 replay, admission and trust-finalization cases. All six local package-contract scripts passed. Separately, actual plugin packages passed signed installation, wrong-key rejection, upgrade and Firmware checks. Inspected retained author RED/GREEN logs and independently verified applicable source equivalence. Logs: /tmp/eg-r49-independent.bi8d4arh/history-green/, native-remaining/ and source-equivalence.json. The release-eligible exact-target branch-push GitVersion-to-manifest-to-signed-client chain and hosted owner-dispatched workflow were not observed. No production signing or deployment occurred.

CRITERION: AC-10 The native settings and status interfaces pass reproducible automated browser journeys for setup, reload persistence, success/failure states and permissions on owned disposable fixtures, with the applicable responsive and accessibility checks and developer tooling excluded from the runtime package.
VERDICT: met
EVIDENCE: Locked Chromium and Firefox passed ten main checks, two dark-theme checks and two rejected-delivery checks on the fresh exact-source appliance. Rejection checks skipped in the main profile passed in their separate profile. Verified setup, persistence, privilege boundaries, retained receipts, keyboard interaction, reduced motion and widths 1280/640/390/320. Both real 200-percent zoom checks passed with viewport 800 to 400 CSS pixels, DPR 1 to 2 and no horizontal overflow. Inspected mobile, dark-theme and both zoom captures. Runtime inventory excluded browser tooling/private fixtures. Evidence: /tmp/eg-r49-independent.bi8d4arh/browser/. All reviewer guest launchers finished; no reviewer QEMU processes remained.

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Acceptance Criteria and Test Plan / AC-08; docs/compatibility.md / Installed 26.7.9_1 runtime audit and CVE-2025-15367 disposition
EVIDENCE: Independently executed pkg audit against the retained full VuXML snapshot on the exact-source installed target. It returned exit 1 for python313-3.13.18 and CVE-2025-15367. Snapshot SHA-256: 0b17cc23a3098cf795947b8016ed8b714bd40d632ea59703c45c6e0718d35011. Inventory SHA-256: cc2027945b8e8d8e48bc54207418a24dc1c3c79490e29dc3375469d05d337395. No independently reviewed owner-approved disposition applies. Evidence: /tmp/eg-r49-independent.bi8d4arh/audit/console.log.
PROPOSAL: Resolve the affected appliance dependency through a supported fix and repeat the audit, or obtain and record an independently reviewed owner-approved disposition before completing AC-08.

FINDING: F-02
KIND: factual
SEVERITY: blocking
WHERE: R-49 review execution / source and Git-ref preservation requirement
EVIDENCE: Starting and final snapshots show unchanged target HEAD, clean worktree status and identical index checksum. Every original ref is unchanged, but refs/codex/turn-diffs/captures/1794699313307/f7d0e540-70d5-428b-b43a-deb19320b18b/base appeared at b037bd46399d171c2eef840605dcf5d930f3d756 during this review. Its creation mechanism was not independently established. The added ref was left untouched because source writes are prohibited. This pass cannot attest that all refs were preserved. Evidence: /tmp/eg-r49-independent.bi8d4arh/refs.before, refs.after and preservation.json.
PROPOSAL: Retain this procedural preservation limitation with R-49. Repeat the review with host-enforced read-only access to both source and Git metadata before asserting full ref preservation.

### R-50 criterion evidence

- AC-01 returned met in R-50.
- AC-02 returned met in R-50.
- AC-03 returned met in R-50.
- AC-04 returned met in R-50.
- AC-05 returned met in R-50.
- AC-06 returned met in R-50.
- AC-07 returned met in R-50.
- AC-08 returned not met in R-50.
- AC-09 returned not verified in R-50.
- AC-10 returned met in R-50.

### R-50

TARGET: bebe5f5b9388eb0e89d62ec668747a8908fc431e

CRITERION: AC-01 The package installs and upgrades on the selected supported releases, exposes its provider in the native Backups screen and preserves core and unrelated provider behavior.
VERDICT: met
EVIDENCE: Reused the independently executed R-49 installation, lifecycle, provider-discovery and sibling-provider checks at 0888a750d3eefde56458f196f7acb8e7e91dde5b after observing source and accepted-baseline equivalence to the frozen target. Fresh exact-target builds, installs and integrity checks also passed in v1, admitted, notification, eligible and audit overlays. The eligible overlay upgraded the actual plugin through the native Firmware launcher. Runtime was OPNsense 26.7.9_1, FreeBSD 15.1-RELEASE-p6 and PHP 8.5.12. Evidence is /tmp/eg-r50-review.38oYgG/source-equivalence.json, case-evidence.json and r49-evidence-inspection.json. The broader R-49 lifecycle suite was reused under the requested focused-review protocol.

CRITERION: AC-02 Complete encrypted exports restore through the native OPNsense interface on an isolated appliance, while all newly created provider Git snapshots and staging exclude plaintext configuration and synthetic secrets.
VERDICT: met
EVIDENCE: Reused R-49 independently executed native rotation, full-export decrypt/import, pre-cutover recovery, encrypted-only snapshot and staging inspection after verifying implementation and test-source equivalence to the frozen target. Inspected the retained successful native-remaining, preliminary-restart and fresh-v1 execution records and PHPUnit output. The five-snapshot inspector and restored delivery passed. Evidence is /tmp/eg-r49-independent.bi8d4arh/native-remaining/, preliminary-restart/, fresh-v1/ and /tmp/eg-r50-review.38oYgG/r49-evidence-inspection.json. These broader restoration checks were reused, with synthetic inputs.

CRITERION: AC-03 Validated configuration and secret custody survive the documented restore/upgrade paths, enforce the selected privilege boundary and permit recovery and credential rotation independently of management services.
VERDICT: met
EVIDENCE: Fresh enabled legacy-entry v1 upgrade from actual 2044d6bd264b4ae1498c8765b579fe0edc6f07b2 to the exact target passed pre-save hold, unchanged pending/remote assertions, rejected legacy-v1 activation, fresh-v2 activation and retained pending ancestry. A separate fresh migration installed actual 05489b66c5aa8ffcc8ce1c2bc3ad5adbd21cfa1f and compared its installed worker, NativeRun and GitDelivery files with that historical tree. Observed its real configd worker in native flock after checkpoint checks. The versioned operator-drain-admitted.sh passed, both old entry points held, pending and remote refs were preserved, independent retained-pair verification passed, and exact-target package reinstall, integrity, resume, ancestry and receipt checks passed. Only rollback.php from bebe5f5 was staged alongside the historical provider for the transition, with SHA-256 40f50d2fc31dd5f1cb697b7c4776f2f43afd422a61a13b0fdfdae57c9705bb03. Reused source-equivalent R-49 privilege, custody, rotation, restore, replacement, reversal and ref-fault executions. Evidence is /tmp/eg-r50-review.38oYgG/eg-r50-v1.dyyyfrpl/, eg-r50-admitted.iiq5bu71/, case-evidence.json and r49-evidence-inspection.json. All appliance inputs were synthetic.

CRITERION: AC-04 Manual and scheduled runs produce consistent Git state under overlap, rejection, interrupted response, retry and divergent-remote cases, with success reflecting independently verified remote retention.
VERDICT: met
EVIDENCE: Reused the independently executed R-49 PHP 8.5.12 PHPUnit result of 26 tests and 105 assertions and installed overlap, blocked-loopback transport, worker termination, retry, lost-response, ref-deletion and divergent-read-back checks after verifying frozen-target source equivalence. Inspected successful native-remaining and individual ref-case console markers and exits. The original native-broad invocation failed after its successful scheduling checks because delivery-interrupt.sh lacked an argument. The corrected native-remaining execution passed and both records remain retained. Evidence is /tmp/eg-r49-independent.bi8d4arh/native-remaining/, ref-loss/, ref-delete/, readback-identity/ and /tmp/eg-r50-review.38oYgG/r49-evidence-inspection.json.

CRITERION: AC-05 Native scheduling survives regeneration and upgrade, failure of another provider cannot silently suppress the selected scheduling path, and native status plus independent freshness checking expose stale or failed delivery.
VERDICT: met
EVIDENCE: Fresh exact-target authenticated A/B monitor execution passed through the real native status endpoint using locked Chromium and recreated synthetic credentials. A and B responses retained the same failed A target identifier and timestamp after the settings switch. Independently retrieved Git receipts produced fresh/failed for A, fresh/unknown for B and unreachable status, and stale/unknown for expired B. Exactly two expected sanitized HTTP deliveries reached the owned loopback recipient. Reused source-equivalent R-49 cron regeneration, actual scheduled delivery, sibling-provider exception, unchanged-source and stopped-scheduler executions, plus the missing-target behavior test. Evidence is /tmp/eg-r50-review.38oYgG/eg-r50-notification.knt8wlwv/a.json, b.json, synthetic-notifications.json and driver.log, and r49-evidence-inspection.json. Notification execution was confined to the synthetic recipient. Real owner notification remains a separately authorized rollout responsibility.

CRITERION: AC-06 Migration preserves the verified final legacy history and previous remote ancestor off the firewall, prevents new credentials entering the legacy plaintext capture path and remains recoverable after interruption.
VERDICT: met
EVIDENCE: Reused the independently executed R-49 complete cutover and recovery matrix after verifying source, tests and accepted-baseline equivalence to the frozen target. Inspected successful preliminary writer-shutdown interruption, drain, drained/final-archive holds, missing/v1 export-evidence rejection, interrupted validation and concurrent-save serialization records. Independent export and archive read-back, rejected-pending preservation, native recovery and resumed encrypted delivery passed. Retained export SHA-256 is 9fb6ff6f62b9467e17fd52970d4482a032bb7e99651585146c495ba5217c938e and archive SHA-256 is 7981ff9153ac5846498636ee54ceaa77f0fa938c3278078b75048ec4fec3a3c5. Evidence is /tmp/eg-r49-independent.bi8d4arh/preliminary-restart/, cutover-stages/, cutover-restart/ and /tmp/eg-r50-review.38oYgG/r49-evidence-inspection.json.

CRITERION: AC-07 A second operator can install, configure, observe and recover the provider from versioned documentation and verified package inputs, with supported versions, diff/storage trade-offs and distribution/contribution limits explicit.
VERDICT: met
EVIDENCE: Reused R-49 independent versioned installation, trust bootstrap, null-legacy v1 activation, off-guest pair recovery and native restoration after verifying frozen-target source and documentation equivalence outside returned review records. Inspected successful retained executions and the measured three 53,648-byte encrypted artifacts with repository growth from 216 to 432 KiB. Fresh R-50 execution also followed the historical-provider transition, independent pair verification and compatible-package resume, and verified actual signed Firmware upgrade. Evidence is /tmp/eg-r49-independent.bi8d4arh/fresh-v1/, offguest/, native-remaining/, /tmp/eg-r50-review.38oYgG/eg-r50-admitted.iiq5bu71/ and eg-r50-eligible.c5dn7kgl/. Supported-version, storage/diff and contribution guidance remains source-equivalent.

CRITERION: AC-08 Owned PHP source and tests pass the selected runtime syntax checks, PSR-12 style, declared static-analysis checks and behavior tests, with visible coverage and reviewed narrow exceptions. Required security scans and native audits complete with expected coverage and any findings resolved or given an independently reviewed, owner-approved disposition. The runtime package excludes development tooling and private fixtures.
VERDICT: not met
EVIDENCE: Fresh exact-target installation followed by native pkg audit against the retained full VuXML snapshot returned exit 1 for python313-3.13.18 and CVE-2025-15367. Advisory snapshot SHA-256 is 0b17cc23a3098cf795947b8016ed8b714bd40d632ea59703c45c6e0718d35011 and inventory SHA-256 is cc2027945b8e8d8e48bc54207418a24dc1c3c79490e29dc3375469d05d337395. The Python finding remains unwaived. Inspected source-equivalent R-49 syntax, PSR-12, maximum-level PHPStan, PHPUnit, Psalm, Gitleaks and runtime-inventory evidence. PHPUnit retained one deprecation and Psalm eight informational issues. Full Composer and Semgrep execution remains unverified in this pass. Evidence is /tmp/eg-r50-review.38oYgG/eg-r50-audit.impjzwbo/console.log and r49-evidence-inspection.json. The audit used an identified retained database snapshot.

CRITERION: AC-09 The signed repository supports verified native installation and updates on the selected runtime, rejects untrusted catalogues, modified packages and incompatible targets, and preserves recoverable trust and a usable prior generation for established feeds through failed publication and signing-key rotation. An unresolved first activation prohibits further publisher mutations while the pending request may still become live. Bootstrap recovery withdraws the first catalogue and retains its packages for cached clients. A terminal live recovery that fails native validation permits one retry of the same approved files per separately authorized dispatch. Newer releases stay blocked until recovery is verified. Production signing and deployment require owner approval, and fixture execution has access only to owned staging and fixture keys.
VERDICT: not verified
EVIDENCE: Checksummed GitVersion.Tool 6.8.0 archive against 8e7ede2369fb8138b40d3831a36bcddfee5836c840f749b9d604788a44c260f9 and byte-compared its configuration with gitversion-tag-action pin 8cf5869816cf71437052ac97d086e00526bf2d89. A private remote-free Git copy with local main at the exact target calculated 0.1.0 and the exact target SHA. Created its immutable synthetic v0.1.0 tag only in scratch and carried HEAD/tag plus version.json into a fresh native overlay. Shared release-identity validation, actual framework build, manifest, signed catalogue, package authentication and actual Firmware upgrade passed. Package SHA-256 is d7b9d252d4082b59d571b28639ec2fb6600cd6d2de3f444e816c9aac182374b1. Reused source-equivalent R-49 native controller execution covering ambiguity, history, recovery, Q3 replay, trust rotation/finalization and package-contract negatives. Independently inspected successful public PR run 43640813055 at 10ee1f1, including workflow_call fixture and native-verifier jobs. Workflow wiring is equivalent, while later controller changes are covered by R-49 local native execution. The prescribed owner-dispatched fixture workflow execution was not observed. feed.yml is absent from the current default branch and its workflow-run lookup returned 404. The owner fixture workflow_dispatch mode and production publish mode are separate. Evidence is /tmp/eg-r50-review.38oYgG/version.json, eg-r50-eligible.c5dn7kgl/, public-current-pr-run.json, source-equivalence.json and /tmp/eg-r49-independent.bi8d4arh/history-green/. The workflow-attempt identity in the eligible harness is synthetic. Production execution remains outside this review.

CRITERION: AC-10 The native settings and status interfaces pass reproducible automated browser journeys for setup, reload persistence, success/failure states and permissions on owned disposable fixtures, with the applicable responsive and accessibility checks and developer tooling excluded from the runtime package.
VERDICT: met
EVIDENCE: Reused independently executed R-49 locked Chromium and Firefox journeys after observing frozen-target source, tests and browser-configuration equivalence. Inspected retained results for ten main checks, two dark-theme checks, two rejection checks and both real 200-percent zoom measurements, alongside permission, persistence, keyboard, reduced-motion and 1280/640/390/320-width coverage. The fresh authenticated monitor journey also passed. Evidence is /tmp/eg-r49-independent.bi8d4arh/browser/ and /tmp/eg-r50-review.38oYgG/r49-evidence-inspection.json. Execution-host findmnt confirmed read-only mounts for source and Git metadata. Final HEAD, index checksum, status and complete refs are byte-identical to the supplied before snapshots in /tmp/eg-r50-review.38oYgG/preservation.json. All five new reviewer-owned guest launchers exited successfully and their QEMU processes exited. R-49 historical ref-preservation limitations remain recorded with R-49.

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Acceptance Criteria and Test Plan / AC-08; docs/compatibility.md / Installed 26.7.9_1 runtime audit and CVE-2025-15367 disposition
EVIDENCE: Fresh independent native pkg audit on the exact-target installed disposable appliance returned exit 1 for python313-3.13.18 and CVE-2025-15367. VuXML SHA-256 is 0b17cc23a3098cf795947b8016ed8b714bd40d632ea59703c45c6e0718d35011. Installed inventory SHA-256 is cc2027945b8e8d8e48bc54207418a24dc1c3c79490e29dc3375469d05d337395. No independently reviewed owner-approved disposition applies. Evidence is /tmp/eg-r50-review.38oYgG/eg-r50-audit.impjzwbo/console.log.
PROPOSAL: Resolve the affected dependency through a supported fix and repeat the audit, or record an independently reviewed owner-approved disposition before completing AC-08.

### R-51 criterion evidence

- AC-01 returned met in R-51.
- AC-02 returned met in R-51.
- AC-03 returned met in R-51.
- AC-04 returned met in R-51.
- AC-05 returned met in R-51.
- AC-06 returned met in R-51.
- AC-07 returned met in R-51.
- AC-08 returned not met in R-51.
- AC-09 returned met in R-51.
- AC-10 returned met in R-51.

### R-51

TARGET: bf75a27f49f29a8e86648d47dc6c06ce66a3a15d

CRITERION: AC-01 The package installs and upgrades on the selected supported releases, exposes its provider in the native Backups screen and preserves core and unrelated provider behavior.
VERDICT: met
EVIDENCE: Independently verified implementation, test, workflow and operator-guide equivalence from R-50 bebe5f5b9388eb0e89d62ec668747a8908fc431e through dispatched 4a92a0df3506d633497e3ae3661cf1894cb54294 to this target. Dispatched and target trees both equal 0cb61d419e0d85bf972863df56dd31120b5a2994. Accepted criteria and normative baseline match R-50. Re-inspected checksum-matching R-50 native build, install, integrity and actual Firmware upgrade evidence on OPNsense 26.7.9_1, plus equivalent R-49 discovery, lifecycle and sibling-provider checks. Reused these executions under the requested focused protocol. Evidence is /tmp/eg-feed-r51-review.6u3JGV/source-equivalence.json and /tmp/eg-r50-review.38oYgG/case-evidence.json.

CRITERION: AC-02 Complete encrypted exports restore through the native OPNsense interface on an isolated appliance, while all newly created provider Git snapshots and staging exclude plaintext configuration and synthetic secrets.
VERDICT: met
EVIDENCE: Re-inspected retained R-49 native decrypt/import, full restore, encryption rotation, five-snapshot inspection and restored-delivery execution evidence referenced by R-50. Recomputed retained log hashes and matched R-50 inspection records. These synthetic-input executions apply through verified implementation and test equivalence. Evidence is /tmp/eg-r49-independent.bi8d4arh/native-remaining/, preliminary-restart/, fresh-v1/ and /tmp/eg-feed-r51-review.6u3JGV/prior-evidence-inspection.json.

CRITERION: AC-03 Validated configuration and secret custody survive the documented restore/upgrade paths, enforce the selected privilege boundary and permit recovery and credential rotation independently of management services.
VERDICT: met
EVIDENCE: Re-inspected checksum-matching R-50 historical-package upgrade and admitted-worker drain logs and inputs. Pre-save holds, legacy-v1 rejection, v2 activation, blocked old entry points, retained pending and remote ancestry, independent pair verification and packaged resume passed. Reused equivalent R-49 privilege, custody, rotation, restore, replacement and ref-fault executions. Evidence is /tmp/eg-r50-review.38oYgG/eg-r50-v1.dyyyfrpl/, eg-r50-admitted.iiq5bu71/ and /tmp/eg-feed-r51-review.6u3JGV/prior-input-check.json. The historical-provider transition used the separately identified current rollback helper recorded in R-50. Inputs were synthetic.

CRITERION: AC-04 Manual and scheduled runs produce consistent Git state under overlap, rejection, interrupted response, retry and divergent-remote cases, with success reflecting independently verified remote retention.
VERDICT: met
EVIDENCE: Re-inspected equivalent R-49 installed overlap, interrupted-worker, rejection/retry, lost-response, deleted-ref and divergent-read-back logs. Retained PHP 8.5.12 PHPUnit execution reported 26 tests and 105 assertions. The initial native-broad harness failure and corrected passing native-remaining run are both retained. Evidence is /tmp/eg-r49-independent.bi8d4arh/native-remaining/, ref-loss/, ref-delete/, readback-identity/ and /tmp/eg-feed-r51-review.6u3JGV/prior-evidence-inspection.json.

CRITERION: AC-05 Native scheduling survives regeneration and upgrade, failure of another provider cannot silently suppress the selected scheduling path, and native status plus independent freshness checking expose stale or failed delivery.
VERDICT: met
EVIDENCE: Re-inspected R-50 authenticated A/B monitor logs, status responses and two synthetic loopback notification deliveries, plus equivalent R-49 native cron regeneration, scheduled delivery, sibling exception, unchanged-source and stopped-scheduler evidence. Attempt identity persists after switching targets. Independent receipts expose fresh/failed, fresh/unknown and stale/unknown outcomes. Evidence is /tmp/eg-r50-review.38oYgG/eg-r50-notification.knt8wlwv/ and /tmp/eg-r49-independent.bi8d4arh/native-broad/. Real owner notification belongs to separately authorized rollout.

CRITERION: AC-06 Migration preserves the verified final legacy history and previous remote ancestor off the firewall, prevents new credentials entering the legacy plaintext capture path and remains recoverable after interruption.
VERDICT: met
EVIDENCE: Re-inspected checksum-matching R-49 writer-shutdown interruption, drain, stage holds, missing/v1 export-evidence rejection, interrupted validation, concurrent-save serialization, independent archive/export read-back and recovered-delivery logs. Implementation, tests and accepted baseline are equivalent through this target. Evidence is /tmp/eg-r49-independent.bi8d4arh/preliminary-restart/, cutover-stages/, cutover-restart/ and /tmp/eg-feed-r51-review.6u3JGV/prior-evidence-inspection.json. Retained executions used synthetic appliance inputs.

CRITERION: AC-07 A second operator can install, configure, observe and recover the provider from versioned documentation and verified package inputs, with supported versions, diff/storage trade-offs and distribution/contribution limits explicit.
VERDICT: met
EVIDENCE: Verified operator-guide equivalence and re-inspected retained second-operator installation, trust bootstrap, fresh activation, off-guest pair recovery, native restoration and R-50 packaged-resume evidence. Actual signed Firmware upgrade passed in R-50. Retained measurement covers three 53,648-byte artifacts and repository growth from 216 to 432 KiB. Evidence is /tmp/eg-r49-independent.bi8d4arh/fresh-v1/, offguest/, native-remaining/ and /tmp/eg-r50-review.38oYgG/eg-r50-eligible.c5dn7kgl/.

CRITERION: AC-08 Owned PHP source and tests pass the selected runtime syntax checks, PSR-12 style, declared static-analysis checks and behavior tests, with visible coverage and reviewed narrow exceptions. Required security scans and native audits complete with expected coverage and any findings resolved or given an independently reviewed, owner-approved disposition. The runtime package excludes development tooling and private fixtures.
VERDICT: not met
EVIDENCE: Re-inspected checksum-matching R-50 native audit execution and inputs. pkg audit returned exit 1 for python313-3.13.18 and CVE-2025-15367. VuXML SHA-256 is 0b17cc23a3098cf795947b8016ed8b714bd40d632ea59703c45c6e0718d35011 and inventory SHA-256 is cc2027945b8e8d8e48bc54207418a24dc1c3c79490e29dc3375469d05d337395. No accepted disposition applies. Re-inspected equivalent syntax, PSR-12, maximum-level PHPStan, PHPUnit, Psalm, Gitleaks and runtime-package boundary evidence. PHPUnit retains one deprecation and Psalm eight informational issues. Full Composer and Semgrep execution remains unverified in this pass. Current pinned feature lint passes. Evidence is /tmp/eg-r50-review.38oYgG/eg-r50-audit.impjzwbo/console.log and /tmp/eg-feed-r51-review.6u3JGV/prior-evidence-inspection.json.

CRITERION: AC-09 The signed repository supports verified native installation and updates on the selected runtime, rejects untrusted catalogues, modified packages and incompatible targets, and preserves recoverable trust and a usable prior generation for established feeds through failed publication and signing-key rotation. An unresolved first activation prohibits further publisher mutations while the pending request may still become live. Bootstrap recovery withdraws the first catalogue and retains its packages for cached clients. A terminal live recovery that fails native validation permits one retry of the same approved files per separately authorized dispatch. Newer releases stay blocked until recovery is verified. Production signing and deployment require owner approval, and fixture execution has access only to owned staging and fixture keys.
VERDICT: met
EVIDENCE: Independently retrieved live GitHub metadata, jobs, artifact inventory and raw logs for run 43677265727, attempt 1. Actor and triggering actor are michielvha, event is workflow_dispatch, branch is feat/native-encrypted-git-backup and head is 4a92a0df3506d633497e3ae3661cf1894cb54294. Fixture and native-verifier succeeded. Verify-release and publish were skipped. Artifact count is zero. GitHub commit tree and workflow bytes match local source and this tree-preserving merge target. Inspected executed fixture source, disposable RSA signers, loopback-only APIs and SSH forwarding, pinned pkg 2.8.4_1,1, native catalogue authentication/fetch, incompatible ABI and modified-package rejection, recovery, cached-client retrieval, trust rotation/retirement and retry/replay assertions. Native TAP reports one passed, zero failed and zero skipped in 75.9 seconds. Hosted packages are synthetic. Separately re-inspected checksum-matching R-50 actual plugin GitVersion-to-manifest-to-signed-catalogue Firmware upgrade proof, including package SHA-256 d7b9d252d4082b59d571b28639ec2fb6600cd6d2de3f444e816c9aac182374b1, and equivalent R-49 controller and package-contract evidence. This combines the newly observed owner dispatch with retained actual-plugin native proof under the authorized equivalence protocol. Production execution was outside this fixture review. Evidence is https://github.com/vhco-pro/opnsense-encrypted-git-backup/actions/runs/43677265727, /tmp/eg-feed-r51-review.6u3JGV/live-logs.zip, live-source-check.json, source-equivalence.json and /tmp/eg-r50-review.38oYgG/eg-r50-eligible.c5dn7kgl/.

CRITERION: AC-10 The native settings and status interfaces pass reproducible automated browser journeys for setup, reload persistence, success/failure states and permissions on owned disposable fixtures, with the applicable responsive and accessibility checks and developer tooling excluded from the runtime package.
VERDICT: met
EVIDENCE: Re-inspected checksum-matching R-49 Chromium and Firefox evidence for ten main checks, two dark-theme checks, two rejected-delivery checks and both real 200-percent zoom measurements, plus the R-50 authenticated monitor journey. Source, tests, browser configuration and runtime-package boundaries are equivalent. Evidence is /tmp/eg-r49-independent.bi8d4arh/browser/ and /tmp/eg-feed-r51-review.6u3JGV/prior-evidence-inspection.json. This pass reused retained browser executions. findmnt confirmed read-only source and Git metadata. Final HEAD, index, status and complete refs match every supplied before snapshot in /tmp/eg-feed-r51-review.6u3JGV/preservation.json.

FINDING: F-01
KIND: factual
SEVERITY: blocking
WHERE: Acceptance Criteria and Test Plan / AC-08, docs/compatibility.md / Installed 26.7.9_1 runtime audit and CVE-2025-15367 disposition
EVIDENCE: Retained independent R-50 native pkg audit on the installed source-equivalent appliance returned exit 1 for python313-3.13.18 and CVE-2025-15367. Recomputed retained console and advisory-input hashes in this pass. VuXML SHA-256 is 0b17cc23a3098cf795947b8016ed8b714bd40d632ea59703c45c6e0718d35011. Inventory SHA-256 is cc2027945b8e8d8e48bc54207418a24dc1c3c79490e29dc3375469d05d337395. The proposed disposition received should-fix findings and has no recorded owner acceptance. Evidence is /tmp/eg-r50-review.38oYgG/eg-r50-audit.impjzwbo/console.log and /tmp/eg-r50-review.38oYgG/disposition-return.txt.
PROPOSAL: Resolve the affected dependency through a supported fix and repeat the identified native audit, or obtain and record an independently reviewed owner-approved disposition before completing AC-08.

### R-52

TARGET: 6bbbb910c6892f0dade9dd302dafe7994ba4284e

FINDING: F-01
KIND: factual
SEVERITY: nit
WHERE: Context / Owner summary, docs/specs/native-encrypted-git-backup.md:65-66.
EVIDENCE: The summary says the release workflow and native feed promotion and rollback tests remain open and the revised specification needs renewed acceptance. AC-09 and R-51 record completed fixture verification; independently fetched jobs for run 43677265727 confirm fixture and native-verifier succeeded and both production jobs were skipped. The normative baseline matches accepted R-44 exactly. Pinned vh-adlc fresh reports only covered-drift, and gate in-progress fails only spec_review_fresh, with acceptance retained under the pinned convention. These summary statements predate the registration change and conflict with the current recorded state.
PROPOSAL: Refresh the summary to distinguish completed fixture verification from separately authorized production validation and publication. State that R-44 acceptance remains valid while this covered-drift refresh is recorded, preserving the open AC-08 audit finding and all production authorization boundaries.

### R-53

TARGET: 6d00f2f78a8006173c4855cf9eeea693a702ec1e

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Design / Activation reconciliation and retry eligibility, line 291 ("after a complete journal read shows no submission record"); Test Plan / AC-09, line 320 ("verify a later authorized dispatch reads the complete journal and resumes from the retained approved assets"); Tasks / T14, line 346
EVIDENCE: This revision makes repeating staging depend on a complete journal read. No other part of the baseline defines what counts as complete or says that an incomplete or bounded read must hold. The only proof sentence is in the owner-selected replacement block, and it checks the positive path only. Fixture journals are small, so a reader that takes only the first page as the whole journal would pass that sentence. It would then restage, and could submit, past an unseen submission record. The committed loopback test does cover this case: it sets a truncated journal, expects rejection at the "complete-read bound", and requires zero journal writes and zero creates (supplied revision diff, tests/package/feed-publisher-http.mjs, around lines 886 to 890). The Test Plan row does not require that check, so the proof could pass on a wrong implementation. This traces to the replacement Test Plan block added in this revision.
PROPOSAL: Add an AC-09 proof step in which an incomplete or bounded journal read causes a hold with zero staging repeats and zero Pages creates. Because the owner selected the replacement text verbatim, confirm the added sentence with the owner before acceptance.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: Design / Activation reconciliation and retry eligibility, line 291 ("Persist and independently verify a submission-started record before making any Pages create request"); Design / Activation reconciliation rule 2, line 285; Test Plan / AC-09, line 320 (the "Terminate a runner immediately after recording submission-started" step and the Q3 durable write boundary steps); Tasks / T14, line 346
EVIDENCE: This revision adds a requirement to independently verify the record before any create, for both candidate and recovery submissions. No AC-09 proof step makes that verification fail or return a mismatch and then requires zero creates followed by the reconciliation hold. The existing steps stop the runner after the record is written, or check the Q3 pair from the test's side. An implementation that trusts the write response and skips its own read-back passes all of them. The supplied diff adds a read-back for candidates and recoveries (append_verified_submission in scripts/publish-feed.sh, used by the recovery-started path in scripts/feed-recovery.sh). The loopback test exercises only a candidate read-back that returns 404 and then holds with no create. The recovery read-back path has no test in the diff. The supplied green log covers that single publisher test, and the red log shows the 404 expectation failing before the fix.
PROPOSAL: Add an AC-09 proof step that makes the independent read-back fail or return a mismatched record, for both a candidate submission and a recovery submission. Require zero Pages creates and require a later dispatch to hold under Pages reconciliation. Leave T14 open until both paths have been run.

FINDING: F-03
KIND: judgement
SEVERITY: should-fix
WHERE: Frontmatter `branch`, line 3; Tasks / T14, line 346; Review Log
EVIDENCE: This revision changes `branch` from feat/native-encrypted-git-backup to docs/merged-implementation-status. The pinned convention says a document "keeps it until the feature is closed". It also says a revision moves the document to draft "on its feature branch when it has one" and that implementation re-enters through that branch after acceptance. The binary's on_feature_branch_if_set gate reads this field, so the change makes the gate pass on the docs branch. The same target commit also changes the covered scripts/publish-feed.sh and scripts/feed-recovery.sh while the document is still draft. The follow-up says the design choice "authorizes revision and review". Repository AGENTS.md keeps implementation under separate design, review and owner approvals. The only local branch ref is the docs branch.
PROPOSAL: Raise an Open Question asking the owner which branch the revised feature re-enters through. Also ask whether the pre-acceptance script changes stay as draft work for T14 or wait until renewed acceptance.

FINDING: F-04
KIND: judgement
SEVERITY: nit
WHERE: Context / Owner summary, line 65
EVIDENCE: The summary says the owner selected "Use simpler single-record contract (Recommended)" for F-07. The document never says what F-07 refers to and does not link docs/reviews/opus-5-5-follow-up.md. The document's own Review Log has an unrelated F-07 under R-8 (line 578). The convention asks the summary to explain material changes since the last accepted scope. This summary does not say that the durable prepared state and its discard after runner termination were removed. It also does not say that staging may now repeat after a complete journal read finds no submission record. It does state the accepted risk correctly: a crash after the record may need manual investigation even when no create was sent. That agrees with line 291.
PROPOSAL: Link the follow-up review and add one sentence saying that the prepared state was removed and that staging may repeat from retained approved assets only after a complete journal read finds no submission record.
### R-54

TARGET: 1ffa659919eea42a6de0b7ad89543f29586c805f

FINDING: F-01
KIND: factual
SEVERITY: should-fix
WHERE: Test Plan / AC-09, line 320 ("For candidate and recovery submissions, fail the independent read-back after the submission record commits. Verify zero Pages create requests and require a later authorized dispatch to hold under Pages reconciliation if there is no correlated create."); Design / Activation reconciliation and retry eligibility, line 291 ("Persist and independently verify a submission-started record before making any Pages create request"); Design / rule 2, line 285 (submission-started pairing for Q3); Tasks / T14, line 346
EVIDENCE: The Design requires an independent verification of the record. That means the read-back content has to match what was written, not just that a read succeeds. The proof step this revision added only says to "fail" the read-back. The committed fixture fails it in one way only: the record read returns HTTP 404 (tests/package/feed-publisher-http.mjs:72-80). It then asserts the hold for a candidate (lines 908-923) and a recovery (lines 790-798). The publisher does compare id, sha, environment and payload (scripts/publish-feed.sh:26-30). But an implementation that issues the GET and checks only the HTTP status, ignoring the record body, would pass both the row text and the fixture. The row does not require a read-back that succeeds but returns a different or partial record. R-53 F-02 proposed "fail or return a mismatched record". This revision applied the failure half only. The gap traces to that change.
PROPOSAL: Extend the AC-09 step so that, for both candidate and recovery submissions, the independent read-back returns a well-formed but mismatched record. Require zero Pages creates in that case and a later authorized dispatch that holds under Pages reconciliation. Keep T14 open until that case has also been run.

FINDING: F-02
KIND: factual
SEVERITY: nit
WHERE: Context / Owner summary, lines 65-66
EVIDENCE: The convention asks the summary to explain material changes since the last accepted scope and to separate planned checks from observed proof. The summary covers removal of the prepared state, repeated staging after a complete journal read, and the accepted risk after a crash. It does not mention the new requirement to independently verify the record before any create (line 291). It does not say that a failed read-back also leaves the hold with no create sent, not only a crash. It also does not say that an incomplete or truncated journal read holds without restaging (line 320). On validation state, it says live criterion evidence was removed. It does not say that the revision's proof so far is an executed loopback publisher test, with T14 and the native and recovery verification still open. Nothing in the summary claims a native rerun, and the R-51 and native fixture statements read as history.
PROPOSAL: Add one or two sentences saying that the record is read back independently before any create. Say that a failed read-back or an incomplete journal read holds without a create or restage, and that the revision's verification is still open under T14.

FINDING: F-03
KIND: factual
SEVERITY: nit
WHERE: Frontmatter `branch`, line 3; Open Questions, line 350; Context / Owner summary, lines 64-66; Review Log R-53 F-03, lines 2103-2108
EVIDENCE: R-53 F-03 was a judgement finding. It asked which branch the revised feature re-enters through, and whether the source changes made before acceptance stay as T14 draft work. Open Questions says "None.", so the question was either never raised or was answered and removed. The convention says an answered question is "folded into the document". Nothing in the document records the answer: not the continuation on the existing follow-up PR, not the removal of the original feature branch after merge, and not the owner's permission for the already approved source repair to continue before renewed acceptance. Only the frontmatter value changed. The follow-up review still says only that "The design choice authorizes revision and review" (docs/reviews/opus-5-5-follow-up.md:59), while commits on this branch change the covered scripts/publish-feed.sh, scripts/feed-recovery.sh and tests/package/feed-publisher-http.mjs. The binary was not run in this pass, so the gate effect was not observed.
PROPOSAL: Record the owner's answer to R-53 F-03 in the Owner summary or the follow-up review. Name the branch implementation re-enters through and the limits on source repair before acceptance, with no merge or production authority, so the frontmatter change and the draft source commits can be traced to that decision.

### R-55

TARGET: c21c21bc36bd57e6ebed2495745a1c07ac0ab67d

FINDING: F-01
KIND: factual
SEVERITY: nit
WHERE: Context / Owner summary, docs/specs/native-encrypted-git-backup.md:65 ("The candidate loopback checks have run, and T14 remains open for native recovery verification."); Tasks / T14, line 346; docs/reviews/opus-5-5-follow-up.md:77-81 (Exact repair verification)
EVIDENCE: The convention says Context cites its claims with a file:line or a command and its output, and that the summary separates planned checks from observed proof. This sentence claims observed proof but cites no command, run or target commit. The only loopback run recorded in the follow-up is at repair source 89414487, which predates the F-07 revision, and the follow-up says that run "describes current behavior" and is "not conformance to the accepted AC-09 sequence". The supplied passing loopback logs show one passing test ("publisher holds ambiguous responses and reconciles one live deployment") but no commit or command header. The claim itself is consistent with the test file. The truncated journal hold (tests/package/feed-publisher-http.mjs:903-909) and the candidate missing and mismatched read-back cases (lines 910-928) run in every mode. The recovery missing and mismatched read-back cases (lines 786-800) run only inside the native branch, so they stay open under T14. The summary claims no native rerun, and the R-51 statements read as history. This is a citation gap and changes nothing an implementer builds.
PROPOSAL: Cite the command and the target commit of the candidate loopback run in the summary or the follow-up. Alternatively, describe the run as observed outside the document until it is recorded with that identity.

FINDING: F-02
KIND: factual
SEVERITY: nit
WHERE: docs/reviews/opus-5-5-follow-up.md:46-57 ("The draft applies these exact normative edits", items 1 and 2); Test Plan / AC-09, line 320 (the sentences "For an incomplete or truncated journal read, verify a hold with zero repeated staging and zero Pages create requests." and "For candidate and recovery submissions, test both a failed independent read-back and a successful read that returns a mismatched record after the submission record commits. Verify zero Pages create requests and require a later authorized dispatch to hold under Pages reconciliation if there is no correlated create."); Context / Owner summary, line 65; Review Log R-53 F-01, line 2095
EVIDENCE: Both owner-selected blocks appear verbatim in the baseline: the Design block at line 291 and the Test Plan replacement at line 320. No normative remnant of the prepared state or of discard after runner termination remains. The baseline also carries two more AC-09 proof sentences that came from R-53 F-01, R-53 F-02 and R-54 F-01, not from the owner's selection. The follow-up lists only the two selected edits as what "the draft applies" and does not mention the added proof sentences. R-53 F-01 asked that the added sentence be confirmed with the owner before acceptance. The added sentences are consistent with the selected Design text, because "complete journal read" and "independently verify" imply both checks, and they waive nothing. The renewed acceptance still covers the whole baseline. This is a traceability slip outside the baseline and changes no proof.
PROPOSAL: In the follow-up or the acceptance request, say that the revised baseline adds the R-53 and R-54 proof sentences on top of the two owner-selected blocks, so the renewed acceptance names them explicitly.

I ran no tests or binary commands because this session has no shell. I read the source and the supplied logs with file tools only, and nothing in the repository was changed.
