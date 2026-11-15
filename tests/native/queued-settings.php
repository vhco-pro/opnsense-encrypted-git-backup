<?php

declare(strict_types=1);

use OPNsense\Core\Config;

$bootstrap = '/usr/local/opnsense/mvc/script/load_phalcon.php';
if (!is_file($bootstrap) || !isset($argv[1])) {
    throw new RuntimeException('Run on the disposable appliance with a protected fixture directory.');
}
require $bootstrap;

$config = Config::getInstance();
$directory = $argv[1];
$config->lock();
try {
    touch($directory . '/locked');
    $deadline = time() + 30;
    while (!is_file($directory . '/proceed')) {
        if (time() >= $deadline) {
            throw new RuntimeException('Timed out waiting for queued delivery.');
        }
        sleep(1);
        clearstatcache();
    }
    $enabled = $config->object()->xpath('/opnsense/system/backup/encryptedgit/enabled')[0] ?? null;
    if (!$enabled instanceof SimpleXMLElement) {
        throw new RuntimeException('Fixture configuration has no enabled flag.');
    }
    $enabled[0] = '0';
    $config->save();
} finally {
    $config->unlock();
}
