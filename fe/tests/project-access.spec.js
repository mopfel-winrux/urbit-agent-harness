import { expect, test } from '@playwright/test'

const open = async (page) => {
  await page.goto('/apps/harness/tests/workspace-fixture.html#/projects/neighborhood')
  await page.getByRole('button', { name: 'Access', exact: true }).click()
}
const calls = (page, action) => page.evaluate((action) => window.workFixture.calls.filter((call) => call.action === action), action)
const create = async (page) => {
  await page.getByRole('button', { name: 'Create read-only key…', exact: true }).click()
  const dialog = page.getByRole('dialog')
  await dialog.getByLabel('Client label', { exact: true }).fill('Project dashboard')
  await expect(dialog.getByRole('button', { name: 'Create read-only key', exact: true })).toBeDisabled()
  await dialog.getByRole('checkbox').check()
  return dialog
}

test('maintainer changes are explicit, versioned and reversible without resource grants', async ({ page }) => {
  await open(page)
  for (const role of ['maintainer', 'reader', 'contributor']) {
    await page.getByRole('button', { name: 'Change role…', exact: true }).click()
    await page.getByRole('combobox', { name: 'New access level', exact: true }).selectOption(role)
    await page.getByRole('button', { name: 'Confirm access', exact: true }).click()
    await expect(page.getByText(`${role} · Workspace tools enabled`, { exact: true })).toBeVisible()
  }
  expect((await calls(page, 'member')).map((call) => [call.args.role, call.args.version])).toEqual([['maintainer', 1], ['reader', 2], ['contributor', 3]])
  expect(await page.evaluate(() => window.workFixture.db.sessions[0].workspaceTools)).toBe(true)
  await page.getByRole('button', { name: 'Change role…', exact: true }).click()
  await page.evaluate(() => { window.workFixture.db.projects.neighborhood.version++; window.workFixture.changed() })
  await expect(page.getByRole('button', { name: 'Confirm access', exact: true })).toBeDisabled()
  await expect(page.getByRole('dialog')).toContainText('Project settings or access changed')
})

test('key creation requires confirmation, reveals once, and never writes browser storage or URLs', async ({ page }) => {
  await open(page)
  const dialog = await create(page)
  expect(await calls(page, 'client-create')).toHaveLength(0)
  await dialog.getByRole('button', { name: 'Create read-only key', exact: true }).click()
  await expect(dialog.getByRole('heading', { name: 'Read-only key created' })).toBeVisible()
  const key = await dialog.getByLabel('Project bearer key', { exact: true }).inputValue()
  expect(key).toMatch(/^hpr_[0-9a-f]{64}$/)
  await expect(dialog.getByLabel('Project bearer key', { exact: true })).toHaveAttribute('type', 'password')
  await dialog.getByRole('button', { name: 'Reveal key', exact: true }).click()
  await expect(dialog.getByLabel('Project bearer key', { exact: true })).toHaveAttribute('type', 'text')
  expect(await page.evaluate(() => `${JSON.stringify(localStorage)} ${JSON.stringify(sessionStorage)} ${location.href}`)).not.toContain(key)
  await page.evaluate(() => Object.defineProperty(navigator, 'clipboard', { configurable: true, value: { writeText: async () => { throw new Error('Denied') } } }))
  await dialog.getByRole('button', { name: 'Copy key', exact: true }).click()
  await expect(dialog.getByRole('status')).toContainText('copy it manually')
  await dialog.getByRole('button', { name: 'Done', exact: true }).click()
  await expect(page.getByLabel('Project bearer key', { exact: true })).toHaveCount(0)
  expect(await page.locator('body').innerText()).not.toContain(key)
  expect(JSON.stringify(await page.evaluate(() => window.workFixture.db.clients))).not.toContain(key)
  expect(await calls(page, 'client-create')).toHaveLength(1)
})

