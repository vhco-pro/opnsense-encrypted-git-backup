<?php

declare(strict_types=1);

namespace Tests;

use OPNsense\EncryptedGitBackup\GitDelivery;
use OPNsense\EncryptedGitBackup\Process;
use PHPUnit\Framework\TestCase;
use RuntimeException;

final class GitDeliveryTest extends TestCase
{
    public function testMigrationKeepsTheLegacyParentWithoutCheckingOutPlaintext(): void
    {
        $directory = sys_get_temp_dir() . '/delivery-' . bin2hex(random_bytes(12));
        self::assertTrue(mkdir($directory, 0700));
        try {
            $remote = $directory . '/remote';
            $init = ['/usr/bin/git', 'init', '-b', 'snapshots', $remote];
            self::assertSame(0, Process::run($init, $directory, [], 5)[0]);
            self::assertNotFalse(file_put_contents($remote . '/config.xml', 'synthetic legacy plaintext'));
            self::assertSame(0, Process::run(['/usr/bin/git', 'add', 'config.xml'], $remote, [], 5)[0]);
            self::assertSame(0, Process::run(
                ['/usr/bin/git', '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.test',
                    'commit', '-m', 'Legacy fixture'],
                $remote,
                [],
                5
            )[0]);
            self::assertSame(0, Process::run(
                ['/usr/bin/git', 'config', 'receive.denyCurrentBranch', 'ignore'],
                $remote,
                [],
                5
            )[0]);
            [$exit, $legacy] = Process::run(['/usr/bin/git', 'rev-parse', 'HEAD'], $remote, [], 5);
            self::assertSame(0, $exit);
            $delivery = new GitDelivery('/usr/bin/git', $directory, ['GIT_CONFIG_NOSYSTEM' => '1'], trim($legacy));
            $result = $delivery->deliver($remote, 'snapshots', '1.0', 'key', static fn (): string => 'encrypted');
            self::assertSame(
                [0, $legacy],
                Process::run(['/usr/bin/git', 'rev-parse', $result . '^'], $remote, [], 5)
            );
            self::assertSame(
                [0, "config.xml.enc\nsnapshot.json\n"],
                Process::run(['/usr/bin/git', 'ls-tree', '--name-only', $result], $remote, [], 5)
            );
            self::assertFileDoesNotExist($directory . '/pending/config.xml');
            $receipt = file_get_contents($directory . '/verified.json');
            foreach (['activation', 'credentials', 'configuration'] as $category) {
                $delivery->recordPreconditionFailure($remote, 'snapshots', $category);
                $attempt = file_get_contents($directory . '/attempt.json');
                self::assertIsString($attempt);
                self::assertMatchesRegularExpression(
                    '/^{"attempt":"[^"]+","target":"[a-f0-9]{64}","outcome":"failed","category":"' . $category . '"}/',
                    $attempt
                );
                self::assertSame($receipt, file_get_contents($directory . '/verified.json'));
            }
            $incompatible = new GitDelivery('/usr/bin/git', $directory, [], str_repeat('a', 40));
            try {
                $incompatible->deliver($remote, 'snapshots', '2.0', 'key', static fn (): string => 'new snapshot');
                self::fail('Delivery accepted pending history without the active checkpoint parent.');
            } catch (RuntimeException $error) {
                self::assertSame(
                    'Pending history does not contain the active checkpoint parent.',
                    $error->getMessage()
                );
            }
            self::assertSame($receipt, file_get_contents($directory . '/verified.json'));
            self::assertSame(
                [0, $result . "\n"],
                Process::run(['/usr/bin/git', 'rev-parse', 'refs/heads/snapshots'], $remote, [], 5)
            );
        } finally {
            Process::run(['/bin/rm', '-rf', '--', $directory], sys_get_temp_dir(), [], 5);
        }
    }

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
            self::assertStringContainsString(
                hash('sha256', json_encode([$remote, 'snapshots'], JSON_THROW_ON_ERROR)),
                $attempt
            );
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

