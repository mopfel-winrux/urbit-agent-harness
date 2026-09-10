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
  await expect(page.getByRole('combobox', { name: 'Provider', exact: true })).toHaveValue('anthropic')
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
