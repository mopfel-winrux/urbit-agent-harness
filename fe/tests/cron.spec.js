import { expect, test } from '@playwright/test'
import { mkdir } from 'node:fs/promises'

test('Tlon links to shared schedules instead of owning a schedule panel', async ({ page }) => {
  await page.goto('/apps/harness/tests/tlon-fixture.html')
  await expect(page.getByRole('heading', { name: 'Scheduled work' })).toHaveCount(0)
  await expect(page.getByRole('link', { name: 'Settings → Schedules' })).toHaveAttribute('href', '#/settings?tab=schedules')
})

test('schedule errors do not claim there are no jobs, and support retry', async ({ page }) => {
  await page.goto('/apps/harness/tests/tlon-fixture.html?schedules')
  await expect(page.getByText('No schedules yet.', { exact: false })).toBeVisible()
  await page.evaluate(() => { window.tlonFixture.cronError = 'Scheduler temporarily unavailable'; window.dispatchEvent(new Event('focus')) })
  await expect(page.getByRole('alert')).toHaveText('Scheduler temporarily unavailable')
  await expect(page.getByText('No schedules yet.', { exact: false })).toHaveCount(0)
  await page.evaluate(() => { window.tlonFixture.cronError = '' })
  await page.getByRole('button', { name: 'Retry loading schedules' }).click()
  await expect(page.getByRole('alert')).toHaveCount(0)
  await expect(page.getByText('No schedules yet.', { exact: false })).toBeVisible()
})

for (const [width, theme] of [[1440, 'light'], [390, 'light'], [390, 'dark']]) test(`shared schedules show multiple hands at ${width}px in ${theme}`, async ({ page }) => {
  await page.setViewportSize({ width, height: 960 })
  await page.emulateMedia({ colorScheme: theme })
  await page.goto('/apps/harness/tests/tlon-fixture.html?schedules')
  await page.evaluate(() => {
    window.tlonFixture.cron = [
      { id: '0v1', sessionId: 'daily-notes', runSessionId: 'schedule-0v1', hand: 'tlon', destination: 'dm/~nec', prompt: 'Summarize the project updates', schedule: '0 9 * * 1-5', timezone: 'UTC', kind: 'prompt', state: 'active', remaining: 4, next: '~2026.9.10..09.00.00', execution: 'completed', delivery: 'delivered' },
      { id: '0v2', sessionId: 'team-room', runSessionId: 'schedule-0v2', hand: 'test-chat', destination: 'room/project-planning', prompt: 'Review the launch checklist', schedule: '2026-09-10T10:00:00-05:00', timezone: 'UTC-05:00', kind: 'reminder', state: 'complete', remaining: 0, execution: 'completed', delivery: 'uncertain', reason: 'Delivery outcome needs inspection before another send.' },
      { id: '0v3', sessionId: 'reading-list', runSessionId: 'schedule-0v3', hand: 'test-chat', destination: 'room/reading-list', prompt: 'A settled reminder', schedule: '2026-09-09T09:00:00Z', timezone: 'UTC', kind: 'reminder', state: 'complete', remaining: 0, execution: 'completed', delivery: 'delivered', clearable: true },
    ]
    window.dispatchEvent(new Event('focus'))
  })
  await expect(page.getByRole('heading', { name: 'Settings', exact: true })).toBeVisible()
  await expect(page.getByRole('button', { name: 'Schedules', exact: true })).toHaveAttribute('aria-current', 'page')
  await expect(page.getByText('Hand: test-chat · Destination: room/project-planning', { exact: true })).toBeVisible()
  await expect(page.getByText(/Execution: completed · Delivery: uncertain/)).toBeVisible()
  await expect(page.getByRole('link', { name: 'Source conversation' }).first()).toHaveAttribute('href', '#/daily-notes')
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true)
  if (process.env.CRON_SCREENSHOTS) {
    await mkdir('../.impeccable/review/cron', { recursive: true })
    await page.screenshot({ path: `../.impeccable/review/cron/${width === 1440 ? 'desktop' : `mobile-${theme}`}.png`, fullPage: true })
  }
})
