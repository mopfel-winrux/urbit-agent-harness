import { expect, test } from '@playwright/test'
import { mkdir } from 'node:fs/promises'

test('batched inbox visual evidence across desktop, mobile, and both themes', async ({ page }) => {
  test.skip(!process.env.INBOX_VISUAL, 'Set INBOX_VISUAL=1 for the bounded visual review pass')
  const directory = '../.impeccable/review/inbox'
  await mkdir(directory, { recursive: true })
  for (const [device, width] of [['desktop', 1440], ['mobile', 390]]) {
    for (const theme of ['light', 'dark']) {
      await page.setViewportSize({ width, height: 960 })
      await page.emulateMedia({ colorScheme: theme, reducedMotion: 'reduce' })
      await page.goto('/apps/harness/tests/workspace-fixture.html#/inbox')
      await expect(page.locator('.inbox-record')).toHaveCount(4)
      const evidence = page.locator('.inbox-record').first().locator('details')
      if (await evidence.getAttribute('open') === null) await evidence.getByText('Recorded evidence', { exact: true }).click()
      await expect(evidence).toHaveAttribute('open', '')
      await page.evaluate(() => window.scrollTo(0, 0))
      expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true)
      await page.screenshot({ path: `${directory}/${device}-${theme}.png`, fullPage: true })
    }
  }
})
