<?php

declare(strict_types=1);

// This fixture runs only in the disposable guest. Pause a real old delivery at
// the configuration lock, after its activation and credential checks.
$bootstrap = '/usr/local/opnsense/mvc/script/load_phalcon.php';
if (!is_file($bootstrap) || !isset($argv[1])) {
    throw new RuntimeException('Supply the isolated fixture coordination directory.');
}
require $bootstrap;

$config = OPNsense\Core\Config::getInstance();
$config->lock();
try {
    touch($argv[1] . '/config-locked');
    $deadline = time() + 60;
    while (!is_file($argv[1] . '/release-config')) {
        if (time() >= $deadline) {
            throw new RuntimeException('Fixture did not release the native configuration lock.');
        }
        sleep(1);
        clearstatcache();
    }
} finally {
    $config->unlock();
}
