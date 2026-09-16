import { expect, test } from '@playwright/test'

for (const legacy of [false, true]) test(`startup ${legacy ? 'falls back for old ships' : 'uses the combined welcome/list response'}`, async ({ page }) => {
  await page.clock.install()
  await page.goto(`/apps/harness/tests/settings-fixture.html?page=app${legacy ? '&legacy-bootstrap' : ''}`)
  await expect(page.getByRole('button', { name: 'daily-notes', exact: true })).toBeVisible()
  const calls = await page.evaluate(() => window.settingsFixture.calls)
  expect(calls).toContain('harness/onboarding/ensure')
  expect(calls.includes('session/list')).toBe(legacy)
})

test('sidebar pages twenty at a time and searches unloaded conversation names', async ({ page }) => {
  await page.goto('/apps/harness/tests/fixture.html?many')
  await expect(page.locator('.chat-row')).toHaveCount(20)
  await page.getByRole('button', { name: /Load more conversations/ }).click()
  await expect(page.locator('.chat-row')).toHaveCount(40)
  await page.getByRole('button', { name: /Load more conversations/ }).click()
  await expect(page.locator('.chat-row')).toHaveCount(47)
  await expect(page.getByRole('button', { name: /Load more conversations/ })).toHaveCount(0)
  const search = page.getByRole('searchbox', { name: 'Search conversations' })
  await search.fill('CONVERSATION-45')
  await expect(page.locator('.chat-row')).toHaveCount(1)
  await expect(page.getByRole('button', { name: 'conversation-45', exact: true })).toBeVisible()
  await search.fill('missing conversation')
  await expect(page.getByText('No matches', { exact: true })).toBeVisible()
  await search.fill('')
  await expect(page.locator('.chat-row')).toHaveCount(20)
})

test('sidebar logo keeps its rounded white background in both themes', async ({ page }) => {
  await page.goto('/apps/harness/tests/fixture.html')
  const logo = page.getByRole('img', { name: 'Harness', exact: true })
  await expect(logo).toBeVisible()
  for (const theme of ['light', 'dark']) {
    await page.evaluate((theme) => { document.documentElement.dataset.theme = theme }, theme)
    await expect(logo).toHaveCSS('background-color', 'rgb(255, 255, 255)')
    await expect(logo).toHaveCSS('border-radius', '8px')
  }
})

test('conversation names reclaim action space until hover or keyboard focus', async ({ page }) => {
  await page.goto('/apps/harness/tests/fixture.html')
  const row = page.locator('.chat-row').first()
  const link = row.locator('.chat-link')
  const name = link.locator('.truncate')
  await page.mouse.move(1000, 800)
  await expect(link).toHaveCSS('padding-right', '10px')
  await expect(row.locator('.chat-actions')).toHaveCSS('opacity', '0')
  const fullWidth = (await name.boundingBox()).width
  await row.hover()
  await expect(link).toHaveCSS('padding-right', '82px')
  expect(fullWidth - (await name.boundingBox()).width).toBeCloseTo(72, 0)
  await expect(row.locator('.chat-actions')).toHaveCSS('opacity', '1')
  await page.mouse.move(1000, 800)
  await expect(link).toHaveCSS('padding-right', '10px')
  await row.getByRole('button', { name: /^Rename / }).focus()
  await expect(link).toHaveCSS('padding-right', '82px')
  await expect(row.locator('.chat-actions')).toHaveCSS('opacity', '1')
  await page.getByRole('searchbox', { name: 'Search conversations' }).focus()
  await expect(link).toHaveCSS('padding-right', '10px')
})

test('mobile conversation actions keep visible touch targets and reserved space', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await page.goto('/apps/harness/tests/fixture.html')
  await page.getByRole('button', { name: 'Open navigation' }).click()
  const row = page.locator('.chat-row').first()
  await expect(row.locator('.chat-link')).toHaveCSS('padding-right', '138px')
  await expect(row.locator('.chat-actions')).toHaveCSS('opacity', '1')
  await expect(row.getByRole('button', { name: /^Rename / })).toHaveCSS('width', '44px')
})
