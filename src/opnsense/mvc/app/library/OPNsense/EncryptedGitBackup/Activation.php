<?php

declare(strict_types=1);

namespace OPNsense\EncryptedGitBackup;

use RuntimeException;

final class Activation
{
    private const LEGACY_HOOK = '/usr/local/etc/rc.syshook.d/config/10-git-backup';
    private const LEGACY_REPOSITORY = '/conf/backup/git';

    /** @return array{id: string, parent: ?string} */
    public static function check(
        string $destination,
        string $branch,
        string $savedActivation,
        ?string $configurationDigest = null
    ): array {
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
        $legacy = self::validate(
            $contents,
            $destination,
            $branch,
            file_exists(self::LEGACY_REPOSITORY) || is_link(self::LEGACY_REPOSITORY)
        );
        $id = hash('sha256', $contents);
        if (!hash_equals($id, $savedActivation)) {
            if ($configurationDigest === null) {
                throw new RuntimeException('Save and verify activation before delivery.');
            }
            if ($legacy !== null) {
                self::verifyConfigurationDigest($contents, $configurationDigest);
            }
        }
        if ($legacy === null) {
            return ['id' => $id, 'parent' => null];
        }
        if (is_link(self::LEGACY_REPOSITORY)) {
            throw new RuntimeException('The legacy repository path is unsafe.');
        }
        [$exit, $tip] = Process::run(
            ['/usr/local/bin/git', 'rev-parse', '--verify', 'HEAD'],
            self::LEGACY_REPOSITORY,
            ['GIT_CONFIG_NOSYSTEM' => '1', 'GIT_CONFIG_GLOBAL' => '/dev/null'],
            5
        );
        if ($exit !== 0 || trim($tip) !== $legacy['tip']) {
            throw new RuntimeException('The legacy repository changed after the verified archive checkpoint.');
        }
        return ['id' => $id, 'parent' => $legacy['remote']];
    }

    public static function verifyConfigurationDigest(string $contents, string $actual): void
    {
        $checkpoint = json_decode($contents, true, 8);
        $expected = is_array($checkpoint) ? ($checkpoint['configurationSha256'] ?? null) : null;
        if (!self::isDigest($expected, '/\A[0-9a-f]{64}\z/') || !hash_equals($expected, $actual)) {
            throw new RuntimeException('The configuration changed after the verified export.');
        }
    }

    /** @return array{tip: string, remote: string, archiveSha256: string}|null */
    public static function validate(string $contents, string $destination, string $branch, bool $legacyExists): ?array
    {
        $checkpoint = json_decode($contents, true, 8);
        if (!is_array($checkpoint)) {
            throw new RuntimeException('A verified activation checkpoint is required for this backup target.');
        }
        return self::parseCheckpoint($checkpoint, $destination, $branch, $legacyExists);
    }

    /**
     * @param array<array-key, mixed> $checkpoint
     * @return array{tip: string, remote: string, archiveSha256: string}|null
     */
    private static function parseCheckpoint(
        array $checkpoint,
        string $destination,
        string $branch,
        bool $legacyExists
    ): ?array {
        if (
            ($checkpoint['destination'] ?? null) !== $destination
            || ($checkpoint['branch'] ?? null) !== $branch
            || !array_key_exists('legacy', $checkpoint)
            || ($checkpoint['legacy'] === null) === $legacyExists
        ) {
            throw new RuntimeException('A verified activation checkpoint is required for this backup target.');
        }
        $legacy = $checkpoint['legacy'];
        if ($legacy === null && count($checkpoint) === 4 && ($checkpoint['version'] ?? null) === 1) {
            return null;
        }
        if (
            ($checkpoint['version'] ?? null) !== 2
            || count($checkpoint) !== 6
            || !self::isDigest($checkpoint['exportSha256'] ?? null, '/\A[0-9a-f]{64}\z/')
            || !self::isDigest($checkpoint['configurationSha256'] ?? null, '/\A[0-9a-f]{64}\z/')
            || !is_array($legacy) || count($legacy) !== 3
            || !self::isDigest($legacy['tip'] ?? null, '/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/')
            || !self::isDigest($legacy['remote'] ?? null, '/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/')
            || !self::isDigest($legacy['archiveSha256'] ?? null, '/\A[0-9a-f]{64}\z/')
        ) {
            throw new RuntimeException('The legacy archive checkpoint is invalid.');
        }
        return [
            'tip' => $legacy['tip'],
            'remote' => $legacy['remote'],
            'archiveSha256' => $legacy['archiveSha256'],
        ];
    }

    /** @phpstan-assert-if-true string $value */
    private static function isDigest(mixed $value, string $pattern): bool
    {
        return is_string($value) && preg_match($pattern, $value) === 1;
    }
}