    public function testDivergentRemoteDoesNotReplaceLastVerifiedReceipt(): void
    {
        $directory = sys_get_temp_dir() . '/delivery-' . bin2hex(random_bytes(12));
        self::assertTrue(mkdir($directory, 0700));
        try {
            $remote = $directory . '/remote';
            self::assertSame(0, Process::run(['/usr/bin/git', 'init', '--bare', $remote], $directory, [], 5)[0]);
            $delivery = new GitDelivery('/usr/bin/git', $directory, ['GIT_CONFIG_NOSYSTEM' => '1']);
            $first = $delivery->deliver($remote, 'snapshots', '1.0', 'key', static fn (): string => 'encrypted');
            $receipt = file_get_contents($directory . '/verified.json');
            [$exit, $tree] = Process::run(['/usr/bin/git', 'rev-parse', $first . '^{tree}'], $remote, [], 5);
            self::assertSame(0, $exit);
            [$exit, $other] = Process::run(
                ['/usr/bin/git', '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.test',
                    'commit-tree', trim($tree), '-m', 'Divergent history'],
                $remote,
                [],
                5
            );
            self::assertSame(0, $exit);
            self::assertSame(0, Process::run(
                ['/usr/bin/git', 'update-ref', 'refs/heads/snapshots', trim($other), $first],
                $remote,
                [],
                5
            )[0]);
            try {
                $delivery->deliver($remote, 'snapshots', '2.0', 'key', static fn (): string => 'encrypted-new');
                self::fail('Divergent history was accepted.');
            } catch (RuntimeException $exception) {
                self::assertStringContainsString('diverged', $exception->getMessage());
            }
            self::assertSame($receipt, file_get_contents($directory . '/verified.json'));
            self::assertSame(
                [0, $other],
                Process::run(['/usr/bin/git', 'rev-parse', 'refs/heads/snapshots'], $remote, [], 5)
            );
        } finally {
            Process::run(['/bin/rm', '-rf', '--', $directory], sys_get_temp_dir(), [], 5);
        }
    }

    public function testLostPushResponseStillRequiresRemoteReadBack(): void
    {
        $directory = sys_get_temp_dir() . '/delivery-' . bin2hex(random_bytes(12));
        self::assertTrue(mkdir($directory, 0700));
        try {
            $remote = $directory . '/remote';
            self::assertSame(0, Process::run(['/usr/bin/git', 'init', '--bare', $remote], $directory, [], 5)[0]);
            $wrapper = $directory . '/git';
            $script = <<<'SH'
#!/bin/sh
for argument do
    if [ "$argument" = push ]; then
        /usr/bin/git "$@" || exit "$?"
        exit 1
    fi
done
exec /usr/bin/git "$@"
SH;
            self::assertNotFalse(file_put_contents($wrapper, $script));
            self::assertTrue(chmod($wrapper, 0700));
            $delivery = new GitDelivery($wrapper, $directory, ['GIT_CONFIG_NOSYSTEM' => '1']);
            $commit = $delivery->deliver($remote, 'snapshots', '1.0', 'key', static fn (): string => 'encrypted');
            self::assertSame(
                [0, $commit . "\n"],
                Process::run(['/usr/bin/git', 'rev-parse', 'refs/heads/snapshots'], $remote, [], 5)
            );
            self::assertFileExists($directory . '/verified.json');
        } finally {
            Process::run(['/bin/rm', '-rf', '--', $directory], sys_get_temp_dir(), [], 5);
        }
    }

    public function testOverlapFailsWithoutWritingAnAttemptReceipt(): void
    {
        $directory = sys_get_temp_dir() . '/delivery-' . bin2hex(random_bytes(12));
        self::assertTrue(mkdir($directory, 0700));
        $lock = fopen($directory . '/delivery.lock', 'c');
        self::assertIsResource($lock);
        try {
            self::assertTrue(flock($lock, LOCK_EX | LOCK_NB));
            $delivery = new GitDelivery('/usr/bin/git', $directory, []);
            $this->expectExceptionMessage('Another encrypted backup is running.');
            $delivery->deliver('unused', 'snapshots', '1.0', 'key', static fn (): string => 'encrypted');
        } finally {
            self::assertFileDoesNotExist($directory . '/attempt.json');
            fclose($lock);
            Process::run(['/bin/rm', '-rf', '--', $directory], sys_get_temp_dir(), [], 5);
        }
    }

