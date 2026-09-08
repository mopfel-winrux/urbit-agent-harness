import { expect, test } from '@playwright/test'

for (const width of [390, 1280]) test(`default and individual settings have separate entry points at ${width}px`, async ({ page }) => {
  await page.setViewportSize({ width, height: 844 })
  await page.goto('/apps/harness/tests/settings-fixture.html?page=app#/daily-notes')
  await expect(page.locator('.chat-heading strong')).toHaveText('daily-notes')
  const openNavigation = async () => {
    if (width < 760) await page.getByRole('button', { name: 'Open navigation' }).click()
  }
  await openNavigation()
  const row = page.locator('.chat-row').filter({ has: page.getByRole('button', { name: 'reading-list', exact: true }) })
  await row.hover()
  await row.getByRole('button', { name: 'Settings for reading-list', exact: true }).click()
  await expect(page).toHaveURL(/#\/settings\/reading-list$/)
  const sections = page.getByRole('navigation', { name: 'Settings sections' })
  await expect(sections.getByRole('button', { name: 'Conversation', exact: true })).toHaveAttribute('aria-current', 'page')
  await expect.poll(() => page.evaluate(() => window.settingsFixture.reads.includes('session/reading-list'))).toBe(true)
  if (width < 760) await expect(page.getByRole('dialog', { name: 'Navigation' })).not.toBeVisible()

  await openNavigation()
  await page.getByRole('button', { name: 'Settings', exact: true }).click()
  await expect(page).toHaveURL(/#\/settings$/)
  await expect(sections.getByRole('button', { name: 'Defaults', exact: true })).toHaveAttribute('aria-current', 'page')
  await expect(sections.getByRole('button', { name: 'Conversation', exact: true })).toHaveCount(0)

  await sections.getByRole('button', { name: 'Providers', exact: true }).click()
  await openNavigation()
  await page.getByRole('button', { name: 'Settings', exact: true }).click()
  await expect(sections.getByRole('button', { name: 'Defaults', exact: true })).toHaveAttribute('aria-current', 'page')
  await page.goBack()
  await page.goBack()
  await expect(page).toHaveURL(/#\/settings\/reading-list$/)
  await expect(sections.getByRole('button', { name: 'Conversation', exact: true })).toHaveAttribute('aria-current', 'page')
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true)
})
