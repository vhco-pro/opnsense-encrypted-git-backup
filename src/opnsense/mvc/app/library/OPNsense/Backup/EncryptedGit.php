<?php

declare(strict_types=1);

namespace OPNsense\Backup;

use InvalidArgumentException;
use OPNsense\Core\ACL;
use OPNsense\Core\Config;
use OPNsense\EncryptedGitBackup\Settings;
use RuntimeException;

final class EncryptedGit extends Base implements IBackupProvider
{
    private const LEGACY_HOOK = '/usr/local/etc/rc.syshook.d/config/10-git-backup';

    /** @return list<array{name: string, type: string, label: string, value: string}> */
    public function getConfigurationFields()
    {
        $model = new EncryptedGitSettings();
        $fields = [];
        $labels = [
            'enabled' => gettext('Enable'),
            'destination' => gettext('SSH repository URL'),
            'branch' => gettext('Git branch'),
            'identity' => gettext('SSH identity reference'),
            'hostTrust' => gettext('SSH known hosts reference'),
            'encryptionKey' => gettext('Encryption key identifier'),
            'freshnessHours' => gettext('Freshness limit in hours'),
        ];
        foreach ($labels as $name => $label) {
            $fields[] = [
                'name' => $name,
                'type' => $name === 'enabled' ? 'checkbox' : 'text',
                'label' => $label,
                'value' => $this->readField($model, $name),
            ];
        }
        return $fields;
    }

    /**
     * @param mixed $conf
     * @return list<string>
     */
    public function setConfiguration($conf)
    {
        $username = $_SESSION['Username'] ?? null;
        if (!is_string($username) || $username === '' || (new ACL())->hasPrivilege($username, 'user-config-readonly')) {
            return [gettext('This account cannot change encrypted Git backup settings.')];
        }
        if (!is_array($conf)) {
            return [gettext('Invalid encrypted Git backup settings.')];
        }
        $enabled = match ($conf['enabled'] ?? null) {
            '1', 'on' => '1',
            null, '', '0' => '0',
            default => null,
        };
        if ($enabled === null) {
            return [gettext('Invalid enabled setting.')];
        }
        $values = ['enabled' => $enabled];
        try {
            $validators = [
                'destination' => Settings::validateDestination(...),
                'branch' => Settings::validateBranch(...),
                'identity' => Settings::validateCredentialReference(...),
                'hostTrust' => Settings::validateCredentialReference(...),
                'encryptionKey' => Settings::validateCredentialReference(...),
            ];
            foreach ($validators as $name => $validate) {
                $value = $conf[$name] ?? '';
                if (!is_string($value)) {
                    throw new InvalidArgumentException('Backup settings must be text.');
                }
                if ($value !== '' || $enabled === '1') {
                    $validate($value);
                }
                $values[$name] = $value;
            }
            $freshness = $conf['freshnessHours'] ?? '';
            if (
                !is_string($freshness)
                || preg_match('/\A[1-9][0-9]{0,3}\z/', $freshness) !== 1
                || (int)$freshness > 8760
            ) {
                throw new InvalidArgumentException('The freshness limit must be between 1 and 8760 hours.');
            }
            $values['freshnessHours'] = $freshness;
            if ($enabled === '1') {
                self::assertLegacyHookAbsent();
                throw new RuntimeException('Encrypted Git delivery is unavailable until transport is configured.');
            }
        } catch (InvalidArgumentException | RuntimeException $exception) {
            return [$exception->getMessage()];
        }

        $model = new EncryptedGitSettings();
        $this->setModelProperties($model, $values);
        $errors = $this->validateModel($model);
        if ($errors === []) {
            $model->serializeToConfig();
            Config::getInstance()->save();
        }
        return $errors;
    }

    /** @return string */
    public function getName()
    {
        return gettext('Encrypted Git');
    }

    /** @return list<string> */
    public function backup()
    {
        self::assertLegacyHookAbsent();
        throw new RuntimeException('Encrypted Git delivery is unavailable until transport is configured.');
    }

    /** @return bool */
    public function isEnabled()
    {
        return $this->readField(new EncryptedGitSettings(), 'enabled') === '1';
    }

    private function readField(EncryptedGitSettings $model, string $name): string
    {
        $node = $model->getNodeByReference($name);

        return $node?->getValue() ?? '';
    }

    private static function assertLegacyHookAbsent(): void
    {
        clearstatcache(true, self::LEGACY_HOOK);
        if (file_exists(self::LEGACY_HOOK) || is_link(self::LEGACY_HOOK)) {
            throw new RuntimeException('Remove and drain the legacy Git capture hook before enabling backups.');
        }
    }
}
