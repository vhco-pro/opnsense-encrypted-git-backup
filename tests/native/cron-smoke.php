<?php

declare(strict_types=1);

use OPNsense\Core\Config;

$bootstrap = '/usr/local/opnsense/mvc/script/load_phalcon.php';
if (!is_file($bootstrap) || !isset($argv) || count($argv) !== 2 || !in_array($argv[1], ['add', 'remove'], true)) {
    throw new RuntimeException('Run on the disposable appliance with add or remove.');
}
require $bootstrap;

$config = Config::getInstance();
$config->lock();
try {
    $root = $config->object();
    $jobs = $root->xpath('/opnsense/OPNsense/cron/jobs')[0] ?? null;
    if (!$jobs instanceof SimpleXMLElement) {
        throw new RuntimeException('Native cron configuration is unavailable.');
    }
    $uuid = '1e890535-a7c2-4675-b87e-91b72addc813';
    foreach ($jobs->xpath("job") ?: [] as $existing) {
        if ((string)$existing['uuid'] === $uuid) {
            $node = dom_import_simplexml($existing);
            $node->parentNode?->removeChild($node);
            break;
        }
    }
    if ($argv[1] === 'add') {
        $job = $jobs->addChild('job');
        $job->addAttribute('uuid', $uuid);
        $fields = [
            'origin' => 'cron',
            'enabled' => '1',
            'minutes' => '*',
            'hours' => '*',
            'days' => '*',
            'months' => '*',
            'weekdays' => '*',
            'who' => 'root',
            'command' => 'system remote backup',
            'parameters' => '0',
            'description' => 'Encrypted Git synthetic schedule',
        ];
        foreach ($fields as $field => $value) {
            $job->addChild($field, $value);
        }
    }
    $config->save();
} finally {
    $config->unlock();
}
