<?php

declare(strict_types=1);

namespace OPNsense\EncryptedGitBackup;

use DOMDocument;
use DOMXPath;
use InvalidArgumentException;
use OPNsense\Backup\Local;
use RuntimeException;

final class NativeRun
{
    public static function run(
        string $destination,
        string $branch,
        string $identity,
        string $trust,
        string $key,
        string $activation,
        string $xml
    ): string {
        $directory = Credentials::DIRECTORY;
        Credentials::privateDirectory($directory);
        $category = 'activation';
        try {
            $legacyParent = Activation::check($destination, $branch, $activation)['parent'];
            $category = 'configuration';
            Settings::validateDestination($destination);
            Settings::validateBranch($branch);
            $category = 'credentials';
            $identityPath = Credentials::file('identity', $identity);
            $trustPath = Credentials::file('hosts', $trust);
            $passwordPath = Credentials::file('password', $key);
            $password = file_get_contents($passwordPath, false, null, 0, 4097);
            if ($password === false || strlen($password) > 4096) {
                throw new RuntimeException('Could not read the encryption credential.');
            }
            $password = str_ends_with($password, "\n") ? substr($password, 0, -1) : $password;
            $category = 'configuration';
            $document = new DOMDocument();
            if (!$document->loadXML($xml, LIBXML_NONET | LIBXML_NOERROR | LIBXML_NOWARNING)) {
                throw new RuntimeException('The captured configuration is invalid.');
            }
            $timestamp = (new DOMXPath($document))->evaluate('string(/opnsense/revision/time)');
            if (!is_string($timestamp) || preg_match('/\A[0-9]+(?:\.[0-9]+)?\z/', $timestamp) !== 1) {
                throw new RuntimeException('The captured configuration revision is invalid.');
            }
        } catch (InvalidArgumentException | RuntimeException $error) {
            (new GitDelivery('/usr/local/bin/git', $directory, []))
                ->recordPreconditionFailure($destination, $branch, $category);
            throw $error;
        }
        $crypter = new Local();
        $snapshot = new Snapshot(
            static fn (string $data, string $pass): ?string => $crypter->encrypt($data, $pass),
            static fn (string $data, string $pass): ?string => $crypter->decrypt($data, $pass)
        );
        $ssh = '/usr/local/bin/ssh -F /dev/null -o BatchMode=yes -o IdentitiesOnly=yes'
            . ' -o IdentityAgent=none -o StrictHostKeyChecking=yes -o GlobalKnownHostsFile=/dev/null'
            . ' -o ConnectTimeout=8 -o ConnectionAttempts=1'
            . ' -o UserKnownHostsFile=' . escapeshellarg($trustPath)
            . ' -i ' . escapeshellarg($identityPath);
        $delivery = new GitDelivery('/usr/local/bin/git', $directory, [
            'HOME' => $directory,
            'PATH' => '/bin:/usr/bin:/usr/local/bin',
            'GIT_CONFIG_NOSYSTEM' => '1',
            'GIT_CONFIG_GLOBAL' => '/dev/null',
            'GIT_TERMINAL_PROMPT' => '0',
            'GIT_ALLOW_PROTOCOL' => 'ssh',
            'GIT_SSH_COMMAND' => $ssh,
        ], $legacyParent);

        return $delivery->deliver(
            $destination,
            $branch,
            $timestamp,
            $key,
            static fn (): string => $snapshot->create($xml, $password)
        );
    }
}
