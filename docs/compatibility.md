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

A second disconnected guest built the source at `c7ae001` and installed it from a signed `file://` fixture repository. The native client logged invalid signature and removed the repository when configured with the wrong key, although `pkg update` returned success. It rejected a corrupted package. After the guest's installed `opnsense` package reached 26.7.9_1 and PHP reached 8.5.12, a rotated fixture key authenticated a catalogue containing an upgrade from 0.1 to 0.2. The guest still used the installer kernel at FreeBSD 15.1-RELEASE-p1. This establishes the observed client behavior on that mixed runtime.

On the second guest, a synthetic encrypted export was decrypted using the native backup library and passed to `Config::restoreBackup()`, the full-configuration import method used by Backups. The restored marker was present in `/conf/config.xml`. This exercised the native restore method through PHP. The browser upload and restore journey remains open.

## Security checks

The feature adopts the [PHP security convention](https://github.com/vhco-pro/docs/blob/1edeb5f32d868bbe761ef3221f350634cd6ff022/conventions/php.md#security-checks). The commands and pinned tool installation are in `tests/security/`. Composer 2.11.2 audited 28 developer and transitive packages with no advisories or abandonment reported. The lock contains zero production packages.

Semgrep CE 1.185.0 ran three local rules against 15 tracked PHP files with zero findings or parse errors. Its analysis is limited to the checked patterns and intra-function request taint. A synthetic file hit each rule, an escaped output fixture passed, and a missing rules file failed. The Python prerelease scan crashed and its output was retained. The successful run used system Python. Gitleaks 8.21.2 scanned the feature Git range and `src` with full redaction and zero findings. Its synthetic token and missing-input probes both failed as expected.

Native pkg 2.3.1 audited installed packages with FreeBSD VuXML snapshot SHA-256 `76d5b3f677d5171048bd4fd9671c6b3853408ab8ed2e3e7599a29c435a193c26`. The mixed-version fixture returned exit 1 with 11 affected packages. A missing database also returned exit 1 and a different diagnostic. Querying the 11 corresponding versions from the current upstream catalogue still reported CVE-2025-15367 on `python313-3.13.18`. The catalogue candidate query does not establish the installed target's vulnerability status.

The follow-up scan split filesystem and HTML taint. Its positive probe flags a request-controlled path even after HTML escaping. Its escaped HTML probe passes. A repository-level ignore file replaces Semgrep's default test exclusions. The scan then covered all 15 PHP files under `src/` and eight PHP files under `tests/` with zero findings and errors. Non-PHP fixtures and analysis stubs with the `.stub` extension remain outside this PHP scan. The hash-locked scanner environment passed the CI probe script locally, including the distinct Gitleaks finding and error exits.

Additional fixture observations on the installed 26.7.9_1 core package and PHP 8.5.12 with the installer kernel:

- Native configd accepted root-owned 0600 credential files and rejected both a mode-0644 password file and a present legacy capture hook.
- A native model save activated the provider for a synthetic loopback SSH repository. The native configd run returned a commit that matched the remote branch and the verification receipt.
- Chromium and Firefox each verified anonymous status denial, authenticated settings persistence, and a mobile status page with the seeded failed attempt and previous successful receipt. The tests retained screenshots and checked page errors and keyboard focus. Read-only-account, theme, zoom and successful delivery journeys remain open.

## Installed 26.7.9_1 runtime audit

A separate offline appliance installed to its owned disk and booted FreeBSD 15.1-RELEASE-p6 after applying the signed 26.7.9 base and kernel sets. Native pkg upgraded the staged catalogue package closure and installed OPNsense 26.7.9_1, PHP 8.5.12 (package 8.5.12_2), Git 2.56.1, OpenSSH 10.6.p2,1, OpenSSL 3.5.9 and pkg 2.8.4_1,1. The full inventory and PHP extension output are retained in the fixture evidence.

On that installed runtime, `pkg audit -f /tmp/target-vuln.xml` returned exit 1 with one affected package, `python313-3.13.18`. The selected OPNsense catalogue supplies that same version. Python is an appliance dependency and is outside the plugin's PHP backup path. There is no clean installed-runtime audit at the selected catalogue revision. [FreeBSD VuXML advisory](https://vuxml.freebsd.org/freebsd/6d3488ae-2e0f-11f1-88c7-00a098b42aeb.html)

On the installed target, the [exact-source GitVersion run](https://github.com/vhco-pro/opnsense-encrypted-git-backup/actions/runs/43580901279) mapped `0.0.1-alpha.1` to `0.0.1.alpha1`. The native `pkg version -t` comparisons and release identity tests passed. Using that source and version, the pinned framework built the package, and the package manifest and signed catalogue agreed on `0.0.1.alpha1`. The native client installed the signed package, removed it and reinstalled it from the fixture catalogue. The installed runtime audit after adding the plugin still reported only the upstream Python advisory. The first catalogue staging attempt failed because pkg ignored the hidden staging directory. The retry passed with a visible staging directory.

### CVE-2025-15367 disposition

The Python Security Response Team describes POP3 command injection when an application passes user-controlled commands to CPython's `poplib` client. FreeBSD VuXML lists `python313` without a fixed-version bound. The installed fixture contained `python313-3.13.18`, and the corresponding CPython release source still lacks the control-character rejection described by the advisory. [Python security announcement](https://mail.python.org/archives/list/security-announce@python.org/thread/CBFBOWVGGUJFSGITQCCBZS4GEYYZ7ZNE/) · [CPython 3.13.18 source](https://github.com/python/cpython/blob/v3.13.18/Lib/poplib.py) · [FreeBSD VuXML](https://vuxml.freebsd.org/freebsd/6d3488ae-2e0f-11f1-88c7-00a098b42aeb.html)

Source inspection found no POP3 client path in the plugin or pinned OPNsense core PHP and Python sources. The backup path uses PHP, Git, SSH and the native encryption library. That inspection covers those sources and does not establish exposure across every appliance package or deployment. The installed audit remains open pending a supported catalogue fix and a fresh native audit, or an independently reviewed owner disposition. Upgrading the plugin does not update the affected interpreter.

The installed 26.7.9_1 fixture delivered two snapshots over loopback SSH using different encryption key identifiers. Both remote exports decrypted with their corresponding credentials using `opnsense-crypt`. The active tree contained only `config.xml.enc` and `snapshot.json`. The native remote-backup runner exited zero and recorded a verified commit. `Config::restoreBackup()` restored a synthetic full-configuration marker to `/conf/config.xml`, and `configctl cron restart` returned `OK`. A timed cron invocation and failure isolation across providers still need verification.

The offline reconstruction verified the base and kernel signatures. On reboot, OPNsense self-test reported untrusted package sources for pkg and core after their local installation. The reconstructed fixture establishes the observed runtime behaviors and versions. It does not establish trusted firmware upgrade provenance.

## Isolated native run at 05489b6

The disposable QEMU guest `encryptedgit-current-proof` used a writable overlay over the feature-owned appliance image, with no network adapter. The guest reported FreeBSD 15.1-RELEASE-p6, OPNsense 26.7.9_1 and PHP 8.5.12. The pinned plugins framework built exact source `05489b66c5aa8ffcc8ce1c2bc3ad5adbd21cfa1f` as synthetic package `0.0.9.alpha1`, SHA-256 `97dd5274376041c12778577a638f829bfbe3ad6d112712c636450f726e6d284a`. The installed package inventory and console evidence are retained in ignored `work/appliance/current-proof/`.

The native settings save persisted its checkpoint identifier. The fixture rejected a 0644 credential and a present legacy hook without changing the saved configuration. Native configd delivered over loopback SSH, and the remote commit and encrypted artifact matched the local receipt. Native package removal preserved the activation checkpoint and reinstall resumed delivery. The native restore method imported the configuration decrypted from that remote snapshot. A generated cron entry invoked the native backup action at a real minute tick and advanced the remote ref.

The legacy fixture verified a synthetic archive, rejected an export checkpoint after a configuration save, then saved against refreshed evidence. Delivery used the legacy remote tip as parent and left only the encrypted export and metadata in the new tree. The fixture retained archives inside the disconnected guest. Interruption, independently hosted archive recovery and downgrade behavior need separate proof.

The installed audit returned exit 1 with `python313-3.13.18` using local VuXML SHA-256 `353ce8ff41997d69c26163614421b65cfebbc733017dec3f945241c48f5d3c46`. Initial console transfer and fixture runs failed before the checksum-matched scripts, fresh synthetic credentials, correct restore marker and native cron action spelling were in place. The raw console retains those attempts. This run verified direct package removal and reinstallation, with signed-feed client upgrade, browser permissions, scheduling failure isolation and final-source appliance verification still open.

## Upgrade and recovery run at 0314d16

The next boot of the same owned disconnected overlay upgraded synthetic `0.0.9.alpha1` to `0.0.9.alpha2`, built from `0314d16063769c74b430e71872b2283a350a2513`. The new package SHA-256 was `c63fd0029fd039d3d35bddbfe927f2789d543e158fc5b5b0a81b6d48e288c1db`. Native pkg preserved the saved activation checkpoint and pending Git commit. A synthetic sibling provider threw an ordinary exception. The native runner reported aggregate failure while the encrypted provider advanced its remote branch. Old and rotated external passwords each decrypted and restored their corresponding full exports.

The interrupted downgrade fixture withheld the active checkpoint, installed the older encrypted provider and confirmed both native entry points failed without moving the remote or pending ref. The corrected repeat checked that configd was available and returned a structured rejection, then restored the current package and checkpoint and resumed delivery. This does not establish rollback across every input replacement boundary or exclusion of a queued old worker.

Using disposable signing keys, a native pkg client installed the older package from a local signed catalogue, rejected an unrelated signer, then upgraded to the newer package from the trusted catalogue. This fixture uses local catalogue files. It does not exercise the owner-dispatched promotion workflow, signing-key rotation, deployed URL recovery or incompatible ABI. The raw console in ignored `work/appliance/current-proof/next-console.log` retains the first failed build attempt after reboot cleared the temporary checkout and the initial configd startup race.

### Browser and scheduling run on the upgraded fixture

A new writable overlay used the powered-off `0314d16` appliance as its backing image. QEMU restricted the fixture network and bound the browser port to loopback only. The installed runtime remained OPNsense 26.7.9_1, PHP 8.5.12 and fixture package `0.0.9.alpha2`.

Playwright passed eight successful setup and access-control checks across Chromium and Firefox. Both browsers rejected anonymous and authenticated unprivileged status requests, preserved settings from a read-only user, rejected a missing credential reference, and verified delivery and keyboard navigation from the mobile status page. A separate two-check run rejected delivery through a synthetic server hook and showed the previous verified receipt in both browsers. The initial delivery checks timed out before the status loaded. Their logs and traces remain in ignored `work/appliance/current-proof/` and `artifacts/`.

The native queued-delivery fixture held the configuration write lock while a configd delivery was started, then saved disabled settings. The queued request failed and the branch stayed unchanged. This covers a queued current provider across native settings save. It does not reproduce the older package worker after it passed checkpoint verification during downgrade. After reactivation, the actual generated cron entry advanced the migrated remote branch and recorded a matching verified receipt on the upgraded package.

### Older admitted worker and compatible resume

The disconnected `encryptedgit-drain-proof` overlay ran the `05489b6` package before the native configuration synchronization change. The fixture held the native configuration lock and observed the configd action worker blocked in the FreeBSD `flock` stack after activation checks. Holding the provider's delivery lock, it withheld the checkpoint and released the configuration lock. The admitted worker returned a structured failure without moving the remote or pending ref. New requests through both configd and the native remote-backup runner also failed while the checkpoint was withheld.

The retained input check rejected altered settings, then verified the original settings, checkpoint identity, destination and pending ancestry. The older provider stayed held. Reinstalling the compatible `0314d16` package and restoring the verified checkpoint allowed delivery to resume. Raw commands and earlier setup failures remain in ignored `work/appliance/current-proof/drain.log`. The fixture targets a known admitted request and does not prove an arbitrary appliance's operator has accounted for all outstanding work.
