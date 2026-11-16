# VHCO Packages homepage

The static homepage lists VHCO package repositories and links to their installation and signing guidance. HTML, CSS and the small theme/copy script live in `public/`. Its deployment uses the official Cloudflare Wrangler action, independently of package releases.

## Develop

Use the repository's pinned Bun version, Wrangler's supported Node.js runtime, Docker with daemon access, and the locked development tools. Wrangler itself runs under its native Node.js launcher.

```sh
bun install --frozen-lockfile --ignore-scripts
bun x playwright install chromium firefox
bun run packages:preview
```

The native Wrangler preview listens on `http://127.0.0.1:39441`. Stop it with Ctrl+C. Wrangler's ignored `.wrangler/` cache can remain between runs. Use the installed remote-gui procedure when sharing this local preview with the owner.

## Verify

```sh
bun run packages:verify
```

The aggregate command checks the exact public file list and native configuration, runs Bun tests, the pinned Gitleaks source scan and synthetic exclusion cases, exercises stale/restored content through native Wrangler, then runs Chromium and Firefox. Its owned native fixture processes and temporary restoration/scanner data are stopped and removed automatically. Browser captures and failures remain under ignored `work/packages-browser/`.

Run a focused browser case while repairing a failure.

```sh
bun run packages:browser --grep 'theme switch'
```

The source scan uses `.gitleaks.toml`, extending upstream defaults and excluding generated Wrangler state and dependencies. Upstream defaults exclude scanner configuration, images and fonts. Review the configuration and the explicit public asset list directly. The workflow is the authoritative scanner image pin, and the local command reads it through Bun's YAML parser.

## Publication

`.github/workflows/packages-site.yml` verifies affected PRs without Cloudflare credentials. An enabled main push or main-only manual dispatch deploys through the protected `packages-site-production` environment. It uploads/deploys a native Cloudflare version tagged with the run and attempt, then compares public bytes and media types against the checkout.

```sh
bun run packages:smoke -- https://pkg.vhco.pro
```

Lab owns Worker creation, routes, the main-only environment and its credential. Homelab deployment procedures and private inputs stay in VitePress and Lab. The workflow publishes site content only. Existing package publication, signed catalogue and GitVersion calculations retain their own workflow.

Restore earlier page files in a new main commit to recover through the same verification and deployment pipeline. GitHub and Cloudflare retain the source/run/deployment history.

## Assets and rights

The approved design snapshot remains in [the prototype directory](../../docs/prototypes/vhco-packages/README.md). Production assets retain the [VHCO logo notice](public/_site/VHCO-LOGO-NOTICE.txt) and [Inter font licence](public/_site/INTER-LICENSE.txt). Additional repository entries are authored as ordinary static content.
