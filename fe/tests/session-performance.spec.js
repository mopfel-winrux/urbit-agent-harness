import { expect, test } from '@playwright/test'

test.beforeEach(async ({ page }) => { await page.clock.install() })
const reads = (page) => page.evaluate(() => window.harnessFixture.snapshotReads)

for (const history of [95, 4096]) test(`idle read budget stays bounded with ${history} retained messages`, async ({ page }) => {
  await page.goto(`/apps/harness/tests/fixture.html?history&history-count=${history}`)
  await expect(page.locator('.message.assistant')).toHaveCount(40)
  const start = await reads(page)
  await page.clock.runFor(60_000)
  expect(await reads(page) - start).toBe(6)
  await page.getByRole('button', { name: 'Load earlier messages', exact: true }).click()
  await expect(page.locator('.message.assistant')).toHaveCount(80)
  await page.clock.runFor(10_000)
  await expect(page.locator('.message.assistant')).toHaveCount(80)
})

test('notifications wake idle views immediately; busy snapshots retain the 600ms cadence', async ({ page }) => {
  await page.goto('/apps/harness/tests/fixture.html')
  await expect(page.getByRole('heading', { name: 'A small head, capable hands' })).toBeAttached()
  await page.evaluate(() => window.harnessFixture.update({ phase: 'thinking', streaming: 'First update' }))
  await expect(page.locator('.thinking-message')).toContainText('First update')
  const start = await reads(page)
  await page.evaluate(() => window.harnessFixture.update({ streaming: 'Silent update' }, false))
  await page.clock.runFor(600)
  await expect(page.locator('.thinking-message')).toContainText('Silent update')
  expect(await reads(page) - start).toBe(1)
  await page.clock.runFor(5400)
  expect(await reads(page) - start).toBe(10)
  await page.evaluate(() => window.harnessFixture.update({ phase: 'idle', streaming: '' }))
  await expect(page.locator('.thinking-message')).toHaveCount(0)
  const idle = await reads(page)
  await page.clock.runFor(9000)
  expect(await reads(page)).toBe(idle)
})

test('the first stream chunk wakes an idle view and reconnect/focus refresh immediately', async ({ page }) => {
  await page.goto('/apps/harness/tests/fixture.html')
  await expect(page.getByRole('heading', { name: 'A small head, capable hands' })).toBeAttached()
  await page.evaluate(() => window.harnessFixture.update({ phase: 'thinking', streaming: 'Stream wake' }, true, 'harness_agent_stream_chunk'))
  await expect(page.locator('.thinking-message')).toContainText('Stream wake')
  const before = await reads(page)
  await page.evaluate(() => window.dispatchEvent(new Event('focus')))
  await expect.poll(() => reads(page)).toBe(before + 1)
})

test('a change during an in-flight snapshot gets one trailing refresh', async ({ page }) => {
  await page.goto('/apps/harness/tests/fixture.html')
  await expect(page.getByRole('heading', { name: 'A small head, capable hands' })).toBeAttached()
  const before = await reads(page)
  await page.evaluate(() => { window.harnessFixture.holdSnapshots = true; window.harnessFixture.update({ phase: 'thinking', streaming: 'Older' }) })
  await expect.poll(() => reads(page)).toBe(before + 1)
  await page.evaluate(() => {
    window.harnessFixture.update({ streaming: 'Newest' })
    window.harnessFixture.holdSnapshots = false
    window.harnessFixture.completeSnapshot(0)
  })
  await expect(page.locator('.thinking-message')).toContainText('Newest')
  expect(await reads(page)).toBe(before + 2)
})
