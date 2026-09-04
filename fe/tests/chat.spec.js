import { expect, test } from '@playwright/test'

test.beforeEach(async ({ page }) => {
  await page.goto('/apps/harness/tests/fixture.html')
  await expect(page.getByRole('heading', { name: 'A small head, capable hands' })).toBeAttached()
})

test('renders GFM safely while preserving literal user messages', async ({ page }) => {
  const reply = page.locator('.message.assistant')
  await expect(reply.locator('strong')).toHaveText('ship owns the session')
  await expect(reply.locator('blockquote')).toContainText('window into the work')
  await expect(reply.locator('table tr')).toHaveCount(3)
  await expect(reply.locator('del')).toHaveText('Polling owns the run.')
  await expect(reply.locator('input[type=checkbox]')).toHaveCount(2)
  await expect(reply.locator('input[type=checkbox]').first()).toBeChecked()
  await expect(reply.locator('input[type=checkbox]').first()).toBeDisabled()
  await expect(page.locator('.message.user .message-body')).toHaveText('Please explain **the harness** with examples.')
  await expect(reply.locator('script, img, a[href^="javascript:"]')).toHaveCount(0)
  await expect(page.getByRole('link', { name: 'Documentation', exact: true })).toHaveAttribute('rel', 'noopener noreferrer')
  expect(await page.evaluate(() => window.markdownExecuted)).toBeUndefined()
})

test('copies code exactly and keeps footnotes inside the current route', async ({ page, context }) => {
  await context.grantPermissions(['clipboard-read', 'clipboard-write'])
  const code = await page.locator('.code-block pre').textContent()
  await page.getByRole('button', { name: 'Copy code' }).click()
  await expect(page.getByRole('button', { name: 'Copy code' })).toHaveText('Copied')
  expect(await page.evaluate(() => navigator.clipboard.readText())).toBe(code)
  const url = page.url()
  await page.locator('.markdown sup a').click()
  expect(page.url()).toBe(url)
  await expect(page.locator('.footnotes')).toBeInViewport()
})

test('composer grows, keeps shift-enter, and renders streaming markdown', async ({ page }) => {
  const input = page.getByRole('textbox', { name: 'Message', exact: true })
  const initial = (await input.boundingBox()).height
  await input.fill('first line\nsecond line\nthird line\nfourth line')
  expect((await input.boundingBox()).height).toBeGreaterThan(initial)
  await input.press('Shift+Enter')
  await expect(input).toHaveValue(/fourth line\n$/)
  expect(await page.evaluate(() => window.harnessFixture.sent.length)).toBe(0)
  await input.press('Enter')
  await expect(input).toHaveValue('')
  await expect(page.locator('.thinking-message strong')).toHaveText('streamed')
  await expect(page.getByRole('button', { name: 'Interrupt', exact: true })).toBeVisible()
  await page.getByRole('button', { name: 'Interrupt', exact: true }).click()
  await expect(page.locator('.thinking-message')).toHaveCount(0)
  await input.fill('A different question')
  await input.press('Enter')
  await expect.poll(() => page.evaluate(() => window.harnessFixture.sent.length)).toBe(2)
})

test('cancelled tool receipts remove running indicators', async ({ page }) => {
  await page.evaluate(() => window.harnessFixture.update({ phase: 'idle', entries: [
    { id: '3', role: 'assistant', calls: [{ id: 'slow', name: 'http_fetch', args: '{}' }] },
    { id: '5:slow', role: 'tool', callId: 'slow', body: 'cancelled: by client', cancelled: true },
  ] }))
  await expect(page.locator('.tool-entry small')).toHaveText('cancelled')
  await expect(page.locator('.tool-entry.running')).toHaveCount(0)
  await expect(page.locator('.thinking-message')).toHaveCount(0)
})

test('does not pull the reader down on updates and offers a jump to latest', async ({ page }) => {
  const transcript = page.getByRole('region', { name: 'Conversation messages' })
  await transcript.evaluate((element) => { element.scrollTop = 0 })
  await expect(page.getByRole('button', { name: 'Latest messages' })).toBeVisible()
  await page.evaluate(() => window.harnessFixture.update({ phase: 'thinking', streaming: '**More** output' }))
  await expect(page.locator('.thinking-message strong')).toHaveText('More')
  expect(await transcript.evaluate((element) => element.scrollTop)).toBe(0)
  await page.getByRole('button', { name: 'Latest messages' }).click()
  await expect(page.getByRole('button', { name: 'Latest messages' })).toBeHidden()
  await expect(page.locator('.thinking-message')).toBeInViewport()
})

test('dialog traps focus, closes with Escape, and restores focus', async ({ page }) => {
  const trigger = page.getByRole('button', { name: 'New conversation', exact: true })
  await trigger.click()
  await expect(page.getByRole('dialog')).toBeVisible()
  await expect(page.getByRole('textbox', { name: 'Name', exact: true })).toBeFocused()
  for (let i = 0; i < 7; i++) await page.keyboard.press('Tab')
  expect(await page.evaluate(() => document.querySelector('dialog').contains(document.activeElement))).toBe(true)
  await page.keyboard.press('Escape')
  await expect(page.getByRole('dialog')).toHaveCount(0)
  await expect(trigger).toBeFocused()
})

for (const width of [1280, 390]) {
  for (const colorScheme of ['light', 'dark']) {
    test(`layout stays contained at ${width}px in ${colorScheme} mode`, async ({ page }, testInfo) => {
      await page.setViewportSize({ width, height: 844 })
      await page.emulateMedia({ colorScheme })
      await page.locator('.transcript').evaluate((element) => { element.scrollTop = 0 })
      expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true)
      expect(await page.locator('.sidebar').evaluate((element) => element.scrollWidth <= element.clientWidth)).toBe(true)
      const pre = page.locator('.code-block pre')
      expect(await pre.evaluate((element) => element.scrollWidth > element.clientWidth)).toBe(true)
      const checkbox = await page.locator('.markdown input').first().boundingBox()
      expect(checkbox.width).toBeLessThanOrEqual(16)
      await expect(page.getByRole('button', { name: 'Conversation settings', exact: true })).toBeInViewport()
      await expect(page.getByRole('textbox', { name: 'Message', exact: true })).toBeInViewport()
      await page.screenshot({ path: testInfo.outputPath(`chat-${width}-${colorScheme}.png`), fullPage: true })
    })
  }
}
