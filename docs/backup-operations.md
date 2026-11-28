# Operate an encrypted backup

## Monitor backups and rotate passwords

For password rotation, provision a new identifier and keep the old password
until you retire every snapshot that uses it.

An account granted **System: Configuration: Encrypted Git backup status** can read `/api/encrypted_git_backup/status/read`. The attempt and verification timestamps distinguish a failed or interrupted attempt from the last retained artifact. An independent monitor must also resolve the expected remote branch and hash the encrypted artifact at that commit.

## Hold delivery during package rollback

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

A running backup holds the native configuration lock while it captures and delivers the snapshot. Git commands share a 180-second delivery budget, with up to 30 seconds per command. The native worker's supervisor starts termination at 195 seconds and allows up to five seconds before escalating, below the plugin's 240-second configd response wait. This leaves time for normal startup and response handling. Delays before the worker launches are controlled by configd. A long lock wait inside the worker counts against the supervisor and can trigger termination before a delivery failure is recorded. A terminated worker may leave an attempt marked running until the next run. Use the independently verified receipt age to detect stale delivery. Pending or ambiguous pushes still require remote read-back on retry.
