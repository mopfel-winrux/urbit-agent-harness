import { expect, test } from '@playwright/test'

test.beforeEach(async ({ page }) => {
  await page.goto('/apps/harness/tests/resource-fixture.html')
  await expect.poll(() => page.evaluate(() => window.resourceFixture?.reads.length || 0)).toBeGreaterThan(0)
})

test('switching resources fences a late read from the previous view', async ({ page }) => {
  await page.evaluate(() => window.resourceFixture.select('b'))
  await expect.poll(() => page.evaluate(() => window.resourceFixture.reads.at(-1).path)).toBe('b')
  await page.evaluate(() => {
    const fixture = window.resourceFixture
    fixture.resolve(fixture.reads.at(-1).id, 'current value')
    for (const read of fixture.reads.filter((read) => read.path === 'a')) fixture.resolve(read.id, 'stale value')
  })
  await expect(page.getByLabel('Value')).toHaveText('current value')
  await expect(page.getByLabel('Resource')).toHaveText('b')
})

test('an acknowledged save cannot be overwritten by a read begun before it', async ({ page }) => {
  await page.evaluate(() => {
    const fixture = window.resourceFixture
    fixture.save('saved value')
    for (const read of fixture.reads) fixture.resolve(read.id, 'before save')
  })
  await expect(page.getByLabel('Value')).toHaveText('saved value')
})
