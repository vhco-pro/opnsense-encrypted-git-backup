# Follow-up to the Opus 5.5 review

The [post-merge reviews](opus-5-5-post-merge.md) cover the merged source
at `d70e8af4595f6be7d2f84f18598d41898bdfc0b5`. The first pass rated F-07
a nit. The second rated it should-fix after checking the publisher against
the approved feed design.

| Finding | Follow-up |
| --- | --- |
| F-01 and F-02 · Lock duration and caller timeout | The pinned core uses a blocking exclusive config-file lock. The plugin used a 240-second configd wait and up to 30 seconds per Git command without a shared deadline. A local Git fixture accepted a push, delayed its response past a proposed two-second budget and still received a success receipt on the old code. The repair keeps the lock and its rollback serialization, budgets Git calls within 180 seconds per admitted delivery, and gives the native worker a 195-second supervisor plus a five-second termination grace. The 240-second caller wait remains. Queueing before the worker starts is outside its supervisor. The regression now records failure without a receipt, retains ambiguous push evidence and verifies the retained snapshot on retry. |
| F-03 · Suffix-matching refs | The local bare-Git regression covers an exact branch alongside a suffix match, then the suffix match alone. The reader selects the exact ref when present and holds when results contain only an unrelated suffix. It still pins and verifies the fetched object. |
| F-04 · Pages asset keys | The old preflight accepted one asset key for two different files. It now rejects conflicting bytes for a duplicated key and accepts identical bytes. The retained bundle and final served-file verification still use SHA-256. Validation of a unique provider asset key against the production key generator requires verified preparation tooling before live publication. |
| F-05 · Credential arguments | Journal and Pages curl calls from the publisher and closure now pass private header file paths. The fixture verifies empty fixture headers and separate synthetic production-shaped headers without making HTTP requests. Runner environment and credential isolation remain part of the protected publication setup. |
| F-06 · Bounded reads | The GitHub query rejects pagination or 100 records, and Pages correlation rejects 100 deployments. Recovery instructions now state that production stops at the bound. A complete-history or migration design needs verification before reaching it. |
| F-07 · Durable prepared state | The earlier prepared-state mismatch was reproduced. The owner selected the single-record contract below. AC-09 remains open on the revised draft pending baseline acceptance and scoped verification. |
| F-08 · Interrupted running status | The hard deadline can terminate the worker before it updates status. The recovery guide now explains that the last attempt can remain marked running and the independent receipt age still detects missed deliveries. |
| F-09 · Legacy path presence | Rollback now checks for a present non-directory entry after its existing symlink rejection, matching delivery's presence check. |
| F-10 · Stale wording | The README and installation guide distinguish merged code from the pending first feed. The Python disposition heading now reflects the accepted scope. The unused covered path and workflow comment are harmless metadata. The accepted `covers` field stays unchanged. |
| F-11 · Publisher readability | Removed the duplicate script directory assignment and split the long jq call. |

The focused native timing fixture ran in a fresh disconnected OPNsense
overlay. It used the installed core's real configuration lock and save with
a synthetic PHP worker. It ran the native supervisor at shortened test
durations. The old configuration save waited 5913 ms and the worker exited 0.
With supervision, the save waited 1904 ms and the worker exited 124. This
checks lock release under termination. It does not measure CI queue latency
or promise a configuration save interval for other services.

## Owner selected the single-record contract for F-07

The earlier accepted design recorded a durable `prepared` state and lets a later
dispatch discard that state only after verifying the original runner
terminated. The current publisher validates and stages immutable assets
before recording `submission-started`. Adding the preceding phase would
require a journal transition and independently verified runner identity
and terminal-state handling across dispatches.

The smaller option retains `submission-started` as the first activation
journal state. Asset staging can be repeated from the retained approved
bundle when no submission record exists. The publisher continues to
hold on ambiguous creates after the record commits. This option drops a
separate durable record of pre-submission preparation and termination.
It does not loosen recovery authorization, history retention or native
client verification.

On 2026-11-15, the owner selected “Use simpler single-record contract (Recommended)”. The draft applies these exact normative edits:

1. In Design, replace the sentences from “Write a prepared state” through
   “Only a durable prepared state from a terminated runner proves that
   the workflow did not start submission” with the following text.

   > Persist and independently verify a submission-started record before making any Pages create request. A later authorized dispatch may repeat pre-submission staging from the same retained approved assets after a complete journal read shows no submission record. After a submission-started record exists, apply Pages reconciliation even if the runner exited before making the request. An unresolved activation can persist indefinitely.

