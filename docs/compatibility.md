# Runtime compatibility

The first target is OPNsense Community Edition 26.7.9_1 on amd64. The 26.7 series uses FreeBSD 15.1 and PHP 8.5. The upstream catalogue identified the package ABI as `FreeBSD:15:amd64` and the PHP package as `php85-8.5.12_2`. The same catalogue lists Git 2.56.1, OpenSSH 10.6.p2,1, OpenSSL 3.5.9 and pkg 2.8.4_1,1. [Release notes](https://docs.opnsense.org/releases/CE_26.7.html) · [Package catalogue](https://pkg.opnsense.org/FreeBSD:15:amd64/26.7/latest/packagesite.pkg)

| Input | Source revision |
| --- | --- |
| Core 26.7.9 | [228ab68d54513046f79bc36d7f583936922d1951](https://github.com/opnsense/core/commit/228ab68d54513046f79bc36d7f583936922d1951) |
| Core hotfix | [e1020455a7bbb8a94ecdcec4fa94cd2ee3bdbbc1](https://github.com/opnsense/core/commit/e1020455a7bbb8a94ecdcec4fa94cd2ee3bdbbc1) |
| Plugins build framework | [a01a2e8cef738b3762830a7bbfc6e857384328f1](https://github.com/opnsense/plugins/commit/a01a2e8cef738b3762830a7bbfc6e857384328f1) |
| Release builder | [877ba55e86d20c4e66fb56770cb2bfd8538a4c9e](https://github.com/opnsense/tools/commit/877ba55e86d20c4e66fb56770cb2bfd8538a4c9e) |

The catalogue inspected on 2026-11-14 had SHA-256 `5fa24685f220b51c042c9cebf29eeb8543d43f529e59672afd49e0c68918f20a`. The hotfix diff changes only `src/opnsense/scripts/auth/add_user.php`. The pinned builder selects FreeBSD 15.1, PHP 8.5 and OpenSSL 3.5.

## Native contracts

- `BackupFactory` instantiates concrete `OPNsense\Backup\IBackupProvider` classes discovered alongside it. The interface declares five methods without native argument or return types, including `setConfiguration($conf)`. The Backups form calls that method with the provider fields, displays its validation errors and calls `backup()` when settings save successfully and the provider is enabled.
- The remote backup command calls enabled providers, catches ordinary exceptions from `backup()` and reports aggregate failure. The core cron registration calls the existing configd action with a random delay.
- Native restore calls `Base::decrypt()` with the default `config.xml` tag. The native `Base` implementation creates plaintext and password files in its application temporary directory, so provider calls must establish a private umask before encryption and round-trip verification.

These observations come from source inspection. Appliance verification will record installed versions, package lifecycle, cron execution, privileges and native restore.

## Disposable appliance observations

A QEMU guest with no network adapter booted the official 26.7 serial image. Its compressed SHA-256 matched `259b441646f1b0d77075a7281e368fe7f4c980360498ed6bc23740bd83c67e32`. The image reported FreeBSD 15.1-RELEASE-p1 and PHP 8.5.8.

At source revision `1753e0bd6ee1c142b7844ad5d2874dada3609b6b`, the pinned plugins framework ran `make package`. The framework warned that the staged archive lacked Git metadata. The build supplied `PLUGIN_HASH` with the source revision and produced `os-encrypted-git-backup-0.1.pkg`. `pkg add` installed the package and migrated its model to 1.0.0. `pkg info -l` showed 12 runtime files and version metadata entries in total. The native factory discovered the disabled provider, and a synthetic XML export passed byte-for-byte decryption using the appliance's native library. `pkg repo` generated a signed catalogue with a disposable local key. The package SHA-256 was `9d0856adc47932f82a95f60b2dcf15661762465377b69fbea069b17447a9c209`.

The pinned hotfix, native restore import, upgrade and removal, signed client install and update, and browser journeys remain open.
