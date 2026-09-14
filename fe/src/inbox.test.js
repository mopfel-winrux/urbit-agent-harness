import assert from 'node:assert/strict'
import test from 'node:test'
import { createInboxPolling, recordContext, recordCount, recordLinks, recordStatus } from './inbox.js'

test('counts distinguish unknown evidence, no records, and attention records', () => {
  assert.equal(recordCount(null, 'all'), null)
  assert.equal(recordCount({}, 'attention'), 0)
  assert.equal(recordCount({ uncertain: 2, blocked: 1, approval: 3, running: 7 }, 'attention'), 6)
  assert.equal(recordCount({ uncertain: 2, blocked: 1, approval: 3, running: 7 }, 'all'), 13)
})

test('status labels preserve claim, execution, and delivery distinctions', () => {
  assert.equal(recordStatus({ kind: 'task', status: 'claimed' }), 'Assigned')
  assert.equal(recordStatus({ kind: 'input', execution: 'completed', delivery: 'uncertain' }), 'Delivery uncertain')
  assert.equal(recordStatus({ kind: 'input', execution: 'completed', delivery: null }), 'Execution complete · no delivery record')
  assert.equal(recordStatus({ kind: 'input', execution: 'failed', delivery: 'delivered' }), 'Execution failed')
  assert.equal(recordStatus({ kind: 'input', execution: 'cancelled', delivery: 'uncertain' }), 'Delivery uncertain')
  assert.equal(recordStatus({ kind: 'input', execution: 'completed', delivery: 'claimed' }), 'Send claimed · awaiting receipt')
  assert.equal(recordStatus({ kind: 'schedule', status: 'complete' }), 'Schedule ended')
  assert.equal(recordStatus({ kind: 'proposal', status: 'accepted' }), 'Proposal accepted')
})

test('record links encode identities and refer to existing source surfaces', () => {
  assert.deepEqual(recordLinks({ kind: 'proposal', id: 'proposal?&/☀', artifact: 'a/b', status: 'pending' }), [{ label: 'Review proposal', href: '#/artifacts/a%2Fb?proposal=proposal%3F%26%2F%E2%98%80' }])
  assert.deepEqual(recordLinks({ kind: 'task', id: 'later task', project: 'p?q' }), [{ label: 'Open task', href: '#/tasks/later%20task' }])
  assert.equal(recordLinks({ kind: 'input', sessionId: 'a/b', hand: 'tlon' })[0].href, '#/a%2Fb')
  assert.equal(recordLinks({ kind: 'input', hand: 'custom' }).length, 0)
  assert.match(recordContext({ kind: 'task', project: 'p', claimant: { label: 'worker' } }), /Assigned to worker/)
})

test('inbox polling coalesces focus and stops completely while hidden or unmounted', async () => {
  let hidden = false, calls = 0, finish
  const timers = new Map()
  let sequence = 0
  const poller = createInboxPolling(() => { calls++; return new Promise((resolve) => { finish = resolve }) }, {
    isHidden: () => hidden,
    setTimer: (fn, ms) => { const id = ++sequence; timers.set(id, { fn, ms }); return id },
    clearTimer: (id) => timers.delete(id),
  })
  const initial = poller.refresh()
  assert.equal(poller.refresh(), initial)
  await Promise.resolve()
  assert.equal(calls, 1)
  hidden = true
  await poller.visibilityChanged()
  finish()
  await initial
  assert.equal(timers.size, 0)
  hidden = false
  const focused = poller.visibilityChanged()
  await Promise.resolve()
  assert.equal(calls, 2)
  finish()
  await focused
  assert.equal(timers.size, 1)
  assert.equal([...timers.values()][0].ms, 30_000)
  hidden = true
  await poller.visibilityChanged()
  assert.equal(timers.size, 0)
  hidden = false
  const departing = poller.refresh()
  await Promise.resolve()
  poller.stop()
  finish()
  await departing
  await poller.refresh()
  assert.equal(calls, 3)
  assert.equal(timers.size, 0)
})
