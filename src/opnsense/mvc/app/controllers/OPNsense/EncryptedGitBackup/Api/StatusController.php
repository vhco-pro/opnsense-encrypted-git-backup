<?php

declare(strict_types=1);

namespace OPNsense\EncryptedGitBackup\Api;

use OPNsense\Base\ApiControllerBase;
use OPNsense\Core\Backend;

final class StatusController extends ApiControllerBase
{
    /** @return array<string, mixed> */
    public function readAction(): array
    {
        $result = json_decode((new Backend())->configdRun('encryptedgit status'), true);
        if (!is_array($result)) {
            return ['outcome' => 'unavailable'];
        }
        return array_intersect_key($result, ['attempt' => true, 'verification' => true]);
    }
}
