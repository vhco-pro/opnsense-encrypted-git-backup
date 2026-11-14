# Install the encrypted Git backup provider

Use the supported runtime and package inputs in [Runtime compatibility](compatibility.md). The private draft package and repository are for disposable validation. Wait for an approved feed and a signing identity verified through an independent channel before installing on a managed appliance.

On the appliance, use the native Firmware package administration to install `os-encrypted-git-backup` from the verified repository. The provider appears under **System → Configuration → Backups**.

Keep deployment identities, known-hosts files and encryption passwords in the root-owned directory `/conf/encrypted-git-backup/credentials`. Its parent and the credential directory require mode 0700. Credential files require mode 0400 or 0600 and a single link. For the reference `example`, the filenames are `identity-example`, `hosts-example`, and `password-example`. Keep recovery copies independently of the appliance. For rotation, provision a new identifier and retain the old password until its snapshots are retired.

Complete the [activation checkpoint](recovery.md#prepare-a-legacy-migration) before enabling the provider. Enter the SSH URL, Git branch, three file references and maximum freshness age. Save and test through the native form. Schedule the existing **Remote backup** job through native cron.

An account granted **System: Configuration: Encrypted Git backup status** can read `/api/encrypted_git_backup/status/read`. The attempt and verification timestamps distinguish a failed or interrupted attempt from the last retained artifact. An independent monitor must also resolve the expected remote branch and hash the encrypted artifact at that commit.

## Verify a disposable signed feed

Build the package in the pinned plugins framework and put it in a new staging directory. Run `pkg repo <generation-directory> <private-signing-key>` on FreeBSD. Keep the signing key outside the generation directory and preserve immutable package filenames across generations.

Use a private, temporary repository configuration directory on the fixture appliance. In its repository definition, set `signature_type` to `pubkey` and point `pubkey` to the independently verified public key. Run `pkg -o REPOS_DIR=<configuration-directory> update -f -r <repository>`, then query that repository for the expected package and version before trying installation. In the observed wrong-key case, pkg logged signature rejection and removed the catalogue even though the update command returned zero.

Keep the prior complete generation available until the new catalogue and its package have passed native client verification. Change the trusted key through an independently verified channel before clients accept a rotated catalogue. Retain the previous generation and the corresponding recovery trust material until the new generation has been verified.
