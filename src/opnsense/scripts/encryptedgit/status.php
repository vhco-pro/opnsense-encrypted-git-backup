<?php

declare(strict_types=1);

use OPNsense\EncryptedGitBackup\Credentials;

$bootstrap = dirname(__DIR__, 2) . '/mvc/script/load_phalcon.php';
if (!is_file($bootstrap)) {
    exit(1);
}
require_once $bootstrap;

try {
    Credentials::privateDirectory(Credentials::DIRECTORY);
    $result = [];
    foreach (['attempt' => 'attempt.json', 'verification' => 'verified.json'] as $key => $file) {
        $path = Credentials::DIRECTORY . '/' . $file;
        if (!is_file($path)) {
            continue;
        }
        Credentials::privateFile($path);
        $contents = file_get_contents($path, false, null, 0, 65537);
        if ($contents === false || strlen($contents) > 65536) {
            throw new RuntimeException('Backup status is unavailable.');
        }
        $result[$key] = json_decode($contents, true, 8, JSON_THROW_ON_ERROR);
    }
    echo json_encode($result, JSON_THROW_ON_ERROR);
} catch (RuntimeException | JsonException) {
    echo '{}';
}
