<?php

declare(strict_types=1);

use OPNsense\Core\Config;

$bootstrap = '/usr/local/opnsense/mvc/script/load_phalcon.php';
if (!is_file($bootstrap) || !isset($argv[1]) || !in_array($argv[1], ['opnsense', 'opnsense-dark'], true)) {
    throw new RuntimeException('Supply an installed fixture theme.');
}
require $bootstrap;
$config = Config::getInstance();
$config->lock();
try {
    $config->object()->theme = $argv[1];
    $config->save();
} finally {
    $config->unlock();
}
