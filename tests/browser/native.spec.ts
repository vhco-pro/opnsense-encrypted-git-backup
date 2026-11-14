import { expect, test } from '@playwright/test';

test('anonymous users cannot read status', async ({ page }) => {
  const response = await page.goto('/api/encrypted_git_backup/status/read');
  const denied = response?.status() === 401 || response?.status() === 403;
  const redirected = !new URL(page.url()).pathname.startsWith('/api/');
  expect(denied || redirected).toBeTruthy();
});

test('native settings persist and the status page renders', async ({ page }, testInfo) => {
  const user = process.env.FIXTURE_ADMIN;
  const password = process.env.FIXTURE_ADMIN_PASSWORD;
  if (!user || !password) {
    throw new Error('Set the disposable fixture administrator credentials.');
  }
  const errors: string[] = [];
  page.on('pageerror', (error) => errors.push(error.message));
  await page.goto('/');
  await page.locator('input[name=usernamefld]').fill(user);
  await page.locator('input[name=passwordfld]').fill(password);
  await page.locator('button[type=submit], input[type=submit]').first().click();
  await page.goto('/diag_backup.php');
  const branch = page.locator('[name=EncryptedGit_branch]');
  await branch.fill('browser-fixture');
  await page.locator('[name=EncryptedGit_enabled]').uncheck();
  await page.locator('[name=setup_EncryptedGit]').click();
  await page.goto('/diag_backup.php');
  await expect(branch).toHaveValue('browser-fixture');

  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/ui/encrypted_git_backup');
  await expect(page.getByRole('heading', { name: 'Encrypted Git backup status' })).toBeVisible();
  const settingsLink = page.getByRole('link', { name: 'Backups settings' });
  await expect(settingsLink).toBeVisible();
  await expect(page.locator('#backup-outcome')).toHaveText('failed');
  await expect(page.locator('#backup-verified')).toHaveText('2026-11-14T11:00:00+00:00');
  await expect(page.locator('#backup-commit')).toHaveText('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
  await settingsLink.focus();
  await expect(settingsLink).toBeFocused();
  await page.screenshot({ path: testInfo.outputPath('status-mobile.png'), fullPage: true });
  expect(errors).toEqual([]);
});
