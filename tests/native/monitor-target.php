<?php

declare(strict_types=1);

use OPNsense\Backup\EncryptedGitSettings;
use OPNsense\Core\Config;

$bootstrap = '/usr/local/opnsense/mvc/script/load_phalcon.php';
if (!is_file($bootstrap) || !isset($argv[1]) || !in_array($argv[1], ['migration', 'monitor-b'], true)) {
    throw new RuntimeException('Supply an owned monitor fixture branch.');
}
require $bootstrap;
$config = Config::getInstance();
$config->lock();
try {
    $model = new EncryptedGitSettings();
    $branch = $model->getNodeByReference('branch');
    if ($branch === null) {
        throw new RuntimeException('Native branch setting is unavailable.');
    }
    // Simulate a settings change without invoking the Backups form's test delivery.
    $branch->setValue($argv[1]);
    $model->serializeToConfig(true);
    $config->save();
} finally {
    $config->unlock();
}
