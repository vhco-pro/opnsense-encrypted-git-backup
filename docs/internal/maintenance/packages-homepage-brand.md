# Maintenance: Packages homepage branding

## Definition

Outcome: Publish the approved homepage refresh, sliding theme switch and scalable VH & Co mark.

Preserved contract: The official static-site workflow owns website delivery. The signed package feed, catalogue paths and signing identity keep their existing delivery path.

Task base: `dd5a1983f69438c744dfcd3b6c4bd68a4e756e25`.

Affected paths: `web/packages/` and `tests/packages/` for the page, public asset list and tests, and `docs/installation.md` for the signing link target.

Verification inputs: `.github/workflows/packages-site.yml`, `package.json`, `bun.lock`, `web/packages/wrangler.toml` and the website source and test paths above.

Proposed change: Use a sliding theme switch and the SVG traced from the existing logo. Keep the legacy PNG and add the signing heading linked from the page.

Required checks: `bun run packages:verify`, `actionlint .github/workflows/packages-site.yml`, `git diff --check`, and read back the signing section and the packaged SVG. Verify the public site through the existing workflow after merge.

## Evidence

The previous main homepage used the PNG for its large mark. The 460-pixel canvas has only 237 × 262 pixels of artwork. The replacement SVG keeps the original proportions, and the existing PNG remains available.

## Reviews

## State

Review pending.
