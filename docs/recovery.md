# Recover an encrypted backup

Retrieve `config.xml.enc` at the verified remote commit. Obtain the password for the key identifier in that commit's `snapshot.json` from independent recovery storage. Verify the encrypted file's SHA-256 against the metadata obtained from the expected branch and commit.

On an isolated appliance, open **System → Configuration → Backups**. Upload the encrypted export, select decryption, enter its password, and select the full configuration for restore. Contain the restored appliance's network identity and services before attaching it to any network. Confirm the restored fields and reprovision the external credentials from their independent copies before enabling delivery.

## Prepare a legacy migration

Use an independently held archive password and a protected staging directory outside both Git working trees. Record the previous remote branch tip by reading the expected ref from the remote. Create a complete Git bundle from the legacy repository with `git bundle create <private-path> --all HEAD`, encrypt the bundle outside Git, and transfer the encrypted archive to independent storage.

From independent storage, retrieve and decrypt the archive into protected temporary storage. Verify and import the bundle into a new bare repository. Confirm that it contains both the captured legacy tip and the recorded remote tip, and verify the remote tip is an ancestor of the legacy tip with `git merge-base --is-ancestor <remote-tip> <legacy-tip>`. Remove the temporary plaintext bundle and recovered bare repository when verification is complete.

Remove the legacy Git plugin through native package administration, confirm its config-change hook is absent, and wait for existing capture processes to exit. Retain the preliminary archive and the legacy repository. Repeat the bundle and independent verification for the final tip after stopping writers. Recheck the local and remote tips before creating the activation checkpoint. If a tip changes or a writer returns, stop activation and repeat the checkpoint verification.

The activation checkpoint is root-owned, mode 0600, under `/conf/encrypted-git-backup/activation.json`. Its JSON fields are `version` (1), `destination`, `branch`, and `legacy`. For a fresh repository, set `legacy` to null. For an existing legacy repository, record its final `tip`, the previous `remote` tip and the `archiveSha256` of the independently retrieved encrypted bundle in the `legacy` object. Write the checkpoint atomically only after completing independent verification. Keep the archive and password independently recoverable.

After a rejected push, retry against the same branch. Local pending commits stay in the provider's private state directory. For divergent history, stop delivery and investigate the remote branch before making any changes to the retained commits or activation checkpoint.