    public function testRemoteCommitMustBeReadBackAndIdenticalSnapshotsReuseTheCiphertextBlob(): void
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
            self::assertNotSame($first, $second);
            self::assertSame(
                Process::run(['/usr/bin/git', 'rev-parse', $first . ':config.xml.enc'], $directory . '/remote', [], 5),
                Process::run(['/usr/bin/git', 'rev-parse', $second . ':config.xml.enc'], $directory . '/remote', [], 5)
            );
            $receipt = file_get_contents($directory . '/verified.json');
            self::assertIsString($receipt);
            self::assertStringContainsString($second, $receipt);
            self::assertStringContainsString(hash('sha256', 'synthetic-encrypted-artifact'), $receipt);
            self::assertSame(
                [0, $second . "\n"],
                Process::run(['/usr/bin/git', 'rev-parse', 'refs/heads/snapshots'], $directory . '/remote', [], 5)
            );
        } finally {
            Process::run(['/bin/rm', '-rf', '--', $directory], sys_get_temp_dir(), [], 5);
        }
    }
    public function testBranchDeletedBetweenObservationAndPushIsNotRecreated(): void
    {
        $directory = sys_get_temp_dir() . '/delivery-' . bin2hex(random_bytes(12));
        self::assertTrue(mkdir($directory, 0700));
        try {
            $remote = $directory . '/remote';
            self::assertSame(0, Process::run(['/usr/bin/git', 'init', '--bare', $remote], $directory, [], 5)[0]);
            $delivery = new GitDelivery('/usr/bin/git', $directory, []);
            $first = $delivery->deliver($remote, 'snapshots', '1.0', 'key', static fn (): string => 'first');
            try {
                $delivery->deliver($remote, 'snapshots', '2.0', 'key', static function () use ($remote): string {
                    self::assertSame(0, Process::run(
                        ['/usr/bin/git', 'update-ref', '-d', 'refs/heads/snapshots'],
                        $remote,
                        [],
                        5
                    )[0]);
                    return 'second';
                });
                self::fail('A deleted remote branch was recreated.');
            } catch (RuntimeException $exception) {
                self::assertSame('The remote did not retain the expected encrypted backup.', $exception->getMessage());
            }
            self::assertSame(1, Process::run(
                ['/usr/bin/git', 'show-ref', '--verify', '--quiet', 'refs/heads/snapshots'],
                $remote,
                [],
                5
            )[0]);
            $receipt = file_get_contents($directory . '/verified.json');
            self::assertIsString($receipt);
            self::assertStringContainsString($first, $receipt);
        } finally {
            Process::run(['/bin/rm', '-rf', '--', $directory], sys_get_temp_dir(), [], 5);
        }
    }
    public function testUnknownInitialCreationDoesNotRecreateMissingBranch(): void
    {
        $directory = sys_get_temp_dir() . '/delivery-' . bin2hex(random_bytes(12));
        self::assertTrue(mkdir($directory, 0700));
        try {
            $remote = $directory . '/remote';
            self::assertSame(0, Process::run(['/usr/bin/git', 'init', '--bare', $remote], $directory, [], 5)[0]);
            $wrapper = $directory . '/git';
            $script = <<<'SH'
#!/bin/sh
for argument do
    if [ "$argument" = push ]; then
        /usr/bin/git "$@" || exit "$?"
        /usr/bin/git -C "$FIXTURE_REMOTE" update-ref -d refs/heads/snapshots || exit "$?"
        exit 1
    fi
done
exec /usr/bin/git "$@"
SH;
            self::assertNotFalse(file_put_contents($wrapper, $script));
            self::assertTrue(chmod($wrapper, 0700));
            $delivery = new GitDelivery($wrapper, $directory, ['FIXTURE_REMOTE' => $remote]);
            try {
                $delivery->deliver($remote, 'snapshots', '1.0', 'key', static fn (): string => 'encrypted');
                self::fail('The removed commit was reported as retained.');
            } catch (RuntimeException $exception) {
                self::assertStringContainsString('did not retain', $exception->getMessage());
            }

            self::assertFileExists($directory . '/creation.json');
            $restarted = new GitDelivery('/usr/bin/git', $directory, []);
            try {
                $restarted->deliver($remote, 'snapshots', '1.0', 'key', static fn (): string => 'encrypted');
                self::fail('An unresolved initial creation was repeated.');
            } catch (RuntimeException $exception) {
                self::assertStringContainsString('requires independent recovery', $exception->getMessage());
            }
            self::assertFileDoesNotExist($directory . '/verified.json');
            self::assertSame(1, Process::run(
                ['/usr/bin/git', 'show-ref', '--verify', '--quiet', 'refs/heads/snapshots'],
                $remote,
                [],
                5
            )[0]);
        } finally {
            Process::run(['/bin/rm', '-rf', '--', $directory], sys_get_temp_dir(), [], 5);
        }
    }
}
