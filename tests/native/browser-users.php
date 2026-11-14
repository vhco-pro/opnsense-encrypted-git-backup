<?php

declare(strict_types=1);

use OPNsense\Core\Config;

$bootstrap = '/usr/local/opnsense/mvc/script/load_phalcon.php';
if (!is_file($bootstrap) || !isset($argv) || count($argv) !== 2) {
    throw new RuntimeException('Supply the protected synthetic browser password file.');
}
require $bootstrap;

$password = file_get_contents($argv[1]);
if ($password === false || trim($password) === '') {
    throw new RuntimeException('Fixture password unavailable.');
}
$config = Config::getInstance();
$config->lock();
try {
    $system = $config->object()->xpath('/opnsense/system')[0] ?? null;
    if (!$system instanceof SimpleXMLElement) {
        throw new RuntimeException('Missing native system settings.');
    }
    $users = [
        'fixture-reader' => ['2301', 'page-encrypted-git-status,user-config-readonly,page-diagnostics-backup-restore'],
        'fixture-denied' => ['2302', 'page-system-login-logout'],
    ];
    foreach ($users as $name => [$uid, $privileges]) {
        foreach ($system->xpath('user') ?: [] as $existing) {
            if ((string)($existing->xpath('name')[0] ?? '') === $name) {
                $node = dom_import_simplexml($existing);
                $node->parentNode?->removeChild($node);
            }
        }
        $user = $system->addChild('user');
        $user->addChild('name', $name);
        $user->addChild('uid', $uid);
        $user->addChild('scope', 'user');
        $user->addChild('password', password_hash(trim($password), PASSWORD_BCRYPT));
        $user->addChild('priv', 'page-system-login-logout,' . $privileges);
    }
    $config->save();
} finally {
    $config->unlock();
}
