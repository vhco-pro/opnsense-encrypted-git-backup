<?php

declare(strict_types=1);

use OPNsense\Backup\EncryptedGit;

$bootstrap = dirname(__DIR__, 2) . '/mvc/script/load_phalcon.php';
if (!is_file($bootstrap)) {
    throw new RuntimeException('The OPNsense runtime bootstrap is unavailable.');
}
require_once $bootstrap;

try {
    echo json_encode(['commit' => (new EncryptedGit())->runConfigured()], JSON_THROW_ON_ERROR);
} catch (Throwable) {
    echo '{"error":"Encrypted Git backup failed."}';
}
