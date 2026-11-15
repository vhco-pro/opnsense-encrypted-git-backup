<?php

declare(strict_types=1);

use OPNsense\EncryptedGitBackup\GitDelivery;

$bootstrap = '/usr/local/opnsense/mvc/script/load_phalcon.php';
if (!is_file($bootstrap) || !isset($argv) || count($argv) !== 4) {
    throw new RuntimeException('Run only on the isolated native fixture.');
}
require $bootstrap;
[, $git, $work, $remote] = $argv;

try {
    $delivery = new GitDelivery($git, $work, ['FIXTURE_STATE' => $work]);
    $delivery->deliver($remote, 'snapshots', 'revision', 'fixture', static fn (): string => 'synthetic ciphertext');
} catch (RuntimeException $error) {
    fwrite(STDERR, $error->getMessage() . PHP_EOL);
    exit(1);
}
