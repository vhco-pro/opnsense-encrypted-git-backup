import { test, expect, chromium } from '@playwright/test';
import path from 'node:path';
import { writeFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';

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
      await expect(page.locator('h1')).toHaveText('Packages from VH & Co.');
      await expect(page.locator('html')).toHaveAttribute('data-theme', theme);
      await expect(page.getByRole('switch', { name: 'Dark theme' })).toHaveAttribute('aria-checked', String(theme === 'dark'));
      await expect(page.locator('.package-name')).toHaveText('os-encrypted-git-backup');
      expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
      const label = await page.locator('.address-label').boundingBox();
      const address = await page.locator('#repository-url').boundingBox();
      if (viewport.width <= 680) {
        await expect(page.locator('.hero-mark')).toBeHidden();
        expect(label.y + label.height).toBeLessThanOrEqual(address.y);
      } else {
        await expect(page.locator('.hero-mark')).toBeVisible();
        expect(Math.abs(label.y + label.height / 2 - (address.y + address.height / 2))).toBeLessThan(1);
      }
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
  await page.getByRole('switch', { name: 'Dark theme' }).click();
  await page.reload();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  await page.getByRole('switch', { name: 'Dark theme' }).click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
});

test('the header links through the company brand and a labeled GitHub icon', async ({ page }) => {
  await page.setViewportSize({ width: 320, height: 568 });
  await page.goto('/');
  const header = page.getByRole('banner');
  const brand = header.getByRole('link', { name: 'VH & Co', exact: true });
  await expect(brand).toHaveAttribute('href', 'https://vhco.pro/');
  await expect(header.getByRole('link', { name: 'vhco.pro', exact: true })).toHaveCount(0);
  const github = header.getByRole('link', { name: 'VH & Co on GitHub', exact: true });
  await expect(github).toHaveAttribute('href', 'https://github.com/vhco-pro');
  await expect(github.locator('svg')).toBeVisible();
  await expect(page.locator('.hero').getByText('pkg.vhco.pro', { exact: true })).toHaveCount(0);
  for (const name of [brand, page.getByRole('link', { name: 'VH & Co logo notice' })]) {
    const lines = await name.locator(':scope > span:last-child').evaluate(label => {
      const range = document.createRange();
      range.selectNode(label.firstChild);
      return range.getClientRects().length;
    });
    expect(lines).toBe(1);
  }
});

test('theme switch supports keyboard activation with a stable accessible label', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.goto('/');
  const themeSwitch = page.getByRole('switch', { name: 'Dark theme' });
  const thumb = themeSwitch.locator('.theme-thumb');
  await expect(themeSwitch).toHaveAttribute('aria-checked', 'false');
  await expect(themeSwitch.locator('.theme-track')).toBeVisible();
  await expect(thumb).toHaveCSS('transition-duration', '0s');
  const lightPosition = (await thumb.boundingBox()).x;
  await themeSwitch.focus();
  await page.keyboard.press('Space');
  await expect(themeSwitch).toBeFocused();
  await expect(themeSwitch).toHaveAttribute('aria-checked', 'true');
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  expect((await thumb.boundingBox()).x - lightPosition).toBe(28);
  await page.keyboard.press('Enter');
  await expect(themeSwitch).toHaveAttribute('aria-checked', 'false');
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
  expect((await thumb.boundingBox()).x).toBe(lightPosition);
});

test('URL copy resolves through the browser and denial selects the URL', async ({ page, context, browserName }) => {
  if (browserName === 'chromium') await context.grantPermissions(['clipboard-read', 'clipboard-write']);
  await page.goto('/');
  await page.getByRole('button', { name: 'Copy repository URL' }).click();
  await expect(page.getByRole('status')).toHaveText('Repository URL copied.');
  await expect(page.getByRole('button', { name: 'Copy repository URL' })).toHaveText('Copied');
  if (browserName === 'chromium') {
    expect(await page.evaluate(() => navigator.clipboard.readText())).toBe('https://pkg.vhco.pro');
  }
  await page.evaluate(() => {
    navigator.clipboard.writeText = () => Promise.reject(new DOMException('Denied', 'NotAllowedError'));
  });
  await page.getByRole('button', { name: 'Copy repository URL' }).click();
  await expect(page.getByRole('status')).toHaveText('Select Copy on your device to copy the repository URL.');
  expect(await page.evaluate(() => window.getSelection().toString())).toBe('https://pkg.vhco.pro');
  await expect(page.getByRole('button', { name: 'Copy repository URL' })).toHaveText('Selected');
  await expect(page.getByRole('status')).toBeInViewport();
});

test('storage denial preserves theme controls', async ({ page }) => {
  await page.addInitScript(() => {
    Storage.prototype.getItem = () => { throw new DOMException('Denied', 'SecurityError'); };
    Storage.prototype.setItem = () => { throw new DOMException('Denied', 'SecurityError'); };
  });
  await page.goto('/');
  await page.getByRole('switch', { name: 'Dark theme' }).click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
});

