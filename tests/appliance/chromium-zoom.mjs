import fs from 'node:fs/promises';
import { chromium } from '@playwright/test';
import assert from 'node:assert/strict';
import path from 'node:path';
const root = process.argv[2];
const url = new URL(process.env.FIXTURE_APPLIANCE_URL);
assert.equal(url.hostname, '127.0.0.1');
const extension = path.resolve('tests/appliance/zoom-extension');
const context = await chromium.launchPersistentContext('', {
 channel:'chromium', ignoreHTTPSErrors:true, viewport:null,
 args:['--window-size=800,900','--disable-extensions-except='+extension,'--load-extension='+extension]
});
try {
 const worker = context.serviceWorkers()[0] ?? await context.waitForEvent('serviceworker');
 const page = context.pages()[0];
 await page.goto(url.href);
 await page.locator('input[name=usernamefld]').fill('fixture-reader');
 await page.locator('input[name=passwordfld]').fill(process.env.FIXTURE_READER_PASSWORD);
 await page.locator('button[type=submit], input[type=submit]').first().click();
 await page.goto(new URL('/ui/encrypted_git_backup', url).href);
 await page.locator('#backup-commit').filter({hasText:/^[a-f0-9]{40}$/}).waitFor();
 const measure = () => page.evaluate(() => ({width:innerWidth,dpr:devicePixelRatio,scroll:document.documentElement.scrollWidth,commit:document.querySelector('#backup-commit').getBoundingClientRect().right}));
 const before = await measure();
 const zoom = await worker.evaluate(async () => {
  const [tab] = await chrome.tabs.query({active:true});
  await chrome.tabs.setZoom(tab.id,2);
  return chrome.tabs.getZoom(tab.id);
 });
 await page.waitForFunction(width => innerWidth < width, before.width);
 const after = await measure();
 console.log(JSON.stringify({zoom,before,after}));
 assert.equal(zoom,2);
 assert.equal(after.dpr/before.dpr,2);
 assert.ok(Math.abs(after.width*2-before.width)<=2);
 assert.ok(after.scroll<=after.width && after.commit<=after.width);
 const shot = await worker.evaluate(() => chrome.tabs.captureVisibleTab({format:'png'}));
 await fs.writeFile(root+'/chromium-real-zoom.png',Buffer.from(shot.split(',')[1],'base64'));
} finally { await context.close(); }
