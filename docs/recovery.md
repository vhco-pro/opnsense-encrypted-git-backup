# Recover an encrypted backup

Retrieve `config.xml.enc` at the verified remote commit. Obtain the password for the key identifier in that commit's `snapshot.json` from independent recovery storage. Verify the encrypted file's SHA-256 against the metadata obtained from the expected branch and commit.

On an isolated appliance, open **System → Configuration → Backups**. Upload the encrypted export, select decryption, enter its password, and select the full configuration for restore. Contain the restored appliance's network identity and services before attaching it to any network. Confirm the restored fields and reprovision the external credentials from their independent copies before enabling delivery.

## Prepare a legacy migration

Use an independently held archive password and a protected staging directory outside both Git working trees. Record the previous remote branch tip by reading the expected ref from the remote. Create a complete Git bundle from the legacy repository with `git bundle create <private-path> --all HEAD`, encrypt the bundle outside Git, and transfer the encrypted archive to independent storage.

From independent storage, retrieve and decrypt the archive into protected temporary storage. Verify and import the bundle into a new bare repository. Confirm that it contains both the captured legacy tip and the recorded remote tip, and verify the remote tip is an ancestor of the legacy tip with `git merge-base --is-ancestor <remote-tip> <legacy-tip>`. Remove the temporary plaintext bundle and recovered bare repository when verification is complete.

Remove the legacy Git plugin through native package administration, confirm its config-change hook is absent, and wait for existing capture processes to exit. Retain the preliminary archive and the legacy repository. Repeat the bundle and independent verification for the final tip after stopping writers. Recheck the local and remote tips before creating the activation checkpoint. If a tip changes or a writer returns, stop activation and repeat the checkpoint verification.

After draining the legacy writer, make a native password-encrypted export of the current configuration and store it independently. Retrieve and decrypt that retained export in protected storage, verify the complete configuration against its source, and record both digests. The configuration digest is SHA-256 of the PHP string representation of the native `Config` object. Use the same source revision for the export and digest. A concurrent save invalidates the evidence and requires a fresh export.

The activation checkpoint is root-owned, mode 0600, at `/conf/encrypted-git-backup/activation.json`. For fresh setup use `version` 1, `destination`, `branch` and `legacy` set to null. For legacy cutover use `version` 2 and the same destination and branch fields. Record the final local `tip`, the previous `remote` tip and the encrypted bundle's `archiveSha256` in the `legacy` object. Set top-level `exportSha256` to the encrypted native export digest and `configurationSha256` to the source configuration digest. A version 1 checkpoint with a legacy entry needs fresh verification before it can authorize cutover.

Write the checkpoint atomically after verification. Keep the archives and passwords independently recoverable. Save activation in the native Backups form before running delivery. If the first delivery fails, keep the plaintext writer disabled. The verified pre-cutover configuration remains the recovery point until the first verified delivery. Restore that export and reapply the provider settings and external credentials from independent records if the configured appliance is lost.


After a definitive rejection, retry against the same branch. If an initial push may have succeeded but the branch is absent, leave the pending commit in place and verify the remote independently before authorizing recovery. Local pending commits stay in the provider's private state directory. For divergent history, stop delivery and investigate the remote branch before making any changes to the retained commits or activation checkpoint.

### Hold delivery during package rollback

Keep the plaintext writer disabled. Retain and read back the checkpoint and its matching provider settings before replacing either. Bind both copies to the active configuration revision. If the active configuration changes before replacement, stop and verify a fresh pair.

Use the provider's private `delivery.lock` with PHP `flock(LOCK_EX | LOCK_NB)` to fence Git delivery. If acquisition fails, a worker may still be writing. Wait for it and try again before replacing any inputs. While holding that lock, atomically move `activation.json` out of its active path and account for and drain any already admitted encrypted backup requests. The missing checkpoint denies new encrypted backup requests through configd and through the native remote-backup runner without disabling other providers. Keep the lock until admitted requests have finished. If their completion cannot be verified, keep the checkpoint withheld and leave rollback on hold.

Leave the checkpoint withheld across interruptions in package or input replacement. Verify the compatible settings, destination, branch and pending ancestry against the retained checkpoint before restoring it. Keep the older encrypted provider on hold if it cannot enforce the required remote ref update condition. Resume with a compatible provider only after the complete pair is verified. Preserve pending encrypted commits and external credential files throughout.

If the installed older provider lacks the ref protection, keep the checkpoint
withheld while restoring its settings and persist the provider as disabled
before restoring any compatible activation file. Both configd and the
remote-backup runner must still hold delivery if the remote branch advances.
Leave the provider disabled until the compatible package is ready to resume.

On a supported appliance, root can run `php /usr/local/opnsense/scripts/encryptedgit/rollback.php hold`. The command tries the delivery fence without waiting, records the checkpoint and configuration digests under the native configuration lock, withholds the checkpoint, and polls the native configd delivery workers. Both the native Backups provider and remote-backup runner route delivery through that action. A worker holding the write lock, an enumeration error, or a drain timeout results in a structured `ROLLBACK_HOLD`. Do not proceed with replacement in that state.