test('lost creation confirmation retries the same key and preserves expiry', async ({ page }) => {
  await open(page)
  await page.evaluate(() => { window.workFixture.loseClientConfirmation = true })
  const dialog = await create(page)
  await dialog.getByRole('button', { name: 'Create read-only key', exact: true }).click()
  await expect(dialog).toContainText('Creation is not confirmed')
  const first = (await calls(page, 'client-create'))[0]
  const expiry = await page.evaluate(() => Object.values(window.workFixture.db.clients)[0].expires)
  await expect(dialog.getByLabel('Client label', { exact: true })).toBeDisabled()
  await dialog.getByRole('button', { name: 'Retry same key', exact: true }).click()
  await expect(dialog.getByRole('heading', { name: 'Read-only key created' })).toBeVisible()
  const attempts = await calls(page, 'client-create')
  expect(attempts).toHaveLength(2)
  expect(attempts[1].args).toEqual(first.args)
  expect(await page.evaluate(() => Object.values(window.workFixture.db.clients)[0].expires)).toBe(expiry)
})

test('pending creation coalesces submissions and cannot be dismissed', async ({ page }) => {
  await open(page)
  await page.evaluate(() => { window.workFixture.holdClientCreate = true })
  const dialog = await create(page)
  await dialog.getByRole('button', { name: 'Create read-only key', exact: true }).click()
  await expect(dialog.getByRole('button', { name: 'Creating…', exact: true })).toBeDisabled()
  await page.keyboard.press('Escape')
  await expect(dialog).toBeVisible()
  expect(await calls(page, 'client-create')).toHaveLength(1)
  await page.evaluate(() => { window.workFixture.holdClientCreate = false; window.workFixture.releaseClientCreate() })
  await expect(dialog.getByRole('heading', { name: 'Read-only key created' })).toBeVisible()
})

test('revocation failure preserves access and explicit retry changes only the selected key', async ({ page }) => {
  await open(page)
  const dialog = await create(page)
  await dialog.getByRole('button', { name: 'Create read-only key', exact: true }).click()
  await dialog.getByRole('button', { name: 'Done', exact: true }).click()
  await page.getByRole('button', { name: 'Revoke…', exact: true }).click()
  await page.evaluate(() => { window.workFixture.failNext = 'client-revoke' })
  await page.getByRole('button', { name: 'Revoke key', exact: true }).click()
  await expect(page.getByRole('dialog')).toContainText('Synthetic save failure')
  expect(await page.evaluate(() => Object.values(window.workFixture.db.clients)[0].status)).toBe('active')
  await page.getByRole('button', { name: 'Revoke key', exact: true }).click()
  await expect(page.getByRole('dialog')).toHaveCount(0)
  await expect(page.getByText('Revoked · Expires', { exact: false })).toBeVisible()
  expect(await calls(page, 'member')).toHaveLength(0)
})

test('unavailable secure randomness and changed projects fail closed before key issuance', async ({ page }) => {
  await open(page)
  let dialog = await create(page)
  await page.evaluate(() => Object.defineProperty(crypto, 'getRandomValues', { configurable: true, value: undefined }))
  await dialog.getByRole('button', { name: 'Create read-only key', exact: true }).click()
  await expect(dialog.getByRole('alert')).toContainText('Secure key generation is unavailable')
  expect(await calls(page, 'client-create')).toHaveLength(0)
  await dialog.getByRole('button', { name: 'Cancel', exact: true }).click()
  dialog = await create(page)
  await page.evaluate(() => { window.workFixture.db.projects.neighborhood.version++; window.workFixture.changed() })
  await expect(dialog.getByRole('button', { name: 'Create read-only key', exact: true })).toBeDisabled()
  expect(await calls(page, 'client-create')).toHaveLength(0)
})

test('archived projects disable creation; failed credential reads do not claim there are no keys', async ({ page }) => {
  await open(page)
  await page.evaluate(() => { window.workFixture.db.projects.neighborhood.archived = true; window.workFixture.changed() })
  await expect(page.getByRole('button', { name: 'Create read-only key…', exact: true })).toBeDisabled()
  await page.evaluate(() => { window.workFixture.db.projects.neighborhood.archived = false; window.workFixture.failNext = 'clients'; window.workFixture.changed() })
  await expect(page.getByRole('alert')).toContainText('Synthetic save failure')
  await expect(page.getByText('No client keys in this view.', { exact: false })).toHaveCount(0)
  await expect(page.getByRole('button', { name: 'Create read-only key…', exact: true })).toBeDisabled()
})
