import { expect, test } from '@playwright/test'
import { mkdir } from 'node:fs/promises'

for (const [name, width, theme] of [['desktop', 1440, 'light'], ['mobile', 390, 'dark']]) {
  test(`Work contains its sections and the sidebar stays compact on ${name}`, async ({ page }) => {
    await page.setViewportSize({ width, height: 960 })
    await page.emulateMedia({ colorScheme: theme, reducedMotion: 'reduce' })
    await page.goto('/apps/harness/tests/workspace-fixture.html#/inbox')
    const openSidebar = async () => { if (name === 'mobile') await page.getByRole('button', { name: 'Open navigation' }).click() }
    const sidebar = page.locator('.sidebar')
    const topnav = page.getByRole('navigation', { name: 'Workspace', exact: true })
    for (const section of ['Inbox', 'Tasks', 'Artifacts', 'Projects']) {
      await topnav.getByRole('link', { name: section, exact: true }).click()
      await expect(topnav.getByRole('link', { name: section, exact: true })).toHaveAttribute('aria-current', 'page')
      await openSidebar()
      await expect(sidebar.locator('.sidebar-action')).toHaveText(['Work', 'Tlon', 'Search', 'Settings'])
      await expect(sidebar.getByRole('button', { name: 'Work', exact: true })).toHaveAttribute('aria-current', 'page')
      await sidebar.getByRole('button', { name: 'Work', exact: true }).click()
      await expect(page.getByRole('heading', { name: 'Work inbox', exact: true })).toBeVisible()
      if (name === 'mobile') await expect(page.getByRole('dialog', { name: 'Navigation' })).not.toBeVisible()
    }
    await openSidebar()
    const search = sidebar.getByRole('button', { name: 'Search', exact: true })
    await search.focus()
    await page.keyboard.press('Enter')
    await expect(page).toHaveURL(/#\/search$/)
    await openSidebar()
    await expect(search).toHaveAttribute('aria-current', 'page')
    await expect(sidebar.getByRole('button', { name: 'Work', exact: true })).not.toHaveAttribute('aria-current')
    await sidebar.getByRole('button', { name: 'Work', exact: true }).click()
    await expect(page.getByRole('heading', { name: 'Work inbox', exact: true })).toBeVisible()
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true)
    if (process.env.WORKSPACE_VISUAL) {
      const directory = '../.impeccable/review/work-navigation'
      await mkdir(directory, { recursive: true })
      await page.screenshot({ path: `${directory}/${name}.png`, fullPage: true })
      if (name === 'mobile') {
        await openSidebar()
        await page.screenshot({ path: `${directory}/mobile-drawer.png`, fullPage: true })
      }
    }
  })
}
