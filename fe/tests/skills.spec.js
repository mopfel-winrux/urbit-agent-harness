import { expect, test } from '@playwright/test'

test('shared skill editor persists literal instructions and requires deletion confirmation', async ({ page }) => {
  await page.goto('/apps/harness/tests/settings-fixture.html?page=skills')
  await page.getByLabel('Skill name', { exact: true }).fill('weekly-summary')
  await page.getByLabel('Description', { exact: true }).fill('Use for a weekly summary')
  const body = '# Instructions\n\nKeep <tags> literal.\n- Summarize what changed.\n'
  await page.getByLabel('Instructions', { exact: true }).fill(body)
  await page.getByRole('button', { name: 'Save skill', exact: true }).click()
  await expect(page.getByRole('status')).toHaveText('Skill saved.')
  await page.reload()
  await page.getByRole('button', { name: /weekly-summary Use for a weekly summary/ }).click()
  await expect(page.getByLabel('Instructions', { exact: true })).toHaveValue(body)
  await expect(page.getByLabel('Skill name', { exact: true })).toBeDisabled()
  await page.getByRole('button', { name: 'Delete skill', exact: true }).click()
  await page.getByRole('button', { name: 'Keep skill', exact: true }).click()
  await expect(page.getByLabel('Instructions', { exact: true })).toHaveValue(body)
  await page.getByRole('button', { name: 'Delete skill', exact: true }).click()
  await page.getByRole('button', { name: 'Confirm delete', exact: true }).click()
  await expect(page.getByText('No saved skills yet. Add instructions below.')).toBeVisible()
})

test('failed save preserves the draft and the text editor follows both themes', async ({ page }) => {
  await page.goto('/apps/harness/tests/settings-fixture.html?page=skills')
  await page.getByLabel('Skill name', { exact: true }).fill('draft')
  const editor = page.getByLabel('Instructions', { exact: true })
  await editor.fill('Keep my unsaved work')
  await page.evaluate(() => { window.settingsFixture.failSave = true })
  await page.getByRole('button', { name: 'Save skill', exact: true }).click()
  await expect(page.getByRole('alert')).toContainText('save failed')
  await expect(editor).toHaveValue('Keep my unsaved work')
  const colors = []
  for (const theme of ['light', 'dark']) {
    await page.evaluate((theme) => { document.documentElement.dataset.theme = theme }, theme)
    const style = await editor.evaluate((element) => ({ bg: getComputedStyle(element).backgroundColor, fg: getComputedStyle(element).color }))
    expect(style.bg).not.toBe(style.fg)
    colors.push(style)
  }
  expect(colors[0]).not.toEqual(colors[1])
})
