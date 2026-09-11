import { expect, test } from '@playwright/test'
import { mkdir } from 'node:fs/promises'

// Opt-in batched visual evidence, not an always-running screenshot baseline.
test('workspace desktop and mobile visual evidence', async ({ page }) => {
  test.skip(!process.env.WORKSPACE_VISUAL, 'Set WORKSPACE_VISUAL=1 for the bounded visual review pass')
  const directory = '../.impeccable/review/workspace'
  await mkdir(directory, { recursive: true })
  for (const [name, width, theme] of [['desktop', 1440, 'light'], ['mobile', 390, 'dark']]) {
    await page.setViewportSize({ width, height: 960 })
    await page.emulateMedia({ reducedMotion: 'reduce', colorScheme: theme })
    await page.goto('/apps/harness/tests/workspace-fixture.html#/artifacts/guide')
    await expect(page.getByLabel('Document body · Markdown')).toBeVisible()
    await page.screenshot({ path: `${directory}/editor-${name}.png`, fullPage: true })
    await page.getByRole('button', { name: 'Proposals', exact: true }).click()
    await page.getByRole('button', { name: /A Saturday with the neighbors.*neighborhood-research/ }).click()
    await expect(page.locator('.diff-added')).toBeVisible()
    await page.screenshot({ path: `${directory}/review-${name}.png`, fullPage: true })
    await page.getByRole('button', { name: 'Publish…', exact: true }).click()
    await expect(page.frameLocator('iframe').getByRole('heading', { name: 'A Saturday with the neighbors' })).toBeVisible()
    await page.screenshot({ path: `${directory}/publish-${name}.png`, fullPage: true })
    await page.getByRole('button', { name: 'Close dialog' }).click()
    await page.goto('/apps/harness/tests/workspace-fixture.html#/projects/neighborhood')
    await page.getByRole('button', { name: 'Tasks', exact: true }).click()
    await expect(page.getByRole('heading', { name: 'Gather the practical details' })).toBeVisible()
    await page.screenshot({ path: `${directory}/tasks-${name}.png`, fullPage: true })
    await page.getByRole('button', { name: 'Access', exact: true }).click()
    await expect(page.getByRole('combobox', { name: 'Conversation', exact: true })).toBeVisible()
    await page.screenshot({ path: `${directory}/access-${name}.png`, fullPage: true })
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true)
  }
})
