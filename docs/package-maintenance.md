# Maintain the signed package feed

## Verify a disposable signed feed

Build the package in the pinned plugins framework and put it in a new staging directory. Run `pkg repo <generation-directory> <private-signing-key>` on FreeBSD. Keep the signing key outside the generation directory and preserve immutable package filenames across generations.

Use a private, temporary repository configuration directory on the fixture appliance. In its repository definition, set `signature_type` to `pubkey` and point `pubkey` to the independently verified public key. Run `pkg -o REPOS_DIR=<configuration-directory> update -f -r <repository>`, then query that repository for the expected package and version before trying installation. In the observed wrong-key case, pkg logged signature rejection and removed the catalogue even though the update command returned zero.

Keep the prior complete generation available until the new catalogue and its package have passed native client verification. Change the trusted key through an independently verified channel before clients accept a rotated catalogue. Retain the previous generation and the corresponding recovery trust material until the new generation has been verified.

## Prepare a versioned package

The CI workflow uses [version-workflow](https://github.com/vhco-pro/version-workflow/blob/3b78b04df802ea1592cbe19338d7a882d1888389/.github/workflows/version.yml) in dry-run mode. For release preparation, use the successful push run for the approved main commit. Pull-request runs calculate against GitHub's synthetic merge commit and are verification evidence.

For the first signed feed, the protected `tag` dispatch accepts the reviewed
main source, its successful calculation run and attempt, and the expected
release tag. It checks the source and version through the pinned shared
GitVersion action before invoking that action with tagging enabled. It then
resolves the remote tag back to the reviewed source. This keeps the release
identity tied to the reviewed package source even when a workflow-only
change lands later.

The matching `publish` dispatch checks out that reviewed source, verifies the
retained release evidence and downloads the retained
`feed-signing-public.pem` asset. Pass the independently verified SHA-256
fingerprint over DER public key bytes as `public_key_sha256`. The private
signing key stays outside Actions. First publication also
requires a retained recovery bundle with the originally advertised packages
and no catalogue or metadata files. A dispatch that reports a recorded
submission is followed by reconciliation with the same retained inputs.

On the selected disposable FreeBSD target, invoke `bash scripts/prepare-native-package.sh <GitVersion-SemVer> <source-sha> <tag-or-empty> <pinned-plugins-tree> <output-directory>`. For release preparation pass the exact tag. The script rejects a different checkout, wrong tag or tag pointing elsewhere, and checks the built package manifest against the mapped version. Stable `1.2.3` stays `1.2.3`. GitVersion prerelease `1.2.3-rc.12` maps to `1.2.3.rc12`, with the same rule for alpha and beta. Arbitrary labels and build metadata are rejected.

`tests/package/version-test.sh` checks source and tag identity. Run it on FreeBSD to exercise native ordering with `pkg version -t`. The signed staging script consumes the prepared package. The shared [gh-release-workflow](https://github.com/vhco-pro/gh-release-workflow/blob/b18de6d2f305f971afe01ba31e17bde5966b1567/.github/workflows/gh-release.yml) assumes its Git tag is the release. This plugin's release artifact is the signed native package and catalogue, so the shared calculation runs separately from the protected feed publisher.

The workflow uses the shared bundled GitVersion configuration. When a branch dry run emits a branch-named prerelease such as `0.1.0-feat-native-encrypted-git-backup.1`, CI reports it as a source preview. The native release mapper remains strict and rejects that label.

## Feed publication fixture

See the [feed fixture notes from the first release](https://github.com/vhco-pro/opnsense-encrypted-git-backup/blob/83a397f564fc016f82fc551172b7c71d87b7f16f/docs/recovery.md#feed-publication-fixture) for the original rehearsal and its limits.
