# Maintenance: Packages homepage branding

## Definition

Outcome: Publish the approved homepage refresh, sliding theme switch and scalable VH & Co mark.

Preserved contract: The official static-site workflow owns website delivery. The signed package feed, catalogue paths and signing identity keep their existing delivery path.

Task base: `dd5a1983f69438c744dfcd3b6c4bd68a4e756e25`.

Affected paths: `web/packages/` and `tests/packages/` for the page, public asset list and tests, and `docs/installation.md` for the signing link target.

Verification inputs: `.github/workflows/packages-site.yml`, `package.json`, `bun.lock`, `web/packages/wrangler.toml` and the website source and test paths above.

Proposed change: Use a sliding theme switch and the SVG traced from the existing logo. Keep the legacy PNG. Display the existing release fingerprint as a reference, require independent confirmation before setup and link to the signing section in the installation guide.

Required checks: `bun run packages:verify`, `actionlint .github/workflows/packages-site.yml`, `git diff --check`, and read back the signing section and the packaged SVG. Download the published v0.1.0 public key and derive the displayed DER SHA-256. Verify the public site through the existing workflow after merge.

## Evidence

The previous main homepage used the PNG for its large mark. The 460-pixel canvas has only 237 × 262 pixels of artwork. The replacement SVG keeps the original proportions, and the existing PNG remains available.

At `8b31dfd7c099f97a6771b7dfb109dfedde935a9e`, `bun run packages:verify` passed five Bun cases, the scanner and native Wrangler restoration checks, and 49 browser cases. Firefox skipped the Chromium-only zoom case. Actionlint and Git whitespace checks passed.

The focused correction asserts the existing independent trust requirement. The expected instruction was absent from the earlier page source and present after correction. The first baseline browser attempt hit a loopback connection refusal, so it supplies no behavioral failure evidence. The corrected browser run passed all six signing, fingerprint and native byte/media cases across Chromium and Firefox.

The public `feed-signing-public.pem` from the v0.1.0 GitHub release yielded `96a1a891e63c16061d968d9d1c64105d14ab64e6e9201b1c2a6dff989df06837` via `openssl pkey -pubin -outform DER | sha256sum`. That value matches both the page and the existing guide. The new guide heading matches the browser link fragment.

## Reviews

### R-1

Isolation: tool-disabled source packet. No checks ran in the review context.

```text
MODEL: claude-opus-5-5
TARGET: 8b31dfd7c099f97a6771b7dfb109dfedde935a9e

FINDING
severity: blocking
category: security / public-contract
location: web/packages/public/index.html:109-113; docs/installation.md:9-12
summary: The homepage now publishes the signing-key fingerprint and makes independent verification optional.
evidence: The new signing section tells readers to "Verify the v0.1.0 release key against this SHA-256 fingerprint". It then says "If you require an independent trusted channel, confirm it through a maintainer contact you already trust." The fingerprint is served by the same site deployment that replaced the `pkg.vhco.pro` eyebrow, which is the catalogue host named in `docs/installation.md`. A single compromise of that origin or its deploy path could replace both the feed and the value readers check it against. `docs/installation.md:11-12` at this target still requires confirmation "through an independent trusted channel before configuring the client". The page now contradicts it. The Definition's preserved contract says the signing identity keeps its existing delivery path. Its proposed change covers only a signing heading and link, not publishing a fingerprint.
required action: Restore guidance that requires independent confirmation before configuring the client. Alternatively, obtain an owner-approved Definition change that declares the new signing-identity delivery path and its trust rationale.

FINDING
severity: blocking
category: test adequacy / correctness
location: web/packages/public/index.html:112; tests/packages/page.spec.mjs:185-189; tests/packages/page.spec.mjs:153-158
summary: The published fingerprint is not bound to the release key, and the existing guidance test no longer detects weakened guidance.
evidence: The fingerprint `96a1a891…df06837` is hard-coded in the page. The Definition and Evidence do not cite a source for it. No check derives it from `feed-signing-public.pem` in the v0.1.0 release or from any repository artifact. The new test only asserts that the same literal string appears in the page. The test "signing guidance directs readers to independent key verification" still passes because it only matches the substring "independent trusted channel", which now appears in a conditional sentence.
required action: Add a check that ties the displayed value to the actual release public key's DER SHA-256. Make the guidance assertion fail when independent verification is presented as optional.

FINDING
severity: blocking
category: missing execution evidence
location: docs/internal/maintenance/packages-homepage-brand.md:17-21
summary: None of the required checks has execution evidence at this target.
evidence: The record requires `bun run packages:verify`, `actionlint .github/workflows/packages-site.yml`, `git diff --check`, and a read-back of the signing section and packaged SVG. The Evidence section contains only design rationale. It has no command output, runner identity or target object. This review was source-only and executed nothing. The change also modifies verification inputs: `web/packages/restoration-check.ts` replaces the stale-page marker with an HTML comment, `verify.ts` adds the SVG to the asset list, and the smoke count changes from 8 to 9. These need a real run to show they still detect what they claim.
required action: Have a fixed operator runner execute the required checks against this exact commit, including the Chromium and Firefox browser projects. Record the results before the review can pass.
```

## State

Review pending.
