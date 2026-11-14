<?php

declare(strict_types=1);

namespace OPNsense\EncryptedGitBackup;

use RuntimeException;

final class Activation
{
    private const LEGACY_HOOK = '/usr/local/etc/rc.syshook.d/config/10-git-backup';
    private const LEGACY_REPOSITORY = '/conf/backup/git';

    public static function check(string $destination, string $branch): void
    {
        clearstatcache();
        if (file_exists(self::LEGACY_HOOK) || is_link(self::LEGACY_HOOK)) {
            throw new RuntimeException('Remove and drain the legacy Git capture hook before enabling backups.');
        }
        Credentials::privateDirectory(Credentials::DIRECTORY);
        $file = Credentials::DIRECTORY . '/activation.json';
        Credentials::privateFile($file);
        $contents = file_get_contents($file, false, null, 0, 65537);
        if ($contents === false || strlen($contents) > 65536) {
            throw new RuntimeException('Could not read the encrypted backup activation checkpoint.');
        }
        self::validate(
            $contents,
            $destination,
            $branch,
            file_exists(self::LEGACY_REPOSITORY) || is_link(self::LEGACY_REPOSITORY)
        );
    }

    public static function validate(string $contents, string $destination, string $branch, bool $legacyExists): void
    {
        $checkpoint = json_decode($contents, true, 8);
        if (
            !is_array($checkpoint)
            || count($checkpoint) !== 4
            || ($checkpoint['version'] ?? null) !== 1
            || ($checkpoint['destination'] ?? null) !== $destination
            || ($checkpoint['branch'] ?? null) !== $branch
            || !array_key_exists('legacy', $checkpoint)
            || $checkpoint['legacy'] !== null
            || $legacyExists
        ) {
            throw new RuntimeException('A verified activation checkpoint is required for this backup target.');
        }
    }
}
