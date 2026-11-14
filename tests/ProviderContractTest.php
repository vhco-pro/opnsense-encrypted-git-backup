<?php

declare(strict_types=1);

namespace Tests;

use OPNsense\Backup\EncryptedGit;
use OPNsense\Backup\IBackupProvider;
use PHPUnit\Framework\TestCase;
use ReflectionClass;

final class ProviderContractTest extends TestCase
{
    public function testNativeFactoryCanConstructProvider(): void
    {
        self::assertTrue(class_exists(EncryptedGit::class));
        $provider = new ReflectionClass(EncryptedGit::class);
        self::assertTrue($provider->implementsInterface(IBackupProvider::class));
        self::assertSame(0, $provider->getConstructor()?->getNumberOfRequiredParameters() ?? 0);
    }
}
