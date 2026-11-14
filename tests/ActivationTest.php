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
    public function testLegacyCutoverRequiresVerifiedNativeExport(): void
    {
        $target = 'ssh://git@backup.example/config.git';
        $checkpoint = [
            'version' => 1,
            'destination' => $target,
            'branch' => 'snapshots',
            'legacy' => [
                'tip' => str_repeat('a', 40),
                'remote' => str_repeat('b', 40),
                'archiveSha256' => str_repeat('c', 64),
            ],
        ];
        $verified = $checkpoint;
        $verified['version'] = 2;
        $verified['exportSha256'] = str_repeat('d', 64);
        $verified['configurationSha256'] = str_repeat('e', 64);
        $legacy = Activation::validate(json_encode($verified, JSON_THROW_ON_ERROR), $target, 'snapshots', true);
        self::assertSame($checkpoint['legacy'], $legacy);

        $this->expectException(RuntimeException::class);
        Activation::validate(json_encode($checkpoint, JSON_THROW_ON_ERROR), $target, 'snapshots', true);
    }

    public function testLegacyCheckpointRejectsMalformedExportDigest(): void
    {
        $target = 'ssh://git@backup.example/config.git';
        $checkpoint = [
            'version' => 2,
            'destination' => $target,
            'branch' => 'snapshots',
            'legacy' => [
                'tip' => str_repeat('a', 40),
                'remote' => str_repeat('b', 40),
                'archiveSha256' => str_repeat('c', 64),
            ],
            'exportSha256' => 'invalid',
            'configurationSha256' => str_repeat('e', 64),
        ];
        $this->expectException(RuntimeException::class);
        Activation::validate(json_encode($checkpoint, JSON_THROW_ON_ERROR), $target, 'snapshots', true);
    }
}
