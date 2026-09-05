import { expect, test } from '@playwright/test'
import { PROVIDERS } from '../src/providers.js'

test.beforeEach(async ({ page }) => {
  await page.goto('/apps/harness/tests/settings-fixture.html')
  await expect.poll(() => page.evaluate(() => window.settingsFixture?.requests.length || 0)).toBeGreaterThan(0)
})

test('context is read from the catalog at save time, even when metadata arrives after selection', async ({ page }) => {
  await expect(page.getByRole('spinbutton')).toHaveCount(0)
  await page.getByRole('combobox', { name: 'Model', exact: true }).fill('test-model')
  await page.evaluate(() => {
    const f = window.settingsFixture
    f.resolve(f.requests.at(-1).id, { modelInfo: [{ id: 'test-model', contextWindow: 32768 }] })
  })
  await expect(page.getByText(/Provider reports 32,768/)).toBeVisible()
  await page.getByRole('button', { name: 'Save defaults' }).click()
  expect(await page.evaluate(() => window.settingsFixture.saves.at(-1)['max-context'])).toBe(32768)
})

test('search key can be configured, survives reload, and can be removed', async ({ page }) => {
  await page.goto('/apps/harness/tests/settings-fixture.html?page=search')
  await expect(page.getByText('key needed', { exact: true })).toBeVisible()
  await page.getByLabel('Brave Search API key').fill('fixture-brave-key')
  await page.getByRole('button', { name: 'Save search key' }).click()
  await expect(page.getByText('key configured', { exact: true })).toBeVisible()
  await expect(page.getByLabel('Brave Search API key')).toHaveValue('')
  await page.reload()
  await expect(page.getByText('key configured', { exact: true })).toBeVisible()
  await page.getByRole('button', { name: 'Remove search key' }).click()
  await expect(page.getByText('key needed', { exact: true })).toBeVisible()
})

test('MCP ids keep focus while typing and row removal preserves remaining headers', async ({ page }) => {
  await page.goto('/apps/harness/tests/settings-fixture.html?page=mcp')
  const add = page.getByRole('button', { name: 'Add server', exact: true })
  const save = page.getByRole('button', { name: 'Save MCP servers' })
  await add.click()
  await page.getByLabel('Server id').pressSequentially('first-server')
  await expect(page.getByLabel('Server id')).toHaveValue('first-server')
  await expect(page.getByLabel('Server id')).toBeFocused()
  await page.getByLabel('Streamable HTTP URL').fill('https://first.example/mcp')
  await save.click()
  await expect(page.getByText('Saved.', { exact: true })).toBeVisible()
  await add.click()
  await expect(page.getByText('Saved.', { exact: true })).toHaveCount(0)
  const second = page.locator('.mcp-server').nth(1)
  await second.getByLabel('Server id').pressSequentially('second-server')
  await second.getByLabel('Streamable HTTP URL').fill('https://second.example/mcp')
  await second.getByRole('button', { name: 'Add header' }).click()
  await second.getByLabel('Header name').fill('authorization')
  await second.getByLabel('Header value').fill('fixture-token')
  await save.click()
  await expect(page.getByText('Saved.', { exact: true })).toBeVisible()
  await page.locator('.mcp-server').first().getByRole('button', { name: 'Remove', exact: true }).click()
  await expect(page.getByText('Saved.', { exact: true })).toHaveCount(0)
  await expect(page.getByLabel('Server id')).toHaveValue('second-server')
  await expect(page.getByLabel('Header value')).toHaveValue('fixture-token')
  await save.click()
  await expect.poll(() => page.evaluate(() => window.settingsFixture.saves.at(-1))).toEqual([
    { id: 'second-server', name: 'second-server', url: 'https://second.example/mcp', enabled: true, headers: [{ name: 'authorization', value: 'fixture-token' }] },
  ])
})

test('switching providers fences stale catalogs and does not reuse another model’s limit', async ({ page }) => {
  await page.getByRole('combobox', { name: 'Provider', exact: true }).selectOption('anthropic')
  await expect.poll(() => page.evaluate(() => window.settingsFixture.requests.at(-1).provider)).toBe('anthropic')
  await page.evaluate(() => {
    const f = window.settingsFixture
    f.resolve(f.requests.at(-1).id, { modelInfo: [{ id: 'test-model', contextWindow: 64000 }] })
    for (const r of f.requests.filter((r) => r.provider === 'openrouter')) f.resolve(r.id, { modelInfo: [{ id: 'test-model', contextWindow: 999999 }] })
  })
  await page.getByRole('combobox', { name: 'Model', exact: true }).fill('test-model')
  await expect(page.getByText(/Provider reports 64,000/)).toBeVisible()
  await page.getByRole('button', { name: 'Save defaults' }).click()
  expect(await page.evaluate(() => window.settingsFixture.saves.at(-1)['max-context'])).toBe(64000)
  await page.getByRole('combobox', { name: 'Model', exact: true }).fill('unknown-model')
  await page.getByRole('button', { name: 'Save defaults' }).click()
  await expect.poll(() => page.evaluate(() => window.settingsFixture.saves.at(-1)['max-context'])).toBe(80000)
})

