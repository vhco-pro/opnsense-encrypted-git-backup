<?php

declare(strict_types=1);

namespace Tests;

use OPNsense\EncryptedGitBackup\Process;
use PHPUnit\Framework\TestCase;
use RuntimeException;

final class ProcessTest extends TestCase
{
    public function testArgumentsRemainLiteral(): void
    {
        $argument = '$(exit 42); still literal';
        self::assertSame(
            [0, $argument],
            Process::run([PHP_BINARY, '-r', 'echo $argv[1];', '--', $argument], __DIR__, [], 3)
        );
    }

    public function testTimeoutFails(): void
    {
        $this->expectException(RuntimeException::class);
        Process::run([PHP_BINARY, '-r', 'sleep(10);'], __DIR__, [], 1);
    }
}
