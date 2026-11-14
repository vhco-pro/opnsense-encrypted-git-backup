<?php

declare(strict_types=1);

use OPNsense\Backup\EncryptedGit;

require_once '/usr/local/opnsense/mvc/script/load_phalcon.php';

try {
    echo json_encode(['commit' => (new EncryptedGit())->runConfigured()], JSON_THROW_ON_ERROR);
} catch (Throwable) {
    echo '{"error":"Encrypted Git backup failed."}';
}
