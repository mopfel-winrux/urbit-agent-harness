import { test, expect } from '@playwright/test'

test('OpenRouter routing saves ZDR and ordered fallbacks and survives reload', async ({ page }) => {
  await page.goto('/apps/harness/tests/settings-fixture.html?page=provider&provider=openrouter')
  await page.getByRole('checkbox', { name: /^Zero data retention/ }).check()
  await page.getByRole('button', { name: 'Add fallback model' }).click()
  await page.getByLabel('Fallback 1 model').fill('z-ai/glm-5.3-flash:nitro')
  await page.getByRole('button', { name: 'Save OpenRouter' }).click()
  expect(await page.evaluate(() => window.settingsFixture.saves.at(-1))).toMatchObject({ zdr: true, fallbacks: [{ provider: 'openrouter', model: 'z-ai/glm-5.3-flash:nitro' }] })
  await page.reload()
  await expect(page.getByRole('checkbox', { name: /^Zero data retention/ })).toBeChecked()
  await expect(page.getByLabel('Fallback 1 model')).toHaveValue('z-ai/glm-5.3-flash:nitro')
  for (const [name, width] of [['desktop', 1280], ['mobile', 390]]) {
    await page.setViewportSize({ width, height: 950 })
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true)
    await page.screenshot({ path: `../.impeccable/review/model-routing-${name}.png`, fullPage: true })
  }
  await page.getByRole('button', { name: 'Remove fallback 1' }).click()
  await page.getByRole('checkbox', { name: /^Zero data retention/ }).uncheck()
  await page.getByRole('button', { name: 'Save OpenRouter' }).click()
  await page.reload()
  await expect(page.getByRole('checkbox', { name: /^Zero data retention/ })).not.toBeChecked()
  await expect(page.getByLabel('Fallback 1 model')).toHaveCount(0)
})

test('ZDR blocks a non-OpenRouter fallback without silently changing it', async ({ page }) => {
  await page.goto('/apps/harness/tests/settings-fixture.html?page=provider&provider=openrouter')
  await page.getByRole('button', { name: 'Add fallback model' }).click()
  await page.getByLabel('Fallback 1 provider').selectOption('openai')
  await page.getByLabel('Fallback 1 model').fill('gpt-5.6-luna')
  await page.getByRole('checkbox', { name: /^Zero data retention/ }).check()
  await page.getByRole('button', { name: 'Save OpenRouter' }).click()
  await expect(page.getByRole('alert')).toContainText('requires OpenRouter fallbacks')
  expect(await page.evaluate(() => window.settingsFixture.saves)).toEqual([])
})
