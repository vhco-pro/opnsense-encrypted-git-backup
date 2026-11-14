<?php

declare(strict_types=1);

namespace Tests;

use DateTimeImmutable;
use OPNsense\EncryptedGitBackup\Freshness;
use PHPUnit\Framework\TestCase;

final class FreshnessTest extends TestCase
{
    public function testFreshnessRequiresMatchingRemoteCommitAndArtifact(): void
    {
        $now = new DateTimeImmutable('2026-11-14T12:00:00+00:00');
        $commit = str_repeat('a', 40);
        $digest = str_repeat('b', 64);
        $receipt = [
            'version' => 1,
            'observedAt' => '2026-11-14T11:00:00+00:00',
            'commit' => $commit,
            'sha256' => $digest,
            'key' => 'fixture-key',
            'revision' => '1.0',
        ];
        self::assertTrue(Freshness::retained($receipt, $commit, $digest, $now, 3600));
        self::assertFalse(Freshness::retained($receipt, $commit, $digest, $now, 3599));
        self::assertFalse(Freshness::retained($receipt, str_repeat('c', 40), $digest, $now, 3600));
        self::assertFalse(Freshness::retained($receipt, $commit, str_repeat('d', 64), $now, 3600));
    }
}
