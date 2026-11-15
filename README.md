# OPNsense encrypted Git backup

A native OPNsense backup provider for encrypted configuration snapshots in Git.

The first implementation is merged. Configure it through OPNsense’s Backups
screen and use the native scheduling interface. Recovery uses OPNsense’s
encrypted configuration export format. See the [feature specification](docs/specs/native-encrypted-git-backup.md)
for the integration, migration and verification scope.

## Installation and release status

The first release and signed package feed are pending. The feed
will provide a signed package catalogue and packages for installation and
upgrades through native OPNsense Firmware or FreeBSD pkg. The Cloudflare Pages
publication workflow has been exercised with disposable fixtures.

See the [installation guide](docs/installation.md) for installation requirements,
the [compatibility notes](docs/compatibility.md) for the verified runtime, and
the [recovery guide](docs/recovery.md) for restore and rollback.

## Design references

- [OPNsense plugin development](https://docs.opnsense.org/development/examples/helloworld.html)
- [Native Git backup](https://docs.opnsense.org/manual/git-backup.html)
- [Existing upstream encryption discussion](https://github.com/opnsense/plugins/issues/5833)

Licensed under [BSD-2-Clause](LICENSE).
