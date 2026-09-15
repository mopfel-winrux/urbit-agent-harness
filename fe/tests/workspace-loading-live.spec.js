import { test, expect } from '@playwright/test'
import { readFile } from 'node:fs/promises'
import { randomUUID } from 'node:crypto'

test('multiple Work tabs load and settle each create exactly once', async ({ context, page }) => {
  test.skip(!process.env.WORKSPACE_LIVE, 'Requires an explicitly selected local test ship')
  test.setTimeout(60_000)
  const base = process.env.SHIP_URL || 'http://127.0.0.1'
  expect(['127.0.0.1', 'localhost', '[::1]']).toContain(new URL(base).hostname)
  const fields = (await readFile(process.env.SHIP_COOKIE, 'utf8')).split('\n').find((row) => /\turbauth-~/.test(row)).split('\t')
  await context.addCookies([{ name: fields[5], value: fields[6], url: base, httpOnly: true, sameSite: 'Lax' }])
  // Test the built assets against the live backend before installing them.
  if (process.env.WORKSPACE_BUILT) await context.route('**/apps/harness/app.js*', (route) => route.fulfill({ path: '../desk/web/app.js', contentType: 'text/javascript' }))
  const creates = [], errors = []
  context.on('request', (request) => {
    if (request.method() !== 'PUT') return
    for (const action of request.postDataJSON() || []) {
      const payload = action.json?.send?.payload
      if (!payload) continue
      const rpc = JSON.parse(payload)
      if (rpc.method === 'harness/workspace' && ['task-create', 'artifact-create'].includes(rpc.params.action)) creates.push(rpc.params)
    }
  })
  const tabs = [page]
  for (let i = 1; i < 4; i++) tabs.push(await context.newPage())
  for (const tab of tabs) {
    tab.on('pageerror', (error) => errors.push(error.message))
    await tab.goto(`${base}/apps/harness/#/projects`, { timeout: 5000 })
    await expect(tab.getByRole('status').filter({ hasText: 'Loading…' })).toHaveCount(0)
    await expect(tab.getByRole('button', { name: 'New project', exact: true })).toBeVisible()
  }
  const active = tabs.at(-1)
  const title = `Loading check ${randomUUID().slice(0, 8)}`
  const nav = active.getByRole('navigation', { name: 'Workspace', exact: true })
  await nav.getByRole('link', { name: 'Tasks', exact: true }).click()
  await active.getByRole('button', { name: 'New task', exact: true }).click()
  await active.getByLabel('Task title', { exact: true }).fill(title)
  await active.getByRole('button', { name: 'Create task', exact: true }).click()
  await expect(active.getByRole('button', { name: 'Creating…', exact: true })).toHaveCount(0)
  const task = active.getByRole('article').filter({ hasText: title })
  await expect(task).toHaveCount(1)
  await task.getByRole('button', { name: 'Update task', exact: true }).click()
  await active.getByRole('button', { name: 'Delete task…', exact: true }).click()
  await active.getByRole('button', { name: 'Delete task', exact: true }).click()
  await expect(task).toHaveCount(0)

  await nav.getByRole('link', { name: 'Artifacts', exact: true }).click()
  await active.getByRole('button', { name: 'New artifact', exact: true }).click()
  await active.getByLabel('Title', { exact: true }).fill(title)
  await active.getByRole('button', { name: 'Create artifact', exact: true }).click()
  await expect(active.getByRole('heading', { name: title, exact: true })).toBeVisible()
  await expect(active.getByLabel('Document body · Markdown')).toBeVisible()
  await active.getByRole('button', { name: 'Archive artifact…', exact: true }).click()
  await active.getByRole('button', { name: 'Archive artifact', exact: true }).click()
  await expect(active.getByRole('button', { name: 'Restore artifact…', exact: true })).toBeVisible()
  expect(creates.map((request) => request.action)).toEqual(['task-create', 'artifact-create'])
  expect(errors).toEqual([])
})
