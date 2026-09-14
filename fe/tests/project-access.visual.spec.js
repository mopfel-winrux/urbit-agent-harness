import { expect, test } from '@playwright/test'
import { mkdir } from 'node:fs/promises'

test.skip(!process.env.PROJECT_ACCESS_CAPTURE, 'Opt-in synthetic capture, not screenshot assertion')
for (const [name, width, height] of [['desktop', 1440, 1000], ['mobile', 390, 844]]) {
  test(`project access ${name}`, async ({ page }) => {
    await mkdir('../.impeccable/review/project-access', { recursive: true })
    await page.setViewportSize({ width, height })
    await page.goto('/apps/harness/tests/workspace-fixture.html#/projects/neighborhood')
    await page.getByRole('button', { name: 'Access', exact: true }).click()
    await expect(page.getByRole('heading', { name: 'Read-only client access' })).toBeVisible()
    await page.evaluate(() => { window.workFixture.db.projects.neighborhood.members[0].role = 'maintainer'; window.workFixture.changed() })
    await expect(page.getByText('maintainer · Workspace tools enabled', { exact: true })).toBeVisible()
    await page.evaluate(() => window.scrollTo(0, 0))
    await page.screenshot({ path: `../.impeccable/review/project-access/${name}.png`, fullPage: true, animations: 'disabled' })
    await page.getByRole('button', { name: 'Create read-only key…', exact: true }).click()
    const dialog = page.getByRole('dialog')
    await dialog.getByLabel('Client label', { exact: true }).fill('Project dashboard · synthetic example')
    await page.evaluate(() => window.scrollTo(0, 0))
    await page.screenshot({ path: `../.impeccable/review/project-access/${name}-create.png`, fullPage: true, animations: 'disabled' })
    await dialog.getByRole('checkbox').check()
    await dialog.getByRole('button', { name: 'Create read-only key', exact: true }).click()
    await expect(dialog.getByRole('heading', { name: 'Read-only key created' })).toBeVisible()
    await page.evaluate(() => window.scrollTo(0, 0))
    await page.screenshot({ path: `../.impeccable/review/project-access/${name}-issued.png`, fullPage: true, animations: 'disabled' })
    await dialog.getByRole('button', { name: 'Done', exact: true }).click()
    await page.getByRole('button', { name: 'Revoke…', exact: true }).click()
    await page.evaluate(() => window.scrollTo(0, 0))
    await page.screenshot({ path: `../.impeccable/review/project-access/${name}-revoke.png`, fullPage: true, animations: 'disabled' })
  })
}
