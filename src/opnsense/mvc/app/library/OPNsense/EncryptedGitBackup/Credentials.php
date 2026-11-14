<?php

declare(strict_types=1);

namespace OPNsense\EncryptedGitBackup;

use RuntimeException;

final class Credentials
{
    public const DIRECTORY = '/conf/encrypted-git-backup';

    public static function privateDirectory(string $path): void
    {
        clearstatcache(true, $path);
        $stat = is_link($path) || !is_dir($path) ? false : stat($path);
        if ($stat === false || $stat['uid'] !== 0 || ($stat['mode'] & 0777) !== 0700) {
            throw new RuntimeException('The encrypted backup directory must be owned by root with mode 0700.');
        }
    }

    public static function file(string $kind, string $reference): string
    {
        Settings::validateCredentialReference($reference);
        $directory = self::DIRECTORY . '/credentials';
        self::privateDirectory(self::DIRECTORY);
        self::privateDirectory($directory);
        $file = $directory . '/' . $kind . '-' . $reference;
        clearstatcache(true, $file);
        $stat = is_link($file) || !is_file($file) ? false : stat($file);
        if (
            $stat === false
            || $stat['uid'] !== 0
            || !in_array($stat['mode'] & 0777, [0400, 0600], true)
            || $stat['nlink'] !== 1
        ) {
            throw new RuntimeException('A required encrypted backup credential is missing or has unsafe permissions.');
        }
        return $file;
    }
}
