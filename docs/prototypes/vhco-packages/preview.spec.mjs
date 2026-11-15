import { test, expect } from '@playwright/test';

const viewports = [
  { width: 320, height: 568 },
  { width: 390, height: 844 },
  { width: 844, height: 390 },
  { width: 768, height: 1024 },
  { width: 1280, height: 720 },
  { width: 1440, height: 900 },
];

for (const theme of ['light', 'dark']) {
  for (const viewport of viewports) {
    test(`${theme} at ${viewport.width} by ${viewport.height}`, async ({ page }, testInfo) => {
      const errors = [];
      page.on('pageerror', error => errors.push(error.message));
      page.on('response', response => {
        if (response.status() >= 400) errors.push(`HTTP ${response.status()}`);
      });
      await page.setViewportSize(viewport);
      await page.emulateMedia({ colorScheme: theme, reducedMotion: 'reduce' });
      await page.goto('/');
      await expect(page.locator('h1')).toHaveText('Packages fromVH & Co.');
      await expect(page.locator('html')).toHaveAttribute('data-theme', theme);
      await expect(page.locator('.package-name')).toHaveText('os-encrypted-git-backup');
      expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
      for (const button of await page.locator('button:visible, .button').all()) {
        expect((await button.boundingBox()).height).toBeGreaterThanOrEqual(44);
      }
      expect(await page.locator('h1').evaluate(element => parseFloat(getComputedStyle(element).fontSize))).toBeGreaterThanOrEqual(35);
      await page.getByRole('link', { name: 'Repository setup' }).click();
      await expect(page).toHaveURL(/#repository-setup$/);
      await expect(page.getByRole('heading', { name: 'Add the repository' })).toBeInViewport();
      await page.screenshot({ path: testInfo.outputPath(`${theme}.png`), fullPage: true });
      expect(errors).toEqual([]);
    });
  }
}

test('theme selection survives reload and keyboard navigation reaches setup', async ({ page }) => {
  await page.goto('/');
  await page.keyboard.press('Tab');
  await expect(page.getByRole('link', { name: 'Skip to content' })).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(page).toHaveURL(/#main$/);
  await page.getByRole('button', { name: 'Switch to dark theme' }).click();
  await page.reload();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  await page.getByRole('button', { name: 'Switch to light theme' }).click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
});

test('URL copy resolves through the browser and denial selects the URL', async ({ page, context, browserName }) => {
  if (browserName === 'chromium') await context.grantPermissions(['clipboard-read', 'clipboard-write']);
  await page.goto('/');
  await page.getByRole('button', { name: 'Copy repository URL' }).click();
  await expect(page.getByRole('status')).toHaveText('Repository URL copied.');
  if (browserName === 'chromium') {
    expect(await page.evaluate(() => navigator.clipboard.readText())).toBe('https://pkg.vhco.pro');
  }
  await page.evaluate(() => {
    navigator.clipboard.writeText = () => Promise.reject(new DOMException('Denied', 'NotAllowedError'));
  });
  await page.getByRole('button', { name: 'Copy repository URL' }).click();
  await expect(page.getByRole('status')).toHaveText('Select Copy on your device to copy the repository URL.');
  expect(await page.evaluate(() => window.getSelection().toString())).toBe('https://pkg.vhco.pro');
});

test('storage denial preserves theme controls', async ({ page }) => {
  await page.addInitScript(() => {
    Storage.prototype.getItem = () => { throw new DOMException('Denied', 'SecurityError'); };
    Storage.prototype.setItem = () => { throw new DOMException('Denied', 'SecurityError'); };
  });
  await page.goto('/');
  await page.getByRole('button', { name: 'Switch to dark theme' }).click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
});

test('reading and documentation links work without JavaScript', async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false });
  try {
    const page = await context.newPage();
    await page.goto(process.env.VHCO_PACKAGES_PREVIEW_URL);
    await expect(page.locator('h1')).toBeVisible();
    await expect(page.getByRole('link', { name: 'Read the installation guide' })).toHaveAttribute('href', /\/docs\/installation\.md$/);
    await expect(page.getByRole('link', { name: 'Signing keys and release notes' })).toHaveAttribute('href', /\/releases$/);
    await expect(page.locator('.copy-button')).toBeHidden();
    await expect(page.locator('.theme-toggle')).toBeHidden();
  } finally {
    await context.close();
  }
});
