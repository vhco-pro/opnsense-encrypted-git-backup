<?php

declare(strict_types=1);

namespace OPNsense\EncryptedGitBackup;

use Closure;
use RuntimeException;

final class GitDelivery
{
    private const ARTIFACT = 'config.xml.enc';
    private const METADATA = 'snapshot.json';

    /** @param array<string, string> $environment */
    public function __construct(
        private string $git,
        private string $directory,
        private array $environment,
        private ?string $legacyParent = null
    ) {
    }

    /** @param Closure(): string $capture */
    public function deliver(
        string $destination,
        string $branch,
        string $revision,
        string $key,
        Closure $capture
    ): string {
        Settings::validateBranch($branch);
        Settings::validateCredentialReference($key);
        $mask = umask(0077);
        try {
            $lock = fopen($this->directory . '/delivery.lock', 'c');
            if ($lock === false) {
                throw new RuntimeException('Could not open the backup lock.');
            }
            try {
                if (!flock($lock, LOCK_EX | LOCK_NB)) {
                    throw new RuntimeException('Another encrypted backup is running.');
                }
                $binding = json_encode([$destination, $branch], JSON_THROW_ON_ERROR);
                $target = $this->directory . '/target.json';
                if (is_file($target)) {
                    if (file_get_contents($target) !== $binding) {
                        throw new RuntimeException('The backup state belongs to a different destination or branch.');
                    }
                } else {
                    $this->write($this->directory, 'target.json', $binding);
                }
                return $this->recordDelivery($destination, $branch, $revision, $key, $capture);
            } finally {
                fclose($lock);
            }
        } finally {
            umask($mask);
        }
    }

    /** @param Closure(): string $capture */
    private function recordDelivery(
        string $destination,
        string $branch,
        string $revision,
        string $key,
        Closure $capture
    ): string {
        $attempt = [
            'attempt' => gmdate(DATE_ATOM),
            'target' => hash('sha256', json_encode([$destination, $branch], JSON_THROW_ON_ERROR)),
        ];
        $this->writeStatus($attempt + ['outcome' => 'running']);
        try {
            $commit = $this->reconcile($destination, $branch, $revision, $key, $capture);
            $snapshot = $this->snapshot($this->directory . '/pending', $commit);
            $verification = [
                'version' => 1,
                'commit' => $commit,
                'observedAt' => gmdate(DATE_ATOM),
                'revision' => $snapshot['revision'],
                'key' => $snapshot['key'],
                'sha256' => $snapshot['sha256'],
            ];
            $this->write(
                $this->directory,
                'verified.json',
                json_encode($verification, JSON_THROW_ON_ERROR) . "\n"
            );
            $creation = $this->directory . '/creation.json';
            if (is_file($creation) && !unlink($creation)) {
                throw new RuntimeException('Could not retire the initial creation attempt.');
            }
            $this->writeStatus($attempt + ['outcome' => 'verified']);
            return $commit;
        } catch (RuntimeException $exception) {
            $this->writeStatus($attempt + ['outcome' => 'failed']);
            throw $exception;
        }
    }

    /** @param array{attempt: string, target: string, outcome: string} $status */
    private function writeStatus(array $status): void
    {
        $this->write($this->directory, 'attempt.json', json_encode($status, JSON_THROW_ON_ERROR) . "\n");
    }

