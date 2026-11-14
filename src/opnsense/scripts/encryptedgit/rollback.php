<?php

declare(strict_types=1);

use OPNsense\Core\Config;
use OPNsense\EncryptedGitBackup\Credentials;
use OPNsense\EncryptedGitBackup\Process;

$bootstrap = dirname(__DIR__, 2) . '/mvc/script/load_phalcon.php';
if (!is_file($bootstrap) || !isset($argv) || count($argv) !== 2 || posix_geteuid() !== 0) {
    exit(64);
}
require $bootstrap;
umask(0077);
$state = Credentials::DIRECTORY;
$checkpoint = $state . '/activation.json';
$retained = $state . '/rollback.json';
$pair = $state . '/rollback-pair.json';
try {
    Credentials::privateDirectory($state);
    $lock = fopen($state . '/delivery.lock', 'c');
    if ($lock === false || !flock($lock, LOCK_EX | LOCK_NB)) {
        throw new RuntimeException('Git delivery still holds its write lock.');
    }
    try {
        if ($argv[1] === 'hold') {
            if (file_exists($checkpoint) || is_link($checkpoint)) {
                $config = Config::getInstance();
                $config->lock();
                try {
                    Credentials::privateFile($checkpoint);
                    $digest = hash_file('sha256', $checkpoint);
                    if ($digest === false) {
                        throw new RuntimeException('Could not hash the checkpoint.');
                    }
                    $record = json_encode([
                        'checkpoint' => $digest,
                        'configuration' => hash('sha256', (string)$config),
                    ], JSON_THROW_ON_ERROR);
                    if (file_exists($pair) || is_link($pair)) {
                        Credentials::privateFile($pair);
                        if (file_get_contents($pair, false, null, 0, 4096) !== $record) {
                            throw new RuntimeException('The prepared rollback pair no longer matches.');
                        }
                    } else {
                        $stage = tempnam($state, '.rollback-');
                        if ($stage === false) {
                            throw new RuntimeException('Could not stage the rollback record.');
                        }
                        try {
                            if (
                                file_put_contents($stage, $record) !== strlen($record)
                                || file_get_contents($stage) !== $record
                                || !rename($stage, $pair)
                            ) {
                                throw new RuntimeException('Could not retain the rollback record.');
                            }
                        } finally {
                            if (is_file($stage)) {
                                unlink($stage);
                            }
                        }
                    }
                    if (file_exists($retained) || is_link($retained) || !rename($checkpoint, $retained)) {
                        throw new RuntimeException('Could not safely retain the active checkpoint.');
                    }
                } finally {
                    $config->unlock();
                }
            }
            Credentials::privateFile($retained);
            Credentials::privateFile($pair);
            $deadline = time() + 30;
            do {
                [$status, $workers] = Process::run(
                    [
                        '/usr/bin/pgrep',
                        '-f',
                        '(^|[[:space:]])/usr/local/opnsense/scripts/encryptedgit/run[.]php([[:space:]]|$)',
                    ],
                    $state,
                    [],
                    5
                );
                if ($status === 1 && trim($workers) === '') {
                    echo "HELD_AND_DRAINED\n";
                    exit(0);
                }
                if ($status !== 0) {
                    throw new RuntimeException('Could not enumerate native delivery workers.');
                }
                sleep(1);
            } while (time() < $deadline);
            throw new RuntimeException('Native delivery workers did not drain.');
        }
        if ($argv[1] === 'verify') {
            if (file_exists($checkpoint) || is_link($checkpoint)) {
                throw new RuntimeException('The active checkpoint has not been withheld.');
            }
            Credentials::privateFile($retained);
            Credentials::privateFile($pair);
            $config = Config::getInstance();
            $config->lock();
            try {
                $bytes = file_get_contents($pair, false, null, 0, 4096);
                $record = $bytes === false ? null : json_decode($bytes, true, 8, JSON_THROW_ON_ERROR);
                if (
                    !is_array($record)
                    || ($record['checkpoint'] ?? null) !== hash_file('sha256', $retained)
                    || ($record['configuration'] ?? null) !== hash('sha256', (string)$config)
                ) {
                    throw new RuntimeException('The checkpoint or native configuration changed.');
                }
                echo "PAIR_VERIFIED_CHECKPOINT_WITHHELD\n";
                exit(0);
            } finally {
                $config->unlock();
            }
        }
        throw new RuntimeException('Unknown rollback action.');
    } finally {
        fclose($lock);
    }
} catch (Throwable $error) {
    fwrite(STDERR, "ROLLBACK_HOLD: " . $error->getMessage() . PHP_EOL);
    exit(1);
}
