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

## Prepare a versioned package

The private workflow uses [version-workflow](https://github.com/vhco-pro/version-workflow/blob/3b78b04df802ea1592cbe19338d7a882d1888389/.github/workflows/version.yml) in dry-run mode. Use the branch-push run for the exact branch commit. Pull-request runs calculate against GitHub's synthetic merge commit.

On the selected disposable FreeBSD target, invoke `bash scripts/prepare-native-package.sh <GitVersion-SemVer> <source-sha> <tag-or-empty> <pinned-plugins-tree> <output-directory>`. For release preparation pass the exact tag. The script rejects a different checkout, wrong tag or tag pointing elsewhere, and checks the built package manifest against the mapped version. Stable `1.2.3` stays `1.2.3`. GitVersion prerelease `1.2.3-rc.12` maps to `1.2.3.rc12`, with the same rule for alpha and beta. Arbitrary labels and build metadata are rejected.

`tests/package/version-test.sh` checks source and tag identity. Run it on FreeBSD to exercise native ordering with `pkg version -t`. The signed staging script consumes the prepared package. The shared [gh-release-workflow](https://github.com/vhco-pro/gh-release-workflow/blob/b18de6d2f305f971afe01ba31e17bde5966b1567/.github/workflows/gh-release.yml) assumes its Git tag is the release. This plugin's release artifact is the signed native package and catalogue, so the current workflow prepares versions without publishing release effects.

The workflow uses the shared bundled GitVersion configuration. When a branch dry run emits a branch-named prerelease such as `0.1.0-feat-native-encrypted-git-backup.1`, CI reports it as a source preview. The native release mapper remains strict and rejects that label.
