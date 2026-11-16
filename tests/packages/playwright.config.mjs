import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: '.',
  testMatch: 'page.spec.mjs',
  outputDir: '../../work/packages-browser/' + (process.env.GITHUB_RUN_ID ? `${process.env.GITHUB_RUN_ID}-${process.env.GITHUB_RUN_ATTEMPT}` : Date.now()),
  timeout: 30_000,
  workers: 1,
  reporter: 'list',
  webServer: {
    command: 'bun run packages:preview',
    url: 'http://127.0.0.1:39441',
    reuseExistingServer: false,
    timeout: 60_000,
    env: { WRANGLER_SEND_METRICS: 'false', CI: 'true' },
  },
  use: {
    baseURL: 'http://127.0.0.1:39441',
    colorScheme: 'light',
    reducedMotion: 'reduce',
  },
  projects: [
    { name: 'chromium', use: { browserName: 'chromium' } },
    { name: 'firefox', use: { browserName: 'firefox' } },
  ],
});
