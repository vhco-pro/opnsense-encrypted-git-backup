<?php

declare(strict_types=1);

use OPNsense\EncryptedGitBackup\Activation;
use OPNsense\EncryptedGitBackup\Credentials;

$bootstrap = dirname(__DIR__, 2) . '/mvc/script/load_phalcon.php';
if (!is_file($bootstrap) || !isset($argv) || count($argv) !== 6) {
    exit(1);
}
require_once $bootstrap;

try {
    Activation::check($argv[1], $argv[2]);
    Credentials::file('identity', $argv[3]);
    Credentials::file('hosts', $argv[4]);
    Credentials::file('password', $argv[5]);
    echo 'ready';
} catch (RuntimeException | InvalidArgumentException) {
    echo 'unavailable';
}
