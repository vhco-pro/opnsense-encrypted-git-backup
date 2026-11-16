# OPNsense encrypted Git backup

A native OPNsense backup provider for encrypted configuration snapshots in Git.

The first implementation is merged. Configure it through OPNsense’s Backups
screen and use the native scheduling interface. Recovery uses OPNsense’s
encrypted configuration export format. See the [feature specification](docs/specs/native-encrypted-git-backup.md)
for the integration, migration and verification scope.

## Installation and release status

[Version 0.1.0](https://github.com/vhco-pro/opnsense-encrypted-git-backup/releases/tag/v0.1.0)
is available from the signed package repository at `https://pkg.vhco.pro`.
The first release targets the compatible OPNsense runtime on FreeBSD amd64.
Verify the repository's signing key before installing.

See the [installation guide](docs/installation.md) for installation requirements,
the [compatibility notes](docs/compatibility.md) for the verified runtime, and
the [recovery guide](docs/recovery.md) for restore and rollback.

## Design references

- [OPNsense plugin development](https://docs.opnsense.org/development/examples/helloworld.html)
- [Native Git backup](https://docs.opnsense.org/manual/git-backup.html)
- [Existing upstream encryption discussion](https://github.com/opnsense/plugins/issues/5833)

Plugin code is licensed under [BSD-2-Clause](LICENSE). The VH & Co logo uses
its [logo-specific notice](web/packages/public/_site/VHCO-LOGO-NOTICE.txt).
This independent plugin uses
OPNsense interfaces. Upstream submission is a separate maintainer
decision and would require upstream review.

## Package homepage

The [VHCO Packages homepage](https://pkg.vhco.pro) lists repositories and setup guides.
See [homepage development and verification](web/packages/README.md) for its native preview,
browser checks and independent Cloudflare pipeline.
