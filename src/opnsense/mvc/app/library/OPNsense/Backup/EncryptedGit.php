<?php

declare(strict_types=1);

namespace OPNsense\Backup;

use InvalidArgumentException;
use OPNsense\Core\ACL;
use OPNsense\Core\Backend;
use OPNsense\Core\Config;
use OPNsense\EncryptedGitBackup\NativeRun;
use OPNsense\EncryptedGitBackup\Settings;
use RuntimeException;

final class EncryptedGit extends Base implements IBackupProvider
{
    /** @return list<array{name: string, type: string, label: string, value: string}> */
    #[\Override]
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
    #[\Override]
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
                $response = (new Backend())->configdpRun(
                    'encryptedgit check',
                    [$values['destination'], $values['branch'], $values['identity'],
                        $values['hostTrust'], $values['encryptionKey']]
                );
                if (trim($response) !== 'ready') {
                    throw new RuntimeException('Backup activation or credential validation failed.');
                }
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
    #[\Override]
    public function getName()
    {
        return gettext('Encrypted Git');
    }

    /** @return list<string> */
    #[\Override]
    public function backup()
    {
        if (!$this->isEnabled()) {
            return [];
        }
        $response = (new Backend())->configdRun('encryptedgit run', false, 240);
        $result = json_decode($response, true);
        $commit = is_array($result) ? ($result['commit'] ?? null) : null;
        if (!is_string($commit) || preg_match('/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/', $commit) !== 1) {
            throw new RuntimeException('Encrypted Git backup failed. Check the encrypted backup status.');
        }
        return ['config.xml.enc'];
    }

    public function runConfigured(): string
    {
        $model = new EncryptedGitSettings();
        if ($this->readField($model, 'enabled') !== '1') {
            throw new RuntimeException('Encrypted Git backup is disabled.');
        }
        return NativeRun::run(
            $this->readField($model, 'destination'),
            $this->readField($model, 'branch'),
            $this->readField($model, 'identity'),
            $this->readField($model, 'hostTrust'),
            $this->readField($model, 'encryptionKey')
        );
    }

    /** @return bool */
    #[\Override]
    public function isEnabled()
    {
        return $this->readField(new EncryptedGitSettings(), 'enabled') === '1';
    }

    private function readField(EncryptedGitSettings $model, string $name): string
    {
        $node = $model->getNodeByReference($name);

        return $node?->getValue() ?? '';
    }
}
