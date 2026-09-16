import assert from 'node:assert/strict'
import test from 'node:test'
import { watchConversationUpdates } from './conversationUpdates.js'

const settle = async () => { for (let i = 0; i < 12; i++) await Promise.resolve() }

test('idle list reads drop from once a second to once per fifteen seconds', async (t) => {
  t.mock.timers.enable({ apis: ['setTimeout'] })
  const acp = new EventTarget(), window = new EventTarget(), document = new EventTarget()
  let reads = 0
  const stop = watchConversationUpdates({ acp, window, document, refresh: async () => { reads++ } })
  await settle()
  for (let i = 0; i < 60; i++) { t.mock.timers.tick(1000); await settle() }
  assert.equal(reads, 5, 'initial read plus four safety polls, formerly 61 reads')
  stop()
  t.mock.timers.tick(60_000); await settle()
  assert.equal(reads, 5)
})

test('change bursts coalesce, focus refreshes, hidden tabs use a minute fallback', async (t) => {
  t.mock.timers.enable({ apis: ['setTimeout'] })
  const acp = new EventTarget(), window = new EventTarget(), document = new EventTarget(), channel = new EventTarget()
  let reads = 0, posts = 0, closed = false
  channel.postMessage = () => { posts++ }; channel.close = () => { closed = true }
  const stop = watchConversationUpdates({ acp, window, document, channel, refresh: async () => { reads++ } })
  await settle()
  for (let i = 0; i < 10; i++) acp.dispatchEvent(new Event('harness/sessions/changed'))
  t.mock.timers.tick(250); await settle()
  assert.equal(reads, 2)
  assert.equal(posts, 10)
  channel.dispatchEvent(new Event('message'))
  t.mock.timers.tick(250); await settle()
  assert.equal(reads, 3); assert.equal(posts, 10, 'remote invalidations never echo')
  document.hidden = true
  t.mock.timers.tick(15_000); await settle()
  t.mock.timers.tick(59_999); await settle()
  assert.equal(reads, 4)
  t.mock.timers.tick(1); await settle()
  assert.equal(reads, 5)
  document.hidden = false; window.dispatchEvent(new Event('focus')); await settle()
  assert.equal(reads, 6)
  stop(); assert.equal(closed, true)
})