Run the same command with `verify` to compare the retained checkpoint and current native configuration against the captured revision. It leaves the checkpoint withheld. An independently retained copy of the matching settings and checkpoint is still required for restore. A passing verification is a read-back and does not authorize an unlocked later replacement.

For legacy cutover, retain the verified replacement checkpoint as root-owned mode 0600 at `/conf/encrypted-git-backup/activation.next`. After a successful hold and drain, run `rollback.php replace` through PHP. It compares the retained provider settings and original revision again while holding both locks. A stale revision leaves the candidate and retained inputs available for inspection. A successful replacement stages the checkpoint for the native activation save. Delivery still requires that save to bind the new checkpoint to the configured target.

If the retained provider settings and native revision still match, reinstall a compatible package while the checkpoint is withheld. Run `rollback.php resume` from that package. It drains the native action again, checks the saved activation and pending target and verifies the retained legacy tip and pending ancestry before publishing the checkpoint under both locks. An interrupted resume rechecks the same retained pair before restoring activation. After a successful resume, the next hold retires the completed rollback record and captures the current pair. If verification reports a hold, keep the retained inputs and pending repository. Resolve the configuration or ancestry mismatch before retrying.

When the provider settings changed during the hold, inspect the current configuration and capture its revision with `rollback.php revision`. Pass that revision to `rollback.php restore-settings REVISION`. The command compares it under the native write lock and saves only the retained provider model. It keeps the checkpoint withheld across a process restart. Review the restored settings and capture a fresh revision. Run `rollback.php resume REVISION` with that revision to verify the retained settings and ancestry before restoring the checkpoint.

### Feed publication fixture

The Signed feed workflow runs against ephemeral loopback GitHub Deployment and Cloudflare Pages HTTP fixtures. Fixture runs have independent concurrency groups. The fixed repository concurrency group serializes production publication. The publisher records a submission attempt in a deployment payload before issuing one Pages create request. The request records the exact source SHA and disables GitHub auto-merge. A later run correlates the attempt with the Pages deployment and checks the served generation marker. Missing or duplicate matches hold the operation. The fixture covers lost replies from both APIs. The durable attempt stays open even after a matching terminal live deployment is observed.

A correlated terminal candidate failure can close when the previous deployment
is still canonical and its approved catalogue and retained packages pass
verification. First publication requires canonical deployment and catalogue
absence instead. The closure records the failed deployment and preserves the
previous generation. An existing recovery-required record continues to control
the attempt.

GitHub Deployment payloads are a candidate journal under single-workflow ownership. GitHub documents workflow concurrency and deployment creation, but supplies no conditional append for this journal. The fixture does not establish that other credentials or workflows cannot create conflicting records. Previous deployment statuses expire, so the publisher does not use them as the replay ledger. The HTTP fixture does not provision real deployment records or upload Pages assets. Full history, durable bundles, retained packages, native verification and release authorization still precede enabling production mode.

The production dispatch job uses the fixed publisher concurrency group and a protected environment. It requires explicit enablement, a main-branch dispatch at the approved SHA, the reviewed run and tag, both retained archives, and a disposable FreeBSD VM on a GitHub-hosted Linux runner. The source token is read-only. A separate deployment-journal credential and the Pages credential are scoped to publication. Configure required environment reviewers and verify the hosted VM before enabling production. Release asset creation belongs to preparation, with a separate asset-writer token. The fixture runs use per-run concurrency and loopback resources.

The native verifier checks the configured ABI against the appliance's actual ABI and leaves pkg's OS version detection active. Overriding ABI alone caused pkg to guess FreeBSD 1500000 on the 1501000 fixture and reject its otherwise compatible package. The corrected verifier passed signed catalogue update and package fetch over the disconnected appliance's loopback HTTP test endpoint.

The journal reader holds when GitHub returns 100 records in the feed environment or Pages returns 100 production deployments in the reconciliation page. This bound prevents a partial response from being used as complete evidence. Before reaching it, a supported migration to a complete retained journal is required. The single writer is enforced among cooperating workflows in this repository by their fixed Actions concurrency group. Administrative deletion, retention changes or writes by unrelated credentials are outside that lock. A missing pinned history or bundle fails closed. An empty response alone cannot establish that someone deleted an entire journal.

After a correlated live candidate fails, the publisher records recovery-required before a recovery submission. An ambiguous submission holds until the provider supplies a unique terminal match. A confirmed live recovery with a terminal result and failing verification can consume one retry for each newly authorized dispatch. The consumption record uses the GitHub run ID, so rerunning the same dispatch preserves its consumed state. A terminal recovery failure with passing checks holds for manual diagnosis.

Retirement requires an approved retirement manifest with the predecessor catalogue path, the operator public-key fingerprint, and every client’s expected trust before and after withdrawal. After verifying live withdrawal, the publisher records trust finalization as pending. It waits for recent signed operator observations tied to the attempt, deployment, archive digest and client scope. Operators manage trust on the clients under their own approved procedure. Before accepting the observations, the publisher checks the live deployment and catalogue withdrawal again. It keeps previously advertised packages at their original paths for clients holding a verified catalogue.
