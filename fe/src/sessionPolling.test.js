import assert from 'node:assert/strict'
import test from 'node:test'
import { createSessionPolling, sessionPollDelay } from './sessionPolling.js'

const settle = async () => { for (let i = 0; i < 20; i++) await Promise.resolve() }

test('idle snapshot budget is six reads per minute; active cadence stays 600ms', async (t) => {
  t.mock.timers.enable({ apis: ['setTimeout'] })
  let reads = 0, active = false, hidden = false
  const loop = createSessionPolling({ read: async () => { reads++ }, active: () => active, hidden: () => hidden })
  await loop.refresh()
  for (let i = 0; i < 60; i++) { t.mock.timers.tick(1000); await settle() }
  assert.equal(reads, 7, 'initial read plus six safety reads, formerly 101 reads')
  assert.equal(sessionPollDelay(false, false), 10_000)
  active = true; await loop.refresh()
  const start = reads
  for (let i = 0; i < 10; i++) { t.mock.timers.tick(600); await settle() }
  assert.equal(reads - start, 10)
  hidden = true; await loop.refresh()
  assert.equal(sessionPollDelay(true, true), 2500)
  active = false; await loop.refresh()
  const background = reads
  t.mock.timers.tick(29_999); await settle(); assert.equal(reads, background)
  t.mock.timers.tick(1); await settle(); assert.equal(reads, background + 1)
  loop.close(); t.mock.timers.tick(60_000); await settle(); assert.equal(reads, background + 1)
})

test('notifications during a slow read request one trailing read, never overlapping', async (t) => {
  t.mock.timers.enable({ apis: ['setTimeout'] })
  let reads = 0, resolve
  const loop = createSessionPolling({ read: () => { reads++; return new Promise((yes) => { resolve = yes }) }, active: () => false, hidden: () => false })
  const first = loop.refresh()
  for (let i = 0; i < 100; i++) assert.equal(loop.refresh(), first)
  t.mock.timers.tick(60_000); await settle(); assert.equal(reads, 1)
  resolve(); await settle(); assert.equal(reads, 2)
  resolve(); await first
  loop.close()
})

test('first stream activity wakes an idle view, active token bursts do not cause reads', async (t) => {
  t.mock.timers.enable({ apis: ['setTimeout'] })
  let reads = 0, active = false
  const loop = createSessionPolling({ read: async () => { reads++; active = true }, active: () => active, hidden: () => false })
  loop.stream(); await settle(); assert.equal(reads, 1)
  for (let i = 0; i < 1000; i++) loop.stream()
  await settle(); assert.equal(reads, 1)
  loop.close()
})
