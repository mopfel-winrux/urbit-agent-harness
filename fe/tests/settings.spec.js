import { expect, test } from '@playwright/test'

test.beforeEach(async ({ page }) => {
  await page.goto('/apps/harness/tests/settings-fixture.html')
  await expect.poll(() => page.evaluate(() => window.settingsFixture?.requests.length || 0)).toBeGreaterThan(0)
})

test('context is read from the catalog at save time, even when metadata arrives after selection', async ({ page }) => {
  await expect(page.getByRole('spinbutton')).toHaveCount(0)
  await page.getByRole('combobox', { name: 'Model', exact: true }).fill('test-model')
  await page.evaluate(() => {
    const f = window.settingsFixture
    f.resolve(f.requests.at(-1).id, { modelInfo: [{ id: 'test-model', contextWindow: 32768 }] })
  })
  await expect(page.getByText(/Provider reports 32,768/)).toBeVisible()
  await page.getByRole('button', { name: 'Save defaults' }).click()
  expect(await page.evaluate(() => window.settingsFixture.saves.at(-1)['max-context'])).toBe(32768)
})

test('switching providers fences stale catalogs and does not reuse another model’s limit', async ({ page }) => {
  await page.getByRole('combobox', { name: 'Provider', exact: true }).selectOption('anthropic')
  await expect.poll(() => page.evaluate(() => window.settingsFixture.requests.at(-1).provider)).toBe('anthropic')
  await page.evaluate(() => {
    const f = window.settingsFixture
    f.resolve(f.requests.at(-1).id, { modelInfo: [{ id: 'test-model', contextWindow: 64000 }] })
    for (const r of f.requests.filter((r) => r.provider === 'openrouter')) f.resolve(r.id, { modelInfo: [{ id: 'test-model', contextWindow: 999999 }] })
  })
  await page.getByRole('combobox', { name: 'Model', exact: true }).fill('test-model')
  await expect(page.getByText(/Provider reports 64,000/)).toBeVisible()
  await page.getByRole('button', { name: 'Save defaults' }).click()
  expect(await page.evaluate(() => window.settingsFixture.saves.at(-1)['max-context'])).toBe(64000)
  await page.getByRole('combobox', { name: 'Model', exact: true }).fill('unknown-model')
  await page.getByRole('button', { name: 'Save defaults' }).click()
  await expect.poll(() => page.evaluate(() => window.settingsFixture.saves.at(-1)['max-context'])).toBe(80000)
})
