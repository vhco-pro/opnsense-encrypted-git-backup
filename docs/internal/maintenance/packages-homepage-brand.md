# Maintenance: Packages homepage branding

## Definition

Outcome: Publish the approved homepage refresh, sliding theme switch and scalable VH & Co mark.

Preserved contract: The official static-site workflow owns website delivery. The signed package feed, catalogue paths and signing identity keep their existing delivery path.

Task base: `dd5a1983f69438c744dfcd3b6c4bd68a4e756e25`.

Affected paths: `web/packages/` and `tests/packages/` for the page, public asset list and tests, and `docs/installation.md` for the signing link target.

Verification inputs: `.github/workflows/packages-site.yml`, `package.json`, `bun.lock`, `web/packages/wrangler.toml` and the website source and test paths above.

Proposed change: Use a sliding theme switch and the SVG traced from the existing logo. Keep the legacy PNG. Display the existing release fingerprint as a reference, require independent confirmation before setup and link to the signing section in the installation guide.

Required checks: `bun run packages:verify`, `actionlint .github/workflows/packages-site.yml`, `git diff --check`, and read back the signing section and the packaged SVG. Inspect screen captures in both themes and browser engines. Download the published v0.1.0 public key and derive the displayed DER SHA-256. Verify the public site through the existing workflow after merge.

## Evidence

The previous main homepage used the PNG for its large mark. The 460-pixel canvas has only 237 × 262 pixels of artwork. The replacement SVG keeps the original proportions, and the existing PNG remains available.

At `8b31dfd7c099f97a6771b7dfb109dfedde935a9e`, `bun run packages:verify` passed five Bun cases, the scanner and native Wrangler restoration checks, and 49 browser cases. Firefox skipped the Chromium-only zoom case. Actionlint and Git whitespace checks passed.

The focused correction asserts the existing independent trust requirement. The expected instruction was absent from the earlier page source and present after correction. The first baseline browser attempt hit a loopback connection refusal, so it supplies no behavioral failure evidence. The corrected browser run passed all six signing, fingerprint and native byte/media cases across Chromium and Firefox.

The public `feed-signing-public.pem` from the v0.1.0 GitHub release yielded `96a1a891e63c16061d968d9d1c64105d14ab64e6e9201b1c2a6dff989df06837` via `openssl pkey -pubin -outform DER | sha256sum`. That value matches both the page and the existing guide. The new guide heading matches the browser link fragment.

The full aggregate reran on unchanged `caf685d5dad907390758552e979a7c882533e9b9` (tree `eba3380d20a121490628ae2153fbabd364d6b75d`). Five Bun tests, the native scanner and restoration checks, and 49 browser scenarios passed. The Firefox Chromium-only zoom case remained skipped. The same run passed actionlint, diff whitespace validation, the signing link target, SVG digest and release-key digest comparisons.

The exact-run browser suite wrote 24 homepage screenshots. Both engines showed the switch in its light and dark positions, readable signing and setup content, and the vector mark with the original layout proportions. I inspected the matrix at all six sizes. Additional Chromium and Firefox captures confirmed that native Wrangler returned HTTP 404 with a visible home link in desktop dark and mobile light. The short dark error page has the existing stylesheet's repeating radial background.

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

### R-2

Isolation: tool-disabled source packet.

