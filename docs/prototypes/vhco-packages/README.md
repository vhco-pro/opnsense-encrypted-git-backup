# VHCO Packages design preview

This static prototype accompanies the [landing-page specification](../../specs/vhco-packages-landing-page.md).
It uses the published OPNsense repository as its initial entry.

Start the owned loopback preview from the repository root.

```sh
bun docs/prototypes/vhco-packages/preview.mjs
```

The command prints a JSON readiness record containing its allocated loopback URL.
Use the installed remote-gui share procedure to obtain an owner-restricted Tailscale preview.
The process serves only the seven explicitly named page assets, including a top-level `404.html`, and serves that document with HTTP 404 for other paths.
Stop it with Ctrl+C when the review ends.

Install the repository's existing pinned browser-test dependencies with `bun install --frozen-lockfile --ignore-scripts`.
Run the focused prototype checks against the URL printed by the preview process.

```sh
VHCO_PACKAGES_PREVIEW_URL=http://127.0.0.1:<allocated-port> bun node_modules/@playwright/test/cli.js test --config docs/prototypes/vhco-packages/playwright.config.mjs
```

The suite uses Chromium and Firefox at six viewports in both themes.
It also checks the explicit 404 response, independent-channel signing guidance, URL copying and clipboard denial after success, theme persistence, keyboard navigation, unavailable storage and reading with JavaScript disabled.
Screenshots and failures are retained under the ignored `work/packages-preview/` directory.
Chromium's copy case reads the resulting clipboard, and Firefox's observes the native write completing and its UI feedback.
The production workflow and actual browser-zoom checks remain in the feature's implementation test plan.

The browser prototype includes light and dark themes, a repository URL copy control and the actual public documentation links.
Page content and navigation work with JavaScript disabled.
The production page and its publication/recovery integration follow the accepted feature specification.

## Asset sources

- `vhco.png` copies the existing VH & Co logo from VitePress `app/public/landing/vhco-github.png`.
  Its SHA-256 is `bd5d562d7828717a0dd81bfd03694c51249ec055a9351e1ccca8e3411efc9616`.
- `inter-latin.woff2` copies the Inter variable roman Latin font bundled with the site's VitePress 1.6.4 installation.
  Its SHA-256 is `f7ab715caa2c78facb4334b211c81ee66f037cf9c99ca3f24acd543e84a93278`.
  The upstream source is [VitePress's font asset](https://github.com/vuejs/vitepress/blob/v1.6.4/src/client/theme-default/fonts/inter-roman-latin.woff2).
  [INTER-LICENSE.txt](INTER-LICENSE.txt) preserves the font's SIL Open Font License.
- Colours and typography follow the observed [VHCO website](https://vhco.pro/) and its VitePress theme source.

## Review scope

The private preview demonstrates the proposed layout and browser interactions.
The live publisher, signed catalogue and native package verification are separate implementation checks named by the specification.
