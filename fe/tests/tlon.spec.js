import { expect, test } from '@playwright/test'

test('Lens export retry is separate from permission changes and retains rejected exports', async ({ page }) => {
  await page.goto('/apps/harness/tests/tlon-fixture.html')
  await expect(page.getByText('Owner-side storage: ~zod. 2 exports acknowledged, 0 pending.')).toBeVisible()
  await expect(page.getByRole('checkbox', { name: /lens/i })).toHaveCount(0)
  await page.evaluate(() => {
    window.tlonFixture.lens.failed = 1
    window.tlonFixture.lensError = 'Export unavailable'
  })
  const retry = page.getByRole('button', { name: 'Retry Lens exports', exact: true })
  await expect(retry).toBeVisible({ timeout: 8000 })
  await retry.click()
  await expect(page.getByRole('alert')).toHaveText('Export unavailable')
  await expect(retry).toBeEnabled()
  await page.evaluate(() => { window.tlonFixture.lensError = '' })
  await retry.click()
  await expect(retry).toHaveCount(0)
  await expect(page.getByText('Owner-side storage: ~zod. 2 exports acknowledged, 1 pending.')).toBeVisible()
  expect(await page.evaluate(() => window.tlonFixture.lensRetries)).toBe(2)
  expect(await page.evaluate(() => window.tlonFixture.saves)).toEqual([])
})

test('Tlon settings require no separate image worker configuration', async ({ page }) => {
  await page.goto('/apps/harness/tests/tlon-fixture.html')
  await expect(page.getByLabel('Media worker URL')).toHaveCount(0)
  await expect(page.getByLabel('Worker token')).toHaveCount(0)
})

test('finished schedules clear with acknowledged state; unresolved work stays', async ({ page }) => {
  await page.goto('/apps/harness/tests/tlon-fixture.html')
  await page.evaluate(() => {
    window.tlonFixture.cron = [
      { id: '0v1', prompt: 'Finished task', remaining: 0, state: 'complete', clearable: true },
      { id: '0v2', prompt: 'Uncertain task', remaining: 0, state: 'complete', delivery: 'uncertain', clearable: false },
    ]
    window.tlonFixture.clearError = 'Schedule is no longer clearable'
  })
  const clear = page.getByRole('button', { name: 'Clear finished schedule', exact: true })
  await expect(clear).toHaveCount(1, { timeout: 8000 })
  await clear.click()
  await expect(page.getByRole('alert')).toHaveText('Schedule is no longer clearable')
  await expect(page.getByText('Finished task', { exact: true })).toBeVisible()
  await page.evaluate(() => { window.tlonFixture.clearError = '' })
  await clear.click()
  await expect(page.getByText('Finished task', { exact: true })).toHaveCount(0)
  await expect(page.getByText('Uncertain task', { exact: true })).toBeVisible()
  expect(await page.evaluate(() => window.tlonFixture.saves)).toEqual([])
})

test('scheduled work distinguishes delivery from execution and cancels independently of policy', async ({ page }) => {
  await page.goto('/apps/harness/tests/tlon-fixture.html')
  await page.evaluate(() => { window.tlonFixture.cron = [{ id: '0v1', runSessionId: 'cron-test', prompt: 'Morning summary', schedule: '0 9 * * *', state: 'active', remaining: 4, next: '~2026.9.6..09.00.00', execution: 'completed', delivery: 'uncertain' }] })
  await expect(page.getByText('Morning summary', { exact: true })).toBeVisible({ timeout: 8000 })
  await expect(page.getByText(/Execution: completed · Delivery: uncertain/)).toBeVisible()
  await expect(page.getByRole('link', { name: 'Scheduled conversation' })).toHaveAttribute('href', '#/settings/cron-test')
  await page.getByRole('button', { name: 'Cancel schedule', exact: true }).click()
  await expect(page.getByText('Cancelled in owner settings')).toBeVisible()
  expect(await page.evaluate(() => window.tlonFixture.cancelled)).toEqual(['0v1'])
  expect(await page.evaluate(() => window.tlonFixture.saves)).toEqual([])
})