```text
MODEL: claude-opus-5-5
TARGET: caf685d5dad907390758552e979a7c882533e9b9

FINDING
severity: blocking
category: missing input
location: review packet
summary: The packet does not supply the engineering-docs revision, a bound repository identity or the diff base.
evidence: The canonical procedure lists repository, commit, maintenance record, authorized outcome and engineering-docs revision as required inputs. The packet gives the target commit, a diff and the record. It names no engineering-docs revision, so no engineering pages can be read at a verified revision. The repository is inferable only from links in the page source, such as `vhco-pro/opnsense-encrypted-git-backup`. The diff carries no stated base. The record declares task base `dd5a1983f69438c744dfcd3b6c4bd68a4e756e25`, but nothing in the packet shows that the diff was produced from that base to this target.
required action: Supply the engineering-docs revision, the repository identity and a diff produced explicitly as `dd5a1983f69438c744dfcd3b6c4bd68a4e756e25..caf685d5dad907390758552e979a7c882533e9b9`. Then rerun the review.

FINDING
severity: blocking
category: scope / source equivalence
location: web/packages/public/_site/style.css; web/packages/public/_site/page.js
summary: The packet does not show whether the stylesheet changed or that the browser inputs not in the diff are source-equivalent to the task base.
evidence: The diff contains no `style.css` entry. A separate excerpt titled "Scoped CSS switch and reduced-motion rules" is supplied without a path, blob ID or diff context. The target markup introduces `shell`, `github-link`, `platform`, `secondary-links`, `fingerprint`, `site-footer`, `footer-brand` and glyph content in `.theme-sun` and `.theme-moon`. The changed tests require `.hero-mark` to be hidden at 680 pixels or narrower, label and address alignment, and a 28-pixel thumb offset. These behaviours depend on stylesheet rules. One of two things follows. Either `style.css` changed and the diff is incomplete, or it is unchanged and the excerpt does not show the rules the tests depend on. In either case, unchanged browser inputs such as `page.js` cannot be confirmed equivalent to the base from this packet.
required action: Provide the complete base-to-target diff including `style.css`, or blob IDs at base and target for each website and verification input under `web/packages/` and `tests/packages/`. Also provide blob IDs for `.github/workflows/packages-site.yml`, `package.json`, `bun.lock` and `web/packages/wrangler.toml`.

FINDING
severity: blocking
category: missing execution evidence
location: docs/internal/maintenance/packages-homepage-brand.md:17-29
summary: The required checks have no execution evidence bound to this target after the trust-guidance correction.
evidence: The record says the full `bun run packages:verify` passed at `8b31dfd7c099f97a6771b7dfb109dfedde935a9e`. R-1 reviewed that commit and found the weakened signing guidance. The correction then changed `web/packages/public/index.html` and `tests/packages/page.spec.mjs`, both of which are verification inputs. The record cites only a focused six-case browser run after the correction. The supplied runner output shows a six-case run and a 49-passed, 1-skipped run. Neither names a commit, tree or record object, so neither can be tied to this target. The 49-case result matches the count the record attributes to `8b31dfd`. The packet has no output for the five Bun cases, the scanner, the native Wrangler restoration check, `actionlint .github/workflows/packages-site.yml`, `git diff --check`, or the read-back of the signing section and packaged SVG at this target. The bare line `96a1a891…df06837` is not accompanied by the command, the downloaded key's source or the key bytes' digest, so it does not show the required derivation from the published v0.1.0 `feed-signing-public.pem`.
required action: Have the fixed operator runner execute every required check against `caf685d5dad907390758552e979a7c882533e9b9`, including the Chromium and Firefox projects, the Bun cases, the scanner, the restoration check, actionlint, `git diff --check`, both read-backs and the key-fingerprint derivation. The output must identify the checked source and record objects. Record those results before the review can pass.
```

### R-3

Isolation: tool-disabled source packet.

