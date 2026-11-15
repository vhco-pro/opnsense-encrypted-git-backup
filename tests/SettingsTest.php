<?php

declare(strict_types=1);

namespace Tests;

use InvalidArgumentException;
use OPNsense\EncryptedGitBackup\Settings;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;

final class SettingsTest extends TestCase
{
    /** @return iterable<string, array{string}> */
    public static function invalidReferences(): iterable
    {
        yield 'absolute path' => ['/root/identity'];
        yield 'traversal' => ['../identity'];
        yield 'option' => ['-identity'];
        yield 'multiline' => ["key\nnew"];
        yield 'empty' => [''];
    }

    #[DataProvider('invalidReferences')]
    public function testCredentialReferencesAreIdentifiers(string $reference): void
    {
        $this->expectException(InvalidArgumentException::class);
        Settings::validateCredentialReference($reference);
    }
}
