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
| F-07 · Durable prepared state | Confirmed absent. Neither the dispatcher nor preflight appends this state. A loopback test that drops the first submission-started write receives no Pages create and finds no prepared record. The journal reducer has no prepared phase. A narrowly scoped decision is below. AC-09 readiness remains open pending resolution of this mismatch. |
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

## Decision pending for F-07

The accepted design records a durable `prepared` state and lets a later
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

If the owner selects this option, the proposed normative edits are:

1. In Design, replace the sentences from “Write a prepared state” through
   “Only a durable prepared state from a terminated runner proves that
   the workflow did not start submission” with the following text.

   > Persist and independently verify a submission-started record before making any Pages create request. A later authorized dispatch may repeat pre-submission staging from the same retained approved assets after a complete journal read shows no submission record. After a submission-started record exists, apply Pages reconciliation even if the runner exited before making the request. An unresolved activation can persist indefinitely.

2. In the AC-09 Test Plan, replace “Terminate a runner while its attempt is
   prepared and verify a later dispatch can resume.” with the following text.

   > Interrupt pre-submission staging before the submission-started record commits. Verify zero Pages create requests, then verify a later authorized dispatch reads the complete journal and resumes from the retained approved assets.

The accepted specification remains unchanged. First publication awaits
resolution of F-07 and separate release approval.