```text
MODEL: claude-opus-5-5
TARGET: caf685d5dad907390758552e979a7c882533e9b9

FINDING
severity: blocking
category: missing execution evidence / visual review
location: docs/internal/maintenance/packages-homepage-brand.md:17; web/packages/public/index.html; web/packages/public/_site/style.css
summary: No representative screenshots of the changed layouts were captured or inspected at this target.
evidence: The change replaces almost the whole stylesheet. It restructures the header, hero, repository card, setup cards and footer, adds an SVG mark and changes the theme switch glyphs. The pinned frontend standard at vhco-pro/docs@1edeb5f3 says to "Capture representative viewport screenshots for each changed layout and important transition state, then inspect them before declaring the UI complete". It also says "Tests and reviewed captures serve different purposes; record both results." The fixed operator log contains only geometry and behavior assertions: 49 passed, with the Firefox zoom case skipped. The record's Required checks omit screenshot capture and review. Its Evidence has no capture or visual-review result for either theme at any viewport in the matrix. Geometry assertions do not cover typography, contrast, spacing, the rendering of the ☼/☾ glyphs or the appearance of the traced SVG. The `packaged SVG` read-back is evidenced only by a SHA-256 line, which does not show inspection of its rendering.
required action: Capture light and dark screenshots of the changed page at the project viewport matrix, including the theme switch in both states and the 404 page. Inspect them, record the results in the record and add screenshot review to its Required checks.

FINDING
severity: minor
category: record accuracy
location: docs/internal/maintenance/packages-homepage-brand.md:23-29; docs/internal/maintenance/packages-homepage-brand.md:64-66
summary: The record's Evidence cites an earlier commit and does not bind the checks to this target.
evidence: The Evidence section reports check results "At `8b31dfd7c099f97a6771b7dfb109dfedde935a9e`", not at `caf685d5`. It records no response to R-1's three findings. The fixed operator log does show the required commands passing at `caf685d5` with tree `eba3380d`. That log is not referenced in the committed record, and State still reads "Review pending."
required action: Update the Evidence section to cite the operator run at `caf685d5` and tree `eba3380d`. Record how each R-1 finding was resolved, then update State in a later commit.
```

### R-4

Isolation: read-only file tool. Capture paths and committed evidence binding were unavailable to the reviewer.

```text
MODEL: claude-opus-5-5
TARGET: caf685d5dad907390758552e979a7c882533e9b9

FINDING
severity: blocking
category: missing input / visual review
location: review working directory /tmp/vhco-site-delivery.4Uk7Hj/review; docs/internal/maintenance/packages-homepage-brand.md (prepared update)
summary: I could not open the Chromium and Firefox matrix PNGs or the Chromium light and Firefox dark 404 captures, so I cannot check R-3's visual-review finding myself.
evidence: The packet asks for the screenshots in the working directory but gives no file names. I have only a file-read tool, which cannot list a directory. Reading the directory returned `EISDIR`. Reading `chromium-matrix.png`, `firefox-matrix.png` and `README.md` returned "File does not exist". The pinned frontend standard at vhco-pro/docs@1edeb5f3 says to "Capture representative viewport screenshots … then inspect them" and "A failing visual review leaves the affected UI work open even when the browser assertions pass." The record's statement that the captures were inspected is not execution evidence. No reviewed capture is available here to confirm the switch positions, glyphs, SVG rendering, contrast or the 404 layout and background.
required action: Supply the exact absolute paths of the matrix PNGs and the 404 captures. List each file with its SHA-256 and the run that produced it at commit `caf685d5` and tree `eba3380d`. Then rerun this review.

FINDING
severity: blocking
category: record binding
location: docs/internal/maintenance/packages-homepage-brand.md
summary: The record update with the screenshot evidence is not bound to any Git object.
evidence: At `caf685d5` the committed record blob is `db5b76ce455d377d512937b1ee8fd92bf3308dd8`. That blob has no screen-capture item in Required checks, no screenshot Evidence and no R-2 or R-3 entries. The latest record exists only as pasted text, labelled "prepared", with no commit, ref or blob ID. The paired-record procedure needs a `record_target` repository, ref and path, and it reads the committed Definition there. The Definition's Required checks also change in this update, because screen-capture inspection is added. That is a change to a review input, not append-only bookkeeping.
required action: Commit the record update. Supply its commit and blob ID as `record_target`, and confirm that the source paths are unchanged from `caf685d5`. Then rerun the review against that pair.
```

## State

Review pending.