test('reading and documentation links work without JavaScript', async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false });
  try {
    const page = await context.newPage();
    await page.goto(test.info().project.use.baseURL);
    await expect(page.locator('h1')).toBeVisible();
    await expect(page.getByRole('link', { name: 'Read the installation guide' })).toHaveAttribute('href', /\/docs\/installation\.md$/);
    await expect(page.getByRole('link', { name: 'Release history' })).toHaveAttribute('href', /\/releases$/);
    await expect(page.locator('.copy-button')).toBeHidden();
    await expect(page.locator('.theme-toggle')).toBeHidden();
  } finally {
    await context.close();
  }
});


test('signing guidance directs readers to independent key verification', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('.signing-guide')).toContainText('independent trusted channel');
  await expect(page.getByRole('link', { name: 'Signing instructions' })).toHaveAttribute('href', /\/docs\/installation\.md#verify-the-signing-key$/);
  await expect(page.getByRole('link', { name: 'Release history' })).toHaveAttribute('href', /\/releases$/);
});

test('missing asset and catalogue routes return the explicit 404 document', async ({ request }) => {
  const notFound = await request.get('/404.html');
  expect(notFound.status()).toBe(200);
  const expected = await notFound.text();
  expect(expected).toContain('Page not found');
  for (const path of ['/unknown', '/packagesite.txz', '/retired/meta.conf']) {
    const response = await request.get(path);
    expect(response.status()).toBe(404);
    expect(await response.text()).toBe(expected);
  }
});

test('the footer logo opens its accessible rights notice', async ({ page }) => {
  await page.goto('/');
  const footer = page.getByRole('contentinfo');
  const publisher = footer.getByRole('link', { name: 'VH & Co logo notice', exact: true });
  await expect(publisher.locator('img')).toHaveAttribute('src', '/_site/vhco.svg');
  await expect(footer.getByRole('link', { name: 'Logo notice', exact: true })).toHaveCount(0);
  await publisher.click();
  await expect(page).toHaveURL(/\/_site\/VHCO-LOGO-NOTICE\.txt$/);
  await expect(page.locator('body')).toContainText('Copyright (c) 2026 VH & Co BV');
  await expect(page.locator('body')).toContainText('All rights reserved.');
  await expect(page.locator('body')).toContainText('display and redistribute');
});

test('the publisher fingerprint is visible to readers', async ({ page }) => {
  await page.goto('/#signing-key');
  const fingerprint = page.locator('#signing-key');
  await expect(fingerprint).toBeInViewport();
  await expect(fingerprint).toContainText('96a1a891e63c16061d968d9d1c64105d14ab64e6e9201b1c2a6dff989df06837');
});

test('native public responses match the exact approved bytes and media types', async () => {
  const result = execFileSync('bun', ['web/packages/smoke.ts', test.info().project.use.baseURL], { encoding: 'utf8' });
  expect(JSON.parse(result)).toMatchObject({ checkedResponses: 9 });
});

test('another authored repository entry fits the static layout', async ({ page }) => {
  await page.goto('/');
  await page.evaluate(() => {
    const entry = document.querySelector('.repository').cloneNode(true);
    entry.removeAttribute('aria-labelledby');
    for (const node of entry.querySelectorAll('[id]')) node.removeAttribute('id');
    entry.querySelector('h3').textContent = 'Synthetic second repository';
    document.querySelector('.repositories').append(entry);
  });
  await expect(page.locator('.repository')).toHaveCount(2);
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
});


test('actual Chromium 200 percent zoom preserves page navigation', async ({ browserName }, testInfo) => {
  test.skip(browserName !== 'chromium', 'Native tabs zoom is exercised through Chromium; Firefox runs the viewport/reflow matrix.');
  const extension = path.resolve('tests/appliance/zoom-extension');
  const context = await chromium.launchPersistentContext('', {
    channel: 'chromium',
    viewport: null,
    args: ['--window-size=1000,900', '--disable-extensions-except=' + extension, '--load-extension=' + extension],
  });
  try {
    const worker = context.serviceWorkers()[0] ?? await context.waitForEvent('serviceworker');
    const page = context.pages()[0];
    await page.goto(testInfo.project.use.baseURL);
    const measure = () => page.evaluate(() => ({ width: innerWidth, ratio: devicePixelRatio, scroll: document.documentElement.scrollWidth }));
    const before = await measure();
    const zoom = await worker.evaluate(async () => {
      const [tab] = await chrome.tabs.query({ active: true });
      await chrome.tabs.setZoom(tab.id, 2);
      return chrome.tabs.getZoom(tab.id);
    });
    await page.waitForFunction(width => innerWidth < width, before.width);
    const after = await measure();
    expect(zoom).toBe(2);
    expect(after.ratio / before.ratio).toBe(2);
    expect(Math.abs(after.width * 2 - before.width)).toBeLessThanOrEqual(2);
    expect(after.scroll).toBeLessThanOrEqual(after.width);
    // Native tab capture needs the zoomed viewport to have reached the compositor.
    await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
    const screenshot = await worker.evaluate(() => chrome.tabs.captureVisibleTab({ format: 'png' }));
    await writeFile(testInfo.outputPath('real-200-zoom.png'), Buffer.from(screenshot.split(',')[1], 'base64'));
    await page.getByRole('link', { name: 'Repository setup' }).click();
    await expect(page.getByRole('heading', { name: 'Add the repository' })).toBeInViewport();
    await testInfo.attach('native-zoom', { body: JSON.stringify({ zoom, before, after }), contentType: 'application/json' });
  } finally {
    await context.close();
  }
});
