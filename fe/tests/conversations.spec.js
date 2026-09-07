import { expect, test } from '@playwright/test'

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
