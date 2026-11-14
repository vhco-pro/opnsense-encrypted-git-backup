<?php

declare(strict_types=1);

use OPNsense\Backup\EncryptedGit;
use OPNsense\Core\Config;

$bootstrap = '/usr/local/opnsense/mvc/script/load_phalcon.php';
if (!is_file($bootstrap)) {
    throw new RuntimeException('Run this fixture on the isolated OPNsense appliance.');
}
require $bootstrap;

$_SESSION['Username'] = 'root';
$provider = new EncryptedGit();
$result = $provider->setConfiguration([
    'enabled' => 'on',
    'destination' => 'ssh://root@127.0.0.1:22222/tmp/fixture.git',
    'branch' => $argv[1] ?? 'snapshots',
    'identity' => 'fixture',
    'hostTrust' => 'fixture',
    'encryptionKey' => 'fixture',
    'freshnessHours' => '48',
]);
if ($result !== []) {
    throw new RuntimeException(implode(' ', $result));
}
$config = Config::getInstance();
$checkpoint = hash_file('sha256', '/conf/encrypted-git-backup/activation.json');
if ($checkpoint === false || !str_contains((string)$config, '<activation>' . $checkpoint . '</activation>')) {
    throw new RuntimeException('The native configuration did not retain the activation identifier.');
}
echo "NATIVE_ACTIVATION_SAVE_OK\n";
