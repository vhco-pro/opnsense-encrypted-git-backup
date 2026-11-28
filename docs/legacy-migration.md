# Prepare a legacy migration

Use an independently held archive password and a protected staging directory outside both Git working trees. Record the previous remote branch tip by reading the expected ref from the remote. Create a complete Git bundle from the legacy repository with `git bundle create <private-path> --all HEAD`, encrypt the bundle outside Git, and transfer the encrypted archive to independent storage.

From independent storage, retrieve and decrypt the archive into protected temporary storage. Verify and import the bundle into a new bare repository. Confirm that it contains both the captured legacy tip and the recorded remote tip, and verify the remote tip is an ancestor of the legacy tip with `git merge-base --is-ancestor <remote-tip> <legacy-tip>`. Remove the temporary plaintext bundle and recovered bare repository when verification is complete.

Remove the legacy Git plugin through native package administration, confirm its config-change hook is absent, and wait for existing capture processes to exit. Retain the preliminary archive and the legacy repository. Repeat the bundle and independent verification for the final tip after stopping writers. Recheck the local and remote tips before creating the activation checkpoint. If a tip changes or a writer returns, stop activation and repeat the checkpoint verification.

After draining the legacy writer, make a native password-encrypted export of the current configuration and store it independently. Retrieve and decrypt that retained export in protected storage, verify the complete configuration against its source, and record both digests. The configuration digest is SHA-256 of the PHP string representation of the native `Config` object. Use the same source revision for the export and digest. A concurrent save invalidates the evidence and requires a fresh export.

The activation checkpoint is root-owned, mode 0600, at
`/conf/encrypted-git-backup/activation.json`. For legacy cutover, set `version`
to 2 and set `destination` and `branch` to the exact values you will enter in
the Backups form. Record the final local `tip`, the previous `remote` tip and the
encrypted bundle's `archiveSha256` in the `legacy` object. Set top-level
`exportSha256` to the encrypted native export digest and
`configurationSha256` to the source configuration digest. A version 1
checkpoint cannot authorize legacy migration. For a new repository with no
legacy history, use the [fresh setup example](installation.md#complete-a-first-backup).

Write the checkpoint atomically after verification. Keep the archives and passwords independently recoverable. Save activation in the native Backups form before running delivery. If the first delivery fails, keep the plaintext writer disabled. The verified pre-cutover configuration remains the recovery point until the first verified delivery. Restore that export and reapply the provider settings and external credentials from independent records if the configured appliance is lost.

After a definitive rejection, retry against the same branch. If an initial push may have succeeded but the branch is absent, leave the pending commit in place and verify the remote independently before authorizing recovery. Local pending commits stay in the provider's private state directory. For divergent history, stop delivery and investigate the remote branch before making any changes to the retained commits or activation checkpoint.

[Restore an encrypted backup](recovery.md) · [Hold delivery during package rollback](backup-operations.md#hold-delivery-during-package-rollback)
