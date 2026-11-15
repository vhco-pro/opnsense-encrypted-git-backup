<?php

declare(strict_types=1);

namespace OPNsense\EncryptedGitBackup;

use InvalidArgumentException;

final class Settings
{
    public static function validateCredentialReference(string $reference): void
    {
        if (preg_match('/\A[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}\z/', $reference) !== 1) {
            throw new InvalidArgumentException('Credential references must be identifiers of at most 64 characters.');
        }
    }

    public static function validateDestination(string $destination): void
    {
        $pattern = '~\Assh://[a-zA-Z0-9_][a-zA-Z0-9_-]*@[a-zA-Z0-9][a-zA-Z0-9.-]*'
            . '(?::([0-9]{1,5}))?(/[a-zA-Z0-9_.-]+(?:/[a-zA-Z0-9_.-]+)*)\z~';
        if (
            preg_match($pattern, $destination, $parts) !== 1
            || ($parts[1] !== '' && ((int)$parts[1] < 1 || (int)$parts[1] > 65535))
            || preg_match('~/(?:\.|\.\.)(?:/|$)~D', $parts[2]) === 1
        ) {
            throw new InvalidArgumentException('Use an SSH repository URL with a user, host and absolute path.');
        }
    }

    public static function validateBranch(string $branch): void
    {
        if (
            preg_match('~\A[a-zA-Z0-9][a-zA-Z0-9_./-]{0,127}\z~', $branch) !== 1
            || preg_match('~(?:\.\.|//|/\.|\.lock(?:/|$)|[/.]$)~D', $branch) === 1
        ) {
            throw new InvalidArgumentException('Enter a valid Git branch name.');
        }
    }
}
