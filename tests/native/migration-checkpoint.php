<?php

declare(strict_types=1);

use OPNsense\Backup\Local;
use OPNsense\Core\Config;

$bootstrap = '/usr/local/opnsense/mvc/script/load_phalcon.php';
if (!is_file($bootstrap) || !isset($argv) || count($argv) !== 6) {
    throw new RuntimeException('Supply isolated fixture inputs for the activation checkpoint.');
}
require $bootstrap;
[$command, $mode, $tip, $remote, $archiveDigest, $directory] = $argv;
if (!in_array($mode, ['stale', 'current'], true) || !is_dir($directory)) {
    throw new RuntimeException('Invalid fixture invocation.');
}
$config = Config::getInstance();
$config->lock();
try {
    $xml = (string)$config;
    $password = 'synthetic-migration-fixture';
    $native = new Local();
    $export = $native->encrypt($xml, $password);
    if (!is_string($export)) {
        throw new RuntimeException('Could not encrypt the fixture configuration.');
    }
    umask(0077);
    $exportPath = $directory . '/pre-cutover.enc';
    if (file_put_contents($exportPath, $export) !== strlen($export)) {
        throw new RuntimeException('Could not retain the fixture export.');
    }
    $retained = file_get_contents($exportPath);
    if ($retained === false || $native->decrypt($retained, $password) !== $xml) {
        throw new RuntimeException('Retained export did not match the configuration.');
    }
    $checkpoint = [
        'version' => 2,
        'destination' => 'ssh://root@127.0.0.1:22222/tmp/fixture.git',
        'branch' => 'migration',
        'legacy' => ['tip' => $tip, 'remote' => $remote, 'archiveSha256' => $archiveDigest],
        'exportSha256' => hash('sha256', $retained),
        'configurationSha256' => hash('sha256', $xml),
    ];
    $path = '/conf/encrypted-git-backup/activation.json';
    $temporary = $path . '.fixture';
    $serialized = json_encode($checkpoint, JSON_THROW_ON_ERROR);
    if (file_put_contents($temporary, $serialized) !== strlen($serialized) || !rename($temporary, $path)) {
        throw new RuntimeException('Could not write the synthetic checkpoint.');
    }
    if ($mode === 'stale') {
        $config->save();
    }
} finally {
    $config->unlock();
}