test('profile reflects Contacts, protects drafts, and saves separately from permissions', async ({ page }) => {
  await page.goto('/apps/harness/tests/tlon-fixture.html')
  const nickname = page.getByRole('textbox', { name: 'Nickname', exact: true })
  const avatar = page.getByRole('textbox', { name: 'Avatar URL' })
  await expect(nickname).toHaveValue('Existing bot')
  await expect(avatar).toHaveValue('https://example.com/bot.png')
  await page.evaluate(() => { window.tlonFixture.profile.nickname = 'Changed in Tlon' })
  await expect(nickname).toHaveValue('Changed in Tlon', { timeout: 8000 })
  await nickname.fill('')
  await avatar.fill('')
  await page.evaluate(() => { window.tlonFixture.profile.nickname = 'Another external edit' })
  await page.waitForTimeout(5500)
  await expect(nickname).toHaveValue('')
  await page.getByRole('button', { name: 'Save profile', exact: true }).click()
  await expect(page.getByText('Profile saved.', { exact: true })).toBeVisible()
  expect(await page.evaluate(() => window.tlonFixture.profile)).toEqual({ nickname: '', avatar: '' })
  expect(await page.evaluate(() => window.tlonFixture.saves)).toEqual([])
})

test('a Contacts save failure retains the profile draft and can be retried', async ({ page }) => {
  await page.goto('/apps/harness/tests/tlon-fixture.html')
  const nickname = page.getByRole('textbox', { name: 'Nickname', exact: true })
  await expect(nickname).toHaveValue('Existing bot')
  await nickname.fill('Retry me')
  await page.evaluate(() => { window.tlonFixture.profileError = 'Contacts could not save the profile' })
  await page.getByRole('button', { name: 'Save profile', exact: true }).click()
  await expect(page.getByRole('alert')).toContainText('Contacts could not save')
  await expect(nickname).toHaveValue('Retry me')
  await page.evaluate(() => { window.tlonFixture.profileError = '' })
  await page.getByRole('button', { name: 'Save profile', exact: true }).click()
  await expect(page.getByText('Profile saved.', { exact: true })).toBeVisible()
})

test('nickname suggestions select concrete ships; tools are explicitly granted', async ({ page }) => {
  await page.goto('/apps/harness/tests/tlon-fixture.html')
  await expect(page.getByRole('combobox', { name: 'Owner ship' })).toHaveValue('~zod')
  const picker = page.getByRole('combobox', { name: 'Add a trusted ship' })
  await picker.fill('alice')
  await expect(page.getByRole('option').first()).toContainText('~nec')
  await page.getByRole('option').first().click()
  await page.locator('.trusted-ship summary').click()
  await expect(page.getByText(/Tlon actions are available within the conversation without extra grants/)).toBeVisible()
  await expect(page.getByRole('checkbox', { name: /tlon-read|tlon-write|cron/i })).toHaveCount(0)
  await expect(page.getByRole('checkbox', { name: 'Web search & requests' })).not.toBeChecked()
  await page.getByRole('checkbox', { name: 'Web search & requests' }).check()
  await page.getByRole('checkbox', { name: /^MCP: Calendar/ }).check()
  await expect(page.getByRole('checkbox', { name: /^MCP: Notes/ })).not.toBeChecked()
  await page.getByRole('checkbox', { name: 'Enable Tlon hand' }).check()
  await page.getByRole('button', { name: 'Save Tlon settings' }).click()
  await expect(page.getByText('Saved.', { exact: true })).toBeVisible()
  expect(await page.evaluate(() => window.tlonFixture.saves.at(-1))).toEqual({
    enabled: true, owner: '~zod', mentions: true, trusted: [{ ship: '~nec', tools: ['web', { mcp: 'calendar' }] }],
  })
})

test('keyboard selection and dark mode work without contacts matching', async ({ page }) => {
  await page.emulateMedia({ colorScheme: 'dark' })
  await page.goto('/apps/harness/tests/tlon-fixture.html')
  const picker = page.getByRole('combobox', { name: 'Owner ship' })
  await picker.fill('~lu')
  await expect(page.getByRole('option')).toHaveCount(0)
  await picker.fill('~lux')
  await expect(page.getByRole('option').first()).toBeVisible()
  await picker.press('Enter')
  await expect(picker).toHaveValue('~lux')
  await expect(picker).toHaveAttribute('aria-expanded', 'false')
})

test('Tlon shows defaults and explicitly applies them to existing sessions', async ({ page }) => {
  await page.goto('/apps/harness/tests/tlon-fixture.html')
  await expect(page.getByText('test/model', { exact: false })).toBeVisible()
  await page.getByRole('button', { name: 'Apply defaults to 1 Tlon conversations' }).click()
  await expect(page.getByRole('status')).toContainText('Updated 1 conversations')
  expect(await page.evaluate(() => window.tlonFixture.modelUpdates)).toEqual(['nec-dm-test'])
  expect(await page.evaluate(() => window.tlonFixture.saves)).toEqual([])
  await page.getByText('Conversation models', { exact: true }).click()
  await expect(page.getByRole('link', { name: 'nec-dm-test' })).toHaveAttribute('href', '#/settings/nec-dm-test')
})
