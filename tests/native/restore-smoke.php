<?php

declare(strict_types=1);

use OPNsense\Backup\Local;
use OPNsense\Core\Config;

$bootstrap = '/usr/local/opnsense/mvc/script/load_phalcon.php';
if (!is_file($bootstrap) || !isset($argv) || count($argv) !== 4) {
    throw new RuntimeException('Supply an encrypted export, fixture password file and expected marker.');
}
require $bootstrap;

$bytes = file_get_contents($argv[1]);
$password = file_get_contents($argv[2]);
if ($bytes === false || $password === false) {
    throw new RuntimeException('Fixture restore inputs are unavailable.');
}
$restored = (new Local())->decrypt($bytes, rtrim($password, "\n"));
if (!is_string($restored) || !str_contains($restored, $argv[3])) {
    throw new RuntimeException('The decrypted export lacks the fixture marker.');
}

umask(0077);
$file = tempnam('/tmp', 'encryptedgit-restore-');
if ($file === false) {
    throw new RuntimeException('Could not prepare synthetic restore staging.');
}
try {
    $config = Config::getInstance();
    if (file_put_contents($file, $restored) !== strlen($restored) || !$config->restoreBackup($file)) {
        throw new RuntimeException('Native full restore failed.');
    }
    if (!str_contains((string)$config, $argv[3])) {
        throw new RuntimeException('Restored configuration lacks the fixture marker.');
    }
    echo "NATIVE_FULL_RESTORE_OK\n";
} finally {
    unlink($file);
}
