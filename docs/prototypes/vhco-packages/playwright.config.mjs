import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: '.',
  testMatch: 'preview.spec.mjs',
  outputDir: '../../../work/packages-preview',
  timeout: 20_000,
  workers: 1,
  reporter: 'list',
  use: {
    baseURL: process.env.VHCO_PACKAGES_PREVIEW_URL,
    colorScheme: 'light',
    reducedMotion: 'reduce',
  },
  projects: [
    { name: 'chromium', use: { browserName: 'chromium' } },
    { name: 'firefox', use: { browserName: 'firefox' } },
  ],
});
