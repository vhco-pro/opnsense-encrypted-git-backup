<?php

declare(strict_types=1);

namespace OPNsense\EncryptedGitBackup;

final class IndexController extends \OPNsense\Base\IndexController
{
    public function indexAction(): void
    {
        $this->view->pick('OPNsense/EncryptedGitBackup/index');
    }
}
