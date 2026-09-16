// Opt-in real local ship smoke test. No provider calls or public publication.
import { test, expect } from '@playwright/test'
import { readFile } from 'node:fs/promises'
import { randomUUID } from 'node:crypto'

test('installed App routes create and edit an artifact against local Gall', async ({ page, context }) => {
  test.skip(!process.env.WORKSPACE_LIVE, 'Requires an explicitly selected local test ship')
  test.setTimeout(90_000)
  const base = process.env.SHIP_URL || 'http://127.0.0.1'
  expect(['127.0.0.1', 'localhost', '[::1]']).toContain(new URL(base).hostname)
  const rows = (await readFile(process.env.SHIP_COOKIE, 'utf8')).split('\n')
  const fields = rows.find((row) => /\turbauth-~/.test(row)).split('\t')
  await context.addCookies([{ name: fields[5], value: fields[6], url: base, httpOnly: true, sameSite: 'Lax' }])
  const title = `Local UI fixture ${randomUUID().slice(0, 8)}`
  const errors = []
  page.on('pageerror', (error) => errors.push(error.message))
  await page.goto(`${base}/apps/harness/#/artifacts`)
  await page.getByRole('button', { name: 'New artifact', exact: true }).click()
  await page.getByLabel('Title', { exact: true }).fill(title)
  await page.getByRole('button', { name: 'Create artifact', exact: true }).click()
  await expect(page.getByRole('heading', { name: title, exact: true })).toBeVisible()
  const artifactURL = page.url()
  try {
    await page.getByLabel('Document body · Markdown').fill('A private local UI smoke-test revision.')
    await page.getByRole('button', { name: 'Save revision', exact: true }).click()
    await expect(page.getByRole('status').filter({ hasText: 'Saved revision 2.' })).toBeVisible()
    await page.reload()
    await expect(page.getByLabel('Document body · Markdown')).toHaveValue('A private local UI smoke-test revision.')
    await page.getByRole('navigation', { name: 'Workspace', exact: true }).getByRole('link', { name: 'Projects', exact: true }).click()
    await expect(page.getByRole('heading', { name: 'Projects', exact: true })).toBeVisible()
    await page.goto(artifactURL)
    await page.getByRole('button', { name: 'Publish…', exact: true }).click()
    await expect(page.getByRole('dialog')).toBeVisible()
    await expect(page.getByRole('button', { name: 'Publish page', exact: true })).toBeDisabled()
    await page.getByRole('button', { name: 'Cancel', exact: true }).click()
    expect(errors).toEqual([])
  } finally {
    await page.goto(artifactURL)
    await page.getByRole('button', { name: 'Archive artifact…', exact: true }).click()
    await page.getByRole('dialog').getByRole('button', { name: 'Archive artifact', exact: true }).click()
    await expect(page.getByRole('button', { name: 'Restore artifact…', exact: true })).toBeVisible()
  }
})
