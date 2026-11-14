<?php

declare(strict_types=1);

namespace Tests;

use OPNsense\EncryptedGitBackup\GitDelivery;
use OPNsense\EncryptedGitBackup\Process;
use PHPUnit\Framework\TestCase;
use RuntimeException;

final class GitDeliveryTest extends TestCase
{
    public function testRemoteCommitMustBeReadBackAndIdenticalSnapshotsDoNotGrowHistory(): void
    {
        $directory = sys_get_temp_dir() . '/delivery-' . bin2hex(random_bytes(12));
        self::assertTrue(mkdir($directory, 0700));
        try {
            self::assertSame(0, Process::run(
                ['/usr/bin/git', 'init', '--bare', $directory . '/remote'],
                $directory,
                [],
                5
            )[0]);
            $delivery = new GitDelivery(
                '/usr/bin/git',
                $directory,
                ['GIT_CONFIG_NOSYSTEM' => '1', 'HOME' => $directory]
            );
            $prepare = static fn (): string => 'synthetic-encrypted-artifact';
            $first = $delivery->deliver($directory . '/remote', 'snapshots', '1.0', 'key', $prepare);
            $second = $delivery->deliver(
                $directory . '/remote',
                'snapshots',
                '1.0',
                'key',
                static fn (): never => throw new RuntimeException('Unchanged capture was encrypted again.')
            );
            self::assertSame($first, $second);
            self::assertSame(
                [0, $first . "\n"],
                Process::run(['/usr/bin/git', 'rev-parse', 'refs/heads/snapshots'], $directory . '/remote', [], 5)
            );
        } finally {
            Process::run(['/bin/rm', '-rf', '--', $directory], sys_get_temp_dir(), [], 5);
        }
    }
}
