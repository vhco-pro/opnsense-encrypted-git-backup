# Claude Code review of the merged plugin

Claude Code 2.1.325 served `claude-opus-5-5` in both independent sessions. Assistant stream metadata and the final model usage agreed on the model. The final usage identifies the provider as `firstParty`. Both sessions targeted merge commit `d70e8af4595f6be7d2f84f18598d41898bdfc0b5`. Its tree matches the tree of the approved PR head `19e1dd3cb580899b671dfccbc3431dec9be1fd69`. The source and Git metadata were mounted read-only, with matching HEAD, index, refs and status before and after review.

The first session inspected source statically. It could not read the reviewer guidance or fixture evidence and executed no tests. The second session had read access to the pinned guidance and the retained manual feed fixture evidence. It did not rerun the native matrix. The second session's unverified verdicts describe that review's coverage. Earlier independent execution records remain in the [feature specification](../specs/native-encrypted-git-backup.md#review-log).

The signed feed is the package catalogue and package store that OPNsense Firmware and pkg will use for installation and upgrades. The reviews cover its implementation and fixture evidence. First release and production publication await separate approval.

## Static pass

````text
MODEL: claude-opus-5-5
TARGET: d70e8af4595f6be7d2f84f18598d41898bdfc0b5

I found no blocking issues. There are 2 should-fix findings and 9 nits. This was a static reading of the code only, so it is not a release approval and I gave no criterion verdicts. I could not read the reviewer definition, the review protocol or the evidence directory.

## What was inspected and what was executed

**Read (static only):**
- `.git/HEAD` is `d70e8af…`, matching the target. I could not read the pack objects, so I did not check the tree contents against the commit object.
- Runtime: the provider `Backup/EncryptedGit.php`; the library files `GitDelivery`, `NativeRun`, `Process`, `Settings`, `Credentials`, `Snapshot`, `Activation`, `Freshness`; the scripts `run`, `check`, `status`, `rollback`; the configd actions file; the status controller and view; the ACL and model.
- Workflows: `feed.yml`, `php.yml`, `native-browser.yml`.
- Feed scripts: `publish-feed`, `feed-dispatch`, `feed-preflight`, `feed-publication-mode`, `feed-bundles`, `feed-payload`, `feed-recovery`, `feed-retirement`, `feed-close`, `feed-release-identity`, `feed-pages-assets.mjs`, `feed-manifest`, `package-version`, `retain-feed-bundles`, `verify-feed-generation`, `feed-verify-native`, `prepare-feed-verifier`.
- Docs: the spec Context, Design, AC and Test Plan sections, plus the R-51 and R-52 records; `docs/compatibility.md`; `docs/recovery.md` §55–78; `docs/security/cve-2025-15367.md`. I also listed the test names in `GitDeliveryTest`.

**Could not use (permission denied in this session):**
- The canonical reviewer definition and the review protocol.
- Everything under the evidence directory. No fixture logs or metadata were inspected.

**Executed: nothing.** I ran no tests, no linters, not the vh-adlc binary, and did not look at the plugin pin. Behaviour I treat as working (overlap, lost response, rollback drain, the feed fixture) rests only on the R-49, R-50 and R-51 records written in the spec. I did not check those against their evidence.

**Criteria:** without the pinned procedure I did not produce AC records. I ticked and waived nothing. AC-08 stays as recorded: unmet, with the owner-accepted Python residual, which covers repository integration and the identified disposable fixture only. Nothing in the runtime I read contradicts that disposition's trace: no POP3 path; Git, SSH and OpenSSL calls go through fixed argument arrays.

## Findings

FINDING: F-01
KIND: judgement
SEVERITY: should-fix
WHERE: `src/opnsense/mvc/app/library/OPNsense/Backup/EncryptedGit.php:150-171`; `GitDelivery.php:376-391`
EVIDENCE: `runConfigured()` holds the native config lock (`Config::lock()`) for the whole delivery, network operations included. Each Git call can take up to 30 s. A delivery that pushes held pending work and then a new snapshot makes up to 8 network Git calls (start fetch 2, push+read-back 3, push+read-back 3). During that time every native configuration save on the appliance waits. This lock is what keeps rollback "hold" and settings saves out of an admitted delivery (`rollback.php:110-111`; compatibility.md "queued-delivery"), so it is deliberate. The cost is that config writes across the whole appliance stall for as long as the remote is slow.
PROPOSAL: Take the config lock only to read the settings, checkpoint and XML. Acquire `delivery.lock` while still holding it, then release the config lock before any network call. Make `setConfiguration()`/`check` and rollback `replace` also take `delivery.lock`, so that settings and checkpoint changes still exclude delivery. Alternatively, keep the current design but bound the total delivery time well below the web request limits and document the stall.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: `EncryptedGit.php:141`; `GitDelivery.php:388`; `Activation.php:53-58`
EVIDENCE: `backup()` waits 240 s for the configd action. The worst case of 8 network calls × 30 s is already 240 s, before the local Git calls, the 5 s legacy `rev-parse` and encryption. When that happens the scheduler or GUI reports failure while `run.php` carries on, still holding the config lock (F-01), and may later write `verified`. The result is safe (a false failure, never a false success), but the status shown to the operator and the actual outcome disagree.
PROPOSAL: Add an overall deadline inside `GitDelivery`, smaller than the caller's timeout, and record a `delivery` failure when it is hit. Or set the configd wait from the computed worst case. Add a test covering a slow remote.

FINDING: F-03
KIND: factual
SEVERITY: nit
WHERE: `GitDelivery.php:257-264`
EVIDENCE: `git ls-remote` matches its patterns against the end of ref names, at a slash boundary. A remote ref whose name ends in `/refs/heads/<branch>` therefore also matches. With such a ref present, a missing branch is reported as "Could not read the remote backup branch" instead of `null`, and an existing branch makes `objectId()` reject the joined output. Both cases fail safe, but the failure is misclassified and blocks delivery. No test covers this (the tests are listed at `GitDeliveryTest.php:14-293`). Confidence is medium: this comes from reading Git's matching rules and has not been run.
PROPOSAL: Split the output into lines and accept exactly one line whose ref name equals `$ref`. Treat "no exact match" as absent only if no other lines exist; otherwise fail with a distinct category. Add a unit test with such a ref.

FINDING: F-04
KIND: judgement
SEVERITY: nit
WHERE: `scripts/feed-pages-assets.mjs:31-40,45-53`
EVIDENCE: The Pages asset keys come from the manifest and are never recomputed from file content, in `--validate` mode or before upload. The approved bundle digest covers both the manifest and the files. A key that does not match its content (a preparation bug) would only be caught after activation, by the check of served SHA-256 values, which sends the run into the recovery path.
PROPOSAL: Recompute each key from the file in `--validate` and before upload, and reject mismatches before `submission-started`.

FINDING: F-05
KIND: judgement
SEVERITY: nit
WHERE: `scripts/feed-publication-mode.sh:25-26`; used in `publish-feed.sh:16`, `feed-close.sh:23`
EVIDENCE: The journal and Pages bearer tokens are passed to `curl` as `-H` arguments. Any other process on the runner can read them from the process table while curl runs. The exposure is small on a single-tenant hosted runner, and the Node asset uploader already reads its token from the environment.
PROPOSAL: Pass the headers from a 0600 temporary file (`-H @file`) or with `--config -` on stdin.

FINDING: F-06
KIND: factual
SEVERITY: nit
WHERE: `scripts/publish-feed.sh:47-52,150-156`; `docs/recovery.md:73`
EVIDENCE: Publishing stops for good once there are 100 journal records or 100 production Pages deployments. The guide says a "supported migration to a complete retained journal is required" before that point, but no such migration exists at TARGET. Each publication adds at least two records, so the hard limit is a few dozen releases. It fails safe.
PROPOSAL: Before production is enabled, implement and test the migration (or paginated reads with a completeness check), and warn when headroom gets low.

FINDING: F-07
KIND: factual
SEVERITY: nit
WHERE: `docs/specs/native-encrypted-git-backup.md:291`; `scripts/publish-feed.sh:376-392`
EVIDENCE: The spec says to write a `prepared` state and then `submission-started`. The publisher writes only `submission-started`. This is stricter in effect (an interrupted run holds rather than being discarded), but the spec text and the code disagree.
PROPOSAL: Align the spec text with the code, or add the prepared state.

FINDING: F-08
KIND: judgement
SEVERITY: nit
WHERE: `GitDelivery.php:100,121-125`
EVIDENCE: `attempt.json` records `running` before the work starts. If the worker is killed or loses power, `running` stays until the next run, and `Freshness::attemptOutcome` reports it as running. Remote freshness still flags the backup as stale, so this does not hide a stopped backup.
PROPOSAL: Have the monitor treat a `running` attempt older than a set bound as unknown or failed, or document this behaviour.

FINDING: F-09
KIND: factual
SEVERITY: nit
WHERE: `src/opnsense/scripts/encryptedgit/rollback.php:234` vs `Activation.php:36`
EVIDENCE: The two files test whether the legacy repository exists in different ways: `is_dir` in rollback, `file_exists || is_link` in Activation. If something other than a directory sits at that path, `resume` and delivery disagree. Delivery fails safe.
PROPOSAL: Use one shared check.

FINDING: F-10
KIND: factual
SEVERITY: nit
WHERE: `docs/specs/native-encrypted-git-backup.md:26`; `docs/security/cve-2025-15367.md:1,3`; `.github/workflows/php.yml:39`
EVIDENCE: Three small documentation and config inconsistencies:
- The spec's `covers:` list names `renovate.json`, which does not exist at TARGET.
- The disposition is titled "Proposed disposition" and says "This proposal grants…", although line 3 records it as accepted.
- `php.yml:39` has a comment about scanning full HEAD history that sits on no input.
PROPOSAL: Remove the stale `covers:` entry, retitle the disposition as accepted while keeping its scope limits, and either remove the comment or restore the explicit history-scan input.

FINDING: F-11
KIND: judgement
SEVERITY: nit
WHERE: `scripts/publish-feed.sh:322,336`
EVIDENCE: `scripts` is assigned a second time for no reason. On line 336 the jq filter and its file argument are separated by a long run of spaces, which looks like a joined line. It is valid Bash but harder to read in a safety-critical script.
PROPOSAL: Remove the duplicate assignment and put the argument on its own line.

## Checked with no issue found (static reading)

- Git and OpenSSH run through argument arrays, with stderr discarded, hooks disabled, SSH as the only allowed protocol and strict host-key checking.
- The credential reference, branch and destination validators are sound.
- The password stays out of command arguments. According to `compatibility.md` the native Base uses temporary files; I did not check this in core here. A 0077 umask applies around capture and encryption.
- Pushes use an expected-old-ref lease, are read back independently, and the code holds when a branch is absent, creation is unresolved or history has diverged.
- The status view only inserts text (`.text()`), so it is XSS-safe.
- Workflow inputs reach scripts through the environment, never by direct `${{ }}` interpolation into run steps.
- Actions are pinned to commit SHAs, and checkouts don't persist credentials.
- Bundle extraction rejects links, path traversal, duplicate entries and oversized archives.
- Release identity is tied to the workflow run, attempt, source SHA and tag.
````

## Evidence access follow-up

````text
MODEL: claude-opus-5-5
TARGET: d70e8af4595f6be7d2f84f18598d41898bdfc0b5

CRITERION: AC-01 The package installs and upgrades on the selected supported releases, exposes its provider in the native Backups screen and preserves core and unrelated provider behavior.
VERDICT: not verified
EVIDENCE: Read-only inspection, d70e8af4595f6be7d2f84f18598d41898bdfc0b5. The provider class implements IBackupProvider with the native field contract at src/opnsense/mvc/app/library/OPNsense/Backup/EncryptedGit.php:15-41. The configd actions are in src/opnsense/service/conf/actions.d/actions_encryptedgit.conf:1-20. The retained public metadata for Native browser run 43694114786 at PR head 19e1dd3cb580899b671dfccbc3431dec9be1fd69 shows a successful step named "Install exact plugin package and exercise native Backups". Only step conclusions were available, not logs. Limitations: this pass had read and search tools only. It ran no shell, binary, test, package build or native fixture, and by instruction it repeated no native matrix. The R-49 and R-50 install, upgrade and sibling-provider executions that R-51 reused were not available to this pass, so they were not observed here.

CRITERION: AC-02 Complete encrypted exports restore through the native OPNsense interface on an isolated appliance, while all newly created provider Git snapshots and staging exclude plaintext configuration and synthetic secrets.
VERDICT: not verified
EVIDENCE: Read-only inspection, d70e8af4595f6be7d2f84f18598d41898bdfc0b5. GitDelivery stages only config.xml.enc and snapshot.json and rejects any other staged path (GitDelivery.php:208-214). Capture runs under a 0077 umask (GitDelivery.php:63). Encryption goes through the native Local crypter with a round-trip Snapshot (NativeRun.php:55-59). Limitations: no native decrypt/import or staged-object inspection was executed or observed in this pass. The R-49 restore evidence that R-51 reused was not available here.

CRITERION: AC-03 Validated configuration and secret custody survive the documented restore/upgrade paths, enforce the selected privilege boundary and permit recovery and credential rotation independently of management services.
VERDICT: not verified
EVIDENCE: Read-only inspection, d70e8af4595f6be7d2f84f18598d41898bdfc0b5. A read-only user is rejected in setConfiguration (EncryptedGit.php:50-53). Credential references are validated, and the password is read from a protected file and kept out of command arguments (NativeRun.php:33-40). Activation binds destination, branch and checkpoint (Activation.php:15-63). Rollback takes the delivery lock and the config lock (rollback.php:79-81,111,170). Limitations: no upgrade, restore, rotation or rollback execution was observed. The R-50 historical-package and admitted-worker logs were not available to this pass.

CRITERION: AC-04 Manual and scheduled runs produce consistent Git state under overlap, rejection, interrupted response, retry and divergent-remote cases, with success reflecting independently verified remote retention.
VERDICT: not verified
EVIDENCE: Read-only inspection, d70e8af4595f6be7d2f84f18598d41898bdfc0b5. A non-blocking delivery lock is used (GitDelivery.php:65-72). Pushes use an expected-old-ref lease and are read back through ls-remote and fetch before success is recorded (GitDelivery.php:272-320). Divergence and absent-branch holds are at GitDelivery.php:151-180. creation.json and initial-rejected track creation outcomes (GitDelivery.php:282-313). Limitations: PHPUnit and the installed overlap and lost-response fixtures were not executed or observed in this pass. The retained public CI metadata for run 43694115250 shows only that the php job step succeeded.

CRITERION: AC-05 Native scheduling survives regeneration and upgrade, failure of another provider cannot silently suppress the selected scheduling path, and native status plus independent freshness checking expose stale or failed delivery.
VERDICT: not verified
EVIDENCE: Read-only inspection, d70e8af4595f6be7d2f84f18598d41898bdfc0b5. backup() throws an ordinary RuntimeException when delivery fails (EncryptedGit.php:136-148). Each attempt records a destination and branch target digest (GitDelivery.php:44-51). Freshness handles the running, failed and verified outcomes (Freshness.php:19). Limitations: no cron regeneration, scheduled run, sibling exception or monitor execution was observed. The R-49 and R-50 scheduling and A/B monitor evidence was not available to this pass.

CRITERION: AC-06 Migration preserves the verified final legacy history and previous remote ancestor off the firewall, prevents new credentials entering the legacy plaintext capture path and remains recoverable after interruption.
VERDICT: not verified
EVIDENCE: Read-only inspection, d70e8af4595f6be7d2f84f18598d41898bdfc0b5. Activation rejects a present legacy hook, requires a version 2 checkpoint with export and configuration digests for the legacy cutover, checks the legacy tip and returns the remote parent (Activation.php:21-63,94-122). setConfiguration runs the configd check under the config lock before saving (EncryptedGit.php:97-124). Limitations: no writer drain, cutover interruption or archive retrieval was executed or observed in this pass.

CRITERION: AC-07 A second operator can install, configure, observe and recover the provider from versioned documentation and verified package inputs, with supported versions, diff/storage trade-offs and distribution/contribution limits explicit.
VERDICT: not verified
EVIDENCE: Read-only inspection of docs/installation.md, docs/recovery.md and docs/compatibility.md at d70e8af4595f6be7d2f84f18598d41898bdfc0b5. Limitations: no second-operator lifecycle, package provenance check or growth measurement was executed or observed in this pass. The R-49 and R-50 lifecycle evidence was not available here. The journal headroom limit in docs/recovery.md:73 has no implemented migration (F-06).

CRITERION: AC-08 Owned PHP source and tests pass the selected runtime syntax checks, PSR-12 style, declared static-analysis checks and behavior tests, with visible coverage and reviewed narrow exceptions. Required security scans and native audits complete with expected coverage and any findings resolved or given an independently reviewed, owner-approved disposition. The runtime package excludes development tooling and private fixtures.
VERDICT: not met
EVIDENCE: Read-only inspection, d70e8af4595f6be7d2f84f18598d41898bdfc0b5, plus retained evidence. The independent R-50 native pkg audit was recorded as exiting 1 for python313-3.13.18, CVE-2025-15367, and it was rechecked in R-51 and in the retained supplemental AC-08 review. docs/security/cve-2025-15367.md:3 records owner acceptance scoped only to repository integration and the identified disposable fixture, states that the native audit failed and keeps the residual. The spec keeps AC-08 unticked with Residual https://github.com/vhco-pro/opnsense-encrypted-git-backup/issues/4. The retained public metadata for run 43694115250 at PR head 19e1dd3cb580899b671dfccbc3431dec9be1fd69 shows that the php-ci-action, scanner-exit probe, Psalm taint probe and package-plan steps succeeded. Limitations: only step conclusions were available for this run. Tool outputs, file coverage counts, Composer and Semgrep results and the package contents were not observed. The supplemental review's counts were made at d9c9e7a and were not re-observed. No PHP tool, pkg audit, vh-adlc lint or gate was executed in this pass. The audit result is retained and was not re-executed.

CRITERION: AC-09 The signed repository supports verified native installation and updates on the selected runtime, rejects untrusted catalogues, modified packages and incompatible targets, and preserves recoverable trust and a usable prior generation for established feeds through failed publication and signing-key rotation. An unresolved first activation prohibits further publisher mutations while the pending request may still become live. Bootstrap recovery withdraws the first catalogue and retains its packages for cached clients. A terminal live recovery that fails native validation permits one retry of the same approved files per separately authorized dispatch. Newer releases stay blocked until recovery is verified. Production signing and deployment require owner approval, and fixture execution has access only to owned staging and fixture keys.
VERDICT: not verified
EVIDENCE: Inspected the retained public metadata and raw log for manual run 43677265727, attempt 1. Event workflow_dispatch, branch feat/native-encrypted-git-backup, head 4a92a0df3506d633497e3ae3661cf1894cb54294. The fixture and native-verifier jobs succeeded, and verify-release and publish were skipped. The native-verifier TAP reports 1 test, 1 pass, 0 fail and 0 skipped in about 76 seconds. The preflight error lines in the fixture log come from expected negative cases inside a job that succeeded. The retained metadata for PR run 43694115250 at 19e1dd3cb580899b671dfccbc3431dec9be1fd69 also shows feed-fixture and native-verifier succeeding, with production jobs skipped. Limitations: these are retained copies that were not retrieved live in this pass. The tree equality of 4a92a0d with the target rests on R-51's record and was not checked by Git here. The actual-plugin Firmware upgrade proof is reused from R-50 and was not available to this pass. A passing subset does not upgrade this composite criterion. The Design's prepared state is absent (F-07). No production execution was performed or observed.

CRITERION: AC-10 The native settings and status interfaces pass reproducible automated browser journeys for setup, reload persistence, success/failure states and permissions on owned disposable fixtures, with the applicable responsive and accessibility checks and developer tooling excluded from the runtime package.
VERDICT: not verified
EVIDENCE: The retained public metadata for Native browser run 43694114786 at PR head 19e1dd3cb580899b671dfccbc3431dec9be1fd69 shows the opnsense-browser job succeeding, including the native Backups exercise and sanitized evidence retention steps. Limitations: only step conclusions were available. Browser coverage, zoom, theme, screenshots, console checks and package exclusion were not observed. The R-49 Chromium and Firefox evidence was not available to this pass, and no Playwright run was executed.

FINDING: F-01
KIND: judgement
SEVERITY: should-fix
WHERE: src/opnsense/mvc/app/library/OPNsense/Backup/EncryptedGit.php:150-171; src/opnsense/mvc/app/library/OPNsense/EncryptedGitBackup/GitDelivery.php:376-391; Design / Guarded migration and recovery
EVIDENCE: Confirmed from source. runConfigured() takes Config::lock() at line 153 and holds it through NativeRun::run, which covers every network Git call. Each call has a 30 second Process limit (GitDelivery.php:388). The worst path makes 8 network calls: fetch at start (2), push and read-back of held pending work (3), and push and read-back of the new snapshot (3). Every native configuration save on the appliance waits during that time, including setConfiguration (EncryptedGit.php:97-98). The lock is deliberate, because it keeps settings and rollback changes out of an admitted delivery, but the cost is an appliance-wide stall while the remote is slow. This validates the first static pass's F-01.
PROPOSAL: Hold the config lock only while reading the settings, checkpoint and XML. Take delivery.lock before releasing it, and make settings saves and rollback replacement also take delivery.lock. Otherwise, bound total delivery time well below the request limits and document the stall.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: src/opnsense/mvc/app/library/OPNsense/Backup/EncryptedGit.php:141; src/opnsense/mvc/app/library/OPNsense/EncryptedGitBackup/GitDelivery.php:388; src/opnsense/mvc/app/library/OPNsense/EncryptedGitBackup/Activation.php:53-58
EVIDENCE: Confirmed from source. backup() waits 240 seconds for configd, which equals the 8 x 30 second network budget, before counting local Git calls, the 5 second legacy rev-parse and encryption. On a caller timeout, the scheduler or GUI reports failure while run.php continues under the config lock and can later record verified. The result fails safe, giving a false failure and never a false success, but the caller's result and the recorded outcome can disagree. SSH ConnectTimeout=8 (NativeRun.php:62) bounds connection setup but not slow transfers. This validates the first static pass's F-02.
PROPOSAL: Add an overall deadline in GitDelivery, shorter than the caller's wait, that records a delivery failure. Alternatively, derive the configd wait from the computed worst case. Add a slow-remote test.

FINDING: F-03
KIND: factual
SEVERITY: nit
WHERE: src/opnsense/mvc/app/library/OPNsense/EncryptedGitBackup/GitDelivery.php:255-270
EVIDENCE: Confirmed by reading only, not executed. ls-remote matches its pattern against the end of a ref name at a slash boundary, so another remote ref whose name ends with the configured ref path also matches. The str_ends_with and substr handling then reports a read failure, or fails objectId on joined output, instead of exact absence or presence. Both outcomes block delivery safely but misclassify the failure. No test covers this.
PROPOSAL: Parse the output line by line, accept exactly one line whose ref equals the configured ref, and use a distinct failure category for extra matches. Add a unit test.

FINDING: F-04
KIND: judgement
SEVERITY: nit
WHERE: scripts/feed-pages-assets.mjs:30-53
EVIDENCE: Confirmed. Asset keys come from the manifest and are never recomputed from file content, in --validate mode or before upload. Files are also deduplicated by key (line 39). A key that does not match its content would only be caught by the post-activation served SHA-256 check, which leads into recovery.
PROPOSAL: Recompute each key from the file content in --validate and before upload, and reject any mismatch before submission-started.

FINDING: F-05
KIND: judgement
SEVERITY: nit
WHERE: scripts/feed-publication-mode.sh:25-26; scripts/publish-feed.sh:47,150
EVIDENCE: Confirmed. The journal and Pages bearer tokens are passed to curl as command-line header arguments, so they are visible in the process table while curl runs. The Node uploader reads its token from the environment instead (feed-pages-assets.mjs:19,43). The exposure is small on a single-tenant hosted runner.
PROPOSAL: Supply the headers from a private temporary file or a curl config on standard input.

FINDING: F-06
KIND: factual
SEVERITY: nit
WHERE: scripts/publish-feed.sh:46-52,150-157; docs/recovery.md:73
EVIDENCE: Confirmed. The publisher stops once there are 100 journal records or 100 production deployments. The guide requires a supported migration to a complete retained journal before that point, but no such migration exists at the target. Each publication adds several journal records, so headroom runs out after a limited number of releases. It fails safe.
PROPOSAL: Implement and test paginated complete reads or the migration before production enablement, and warn when headroom is low.

FINDING: F-07
KIND: factual
SEVERITY: should-fix
WHERE: Design / Activation reconciliation and retry eligibility (docs/specs/native-encrypted-git-backup.md:291); Test Plan AC-09 row; scripts/publish-feed.sh:376-392; scripts/feed-journal-generation.jq:4-58
EVIDENCE: Confirmed. The normative Design requires writing a prepared state and then submission-started, and says only a durable prepared state from a terminated runner proves that submission did not start. The journal has no prepared phase: the phases are submission-started, recovery-required, recovery-started, create-rejected, rejection-closure, candidate-failure-closure, trust-finalization-pending, verified-closure and history-checkpoint. No test under tests/package references a prepared state. The AC-09 proof step "Terminate a runner while its attempt is prepared and verify a later dispatch can resume" therefore has no implemented state to exercise, and AC-09's proof could pass on an implementation that differs from the accepted Design. The behaviour is stricter, holding rather than discarding. This finding raises the first static pass's F-07 from nit because the mismatch affects a normative section and a proof row.
PROPOSAL: Add the prepared phase with discard-after-termination and a test for it. Alternatively, revise the Design and the AC-09 row to the submission-started-only model, which is a normative revision that needs fresh review and owner acceptance.

FINDING: F-08
KIND: judgement
SEVERITY: nit
WHERE: src/opnsense/mvc/app/library/OPNsense/EncryptedGitBackup/GitDelivery.php:99-125; src/opnsense/mvc/app/library/OPNsense/EncryptedGitBackup/Freshness.php:19
EVIDENCE: Confirmed. attempt.json records running before work starts. A killed worker or power loss leaves running in place until the next run, and Freshness reports it as running. Remote freshness still marks the backup stale, so a stopped backup is not hidden.
PROPOSAL: Report a running attempt older than a set bound as unknown or failed, or document this behaviour.

FINDING: F-09
KIND: factual
SEVERITY: nit
WHERE: src/opnsense/scripts/encryptedgit/rollback.php:234; src/opnsense/mvc/app/library/OPNsense/EncryptedGitBackup/Activation.php:36
EVIDENCE: Confirmed. Rollback tests legacy repository presence with is_dir, after rejecting a link at line 230. Activation uses file_exists or is_link. If a non-directory occupies that path, rollback resume and delivery disagree about whether legacy history exists. Delivery then rejects, so it fails safe.
PROPOSAL: Use one shared presence check.

FINDING: F-10
KIND: factual
SEVERITY: nit
WHERE: docs/specs/native-encrypted-git-backup.md:26; docs/security/cve-2025-15367.md:1,3; .github/workflows/php.yml:39
EVIDENCE: Confirmed. The covers list names renovate.json, which does not exist at the target. The disposition is titled "Proposed disposition" and says "This proposal grants", although line 3 records acceptance. php.yml:39 has a comment about scanning full HEAD history that is attached to no input.
PROPOSAL: Remove the stale covers entry, retitle the disposition as accepted while keeping its scope limits, and either remove the comment or restore an explicit history-scan input.

FINDING: F-11
KIND: judgement
SEVERITY: nit
WHERE: scripts/publish-feed.sh:7,322,334-336
EVIDENCE: Confirmed. scripts is assigned identically at lines 7 and 322. At line 336, the jq filter and its file argument are separated by a long run of spaces that looks like an accidentally joined line. Both are valid Bash but harder to read in a safety-critical script.
PROPOSAL: Remove the duplicate assignment and put the file argument on its own line.
````
