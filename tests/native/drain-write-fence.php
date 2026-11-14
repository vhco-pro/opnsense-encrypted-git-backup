<?php

declare(strict_types=1);

// Match the PHP flock used by every released encrypted Git worker.
if (!isset($argv) || count($argv) !== 3) {
    throw new RuntimeException('Supply isolated state, fixture directory.');
}
[, $state, $fixture] = $argv;
$lock = fopen($state . '/delivery.lock', 'c');
if ($lock === false || !flock($lock, LOCK_EX | LOCK_NB)) {
    throw new RuntimeException('Delivery is still admitted. Keep rollback on hold.');
}
try {
    if (!rename($state . '/activation.json', $fixture . '/checkpoint')) {
        throw new RuntimeException('Could not withhold the active checkpoint.');
    }
    touch($fixture . '/release-config');
    $deadline = time() + 30;
    while (!is_file($fixture . '/worker-drained')) {
        clearstatcache();
        if (time() >= $deadline) {
            throw new RuntimeException('Admitted worker did not drain. Keep rollback on hold.');
        }
        sleep(1);
    }
} finally {
    fclose($lock);
}
