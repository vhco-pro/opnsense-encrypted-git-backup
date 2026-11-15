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

## Public CI permission check

GitHub recorded a startup failure at `f1d0311` and started no PHP workflow
jobs. A read-only caller cannot invoke a reusable workflow that declares
write permissions. Moving the unchanged fixture jobs to
`feed-fixture.yml` keeps both automatic CI and manual fixture dispatch
read-only. The production dispatch remains separate with the same
protected jobs and concurrency group.

First-party Opus 5.5 independently reviewed that split at
`707d9b8528eca0c575faca4fb14c2e97d59137d8` with no findings above
informational level. Its read-only review checked the job definitions and
permission changes. Hosted verification runs separately.
[Initial startup failure](https://github.com/vhco-pro/opnsense-encrypted-git-backup/actions/runs/43723162775)

## First production submission

The shared calculation on reviewed source `d646f204` produced `0.1.0`.
The protected tag job repeated the check. GitHub rejected its push because
the Actions token lacked permission to introduce the historical workflow
revision at the new ref. The pinned shared tag script then created
`v0.1.0` from the exact source using the owner's existing CLI credential.
The remote annotated tag resolves to `d646f204`. No credential scopes changed.
[Protected tag attempt](https://github.com/vhco-pro/opnsense-encrypted-git-backup/actions/runs/43728477169)

An owned disposable native client verified the production-signed catalogue
before upload. The candidate and bootstrap recovery retain identical package
bytes. The recovery excludes native catalogue and metadata paths. Both
archives and the public key passed independent readback from the draft release.

The first protected publication recorded the submission before creating Pages
deployment `e658b608-f5ee-4256-bcf8-e987ebaef531`. The deployment reported
success and served the matching manifest, catalogue and package at
`https://pkg.vhco.pro`. The public package SHA-256 is
`b0a23361eaa9ffa73ccc53234f9254b629912f0a42abb3a7eaf6fe2b77550064`.
The catalogue SHA-256 is
`cc7506ebb4b978b09f8a60034d1d2371bc319d85948a206af44804740ecfd66c`.
The downloaded package passed an install and checksum check on a disconnected
OPNsense appliance with the plugin initially absent.
[First protected publication](https://github.com/vhco-pro/opnsense-encrypted-git-backup/actions/runs/43729204119)

The closure run stopped before native verification because the Cloudflare
deployment list rejected `per_page=100` with error 8000024. A read-only query
at `per_page=25` returned the single matching deployment. The publisher now
checks that the first page is complete before correlating an attempt.
The package checkout still targets its approved source. The protected caller
uses publication scripts from its own workflow commit so delivery fixes can
reconcile an older release without rebuilding or moving its tag.
[Failed reconciliation](https://github.com/vhco-pro/opnsense-encrypted-git-backup/actions/runs/43729489795)

First-party Claude Code Opus 5.5 reviewed the repair in a read-only
checkout. The first pass found a missing completeness check in the
definitive rejection path and an outdated documented limit. The follow-up
at `70b3fa55725a7aaa9b67e7ee85e067d679b8683e` found no remaining
issues in the scoped changes. The static review did not execute tests.
The local loopback regression reproduced the HTTP 400 and premature
rejection closure before their fixes, then passed with no new request
or closure when the listing was incomplete. Hosted native verification
runs separately.