for (const surface of ['global', 'conversation']) {
  test(`${surface}: auth owns the OpenAI endpoint and only Custom can edit one`, async ({ page }) => {
    await page.goto(`/apps/harness/tests/settings-fixture.html?page=${surface}&device`)
    await expect(page.getByLabel('Endpoint', { exact: true })).toHaveCount(0)
    await page.getByRole('combobox', { name: 'Provider', exact: true }).selectOption('openai')
    await expect(page.getByLabel('Authentication')).toHaveValue('device')
    await expect.poll(() => page.evaluate(() => window.settingsFixture.requests.at(-1).url)).toBe(PROVIDERS.openai.deviceModelsEndpoint)
    const save = page.getByRole('button', { name: surface === 'global' ? 'Save defaults' : 'Save conversation' })
    await save.click()
    await expect.poll(() => page.evaluate(() => window.settingsFixture.saves.at(-1).url)).toBe(PROVIDERS.openai.deviceEndpoint)
    await page.reload()
    await expect(page.getByLabel('Authentication')).toHaveValue('device')
    await page.getByLabel('Authentication').selectOption('api-key')
    await save.click()
    await expect.poll(() => page.evaluate(() => window.settingsFixture.saves.at(-1).url)).toBe(PROVIDERS.openai.endpoint)
    await page.getByRole('combobox', { name: 'Provider', exact: true }).selectOption('openrouter')
    await page.getByRole('combobox', { name: 'Provider', exact: true }).selectOption('openai')
    await expect(page.getByLabel('Authentication')).toHaveValue('device')
    await page.getByRole('combobox', { name: 'Provider', exact: true }).selectOption('custom')
    await page.getByLabel('Endpoint', { exact: true }).fill('https://inference.example/v1/chat/completions')
    await page.getByLabel('Model', { exact: true }).fill('custom-model')
    await save.click()
    await expect.poll(() => page.evaluate(() => window.settingsFixture.saves.at(-1).url)).toBe('https://inference.example/v1/chat/completions')
  })
}

for (const failSave of [false, true]) test(`device login saves its route and survives reload${failSave ? ' after recovering from a configuration save failure' : ' without a second Save'}`, async ({ page, context }) => {
  await context.route('https://auth.openai.com/**', async (route) => {
    const path = new URL(route.request().url()).pathname
    const payload = path.endsWith('/usercode') ? { device_auth_id: 'fixture', user_code: 'ABCD-EFGH', interval: 2 }
      : path.endsWith('/deviceauth/token') ? { authorization_code: 'fixture-code', code_verifier: 'fixture-verifier' }
        : { access_token: 'fixture-access-token', refresh_token: 'fixture-refresh', id_token: `e30.${Buffer.from(JSON.stringify({ chatgpt_account_id: 'fixture-account' })).toString('base64url')}.signature` }
    await route.fulfill({ json: payload })
  })
  await page.goto('/apps/harness/tests/settings-fixture.html?page=provider')
  await page.getByLabel('Authentication').selectOption('device')
  await expect(page.getByLabel('API key', { exact: true })).toHaveCount(0)
  await expect(page.getByLabel('Endpoint', { exact: true })).toHaveCount(0)
  if (failSave) await page.evaluate(() => { window.settingsFixture.failSave = true })
  await page.getByRole('button', { name: 'Sign in with device code' }).click()
  await page.getByRole('combobox', { name: 'Model', exact: true }).fill('gpt-fixture-selected')
  if (failSave) {
    await expect(page.getByText('Configuration save failed in fixture')).toBeVisible()
    await expect(page.getByText('connected', { exact: true })).toHaveCount(0)
    expect(await page.evaluate(() => window.settingsFixture.saves.length)).toBe(0)
    await page.evaluate(() => { window.settingsFixture.failSave = false })
    await expect(page.getByText('credential configured', { exact: true })).toBeVisible()
    await page.getByRole('button', { name: 'Save OpenAI' }).click()
  }
  await expect.poll(() => page.evaluate(() => window.settingsFixture.saves.at(-1)?.url)).toBe(PROVIDERS.openai.deviceEndpoint)
  expect(await page.evaluate(() => window.settingsFixture.saves.at(-1).model)).toBe('gpt-fixture-selected')
  expect(await page.evaluate(() => window.settingsFixture.credentials)).toEqual(['openai-device'])
  expect(await page.evaluate(() => window.settingsFixture.deviceBundle)).toEqual({ hasRefresh: true, hasAccount: true })
  expect(await page.evaluate(() => window.settingsFixture.saves.at(-1).headers)).toEqual([])
  await page.reload()
  await expect(page.getByLabel('Authentication')).toHaveValue('device')
  await expect(page.getByText('credential configured', { exact: true })).toBeVisible()
  await page.getByLabel('Authentication').selectOption('api-key')
  await page.getByLabel('API key', { exact: true }).fill('sk-fixture-api')
  await page.getByRole('button', { name: 'Save OpenAI' }).click()
  await expect.poll(() => page.evaluate(() => window.settingsFixture.saves.at(-1).url)).toBe(PROVIDERS.openai.endpoint)
  expect(await page.evaluate(() => window.settingsFixture.credentials)).toEqual(['openai'])
})
