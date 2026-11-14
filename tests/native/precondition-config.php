<?php

declare(strict_types=1);

use OPNsense\Backup\EncryptedGitSettings;
use OPNsense\EncryptedGitBackup\NativeRun;

$bootstrap = '/usr/local/opnsense/mvc/script/load_phalcon.php';
if (!is_file($bootstrap)) {
    throw new RuntimeException('Run only on the owned synthetic fixture.');
}
require $bootstrap;
$model = new EncryptedGitSettings();
$value = static fn (string $field): string => $model->getNodeByReference($field)?->getValue() ?? '';
try {
    NativeRun::run(
        $value('destination'),
        $value('branch'),
        $value('identity'),
        $value('hostTrust'),
        $value('encryptionKey'),
        $value('activation'),
        '<opnsense/>'
    );
} catch (RuntimeException $error) {
    exit($error->getMessage() === 'The captured configuration revision is invalid.' ? 0 : 1);
}
exit(1);
