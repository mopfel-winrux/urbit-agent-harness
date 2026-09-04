import { defineConfig } from '@playwright/test'

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  workers: 2,
  use: {
    baseURL: 'http://127.0.0.1:4179',
    // Set PLAYWRIGHT_CHANNEL=chrome to use an installed Chrome instead.
    channel: process.env.PLAYWRIGHT_CHANNEL || undefined,
    viewport: { width: 1280, height: 900 },
    trace: 'retain-on-failure',
  },
  webServer: {
    command: 'npm run dev -- --host 127.0.0.1 --port 4179 --strictPort',
    url: 'http://127.0.0.1:4179/apps/harness/tests/fixture.html',
  },
})
