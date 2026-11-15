<?php

declare(strict_types=1);

namespace OPNsense\EncryptedGitBackup;

use Closure;
use DOMDocument;
use RuntimeException;

final class Snapshot
{
    /**
     * @param Closure(string, string): (string|null) $encrypt
     * @param Closure(string, string): (string|null) $decrypt
     */
    public function __construct(private Closure $encrypt, private Closure $decrypt)
    {
    }

    public function create(string $xml, string $password): string
    {
        if ($password === '' || strpbrk($password, "\x00\r\n") !== false) {
            throw new RuntimeException('The encryption credential is missing or invalid.');
        }
        $document = new DOMDocument();
        if (
            $xml === ''
            || str_contains($xml, "\x00")
            || str_contains($xml, '<!DOCTYPE')
            || !$document->loadXML($xml, LIBXML_NONET | LIBXML_NOERROR | LIBXML_NOWARNING)
            || $document->doctype !== null
            || $document->documentElement?->tagName !== 'opnsense'
        ) {
            throw new RuntimeException('The captured configuration is invalid.');
        }

        $mask = umask(0077);
        try {
            $artifact = ($this->encrypt)($xml, $password);
            if (
                $artifact === null
                || !str_starts_with($artifact, "---- BEGIN config.xml ----\n")
                || !str_ends_with($artifact, "\n---- END config.xml ----\n")
                || ($this->decrypt)($artifact, $password) !== $xml
            ) {
                throw new RuntimeException('The encrypted configuration failed round-trip verification.');
            }
            return $artifact;
        } finally {
            umask($mask);
        }
    }
}
