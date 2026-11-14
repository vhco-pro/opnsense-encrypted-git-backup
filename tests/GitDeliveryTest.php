<?php

declare(strict_types=1);

namespace Tests;

use OPNsense\EncryptedGitBackup\GitDelivery;
use OPNsense\EncryptedGitBackup\Process;
use PHPUnit\Framework\TestCase;
use RuntimeException;

final class GitDeliveryTest extends TestCase
{
    public function testRejectedPushRetainsPendingCommitForRetry(): void
    {
        $directory = sys_get_temp_dir() . '/delivery-' . bin2hex(random_bytes(12));
        self::assertTrue(mkdir($directory, 0700));
        try {
            $remote = $directory . '/remote';
            self::assertSame(0, Process::run(['/usr/bin/git', 'init', '--bare', $remote], $directory, [], 5)[0]);
            $hook = $remote . '/hooks/pre-receive';
            self::assertNotFalse(file_put_contents($hook, "#!/bin/sh\nexit 1\n"));
            self::assertTrue(chmod($hook, 0700));
            $delivery = new GitDelivery('/usr/bin/git', $directory, ['GIT_CONFIG_NOSYSTEM' => '1']);
            try {
                $delivery->deliver($remote, 'snapshots', '1.0', 'key', static fn (): string => 'encrypted');
                self::fail('A rejected push was reported as successful.');
            } catch (RuntimeException $exception) {
                self::assertStringContainsString('did not retain', $exception->getMessage());
            }
            self::assertFileDoesNotExist($directory . '/verified.json');
            $attempt = file_get_contents($directory . '/attempt.json');
            self::assertIsString($attempt);
            self::assertStringContainsString('"outcome":"failed"', $attempt);
            self::assertTrue(unlink($hook));
            $commit = $delivery->deliver(
                $remote,
                'snapshots',
                '1.0',
                'key',
                static fn (): never => throw new RuntimeException('Pending snapshot was not reused.')
            );
            self::assertSame(
                [0, $commit . "\n"],
                Process::run(['/usr/bin/git', 'rev-parse', 'refs/heads/snapshots'], $remote, [], 5)
            );
        } finally {
            Process::run(['/bin/rm', '-rf', '--', $directory], sys_get_temp_dir(), [], 5);
        }
    }

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
            $receipt = file_get_contents($directory . '/verified.json');
            self::assertIsString($receipt);
            self::assertStringContainsString($first, $receipt);
            self::assertStringContainsString(hash('sha256', 'synthetic-encrypted-artifact'), $receipt);
            self::assertSame(
                [0, $first . "\n"],
                Process::run(['/usr/bin/git', 'rev-parse', 'refs/heads/snapshots'], $directory . '/remote', [], 5)
            );
        } finally {
            Process::run(['/bin/rm', '-rf', '--', $directory], sys_get_temp_dir(), [], 5);
        }
    }
}
