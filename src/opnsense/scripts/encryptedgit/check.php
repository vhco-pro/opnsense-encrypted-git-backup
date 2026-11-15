<?php

declare(strict_types=1);

use OPNsense\EncryptedGitBackup\Activation;
use OPNsense\EncryptedGitBackup\Credentials;

$bootstrap = dirname(__DIR__, 2) . '/mvc/script/load_phalcon.php';
if (!is_file($bootstrap) || !isset($argv) || count($argv) !== 8) {
    exit(1);
}
require_once $bootstrap;

try {
    $activation = Activation::check($argv[1], $argv[2], $argv[7], $argv[6]);
    Credentials::file('identity', $argv[3]);
    Credentials::file('hosts', $argv[4]);
    Credentials::file('password', $argv[5]);
    echo $activation['id'];
} catch (RuntimeException | InvalidArgumentException) {
    echo 'unavailable';
}
