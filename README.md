# OPNsense encrypted Git backup

A native OPNsense backup provider for encrypted configuration snapshots in Git.

The project is in design. The [feature specification](docs/specs/native-encrypted-git-backup.md)
describes native integration, encryption, migration, packaging and validation.

## Intended integration

Configure the provider through OPNsense's Backups screen and run it through the
native backup and scheduling interfaces. Reuse OPNsense's encrypted export format
for complete configuration recovery.

## Design references

- [OPNsense plugin development](https://docs.opnsense.org/development/examples/helloworld.html)
- [Native Git backup](https://docs.opnsense.org/manual/git-backup.html)
- [Existing upstream encryption discussion](https://github.com/opnsense/plugins/issues/5833)

Licensed under [BSD-2-Clause](LICENSE).
