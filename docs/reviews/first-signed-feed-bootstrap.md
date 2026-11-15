# First signed feed bootstrap review

The owner approved release and publication from
`d646f204a6ba6c3d48798294a592b88a238aae46`. The successful main push
calculated version `0.1.0` in dry-run mode. It did not create a tag.
The bootstrap correction leaves that release source unchanged.
[Main calculation run 43716602549, attempt 1](https://github.com/vhco-pro/opnsense-encrypted-git-backup/actions/runs/43716602549/attempts/1)

The existing workflow cannot tag that older reviewed source. The patch
adds a protected main dispatch using the same pinned shared GitVersion
tag action. The publisher checks out the approved source without
persisting credentials and verifies the retained signing public key
against the fingerprint supplied in the approved dispatch.

The protected publication job uses GitHub's ephemeral repository token
for the journal and release assets. Its Actions read, Deployments write
and Contents write permissions replace two long-lived credentials.
Contents write can also change refs. The job and its pinned actions
share a runner and token capability. They are one trust boundary,
including for the Pages secret used by the publisher step. The checked-out
publisher logs and links release artefacts, but performs no ref writes.
The tag phase has its own guarded ref write.

## Independent review

First-party Claude Code Opus 5.5 statically reviewed
`27120b015a52721104f36bbfeb4434300e9f6c30`, then
`a4a2046c89b5b9352282f155aa06782a547acbc1`, then
`4af9ba400cc64ecb7f087ec01a16ba481a515055`. The scope was the
workflow, source identity, fingerprint, and permission boundary. The
source and Git checkout were mounted read-only. The final pass found
no blocking issues. Retained source comments still describe the
previous read-only token. Those comments cannot describe the new
job's write capability, and the approved release source stays
byte-identical. The earlier-step trust boundary is documented above.
The tag action's write phase uses the existing pinned composite and its
shared toolchain. No production workflow ran in independent review.

Local workflow lint, six package shell suites and the loopback
controller passed. An exact-source unsigned FreeBSD preflight
built and installed `0.1.0` for `FreeBSD:15:amd64` and passed the
installed package checksum check. That fixture did not establish
a production tag, key, asset or public feed.

The approval required for this patch is the exact bootstrap code and
its job-level permission boundary. The first release already has
owner approval.

## Retained bundle preparation

Build against the verified release tag. Sign the candidate catalogue
with native `pkg repo` using the protected release key. Use
`scripts/feed-manifest.sh` for the package and catalogue digest record.
The candidate's `generation.json` binds the SHA-256 of `release.json`.
The first recovery bundle retains the identical package bytes and
serves no pkg catalogue or metadata. Retain both archives by SHA-256
and seed `advertised-packages.json` with the empty history.

Use Cloudflare's pinned Pages asset hash for each rendered path.
It hashes the base64 contents followed by the filename extension
without the dot and takes the first 32 hex digits of BLAKE3. The provider
helper uses `blake3-wasm@2.1.5`. Prepare the manifest from the signed bytes,
before archiving. Verify the archive contents with `scripts/feed-payload.sh`
and validate the manifest with `scripts/feed-pages-assets.mjs --validate`.
This hash identifies provider upload assets. Release verification
continues to use the separate package, catalogue and archive SHA-256s.
[Cloudflare hash source](https://github.com/cloudflare/workers-sdk/blob/4bca70b301302b018ca28c53af0813de430bedd6/packages/deploy-helpers/src/deploy/helpers/hash.ts)