2. In the AC-09 Test Plan, replace “Terminate a runner while its attempt is
   prepared and verify a later dispatch can resume.” with the following text.

   > Interrupt pre-submission staging before the submission-started record commits. Verify zero Pages create requests, then verify a later authorized dispatch reads the complete journal and resumes from the retained approved assets.

PR #2 was merged after owner approval. The authorized after-merge cleanup
removed the original remote feature branch. The owner directed the same
author to continue the revision and already approved source repairs on
draft PR #5, on `docs/merged-implementation-status`. The branch in the
specification now names that follow-up.

R-55 reviewed `c21c21bc36bd57e6ebed2495745a1c07ac0ab67d` in Claude Code with the
first-party `claude-opus-5-5` model and read-only source and Git mounts. It
returned two documentation nits. Both selected blocks are verbatim. The
additional AC-09 proof checks from R-53 and R-54 exercise what the selected
contract already requires. They cover incomplete journal reads and
missing or mismatched submission records.

The R-55 acceptance row records the owner's selection of the described
contract in session. The reviewed revision matches that selection.
The owner was presented with the contract, and R-55 identifies the
matching source commit. Merge and production publication still require
separate approval.

## Single-record verification

At R-55 source `c21c21bc36bd57e6ebed2495745a1c07ac0ab67d`,
`node --test tests/package/feed-publisher-http.mjs` passed the local
publisher test. The loopback fixture checked that a truncated journal
prevents restaging and create. It also checked that candidate read-back
returning 404 or a different record prevents create and leaves a later
dispatch on reconciliation hold. The recovery counterparts run in the
native fixture. They were outside the local command. The [native-verifier job](https://github.com/vhco-pro/opnsense-encrypted-git-backup/actions/runs/43704991458)
passed both recovery cases on `adf9107df0e9bbb9d1637317bfbf52388651b41f`
using FreeBSD pkg, synthetic packages and owned mock endpoints. The
production verification and publisher jobs were skipped.

[R-56](../specs/native-encrypted-git-backup.md#r-56) independently ran
the loopback fixture at `fcbc9565c00ee6b8ec891f4be9bda5058230e0b4`.
The source and Git mounts were read-only. The author compared HEAD,
refs, index and working state before and after. Claude Code attested
first-party `claude-opus-5-5`. R-56 returned two criteria met, seven not
verified and AC-08 not met. For the signed feed it observed the candidate
and journal cases, and checked hosted metadata for the native recovery
cases. The complete release and native client criterion remains open.

## Targeted native follow-up

Public [browser run 43704991178](https://github.com/vhco-pro/opnsense-encrypted-git-backup/actions/runs/43704991178)
passed at `adf9107df0e9bbb9d1637317bfbf52388651b41f` on its first
attempt. The preceding browser run passed on attempt two after an
activation timeout.

Disconnected OPNsense 26.7.9_1 fixtures installed the follow-up package
built from `4033f572711c17d02a1b7a577d86ea52c524811a`. The merged-to-follow-up
upgrade preserved activation, pending ancestry and the last receipt,
verified the installed timeout command and passed native cron delivery,
configd readiness, removal and reinstall. A separate clean appliance
passed legacy-writer drain, cutover interruption, rollback and Git ref
deletion.

With `631729b8e99d0a3c337831247e615ef88b2be17c`, the versioned
`tests/native/rollback-legacy-entry-hold.sh` failed at the pre-repair
package because rollback resumed with a regular file in the legacy
path. After upgrading the same fixture it observed the structured hold,
unchanged receipt and pending ancestry, then restored activation when
the file was removed. The first repair-side fixture attempt expected
the error without its native prefix. The corrected assertion passed on
a fresh overlay.

The disconnected scheduled-action fault test at
`1ae0cf5c5d05ea525dbd7b402ca13682396b2faa` verified the installed
195-second supervisor and exercised its FreeBSD TERM/KILL path with a
12-second timeout and two-second grace. The test paused a real SSH push
with a rejecting fixture hook. A TERM-ignoring harness held the timeout
open until it logged KILL. The worker, Git and SSH processes exited. The supervisor logged KILL for the harness, and the test did not trace the terminating signal of each descendant.
The native status and the on-disk attempt both reported failure. The
remote commit and last receipt stayed unchanged, the independent check
reported a stale receipt, and retry pushed the retained pending commit.
The sibling failure check also passed. The fault test invokes the
same native action as cron. A separate fixture above observed an actual
wall-clock cron run after upgrade. Early fault-harness runs did not
establish the signal or status assertions.

The isolated signed Firmware chain at
`4e53e671e06acf8263a45d03b8487bcb89f347aa` used the pinned shared
GitVersion configuration. It calculated `0.1.0` at that SHA, used
a synthetic tag on the same Git object, verified the run and release
record with fixture metadata, and upgraded the real plugin through
Firmware. The signed package SHA-256 was
`864194e99c3bd4ca3718a09b4baf0e4b3a058508c9498cce15efb24343741fbf`.
The tag, run record and signing identity were fixture inputs. The manual
fixture run at R-51 verified the dispatch route. Its workflow file is
byte-identical, and the public PR jobs ran the updated controller with
the same fixture commands and conditions. No follow-up manual or
production dispatch was run. Production Pages key generation and
live-provider validation remain separate from this fixture proof.

The first console walkthrough built and installed a local synthetic package, saved
activation, verified the encrypted snapshot from the expected remote
commit, and restored the export through the native restore API. Three
additional snapshots measured 53,648 bytes per encrypted blob and grew
the fixture repository from 200 to 416 KiB. The authored guide proof used
synthetic data, a loopback SSH destination and one disconnected guest.
The native browser artifacts cover the UI; the guide fixture uses the
native save and restore interfaces from the console. It used the native
PHP save entry point and root configctl. It did not verify signed install
provenance, and [R-58](../specs/native-encrypted-git-backup.md#r-58)
records that gap.

## Exact repair verification

On repair source `89414487b5e5755230e90729f55334c9de5a9251`, PHP 8.5.12
passed PHPCS, PHPStan and PHPUnit (28 tests, 125 assertions). The exact-ref
test also passed by itself (one test, six assertions). It failed against
the original source with an invalid backup object identifier. The committed
deadline test failed against that same original source because delivery
reported success after the test deadline. The earlier failed draft test
also observed a late receipt.

All six package shell suites passed, including `feed-preflight-test.sh`
with the duplicate-key and header-file cases. The loopback publisher test
passed. Its green result describes current behavior. The separate prepared
record assertion failed against the merged source and remains evidence
of F-07, not conformance to the accepted AC-09 sequence.

The native timing fixture exercises TERM and lock release using the real
installed core configuration save. SIGKILL escalation, descendant reaping
and configd queue latency were outside that fixture. A long native lock
wait before delivery can consume the supervisor budget before the Git
deadline fires, and supervisor termination can prevent a final status
update.

## Independent review of the repairs

Claude Code served `claude-opus-5-5` and identified the provider as
`firstParty` in its final usage metadata. Source and Git metadata were
mounted read-only. HEAD, refs, index and status matched before and after.
The initial bounded review return follows verbatim. The exact test runs
above address its evidence and test-version findings.

```text
MODEL: claude-opus-5-5
TARGET: 89414487b5e5755230e90729f55334c9de5a9251

FINDING: F-01
KIND: judgement
SEVERITY: should-fix
WHERE: docs/reviews/opus-5-5-follow-up.md, Decision pending for F-07; docs/specs/native-encrypted-git-backup.md, Design and AC-09 Test Plan; tests/package/feed-publisher-http.mjs:864-869
EVIDENCE: The prepared-contract red rerun failed with "No durable prepared record before interrupted submission-started write". That confirms the accepted design's durable prepared state is absent. The spec still contains the exact text the option quotes ("Write a prepared state ... Only a durable prepared state from a terminated runner proves that the workflow did not start submission" and "Terminate a runner while its attempt is prepared and verify a later dispatch can resume"), so the proposed replacement span is exact and the spec is unchanged. The committed test asserts journal.length 0, pages 0 and no new create after a dropped submission-started write. That matches the pending smaller option, not the accepted design. The node green run of this test therefore shows current behaviour, not AC-09 conformance.
PROPOSAL: Keep F-07 open and AC-09 not ready until the owner decides. Do not cite the green publisher test as AC-09 evidence unless the owner adopts the option and a fresh spec review confirms the revised text.

FINDING: F-02
KIND: factual
SEVERITY: should-fix
WHERE: docs/reviews/opus-5-5-follow-up.md, F-03, F-04 and F-05 rows; retained evidence set
EVIDENCE: No red or green log for testRemoteReadBackSelectsTheExactRef exists apart from the aggregate PHP run (28 tests, 125 assertions, no commit recorded). The node green log covers only the publisher HTTP test, not tests/package/feed-preflight-test.sh. The asset-key fixed log shows only the rejection error. It does not show the identical-bytes acceptance path or the synthetic header subtest. None of the logs record the commit or command they ran against.
PROPOSAL: Retain a run of feed-preflight-test.sh and the PHP suite that records the target commit, or describe the F-04 and F-05 rows as inspected rather than observed passing.

FINDING: F-03
KIND: factual
SEVERITY: nit
WHERE: retained timeout red log; tests/GitDeliveryTest.php:144-153
EVIDENCE: The red log fails at GitDeliveryTest.php:150 on the verified.json assertion after 7 assertions. In the committed test, line 150 is the closing brace of the catch block. Against pre-fix code, the first failure would be assertNotNull at line 151 ("Delivery reported success after its deadline."), after 4 earlier assertions. The log supports the substance (the old code wrote verified.json after a delayed push), but it came from a different revision of the test than the one committed.
PROPOSAL: Rerun the committed test against the parent source and retain that output, or label the log as coming from an earlier test draft.

FINDING: F-04
KIND: judgement
SEVERITY: nit
WHERE: src/opnsense/service/conf/actions.d/actions_encryptedgit.conf:2-3; tests/native/config-lock-deadline.sh; follow-up native timing paragraph
EVIDENCE: The fixture checks that the shipped command string is exactly "timeout -k 5 195 php run.php". It then runs a synthetic worker under "timeout -k 1 2" that takes the real config lock and sleeps. The retained output (5913 ms with exit 0, then 1904 ms with exit 124) matches the follow-up text. The synthetic worker exits on SIGTERM, so the -k escalation path is not exercised. It spawns no descendants, so reaping of Git or ssh children is not exercised. It does not run through configd, run.php, encryption or Git. The output file records no appliance or commit identity.
PROPOSAL: State that the 200-second worst case relies on the KILL escalation and descendant reaping that this fixture leaves untested, or add a variant that ignores SIGTERM and forks a child.

FINDING: F-05
KIND: judgement
SEVERITY: nit
WHERE: src/opnsense/mvc/app/library/OPNsense/EncryptedGitBackup/GitDelivery.php:105; src/opnsense/mvc/app/library/OPNsense/Backup/EncryptedGit.php:150-170; docs/recovery.md new paragraph
EVIDENCE: The 180-second deadline starts in recordDelivery. That happens after the blocking config lock wait, the activation check (Process::run with a 5-second limit) and the delivery.lock acquisition. If those take more than 15 seconds, the 195-second supervisor fires before the Git deadline. The worker then dies without writing a failed status, so a running status stays behind. The recovery text says this generally ("A terminated worker may leave an attempt marked running"), but not that a long config lock wait leads to it.
PROPOSAL: Either start the budget at worker entry, or add a sentence to the recovery text saying a long native lock wait can end in supervisor termination instead of a recorded deadline failure.

Observed (no defect found by inspection):
- Budget: the supervisor worst case is 195 + 5 = 200 seconds, below the 240-second wait in EncryptedGit::backup's configdRun call. Each Git call gets min(30, remaining) seconds and fails before starting once the deadline has passed. Process::run accepts a float timeout. The capture and encryption step runs inside the same wall-clock budget.
- Late receipts: a push that times out at the deadline is swallowed. The read-back that follows then throws the deadline error, so neither verified.json nor a verified status is written, and creation.json is kept. On retry, the pending HEAD is read back, observe() adds a verification commit whose parent is the retained tip, and creation.json is retired. The committed test asserts each of these steps.
- Lock order: the worker takes the config lock (blocking), then delivery.lock (non-blocking). Rollback takes delivery.lock (non-blocking), then the config lock (blocking). Neither side waits on the other's inner lock, so they cannot deadlock. The kernel releases both flocks when a worker is terminated. Rollback's config and settings serialization is unchanged apart from the F-09 file_exists change, which still runs after the is_link rejection.
- Ref parsing: fetch() keeps only lines whose second tab field equals the full ref exactly. It requires exactly one match and still checks FETCH_HEAD against that object. A remote that has only a suffix ref now holds. The pre-fix code also failed closed in both test scenarios, through a different error.
- Publication: credentials are written to mode 0600 header files (umask 077) in a per-run temporary directory that a trap removes, and curl reads them with -H @file. feed-close.sh calls publication_headers itself, and feed-recovery.sh and feed-retirement.sh inherit the headers by being sourced. No Authorization value is left on a curl command line. Pages asset keys that repeat must now have the same SHA-256 bytes.

Limitations: No tests were run in this context. All results above come from reading the source at the target commit and the retained logs. FreeBSD timeout(1) reaper behaviour and configd queueing were not checked against the core source. The rollback drain window is 30 seconds against a worker cap of up to 200 seconds. It fails closed, and this commit does not change it. This is a bounded corrective review. It is not a full matrix acceptance verdict, it approves no release, and it leaves residual #4 and earlier independent evidence unchanged.
```

## Independent check of the additional evidence

Claude Code again served `claude-opus-5-5` through `firstParty`. The repository and Git metadata remained read-only and unchanged. The return follows verbatim.

```text
MODEL: claude-opus-5-5
TARGET: 18e99ad6d588d0cab34a046be08d98e6090cdb4a (docs), checking evidence for source 89414487b5e5755230e90729f55334c9de5a9251

**Summary:** The new logs answer the earlier F-02 and F-03 findings. The doc text keeps its supervisor and delay claims within what was actually shown. Two small nits remain about how much the evidence pins down, plus one about wording in the recovery guide. I read the source, the doc and the logs, and ran nothing.

FINDING: prior F-02 (evidence missing) — **answered**
KIND: factual
EVIDENCE: The repair log's header names source `89414487…`. Under that header, PHPStan reports no errors and PHPUnit passes 28 tests with 125 assertions, which matches the doc. Each of the six package shell suites prints PASS, including `feed-preflight-test.sh`, and the Node publisher test passes. That suite runs under `set -euo pipefail`. Its duplicate-key rejection, identical-bytes acceptance and synthetic-header checks are written with `grep -q` and `test`, so they print nothing when they pass. Any failure would stop the suite before PASS, so the PASS line covers them. The other stderr lines in the log come from negative cases the tests expect.

FINDING: prior F-03 (log came from an earlier test draft) — **answered**
KIND: factual
EVIDENCE: The new failing log names the old source `d70e8af`, the test file from `8941448` and the test name. It fails at `GitDeliveryTest.php:151` with "Delivery reported success after its deadline." after 5 assertions. In the committed test, that is the 5th assertion (lines 126, 129, 142, 143, 151), so the log now matches the committed revision. The failing exact-ref log errors with "invalid backup object identifier" at test line 199 after 3 assertions (186, 189, 192), which also matches the committed test and the doc's description.

FINDING: N-01
KIND: factual
SEVERITY: nit
WHERE: Retained exact-ref failing log; the "Exact repair verification" section
EVIDENCE: Unlike the timeout log, the exact-ref failing log has no header. It doesn't record which old source or test-file version it ran against. The single-test green run in the repair log has no test name either. Both are consistent with the committed test, but neither proves which commit was used.
PROPOSAL: Optional. Add the same baseline and test-name header to future retained logs.

FINDING: N-02
KIND: factual
SEVERITY: nit
WHERE: Repair log, shell-suite section
EVIDENCE: The PHP runs used a container checkout. The shell-suite errors show the scripts' root as the docs working checkout instead. The single header line doesn't show which commit that checkout had when the run happened. I couldn't confirm with read-only file tools whether anything outside `docs/` changed between `89414487` and `18e99ad`.
PROPOSAL: Note in the log or doc that the shell suites ran at the source commit, or rerun them from the same checkout as PHP.

FINDING: N-03 (doc text bounds)
KIND: judgement
SEVERITY: nit
WHERE: Follow-up F-01/F-02 row and the "Exact repair verification" paragraph; recovery guide, supervisor paragraph
EVIDENCE:
- The follow-up doc is properly bounded. It says queueing before the worker starts is outside the supervisor. It says the fixture leaves out SIGKILL escalation, descendant reaping and configd queue latency. It says a long native lock wait can use up the supervisor budget before the Git deadline fires. It says termination can prevent the final status update. It doesn't claim a proven 200-second worst case or a CI queue bound. This answers the earlier F-04 and F-05 findings at the review-doc level.
- The recovery guide is less specific. It mentions configd launch delays and a possibly leftover running status. It does not say that the in-worker configuration lock wait counts against the 195-second supervisor. Its line "leaves time for normal startup and response handling" doesn't mention that a long lock wait ends in termination instead of a recorded deadline failure.
PROPOSAL: Optional. Add that sentence to the recovery guide so operators see it, not only reviewers.

**Also confirmed:**
- Timing figures (5913 ms with exit 0, then 1904 ms with exit 124) match between the doc and the earlier review.
- The doc correctly says the green publisher test shows current behaviour and is not evidence of AC-09 conformance.
- F-07 remains an open decision for the owner, and AC-09 readiness and first publication stay blocked. I did not assess F-07.

**Limitations:**
- Only three new log files were checked. Earlier retained logs, including the failing prepared-record run, were taken from the doc's description.
- I couldn't check the Git object store with read-only file tools, so the commit identity of the shell-suite checkout is unconfirmed.
- PHPCS output appears only as a timing line, with no explicit pass line.
- I didn't look at FreeBSD timeout(1) or configd behaviour.
- This is a bounded evidence check. It's not a full review and it doesn't approve a release.
```

## Hosted PHP check correction

The first repair-head PHP run caught Psalm's strict integer/float operand
check in the monotonic deadline calculation. The calculation now converts
seconds to integer nanoseconds before adding them to the monotonic clock.
The configured limits and lock order are unchanged. Local PHPCS, PHPStan,
PHPUnit (28 tests, 125 assertions) and Psalm taint analysis passed after
the correction. The hosted failure remains in the run history.
[First repair-head PHP run](https://github.com/vhco-pro/opnsense-encrypted-git-backup/actions/runs/43699326569)

Independent Claude Code Opus 5.5 review of the correction, with verified first-party metadata and preserved read-only source and Git state. Verbatim return follows.

```text
MODEL: claude-opus-5-5
TARGET: b302f40bc79d6ac26d774314d89ac58861a4ddbb

NO FINDINGS

LIMITS:
- **Scope:** I looked only at the one changed runtime line in `Process.php` and the new correction section of the follow-up review note. The branch ref points at the target commit, and the line in the working tree matches the added line in the supplied diff. I had no shell in this session, so I could not open the commit object itself. The diff comes from the allowed evidence. F-07 and the accepted Python residual were not reviewed and are unchanged by this diff.
- **Arithmetic:** `$timeout * 1_000_000_000.0` is a float times a float. The explicit `(int)` cast then makes `hrtime(true) + int` an int plus an int, so the strict operand check passes. The hosted failure flagged both operands on line 39, and both are fixed by this one change.
- **Bounded times:**
  - Every caller passes a positive timeout of 30 seconds or less. That covers the literal 5 second calls and `min(30, remaining)`, where the delivery path already rejects `remaining <= 0`.
  - At 30 seconds the product is 3.0e10, which is far below 2^53, so it is exact. Truncation only drops fractions of a nanosecond.
  - A tiny positive remainder casts to 0. That makes the deadline "now", so the loop does one read and status check and then times out. The old version behaved the same way in practice.
  - No caller can reach overflow, NaN or a negative value.
  - The new deadline is an exact integer. The old one was a float and lost a few nanoseconds of precision once uptime passed about 104 days. So the change keeps or slightly improves precision.
- **Unchanged semantics:**
  - The comparison `hrtime(true) >= $deadline`, the polling loop, the output limit, and the cleanup in `finally` (close the pipe, kill with signal 9, close the process) are all untouched.
  - The 30 second command limit and the 180 second delivery limit in GitDelivery are untouched.
  - The diff touches no `flock` or lock-order code.
- **Platform:** On 32-bit PHP, `hrtime(true)` returns a float, so the cast would not make the sum an integer there. I did not assess that because the gate targets 64-bit.
- **Evidence:** I did not rerun any tests, as instructed. The local log shows the PHPStan OK result, PHPUnit at 28 tests and 125 assertions, and a bare `[]` that fits an empty Psalm report but has no label. It shows no separate PHPCS output, so the note's claim that PHPCS passed rests on evidence I could not see. I did not open the hosted run link.
```
