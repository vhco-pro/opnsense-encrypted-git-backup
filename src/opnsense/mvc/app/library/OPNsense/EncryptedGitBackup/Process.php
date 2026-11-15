<?php

declare(strict_types=1);

namespace OPNsense\EncryptedGitBackup;

use RuntimeException;

final class Process
{
    /**
     * @param non-empty-list<string> $arguments
     * @param array<string, string> $environment
     * @return array{int, string}
     */
    public static function run(
        array $arguments,
        string $directory,
        array $environment,
        float $timeout,
        int $maxOutput = 65536
    ): array {
        $process = proc_open(
            $arguments,
            [
                0 => ['file', '/dev/null', 'r'],
                1 => ['pipe', 'w'],
                2 => ['file', '/dev/null', 'w'],
            ],
            $pipes,
            $directory,
            $environment
        );
        if ($process === false) {
            throw new RuntimeException('Could not start the backup process.');
        }

        $output = '';
        $deadline = hrtime(true) + (int) ($timeout * 1_000_000_000.0);
        try {
            if (!stream_set_blocking($pipes[1], false)) {
                throw new RuntimeException('Could not configure the backup process output.');
            }
            while (true) {
                $chunk = fread($pipes[1], 8192);
                if ($chunk === false) {
                    throw new RuntimeException('Could not read the backup process output.');
                }
                $output .= $chunk;
                if (strlen($output) > $maxOutput) {
                    throw new RuntimeException('The backup process exceeded its output limit.');
                }
                $status = proc_get_status($process);
                if (!$status['running'] && feof($pipes[1])) {
                    return [$status['exitcode'], $output];
                }
                if (hrtime(true) >= $deadline) {
                    throw new RuntimeException('The backup process exceeded its time limit.');
                }
                if ($chunk === '') {
                    usleep(10_000);
                }
            }
        } finally {
            fclose($pipes[1]);
            if (proc_get_status($process)['running']) {
                proc_terminate($process, 9);
            }
            proc_close($process);
        }
    }
}
