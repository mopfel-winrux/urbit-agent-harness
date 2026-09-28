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

test('failed runs retry once, report errors, and retain schedule timing', async ({ page }) => {
  await page.goto('/apps/harness/tests/tlon-fixture.html?schedules')
  await page.evaluate(() => {
    window.tlonFixture.cron = [{ id: '0v1', lastInput: '0v9', prompt: 'Check the Austin forecast', schedule: '0 9 * * *', state: 'active', remaining: 4, next: 'tomorrow', execution: 'failed', delivery: 'delivered', retryable: true }]
    window.tlonFixture.retryError = 'Schedule changed; refresh and try again'
    window.dispatchEvent(new Event('focus'))
  })
  const retry = page.getByRole('button', { name: 'Retry failed run' })
  await retry.click()
  await expect(page.getByRole('alert')).toHaveText('Schedule changed; refresh and try again')
  await expect(retry).toBeEnabled()
  await page.evaluate(() => { window.tlonFixture.retryError = ''; window.tlonFixture.holdRetry = true })
  await retry.click()
  await expect(page.getByRole('button', { name: 'Retrying…' })).toBeDisabled()
  await expect(page.getByRole('button', { name: 'Cancel schedule' })).toBeDisabled()
  await page.evaluate(() => window.tlonFixture.releaseRetry())
  await expect(page.getByRole('status')).toHaveText('Retry requested for “Check the Austin forecast”.')
  await expect(retry).toHaveCount(0)
  await expect(page.getByText(/Execution: running/)).toBeVisible()
  expect(await page.evaluate(() => window.tlonFixture.recoveries)).toEqual([{ retryCron: { id: '0v1', input: '0v9' } }])
  expect(await page.evaluate(() => window.tlonFixture.cron[0].remaining)).toBe(4)
})

for (const [width, theme] of [[1440, 'light'], [390, 'light'], [390, 'dark']]) test(`shared schedules show multiple hands at ${width}px in ${theme}`, async ({ page }) => {
  await page.setViewportSize({ width, height: 960 })
  await page.emulateMedia({ colorScheme: theme })
  await page.goto('/apps/harness/tests/tlon-fixture.html?schedules')
  await page.evaluate(() => {
    window.tlonFixture.cron = [
      { id: '0v1', sessionId: 'daily-notes', runSessionId: 'schedule-0v1', hand: 'tlon', destination: 'dm/~nec', prompt: 'Summarize the project updates', schedule: '0 9 * * 1-5', timezone: 'UTC', kind: 'prompt', state: 'active', remaining: 4, next: '~2026.9.10..09.00.00', execution: 'failed', delivery: 'delivered', retryable: true, lastInput: '0v9' },
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
