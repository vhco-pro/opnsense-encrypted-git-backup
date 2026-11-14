<?php

declare(strict_types=1);

require_once __DIR__ . '/../work/upstream/core/src/opnsense/mvc/app/library/OPNsense/Backup/IBackupProvider.php';
require_once __DIR__ . '/../work/upstream/core/src/opnsense/mvc/app/library/OPNsense/Backup/Base.php';

spl_autoload_register(static function (string $class): void {
    $file = __DIR__ . '/../src/opnsense/mvc/app/library/' . str_replace('\\', '/', $class) . '.php';
    if (is_file($file)) {
        require_once $file;
    }
});
