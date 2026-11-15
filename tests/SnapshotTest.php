<?php

declare(strict_types=1);

namespace Tests;

use OPNsense\EncryptedGitBackup\Snapshot;
use PHPUnit\Framework\TestCase;
use RuntimeException;

final class SnapshotTest extends TestCase
{
    public function testCompleteCaptureMustRoundTripBeforeUse(): void
    {
        $xml = '<opnsense><system><secret>synthetic-secret</secret></system></opnsense>';
        $artifact = "---- BEGIN config.xml ----\nsynthetic ciphertext\n---- END config.xml ----\n";
        $snapshot = new Snapshot(
            static function (string $data, string $password) use ($xml, $artifact): string {
                self::assertSame($xml, $data);
                self::assertSame('synthetic-password', $password);
                return $artifact;
            },
            static fn (): string => $xml
        );

        self::assertSame($artifact, $snapshot->create($xml, 'synthetic-password'));
    }

    public function testRoundTripMismatchRejectsArtifact(): void
    {
        $snapshot = new Snapshot(
            static fn (): string => "---- BEGIN config.xml ----\nsynthetic ciphertext\n---- END config.xml ----\n",
            static fn (): string => '<opnsense/>'
        );

        $this->expectException(RuntimeException::class);
        $snapshot->create('<opnsense><system/></opnsense>', 'synthetic-password');
    }

    public function testDocumentTypeIsRejectedBeforeEncryption(): void
    {
        $snapshot = new Snapshot(
            static fn (): never => self::fail('Unexpected encryption attempt'),
            static fn (): never => self::fail('Unexpected decryption attempt')
        );

        $this->expectException(RuntimeException::class);
        $snapshot->create('<!DOCTYPE opnsense SYSTEM "file:///synthetic"><opnsense/>', 'synthetic-password');
    }
}
