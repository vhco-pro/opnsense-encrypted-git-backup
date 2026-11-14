<?php

declare(strict_types=1);

namespace OPNsense\EncryptedGitBackup;

use DateTimeImmutable;

final class Freshness
{
    public static function retained(
        mixed $receipt,
        string $expectedCommit,
        string $artifactDigest,
        DateTimeImmutable $now,
        int $maximumAgeSeconds
    ): bool {
        if (
            !is_array($receipt)
            || ($receipt['version'] ?? null) !== 1
            || preg_match('/\A(?:[a-f0-9]{40}|[a-f0-9]{64})\z/', $expectedCommit) !== 1
            || preg_match('/\A[a-f0-9]{64}\z/', $artifactDigest) !== 1
            || ($receipt['commit'] ?? null) !== $expectedCommit
            || ($receipt['sha256'] ?? null) !== $artifactDigest
            || !is_string($receipt['observedAt'] ?? null)
            || !is_string($receipt['key'] ?? null)
            || preg_match('/\A[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}\z/', $receipt['key']) !== 1
            || !is_string($receipt['revision'] ?? null)
            || preg_match('/\A[0-9]+(?:\.[0-9]+)?\z/', $receipt['revision']) !== 1
            || $maximumAgeSeconds <= 0
        ) {
            return false;
        }
        $observed = DateTimeImmutable::createFromFormat(DATE_ATOM, $receipt['observedAt']);
        if ($observed === false || $observed->format(DATE_ATOM) !== $receipt['observedAt']) {
            return false;
        }
        $age = $now->getTimestamp() - $observed->getTimestamp();
        return $age >= 0 && $age <= $maximumAgeSeconds;
    }
}
