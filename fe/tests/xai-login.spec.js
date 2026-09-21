import { expect, test } from '@playwright/test'
import { PROVIDERS } from '../src/providers.js'

for (const width of [390, 1280]) test(`xAI login selects an available subscription model and survives reload at ${width}px`, async ({ page }, testInfo) => {
  await page.setViewportSize({ width, height: 900 })
  await page.goto('/apps/harness/tests/settings-fixture.html?page=provider&provider=xai')
  await page.getByLabel('Authentication').selectOption('device')
  await page.getByRole('button', { name: 'Sign in with device code' }).click()
  await expect(page.getByText('ABCD-1234')).toBeVisible()
  await expect(page.getByRole('link', { name: 'Open sign-in page' })).toHaveAttribute('href', 'https://accounts.x.ai/oauth2/device')
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true)
  await page.screenshot({ path: testInfo.outputPath('device-login.png') })
  await page.evaluate(() => { window.settingsFixture.xaiComplete = true })
  await expect(page.getByText('Connected', { exact: true })).toBeVisible()
  expect(await page.evaluate(() => window.settingsFixture.saves.at(-1))).toMatchObject({ url: PROVIDERS.xai.deviceEndpoint, model: 'grok-build', key: '' })
  expect(await page.evaluate(() => window.settingsFixture.credentials)).toEqual([])
  await page.reload()
  await expect(page.getByLabel('Authentication')).toHaveValue('device')
  await expect(page.getByLabel('Model', { exact: true })).toHaveValue('grok-build')
  await expect(page.getByRole('button', { name: 'Sign in again' })).toBeVisible()
})

test('xAI denial is visible and retryable without saving a model', async ({ page }) => {
  await page.goto('/apps/harness/tests/settings-fixture.html?page=provider&provider=xai')
  await page.getByLabel('Authentication').selectOption('device')
  await page.getByRole('button', { name: 'Sign in with device code' }).click()
  await page.evaluate(() => { window.settingsFixture.xaiError = true })
  await expect(page.getByRole('alert')).toContainText('authorization was denied')
  await expect(page.getByRole('button', { name: 'Sign in with device code' })).toBeEnabled()
  expect(await page.evaluate(() => window.settingsFixture.saves)).toEqual([])
})

test('a default-model save failure remains visible after credentials connect', async ({ page }) => {
  await page.goto('/apps/harness/tests/settings-fixture.html?page=provider&provider=xai')
  await page.getByLabel('Authentication').selectOption('device')
  await page.getByRole('button', { name: 'Sign in with device code' }).click()
  await page.evaluate(() => { window.settingsFixture.failSave = true; window.settingsFixture.xaiComplete = true })
  await expect(page.getByRole('alert')).toContainText('Configuration save failed')
  await expect(page.getByRole('button', { name: 'Sign in again' })).toBeEnabled()
  expect(await page.evaluate(() => window.settingsFixture.saves)).toEqual([])
})
