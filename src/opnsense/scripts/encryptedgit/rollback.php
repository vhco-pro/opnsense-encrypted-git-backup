<?php

declare(strict_types=1);

use OPNsense\Backup\EncryptedGitSettings;
use OPNsense\Core\Config;
use OPNsense\EncryptedGitBackup\Activation;
use OPNsense\EncryptedGitBackup\Credentials;
use OPNsense\EncryptedGitBackup\Process;

$bootstrap = dirname(__DIR__, 2) . '/mvc/script/load_phalcon.php';
if (!is_file($bootstrap) || !isset($argv) || !in_array(count($argv), [2, 3], true)) {
    exit(64);
}
$action = $argv[1];
$expected = $argv[2] ?? null;
if (
    ($expected !== null && (
        !in_array($action, ['restore-settings', 'resume'], true)
        || preg_match('/\A[0-9a-f]{64}\z/', $expected) !== 1
    ))
    || ($action === 'restore-settings' && $expected === null)
) {
    exit(64);
}
require $bootstrap;
umask(0077);
$captureProviderSettings = static function (string $xml): string {
    $document = new DOMDocument();
    if (!$document->loadXML($xml, LIBXML_NONET | LIBXML_NOERROR | LIBXML_NOWARNING | LIBXML_NOBLANKS)) {
        throw new RuntimeException('The native configuration could not be read.');
    }
    $settings = (new DOMXPath($document))->query('/opnsense/system/backup/encryptedgit');
    $provider = $settings === false ? null : $settings->item(0);
    if ($provider instanceof DOMElement) {
        // Native model serialization updates bookkeeping on every save.
        $provider->removeAttribute('persisted_at');
    }
    $serialized = $provider instanceof DOMElement ? $provider->C14N() : false;
    if ($serialized === false) {
        throw new RuntimeException('The native provider settings could not be retained.');
    }
    return $serialized;
};
$drain = static function (string $state): void {
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
            return;
        }
        if ($status !== 0) {
            throw new RuntimeException('Could not enumerate native delivery workers.');
        }
        sleep(1);
    } while (time() < $deadline);
    throw new RuntimeException('Native delivery workers did not drain.');
};
$state = Credentials::DIRECTORY;
$checkpoint = $state . '/activation.json';
$retained = $state . '/rollback.json';
$pair = $state . '/rollback-pair.json';
$closing = $state . '/rollback-closing.json';
try {
    [$status, $uid] = Process::run(['/usr/bin/id', '-u'], '/', [], 5);
    if ($status !== 0 || trim($uid) !== '0') {
        throw new RuntimeException('Rollback requires root.');
    }
    Credentials::privateDirectory($state);
    $lock = fopen($state . '/delivery.lock', 'c');
    if ($lock === false || !flock($lock, LOCK_EX | LOCK_NB)) {
        throw new RuntimeException('Git delivery still holds its write lock.');
    }
    try {
        if (file_exists($closing) || is_link($closing)) {
            Credentials::privateFile($closing);
            if (file_exists($pair) || is_link($pair)) {
                throw new RuntimeException('Conflicting rollback records require inspection.');
            }
            if (file_exists($checkpoint) || is_link($checkpoint)) {
                Credentials::privateFile($checkpoint);
                $closedBytes = file_get_contents($closing, false, null, 0, 4096);
                $closedRecord = $closedBytes === false ? null : json_decode($closedBytes, true, 8, JSON_THROW_ON_ERROR);
                if (
                    !is_array($closedRecord)
                    || ($closedRecord['checkpoint'] ?? null) !== hash_file('sha256', $checkpoint)
                    || file_exists($retained) || is_link($retained)
                    || !unlink($closing)
                ) {
                    throw new RuntimeException('Could not retire the completed rollback record.');
                }
            } else {
                $pair = $closing;
                if (!in_array($action, ['hold', 'revision', 'verify', 'resume'], true)) {
                    throw new RuntimeException('Resume the interrupted checkpoint restoration first.');
                }
            }
        }
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
                        'settings' => $captureProviderSettings((string)$config),
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
            $drain($state);
            echo "HELD_AND_DRAINED\n";
            exit(0);
        }
        if (in_array($argv[1], ['verify', 'replace', 'resume', 'restore-settings', 'revision'], true)) {
            if (file_exists($checkpoint) || is_link($checkpoint)) {
                throw new RuntimeException('The active checkpoint has not been withheld.');
            }
            Credentials::privateFile($retained);
            Credentials::privateFile($pair);
            if ($argv[1] !== 'verify') {
                $drain($state);
            }
            $config = Config::getInstance();
            $config->lock();
            try {
                $bytes = file_get_contents($pair, false, null, 0, 4096);
                $record = $bytes === false ? null : json_decode($bytes, true, 8, JSON_THROW_ON_ERROR);
                $revision = hash('sha256', (string)$config);
                $settings = $captureProviderSettings((string)$config);
                $savedSettings = is_array($record) ? ($record['settings'] ?? null) : null;
                if (
                    !is_string($savedSettings)
                    || ($record['checkpoint'] ?? null) !== hash_file('sha256', $retained)
                ) {
                    throw new RuntimeException('The retained rollback pair is invalid.');
                }
                if ($action === 'revision') {
                    echo $revision . PHP_EOL;
                    exit(0);
                }
                if ($revision !== ($expected ?? ($record['configuration'] ?? null))) {
                    throw new RuntimeException('The checkpoint or native configuration changed.');
                }
                if ($action === 'restore-settings') {
                    $xml = new DOMDocument();
                    if (
                        !$xml->loadXML($savedSettings, LIBXML_NONET | LIBXML_NOERROR | LIBXML_NOWARNING)
                        || $xml->documentElement?->tagName !== 'encryptedgit'
                    ) {
                        throw new RuntimeException('The retained provider settings are invalid.');
                    }
                    $model = new EncryptedGitSettings();
                    foreach ($xml->documentElement->childNodes as $field) {
                        if ($field instanceof DOMElement) {
                            $node = $model->getNodeByReference($field->tagName);
                            if ($node === null) {
                                throw new RuntimeException('The installed model cannot restore the retained settings.');
                            }
                            $node->setValue($field->textContent);
                        }
                    }
                    $model->serializeToConfig(true);
                    if ($captureProviderSettings((string)$config) !== $savedSettings) {
                        throw new RuntimeException('Native serialization did not reproduce the retained settings.');
                    }
                    $config->save();
                    echo "SETTINGS_RESTORED_CHECKPOINT_WITHHELD\n";
                    exit(0);
                }
                if ($savedSettings !== $settings) {
                    throw new RuntimeException('The checkpoint or native configuration changed.');
                }
                if ($argv[1] === 'resume') {
                    $contents = file_get_contents($retained, false, null, 0, 65537);
                    $model = new EncryptedGitSettings();
                    $destination = $model->getNodeByReference('destination')?->getValue() ?? '';
                    $branch = $model->getNodeByReference('branch')?->getValue() ?? '';
                    $saved = $model->getNodeByReference('activation')?->getValue() ?? '';
                    if (
                        $contents === false || strlen($contents) > 65536
                        || !hash_equals(hash('sha256', $contents), $saved)
                        || file_exists('/usr/local/etc/rc.syshook.d/config/10-git-backup')
                        || is_link('/usr/local/etc/rc.syshook.d/config/10-git-backup')
                        || is_link('/conf/backup/git')
                    ) {
                        throw new RuntimeException('Compatible activation or writer quiescence could not be verified.');
                    }
                    $legacy = Activation::validate($contents, $destination, $branch, is_dir('/conf/backup/git'));
                    $pending = $state . '/pending';
                    if (is_dir($pending)) {
                        Credentials::privateFile($state . '/target.json');
                        $target = json_encode([$destination, $branch], JSON_THROW_ON_ERROR);
                        if (file_get_contents($state . '/target.json') !== $target) {
                            throw new RuntimeException('Pending Git target could not be verified.');
                        }
                    }
                    if ($legacy !== null) {
                        $env = ['GIT_CONFIG_NOSYSTEM' => '1', 'GIT_CONFIG_GLOBAL' => '/dev/null'];
                        [$tipStatus, $tip] = Process::run(
                            ['/usr/local/bin/git', 'rev-parse', '--verify', 'HEAD'],
                            '/conf/backup/git',
                            $env,
                            5
                        );
                        if ($tipStatus !== 0 || trim($tip) !== $legacy['tip']) {
                            throw new RuntimeException('The legacy repository has changed.');
                        }
                        if (is_dir($pending)) {
                            [$ancestry] = Process::run(
                                ['/usr/local/bin/git', 'merge-base', '--is-ancestor', $legacy['remote'], 'HEAD'],
                                $pending,
                                $env,
                                5
                            );
                            if ($ancestry !== 0) {
                                throw new RuntimeException('Pending Git ancestry could not be verified.');
                            }
                        }
                    }
                    // Mark the verified pair as closing before making activation visible.
                    // A retry with activation still withheld verifies the same pair again.
                    if ($pair !== $closing && !rename($pair, $closing)) {
                        throw new RuntimeException('Could not record checkpoint restoration in progress.');
                    }
                    if (!rename($retained, $checkpoint)) {
                        throw new RuntimeException('Could not restore the verified compatible checkpoint.');
                    }
                    echo "COMPATIBLE_CHECKPOINT_RESTORED\n";
                    exit(0);
                }
                if ($argv[1] === 'replace') {
                    $candidate = $state . '/activation.next';
                    Credentials::privateFile($candidate);
                    $contents = file_get_contents($candidate, false, null, 0, 65537);
                    if ($contents === false || strlen($contents) > 65536) {
                        throw new RuntimeException('Could not read the replacement checkpoint.');
                    }
                    $model = new EncryptedGitSettings();
                    $destination = $model->getNodeByReference('destination')?->getValue() ?? '';
                    $branch = $model->getNodeByReference('branch')?->getValue() ?? '';
                    $saved = $model->getNodeByReference('activation')?->getValue() ?? '';
                    if (
                        Activation::validate($contents, $destination, $branch, true) === null
                        || hash('sha256', $contents) === $saved
                    ) {
                        throw new RuntimeException('Replacement requires fresh legacy activation.');
                    }
                    Activation::verifyConfigurationDigest($contents, hash('sha256', (string)$config));
                    if (!rename($candidate, $checkpoint)) {
                        throw new RuntimeException('Could not install the replacement checkpoint.');
                    }
                    echo "REPLACEMENT_STAGED_FOR_NATIVE_SAVE\n";
                    exit(0);
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