    /** @param Closure(): string $capture */
    private function reconcile(
        string $destination,
        string $branch,
        string $revision,
        string $key,
        Closure $capture
    ): string {
        $repository = $this->directory . '/pending';
        if (!is_dir($repository . '/.git')) {
            $this->requireGit(['init', '--initial-branch=encrypted-backup', $repository]);
        }
        $ref = 'refs/heads/' . $branch;
        $remote = $this->fetch($repository, $destination, $ref);
        [$exit, $headOutput] = $this->git(['rev-parse', '--verify', 'HEAD'], $repository);
        $head = $exit === 0 ? $this->objectId(trim($headOutput)) : null;
        if ($head === null && $remote !== $this->legacyParent) {
            throw new RuntimeException('The remote branch does not match the activation checkpoint.');
        }
        if (
            $head !== null && $this->legacyParent !== null
            && $this->git(
                ['merge-base', '--is-ancestor', $this->objectId($this->legacyParent), $head],
                $repository
            )[0] !== 0
        ) {
            throw new RuntimeException('Pending history does not contain the active checkpoint parent.');
        }
        if ($head !== null && $remote === null) {
            $permission = $this->directory . '/initial-rejected';
            if (
                $this->legacyParent !== null
                || is_file($this->directory . '/verified.json')
                || is_file($this->directory . '/creation.json')
                || !is_file($permission)
                || file_get_contents($permission) !== $head
            ) {
                throw new RuntimeException('The absent branch requires independent recovery verification.');
            }
        }
        if ($head !== null) {
            if (
                $remote !== null && $head !== $remote
                && $this->git(['merge-base', '--is-ancestor', $remote, $head], $repository)[0] !== 0
            ) {
                throw new RuntimeException('The remote backup branch has diverged.');
            }
            $previous = $this->snapshot($repository, $head);
            if ($remote !== $head) {
                $this->pushAndVerify($repository, $destination, $ref, $head, $previous['sha256'], $remote);
                $remote = $head;
                if ($previous['revision'] === $revision && $previous['key'] === $key) {
                    return $head;
                }
            }
            if ($previous['revision'] === $revision && $previous['key'] === $key) {
                return $this->observe($repository, $destination, $ref, $head, $previous['sha256']);
            }
        }

        $artifact = $capture();
        if ($artifact === '' || strlen($artifact) > 32 * 1024 * 1024) {
            throw new RuntimeException('The encrypted export is empty or too large.');
        }
        $digest = hash('sha256', $artifact);
        $metadata = json_encode([
            'version' => 1,
            'revision' => $revision,
            'key' => $key,
            'capturedAt' => gmdate('Y-m-d\TH:i:s\Z'),
            'sha256' => $digest,
            'observedAt' => gmdate(DATE_ATOM),
        ], JSON_THROW_ON_ERROR) . "\n";
        $this->write($repository, self::ARTIFACT, $artifact);
        $this->write($repository, self::METADATA, $metadata);
        $this->requireGit(['add', '--', self::ARTIFACT, self::METADATA], $repository);
        $staged = $this->requireGit(['diff', '--cached', '--name-only', '-z'], $repository);
        if (array_diff(explode("\0", rtrim($staged, "\0")), [self::ARTIFACT, self::METADATA]) !== []) {
            throw new RuntimeException('Unexpected files are staged in the encrypted backup repository.');
        }
        $tree = $this->objectId(trim($this->requireGit(['write-tree'], $repository)));
        $commitArgs = ['commit-tree', $tree, '-m', 'Encrypted configuration snapshot'];
        $parent = $head ?? $this->legacyParent;
        if ($parent !== null) {
            $commitArgs[] = '-p';
            $commitArgs[] = $parent;
        }
        $commit = $this->objectId(trim($this->requireGit($commitArgs, $repository)));
        $old = $head ?? str_repeat('0', strlen($commit));
        $this->requireGit(['update-ref', 'HEAD', $commit, $old], $repository);
        $this->pushAndVerify($repository, $destination, $ref, $commit, $digest, $remote);

        return $commit;
    }

    private function observe(string $repository, string $destination, string $ref, string $head, string $digest): string
    {
        $metadata = json_decode(
            $this->requireGit(['show', $head . ':' . self::METADATA], $repository),
            true,
            8,
            JSON_THROW_ON_ERROR
        );
        if (!is_array($metadata)) {
            throw new RuntimeException('The retained backup metadata is invalid.');
        }
        $metadata['observedAt'] = gmdate(DATE_ATOM);
        $this->requireGit(['read-tree', $head], $repository);
        $this->write($repository, self::METADATA, json_encode($metadata, JSON_THROW_ON_ERROR) . "\n");
        $this->requireGit(['add', '--', self::METADATA], $repository);
        $tree = $this->objectId(trim($this->requireGit(['write-tree'], $repository)));
        $commit = $this->objectId(trim($this->requireGit(
            ['commit-tree', $tree, '-p', $head, '-m', 'Verify retained encrypted configuration'],
            $repository
        )));
        $this->requireGit(['update-ref', 'HEAD', $commit, $head], $repository);
        $this->pushAndVerify($repository, $destination, $ref, $commit, $digest, $head);
        return $commit;
    }

    private function fetch(string $repository, string $destination, string $ref): ?string
    {
        [$exit, $list] = $this->git(['ls-remote', '--exit-code', '--refs', '--', $destination, $ref], $repository);
        if ($exit === 2 && $list === '') {
            return null;
        }
        if ($exit !== 0 || !str_ends_with($list, "\t" . $ref . "\n")) {
            throw new RuntimeException('Could not read the remote backup branch.');
        }
        $commit = $this->objectId(substr($list, 0, -strlen($ref) - 2));
        $this->requireGit(['fetch', '--no-tags', '--', $destination, $ref], $repository);
        if (trim($this->requireGit(['rev-parse', 'FETCH_HEAD'], $repository)) !== $commit) {
            throw new RuntimeException('The remote branch changed while being verified.');
        }
        return $commit;
    }

