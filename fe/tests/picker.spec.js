import { expect, test } from '@playwright/test'
import { chooseOption } from './picker'

test.beforeEach(async ({ page }) => {
  page.on('pageerror', error => { throw error })
  await page.goto('/apps/harness/tests/picker-fixture.html')
})

test('choices stay in-page, retain labels, and never submit the form', async ({ page }) => {
  await expect(page.locator('select, datalist, input[list]')).toHaveCount(0)
  const runner = page.getByRole('combobox', { name: 'Connected runner', exact: true })
  await chooseOption(runner, 'codex')
  await expect(runner).toContainText('Codex · workstation')
  await expect(runner).toBeFocused()
  await expect(page.getByLabel('Saved choices')).toHaveText('0')
  await page.getByRole('button', { name: 'Save choices' }).click()
  await expect(page.getByLabel('Saved choices')).toHaveText('1')
})

test('keyboard navigation skips disabled choices, commits deliberately, and supports typeahead', async ({ page }) => {
  const runner = page.getByRole('combobox', { name: 'Connected runner', exact: true })
  await runner.focus()
  await runner.press('ArrowDown'); await runner.press('ArrowDown'); await runner.press('ArrowDown')
  await expect(page.getByRole('option', { name: 'Codex · workstation', exact: true })).toHaveClass(/active/)
  await runner.press('Escape')
  await expect(page.getByLabel('Current runner')).toHaveText('')
  await runner.press('End'); await runner.press('Enter')
  await expect(page.getByLabel('Current runner')).toHaveText('long')
  await runner.press('Home'); await runner.press('c'); await runner.press('o'); await runner.press('Enter')
  await expect(page.getByLabel('Current runner')).toHaveText('codex')
  await expect(page.getByLabel('Saved choices')).toHaveText('0')
})

test('required choices focus the picker and show an inline error', async ({ page }) => {
  await page.getByRole('button', { name: 'Save choices' }).click()
  await expect(page.getByRole('alert')).toHaveText('Choose an option.')
  await expect(page.getByRole('combobox', { name: 'Connected runner', exact: true })).toBeFocused()
  await expect(page.getByLabel('Saved choices')).toHaveText('0')
  await chooseOption(page.getByRole('combobox', { name: 'Connected runner', exact: true }), 'claude')
  await expect(page.getByRole('alert')).toHaveCount(0)
})

test('fieldset disabling closes an open list and blocks choices', async ({ page }) => {
  const runner = page.getByRole('combobox', { name: 'Connected runner', exact: true })
  await runner.click()
  await page.getByTestId('fieldset').evaluate(fieldset => { fieldset.disabled = true })
  await expect(page.getByRole('listbox')).toHaveCount(0)
  await expect(runner).toBeDisabled()
  await expect(page.getByLabel('Current runner')).toHaveText('')
})

test('Tab and outside clicks dismiss without changing a choice', async ({ page }) => {
  const runner = page.getByRole('combobox', { name: 'Connected runner', exact: true })
  await runner.click(); await runner.press('ArrowDown'); await runner.press('Tab')
  await expect(page.getByRole('listbox')).toHaveCount(0)
  await expect(page.getByRole('combobox', { name: 'Model', exact: true })).toBeFocused()
  await runner.click(); await page.getByRole('heading', { name: 'In-page picker fixture' }).click()
  await expect(page.getByRole('listbox')).toHaveCount(0)
  await expect(page.getByLabel('Current runner')).toHaveText('')
})

test('editable suggestions filter large catalogs and preserve custom model names', async ({ page }) => {
  const model = page.getByRole('combobox', { name: 'Model', exact: true })
  await model.click()
  await expect(page.getByRole('option')).toHaveCount(100)
  await model.fill('model-999')
  await expect(page.getByRole('option')).toHaveCount(1)
  await model.press('ArrowDown'); await model.press('Enter')
  await expect(model).toHaveValue('provider/model-999')
  await model.fill('my/custom-model')
  await expect(page.getByRole('status').filter({ hasText: 'No suggestions' })).toBeVisible()
  await model.press('Escape')
  await expect(model).toHaveValue('my/custom-model')
})

test('picker is usable inside a modal and Escape closes only its list first', async ({ page }) => {
  await page.getByRole('button', { name: 'Open dialog', exact: true }).click()
  const dialog = page.getByRole('dialog'), runner = dialog.getByRole('combobox', { name: 'Dialog runner' })
  await chooseOption(runner, 'claude')
  await expect(runner).toContainText('Claude Code')
  await runner.click(); await runner.press('Escape')
  await expect(dialog).toBeVisible()
  await expect(page.getByRole('listbox')).toHaveCount(0)
  await runner.press('Escape')
  await expect(dialog).not.toBeVisible()
})

test('long choices wrap inside a narrow viewport', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 640 })
  const runner = page.getByRole('combobox', { name: 'Connected runner', exact: true })
  await runner.click()
  const rect = await page.locator('.picker-popup').boundingBox()
  expect(rect.x).toBeGreaterThanOrEqual(0); expect(rect.x + rect.width).toBeLessThanOrEqual(390)
  expect(rect.y).toBeGreaterThanOrEqual(0); expect(rect.y + rect.height).toBeLessThanOrEqual(640)
  await page.getByRole('option').filter({ hasText: 'Research and implementation' }).click()
  await expect(runner).toContainText('very long connection name')
  expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(390)
})

test('touch selects an in-page option without a native popup', async ({ browser }) => {
  const context = await browser.newContext({ hasTouch: true, viewport: { width: 390, height: 640 } })
  try {
    const page = await context.newPage()
    page.on('pageerror', error => { throw error })
    await page.goto('http://127.0.0.1:4179/apps/harness/tests/picker-fixture.html')
    await page.getByRole('combobox', { name: 'Connected runner', exact: true }).tap()
    await page.getByRole('option', { name: 'Codex · workstation', exact: true }).tap()
    await expect(page.getByLabel('Current runner')).toHaveText('codex')
    await expect(page.locator('select, datalist')).toHaveCount(0)
  } finally { await context.close() }
})

test('an open list follows window and visual viewport resize events', async ({ page }) => {
  await page.getByRole('combobox', { name: 'Connected runner', exact: true }).click()
  await page.setViewportSize({ width: 390, height: 640 })
  await page.evaluate(() => {
    window.dispatchEvent(new Event('resize'))
    window.visualViewport?.dispatchEvent(new Event('resize'))
    window.visualViewport?.dispatchEvent(new Event('scroll'))
  })
  await expect(page.getByRole('listbox')).toBeVisible()
  const rect = await page.locator('.picker-popup').boundingBox()
  expect(rect.x).toBeGreaterThanOrEqual(0)
  expect(rect.x + rect.width).toBeLessThanOrEqual(390)
})
