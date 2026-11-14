<?php

declare(strict_types=1);

use OPNsense\Backup\EncryptedGitSettings;
use OPNsense\Core\Config;

$bootstrap = '/usr/local/opnsense/mvc/script/load_phalcon.php';
if (!is_file($bootstrap)) {
    throw new RuntimeException('Run this fixture on the disconnected appliance.');
}
require $bootstrap;

$config = Config::getInstance();
$config->lock();
try {
    $provider = new EncryptedGitSettings();
    $provider->getNodeByReference('freshnessHours')?->setValue('37');
    $provider->serializeToConfig(true);
    $system = $config->object()->system;
    $system->domain = 'operator-fixture.invalid';
    $config->save();
} finally {
    $config->unlock();
}