    private function pushAndVerify(
        string $repository,
        string $destination,
        string $ref,
        string $commit,
        string $digest,
        ?string $expected
    ): void {
        // Callers only create the branch or advance an observed ancestor.
        $lease = '--force-with-lease=' . $ref . ':' . ($expected ?? '');
        $creation = $this->directory . '/creation.json';
        $permission = $this->directory . '/initial-rejected';
        if ($expected === null) {
            $this->write(
                $this->directory,
                'creation.json',
                json_encode(['ref' => $ref, 'commit' => $commit], JSON_THROW_ON_ERROR)
            );
            if (is_file($permission) && !unlink($permission)) {
                throw new RuntimeException('Could not consume initial push retry evidence.');
            }
        }
        $rejected = false;
        try {
            [$exit, $output] = $this->git(
                ['push', '--porcelain', $lease, '--', $destination, $commit . ':' . $ref],
                $repository
            );
            $rejected = $exit !== 0 && str_contains(
                $output,
                "\n!\t" . $commit . ':' . $ref . "\t[remote rejected]"
            );
        } catch (RuntimeException) {
            // A transport failure may arrive after the server accepted the update.
        }
        $observed = $this->fetch($repository, $destination, $ref);
        if ($expected === null && $rejected && $observed === null) {
            $this->write($this->directory, 'initial-rejected', $commit);
            if (!unlink($creation)) {
                throw new RuntimeException('Could not retire the rejected initial attempt.');
            }
        }
        if (
            $observed !== $commit
            || $this->snapshot($repository, $commit)['sha256'] !== $digest
        ) {
            throw new RuntimeException('The remote did not retain the expected encrypted backup.');
        }
    }

    /** @return array{revision: string, key: string, sha256: string} */
    private function snapshot(string $repository, string $commit): array
    {
        $snapshot = json_decode(
            $this->requireGit(['show', $commit . ':' . self::METADATA], $repository),
            true,
            8,
            JSON_THROW_ON_ERROR
        );
        $artifact = $this->requireGit(['show', $commit . ':' . self::ARTIFACT], $repository, 32 * 1024 * 1024);
        if (
            !is_array($snapshot)
            || ($snapshot['version'] ?? null) !== 1
            || !is_string($snapshot['revision'] ?? null)
            || !is_string($snapshot['key'] ?? null)
            || ($snapshot['sha256'] ?? null) !== hash('sha256', $artifact)
        ) {
            throw new RuntimeException('The retained backup metadata is invalid.');
        }
        return ['revision' => $snapshot['revision'], 'key' => $snapshot['key'], 'sha256' => $snapshot['sha256']];
    }

    private function write(string $repository, string $file, string $content): void
    {
        $temporary = tempnam($repository, '.backup-');
        if ($temporary === false) {
            throw new RuntimeException('Could not create a backup staging file.');
        }
        try {
            if (file_put_contents($temporary, $content) !== strlen($content)) {
                throw new RuntimeException('Could not write the encrypted backup.');
            }
            if (!rename($temporary, $repository . '/' . $file)) {
                throw new RuntimeException('Could not publish the encrypted staging file.');
            }
        } finally {
            if (is_file($temporary)) {
                unlink($temporary);
            }
        }
    }

    private function objectId(string $value): string
    {
        if (preg_match('/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/', $value) !== 1) {
            throw new RuntimeException('Git returned an invalid backup object identifier.');
        }
        return $value;
    }

    /**
     * @param list<string> $arguments
     * @return array{int, string}
     */
    private function git(array $arguments, ?string $repository = null, int $limit = 65536): array
    {
        return Process::run(
            [
                $this->git,
                '-c', 'core.hooksPath=/dev/null',
                '-c', 'user.name=OPNsense encrypted backup',
                '-c', 'user.email=encrypted-backup@localhost',
                ...$arguments,
            ],
            $repository ?? $this->directory,
            $this->environment,
            30,
            $limit
        );
    }

    /** @param list<string> $arguments */
    private function requireGit(array $arguments, ?string $repository = null, int $limit = 65536): string
    {
        [$exit, $output] = $this->git($arguments, $repository, $limit);
        if ($exit !== 0) {
            throw new RuntimeException('A required Git backup operation failed.');
        }
        return $output;
    }
}
