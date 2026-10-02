import { expect, test } from '@playwright/test'
import { defaultConfig } from '../src/defaults.js'
import { PROVIDERS } from '../src/providers.js'

for (const surface of ['global', 'conversation']) test(`${surface}: no speculative catalog before saved provider loads`, async ({ page }) => {
  await page.addInitScript((config) => sessionStorage.setItem('settings-fixture-config', JSON.stringify(config)), {
    ...defaultConfig(), url: PROVIDERS.anthropic.endpoint, model: PROVIDERS.anthropic.model,
  })
  await page.goto(`/apps/harness/tests/settings-fixture.html?page=${surface}&hold-config`)
  await expect.poll(() => page.evaluate(() => typeof window.settingsFixture.releaseConfig)).toBe('function')
  expect(await page.evaluate(() => window.settingsFixture.requests)).toEqual([])
  await page.evaluate(() => window.settingsFixture.releaseConfig())
  await expect.poll(() => page.evaluate(() => window.settingsFixture.requests.map((r) => r.provider))).toEqual(['anthropic'])
  await expect(page.getByRole('combobox', { name: 'Provider', exact: true })).toHaveText('Anthropic')
})

test('conversation reads use notifications with a fifteen-second safety poll', async ({ page }) => {
  await page.clock.install()
  await page.goto('/apps/harness/tests/settings-fixture.html?page=app')
  await expect(page.getByRole('button', { name: 'daily-notes', exact: true })).toBeVisible()
  const lists = () => page.evaluate(() => window.settingsFixture.calls.filter((c) => c === 'session/list').length)
  expect(await page.evaluate(() => window.settingsFixture.calls.filter((c) => c === 'harness/onboarding/ensure').length)).toBe(1)
  await page.clock.runFor(14_000)
  expect(await lists()).toBe(0)
  await page.evaluate(() => window.settingsFixture.sessionsChanged())
  await page.clock.runFor(300)
  expect(await lists()).toBe(1)
  await page.clock.runFor(15_000)
  expect(await lists()).toBe(2)
})

for (const surface of ['global', 'conversation']) test(`${surface}: idle refresh retains the visible model catalog`, async ({ page }) => {
  await page.clock.install()
  await page.goto(`/apps/harness/tests/settings-fixture.html?page=${surface}`)
  await expect.poll(() => page.evaluate(() => window.settingsFixture.requests.length)).toBe(1)
  await page.evaluate((model) => window.settingsFixture.resolve(0, {
    models: [model], modelInfo: [{ id: model, contextWindow: 128_000 }],
  }), defaultConfig().model)
  await expect(page.getByText(/Provider reports .*128,000.*applied automatically on save/)).toBeVisible()
  await page.evaluate(() => {
    window.catalogRemovals = []
    new MutationObserver((records) => {
      for (const record of records) for (const node of record.removedNodes) {
        if (node.textContent.includes('Provider reports')) window.catalogRemovals.push(node.textContent)
      }
    }).observe(document.querySelector('.settings-grid'), { childList: true, subtree: true })
  })
  const before = await page.evaluate(() => window.settingsFixture.reads.length)
  await page.clock.runFor(31_000)
  await expect.poll(() => page.evaluate(() => window.settingsFixture.reads.length)).toBeGreaterThan(before)
  await expect(page.getByText(/Provider reports .*128,000.*applied automatically on save/)).toBeVisible()
  expect(await page.evaluate(() => window.catalogRemovals)).toEqual([])
  expect(await page.evaluate(() => window.settingsFixture.requests.length)).toBe(1)
})
