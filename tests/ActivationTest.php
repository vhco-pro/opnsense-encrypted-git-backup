<?php

declare(strict_types=1);

namespace Tests;

use OPNsense\EncryptedGitBackup\Activation;
use PHPUnit\Framework\TestCase;
use RuntimeException;

final class ActivationTest extends TestCase
{
    public function testFreshCheckpointBindsDestinationAndBranch(): void
    {
        $target = 'ssh://git@backup.example/config.git';
        $checkpoint = '{"version":1,"destination":"' . $target . '","branch":"snapshots","legacy":null}';
        Activation::validate($checkpoint, $target, 'snapshots', false);
        $this->expectException(RuntimeException::class);
        Activation::validate($checkpoint, $target, 'other', false);
    }

    public function testFreshCheckpointCannotAuthorizeExistingLegacyHistory(): void
    {
        $target = 'ssh://git@backup.example/config.git';
        $checkpoint = '{"version":1,"destination":"' . $target . '","branch":"snapshots","legacy":null}';
        $this->expectException(RuntimeException::class);
        Activation::validate($checkpoint, $target, 'snapshots', true);
    }
}
