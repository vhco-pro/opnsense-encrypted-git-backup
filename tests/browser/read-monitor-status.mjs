import { chromium } from '@playwright/test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
const browser = await chromium.launch();
try {
  const context = await browser.newContext({ignoreHTTPSErrors: true});
  const page = await context.newPage();
  const base = new URL(process.env.FIXTURE_APPLIANCE_URL);
  assert.equal(base.hostname, '127.0.0.1');
  await page.goto(base.href);
  await page.locator('[name=usernamefld]').fill('fixture-reader');
  await page.locator('[name=passwordfld]').fill(process.env.FIXTURE_READER_PASSWORD);
  await page.locator('button[type=submit],input[type=submit]').first().click();
  await page.locator('[name=usernamefld]').waitFor({state:'detached'});
  const response = await context.request.get(new URL('/api/encrypted_git_backup/status/read', base).href);
  assert.equal(response.status(), 200);
  const body = await response.json();
  assert.deepEqual(Object.keys(body.attempt).sort(), ['attempt','category','outcome','target']);
  assert.equal(body.attempt.category, 'activation');
  assert.equal(body.attempt.outcome, 'failed');
  assert.match(body.attempt.target, /^[a-f0-9]{64}$/);
  await fs.writeFile(process.argv[2], JSON.stringify(body));
} finally { await browser.close(); }
