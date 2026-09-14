import { expect, test } from '@playwright/test'
import { mkdir } from 'node:fs/promises'

test('tasks have an optional inspection surface', async ({ page }) => {
  test.skip(!process.env.WORKSPACE_VISUAL, 'Set WORKSPACE_VISUAL=1 to capture the note surface')
  const directory = '../.impeccable/review/task-notes'
  await mkdir(directory, { recursive: true })
  for (const [name, width, theme] of [['desktop', 1440, 'light'], ['mobile', 390, 'dark']]) {
    await page.setViewportSize({ width, height: 960 })
    await page.emulateMedia({ reducedMotion: 'reduce', colorScheme: theme })
    await page.goto('about:blank')
    await page.goto('/apps/harness/tests/workspace-fixture.html#/projects/neighborhood')
    await page.getByRole('button', { name: 'Tasks', exact: true }).click()
    await expect(page.getByRole('heading', { name: 'Gather the practical details' })).toBeVisible()
    await expect(page.getByRole('button', { name: 'Claim for myself' })).toHaveCount(0)
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true)
    await page.screenshot({ path: `${directory}/list-${name}.png`, fullPage: true })
    await page.getByRole('button', { name: 'Update task', exact: true }).click()
    await expect(page.getByRole('dialog')).toBeVisible()
    await page.screenshot({ path: `${directory}/edit-${name}.png`, fullPage: true })
    await page.getByRole('button', { name: 'Delete task…', exact: true }).click()
    await expect(page.getByRole('dialog')).toContainText('permanently removes the task record')
    await page.screenshot({ path: `${directory}/delete-${name}.png`, fullPage: true })
    await page.getByRole('button', { name: 'Keep task', exact: true }).click()
    await page.getByRole('button', { name: 'Close dialog' }).click()
    await page.getByRole('button', { name: 'New task', exact: true }).click()
    await expect(page.getByRole('textbox', { name: 'Task title', exact: true })).toBeFocused()
    await page.evaluate(() => window.scrollTo(0, 0))
    await page.screenshot({ path: `${directory}/new-${name}.png`, fullPage: true })
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true)
    await page.goto('about:blank')
    await page.goto('/apps/harness/tests/workspace-fixture.html#/tasks')
    await page.getByRole('button', { name: 'New task', exact: true }).click()
    await page.getByRole('textbox', { name: 'Task title', exact: true }).fill('Check the forecast')
    await page.getByRole('button', { name: 'Create task', exact: true }).click()
    await expect(page.getByRole('heading', { name: 'Check the forecast' })).toBeVisible()
    await page.screenshot({ path: `${directory}/standalone-${name}.png`, fullPage: true })
  }
})
