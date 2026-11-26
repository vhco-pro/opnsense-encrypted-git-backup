# Install the encrypted Git backup provider

Start on a test appliance. The initial verified target is OPNsense Community
Edition 26.7.9_1 on amd64. Check [runtime compatibility](compatibility.md) and
run `pkg config ABI` on the appliance. Version 0.1.0 requires
`FreeBSD:15:amd64`. Stop if the appliance reports a different ABI.

## Verify the signing key

Download [feed-signing-public.pem](https://github.com/vhco-pro/opnsense-encrypted-git-backup/releases/download/v0.1.0/feed-signing-public.pem)
from the v0.1.0 GitHub release. In a separate browser tab, open
[Signing key at pkg.vhco.pro](https://pkg.vhco.pro/#signing-key) over HTTPS and
check the hostname. Run the following command on FreeBSD or OPNsense from the
directory containing the downloaded key.

```sh
openssl pkey -pubin -in feed-signing-public.pem -outform DER | sha256 -q
```

The v0.1.0 fingerprint is
`96a1a891e63c16061d968d9d1c64105d14ab64e6e9201b1c2a6dff989df06837`.
Compare all 64 characters with the fingerprint shown on the package site.
Before configuring the repository, confirm that fingerprint through an
independent trusted channel, such as a maintainer contact you already trust.
Stop if you cannot confirm the fingerprint or if any of the values differ.

## Add the feed and install

On the appliance, place the verified key at
`/usr/local/etc/pkg/vhco-feed-signing-public.pem`, owned by root and readable by
pkg. Create `/usr/local/etc/pkg/repos/vhco.conf` with the following contents.
Keep the existing native OPNsense repository definitions enabled.

```ucl
VHCO: {
  url: "https://pkg.vhco.pro",
  enabled: yes,
  signature_type: "pubkey",
  pubkey: "/usr/local/etc/pkg/vhco-feed-signing-public.pem"
}
```

Refresh and query the VHCO catalogue from a root shell.

```sh
pkg update -f -r VHCO
pkg rquery -U -r VHCO '%n %v' os-encrypted-git-backup
```

Continue only if the update reports no signature error and the query prints
`os-encrypted-git-backup 0.1.0`. A zero exit status from `pkg update` alone does
not establish signature acceptance. Install from the verified VHCO repository
and confirm the installed version.

```sh
pkg install -r VHCO os-encrypted-git-backup
pkg query '%n %v' os-encrypted-git-backup
```

The provider appears under **System → Configuration → Backups**.

## Complete a first backup

If the plaintext Git backup hook or the legacy repository
`/conf/backup/git` exists, follow [legacy migration](recovery.md#prepare-a-legacy-migration)
before enabling encrypted delivery. Use the [recovery guide](recovery.md) when
resuming an existing encrypted backup.

1. Create a private Git repository and choose a branch that does not exist yet.
   Leave that branch uncreated. For an empty repository, skip initialization
   with a README or licence. Grant a dedicated SSH identity permission to create
   and write that branch. The backup runs unattended, so its key must work
   without an interactive passphrase. Verify the Git server's host key and put
   the verified entry in a dedicated known-hosts file.
2. Put the identity, known-hosts file and encryption password under
   `/conf/encrypted-git-backup/credentials`. The parent and credentials
   directories must be owned by root with mode 0700. Each credential file must
   be owned by root, have mode 0400 or 0600, and have a single link. For reference
   `example`, use `identity-example`, `hosts-example` and `password-example`.
   Keep independent recovery copies of all three.
3. Prepare `/conf/encrypted-git-backup/activation.json` with the fields below.
   Replace the example URL and branch with the exact values you will enter in
   the form. Write the file in the same directory as a temporary file owned by
   root with mode 0600, then rename it into place.

   ```json
   {
     "version": 1,
     "destination": "ssh://git@backup.example/config.git",
     "branch": "snapshots",
     "legacy": null
   }
   ```

4. In **System → Configuration → Backups**, enter the matching **SSH repository
   URL** and **Git branch**. If you used the example filenames, enter `example`
   in **SSH identity reference**, **SSH known hosts reference** and **Encryption
   key identifier**. Set **Freshness limit in hours** between 1 and 8760. Enable
   and save the provider. Saving an enabled provider can start delivery
   immediately.
5. Open **System → Configuration → Encrypted Git Backup**. Check that the latest
   **Outcome** is `verified`, and that **Last verified success** and **Remote
   commit** are from this run. A failed attempt can leave an earlier successful
   receipt visible. From a trusted Git client, resolve the configured remote
   branch and compare its tip with **Remote commit**. At that exact commit,
   confirm that `config.xml.enc` and `snapshot.json` are present and that the
   encrypted file's SHA-256 equals the metadata's `sha256` field. Only then
   schedule **Remote backup** under **System → Settings → Cron**. Use the
   [recovery instructions](recovery.md) to test an isolated restore.

For password rotation, provision a new identifier and keep the old password
until you retire every snapshot that uses it.

An account granted **System: Configuration: Encrypted Git backup status** can read `/api/encrypted_git_backup/status/read`. The attempt and verification timestamps distinguish a failed or interrupted attempt from the last retained artifact. An independent monitor must also resolve the expected remote branch and hash the encrypted artifact at that commit.

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
