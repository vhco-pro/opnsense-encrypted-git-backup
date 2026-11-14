import { expect, test, type Page } from '@playwright/test';

async function login(page: Page, user: string | undefined, password: string | undefined) {
  if (!user || !password) {
    throw new Error('Set the disposable fixture credentials.');
  }
  await page.goto('/');
  await page.locator('input[name=usernamefld]').fill(user);
  await page.locator('input[name=passwordfld]').fill(password);
  await page.locator('button[type=submit], input[type=submit]').first().click();
  await expect(page.locator('input[name=usernamefld]')).toHaveCount(0);
}

async function expectStatusDenied(page: Page) {
  const response = await page.goto('/api/encrypted_git_backup/status/read');
  const denied = [401, 403].includes(response?.status() ?? 0);
  const redirected = !new URL(page.url()).pathname.startsWith('/api/');
  expect(denied || redirected).toBeTruthy();
}

test('anonymous users cannot read status', async ({ page }) => {
  await expectStatusDenied(page);
});

test('authenticated user without the status privilege is denied', async ({ page }) => {
  await login(page, 'fixture-denied', process.env.FIXTURE_READER_PASSWORD);
  await expectStatusDenied(page);
});

test('read-only status access cannot change settings', async ({ page }) => {
  await login(page, 'fixture-reader', process.env.FIXTURE_READER_PASSWORD);
  await page.goto('/ui/encrypted_git_backup');
  await expect(page.getByRole('heading', { name: 'Encrypted Git backup status' })).toBeVisible();
  await page.goto('/diag_backup.php');
  const branch = page.locator('[name=EncryptedGit_branch]');
  await expect(branch).toHaveValue('migration');
  if (await branch.isEditable()) {
    await branch.fill('reader-must-not-write');
    await page.locator('[name=setup_EncryptedGit]').click();
    await page.goto('/diag_backup.php');
    await expect(branch).toHaveValue('migration');
  }
});

test('native setup rejects bad credentials and verifies successful delivery', async ({ page }, testInfo) => {
  test.setTimeout(90_000);
  const errors: string[] = [];
  page.on('pageerror', (error) => errors.push(error.message));
  await login(page, process.env.FIXTURE_ADMIN, process.env.FIXTURE_ADMIN_PASSWORD);
  await page.goto('/diag_backup.php');
  const branch = page.locator('[name=EncryptedGit_branch]');
  const key = page.locator('[name=EncryptedGit_encryptionKey]');
  await expect(branch).toHaveValue('migration');
  const activeKey = await key.inputValue();
  await key.fill('fixture-missing-credential');
  await page.locator('[name=setup_EncryptedGit]').click();
  await expect(page.getByText('Backup activation or credential validation failed.')).toBeVisible();
  await page.goto('/diag_backup.php');
  await expect(key).toHaveValue(activeKey);
  await page.locator('[name=setup_EncryptedGit]').click();
  await expect(page.getByText('Backup successful, current file list:', { exact: false })).toBeVisible();

  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/ui/encrypted_git_backup');
  await expect(page.getByRole('heading', { name: 'Encrypted Git backup status' })).toBeVisible();
  await expect(page.locator('#backup-outcome')).toHaveText('verified', { timeout: 20_000 });
  await expect(page.locator('#backup-commit')).toHaveText(/^[a-f0-9]{40}$/);
  const settingsLink = page.getByRole('link', { name: 'Backups settings' });
  await expect(settingsLink).toBeVisible();
  await settingsLink.focus();
  await expect(settingsLink).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(page).toHaveURL(/diag_backup\.php/);
  await expect(branch).toHaveValue('migration');
  await page.goto('/ui/encrypted_git_backup');
  await page.screenshot({ path: testInfo.outputPath('status-mobile.png'), fullPage: true });
  expect(errors).toEqual([]);
});

test('rejected delivery keeps the previous verified receipt visible', async ({ page }) => {
  test.setTimeout(90_000);
  test.skip(process.env.FIXTURE_PUSH_REJECTED !== '1', 'Enable fixture remote rejection for this separate run.');
  await login(page, process.env.FIXTURE_ADMIN, process.env.FIXTURE_ADMIN_PASSWORD);
  await page.goto('/ui/encrypted_git_backup');
  const commit = page.locator('#backup-commit');
  await expect(commit).toHaveText(/^[a-f0-9]{40}$/);
  const previous = await commit.textContent();
  await page.goto('/diag_backup.php');
  await page.locator('[name=setup_EncryptedGit]').click();
  await expect(page.getByText('Encrypted Git backup failed.', { exact: false })).toBeVisible();
  await page.goto('/ui/encrypted_git_backup');
  await expect(page.locator('#backup-outcome')).toHaveText('failed');
  await expect(commit).toHaveText(previous ?? '');
});
