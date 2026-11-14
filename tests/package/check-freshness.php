<?php

declare(strict_types=1);

use OPNsense\EncryptedGitBackup\Freshness;

require dirname(__DIR__, 2) . '/src/opnsense/mvc/app/library/OPNsense/EncryptedGitBackup/Freshness.php';

$args = $_SERVER['argv'] ?? null;
if (
    !is_array($args) || !in_array(count($args), [5, 7], true)
    || !is_string($args[1]) || !is_string($args[2]) || !is_string($args[3]) || !is_string($args[4])
    || !ctype_digit($args[4]) || (int)$args[4] < 1
) {
    fwrite(
        STDERR,
        "Usage: check-freshness.php metadata.json remote-commit artifact-path max-age-seconds"
            . " [expected-target-sha256 native-status.json]\n"
    );
    exit(64);
}
$metadata = file_get_contents($args[1], false, null, 0, 65537);
$digest = hash_file('sha256', $args[3]);
if ($metadata === false || strlen($metadata) > 65536 || $digest === false) {
    exit(2);
}
$receipt = json_decode($metadata, true, 8);
if (!is_array($receipt) || array_key_exists('commit', $receipt)) {
    exit(2);
}
$receipt['commit'] = $args[2];
$fresh = Freshness::retained($receipt, $args[2], $digest, new DateTimeImmutable(), (int)$args[4]);
if (count($args) === 7) {
    if (!is_string($args[5]) || preg_match('/\A[a-f0-9]{64}\z/', $args[5]) !== 1 || !is_string($args[6])) {
        exit(64);
    }
    $status = is_readable($args[6]) ? file_get_contents($args[6], false, null, 0, 65537) : false;
    $outcome = Freshness::attemptOutcome(
        is_string($status) && strlen($status) <= 65536 ? json_decode($status, true, 8) : null,
        $args[5]
    );
    echo json_encode(['remoteFresh' => $fresh, 'attemptOutcome' => $outcome], JSON_THROW_ON_ERROR) . PHP_EOL;
    exit($fresh && $outcome !== 'failed' ? 0 : 1);
}
exit($fresh ? 0 : 1);
