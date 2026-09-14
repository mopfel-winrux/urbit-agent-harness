import { expect, test } from '@playwright/test'
import { defaultConfig } from '../src/defaults.js'

const path = '/apps/harness/tests/settings-fixture.html?page=memory'
const section = (page, title) => page.locator('section').filter({ has: page.getByRole('heading', { name: title, exact: true }) })
const save = (page) => page.getByRole('button', { name: 'Save memory settings' })

test('both summary routes start unset and follow the current global default', async ({ page }) => {
  await page.goto(path)
  for (const title of ['Compaction model', 'LCM model']) {
    await expect(section(page, title).getByRole('checkbox', { name: /Use global default/ })).toBeChecked()
    await expect(section(page, title).getByText(`Follows the current default: ${defaultConfig().model}.`)).toBeVisible()
    await expect(section(page, title).getByRole('combobox', { name: 'Model', exact: true })).toHaveCount(0)
  }
  await save(page).click()
  await expect.poll(() => page.evaluate(() => window.settingsFixture.saves.at(-1))).toEqual({ summaryModels: { compaction: null, lcm: null } })
  await page.evaluate(() => sessionStorage.setItem('settings-fixture-config', JSON.stringify({ ...JSON.parse(sessionStorage.getItem('settings-fixture-config') || '{}'), model: 'current-answer-model' })))
  await page.reload()
  await expect(page.getByText('Follows the current default: current-answer-model.')).toHaveCount(2)
  await expect(page.getByRole('checkbox', { name: /Use global default/ }).nth(0)).toBeChecked()
  await expect(page.getByRole('checkbox', { name: /Use global default/ }).nth(1)).toBeChecked()
})

test('leaf and parent routes save independently without changing answer defaults or granting tools', async ({ page }) => {
  await page.goto(path)
  const leaf = section(page, 'Compaction model'), parent = section(page, 'LCM model')
  await leaf.getByRole('checkbox', { name: /Use global default/ }).uncheck()
  await leaf.getByRole('combobox', { name: 'Model', exact: true }).fill('leaf-model')
  await parent.getByRole('checkbox', { name: /Use global default/ }).uncheck()
  await parent.getByRole('combobox', { name: 'Model', exact: true }).fill('parent-model')
  await save(page).click()
  await expect(page.getByRole('status')).toHaveText('Saved.')
  const models = await page.evaluate(() => window.settingsFixture.saves.at(-1).summaryModels)
  expect(models.compaction.model).toBe('leaf-model')
  expect(models.lcm.model).toBe('parent-model')
  for (const route of Object.values(models)) {
    expect(route.key).toBe('')
    expect(route.system).toBe('')
    expect(route.tools).toEqual([])
  }
  expect(await page.evaluate(() => sessionStorage.getItem('settings-fixture-config'))).toBeNull()
  await page.reload()
  await expect(leaf.getByRole('combobox', { name: 'Model', exact: true })).toHaveValue('leaf-model')
  await expect(parent.getByRole('combobox', { name: 'Model', exact: true })).toHaveValue('parent-model')
  await leaf.getByRole('checkbox', { name: /Use global default/ }).check()
  await save(page).click()
  await expect.poll(() => page.evaluate(() => window.settingsFixture.saves.at(-1).summaryModels)).toEqual({ compaction: null, lcm: models.lcm })
})

test('unavailable saved settings cannot be overwritten with an empty form', async ({ page }) => {
  await page.goto(`${path}&hold-memory`)
  await expect(save(page)).toBeDisabled()
  await expect(page.getByRole('checkbox', { name: /Use global default/ }).first()).toBeDisabled()
  await page.evaluate(() => { window.settingsFixture.failMemoryRead = true; window.settingsFixture.releaseMemory() })
  await expect(page.getByRole('alert')).toContainText('Memory settings unavailable')
  await expect(save(page)).toBeDisabled()
  expect(await page.evaluate(() => window.settingsFixture.saves)).toEqual([])
})

test('failed saves retain the edited routes and do not claim success', async ({ page }) => {
  await page.goto(path)
  const leaf = section(page, 'Compaction model')
  await leaf.getByRole('checkbox', { name: /Use global default/ }).uncheck()
  await leaf.getByRole('combobox', { name: 'Model', exact: true }).fill('retain-this-model')
  await page.evaluate(() => { window.settingsFixture.failSave = true })
  await save(page).click()
  await expect(page.getByRole('alert')).toContainText('Configuration save failed')
  await expect(leaf.getByRole('combobox', { name: 'Model', exact: true })).toHaveValue('retain-this-model')
  await expect(page.getByRole('status')).toHaveText('Unsaved changes.')
  expect(await page.evaluate(() => window.settingsFixture.saves)).toEqual([])
  await page.evaluate(() => { window.settingsFixture.failSave = false })
  await save(page).click()
  await expect(page.getByRole('status')).toHaveText('Saved.')
})
