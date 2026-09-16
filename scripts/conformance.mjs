#!/usr/bin/env node
// Live protocol checks. Creates only uniquely named test sessions and removes
// those sessions in finally. Uses provider credentials already on the ship.
import assert from 'node:assert/strict'
import { Client, base, cookie } from './lib/ship-client.mjs'
import { randomUUID } from 'node:crypto'
import { setTimeout as sleep } from 'node:timers/promises'

const first = new Client(), second = new Client()
const names = []
const suffix = randomUUID().slice(0, 8)
const snapshot = (client, sessionId, extra = {}) => client.call('harness/session/snapshot', { sessionId, ...extra })
const prompt = (client, sessionId, text, clientMessageId = randomUUID()) => client.call('session/prompt', { sessionId, clientMessageId, prompt: [{ type: 'text', text }] })

try {
  await Promise.all([first.start(), second.start()])
  for (const label of ['one', 'two']) {
    const name = `conformance-${suffix}-${label}`
    const result = await first.call('session/new', { name, cwd: '/', mcpServers: [] })
    names.push(result.sessionId)
  }
  const [one, two] = names
  const initial = await snapshot(first, one)
  assert.equal(initial.phase, 'idle')
  assert.deepEqual(initial.entries, [])
  const started = Date.now()
  const inputId = randomUUID()
  const turns = [prompt(first, one, 'Use list_desk_files with path /harness/sur, then name one file returned.', inputId),
    prompt(second, two, 'Reply with one short sentence about the Moon.')]
  const completed = Promise.all(turns)
  completed.catch(() => {})
  let observed
  for (let i = 0; i < 30; i++) {
    observed = await snapshot(second, one)
    if (observed.entries.some((entry) => entry.role === 'user')) break
    await sleep(100)
  }
  assert.ok(observed.entries.some((entry) => entry.role === 'user'), 'second client sees admitted input')
  const admissionMs = Date.now() - started
  assert.ok(admissionMs < 5000, `admission took ${admissionMs}ms`)
  // Detaching is not cancellation. Rejoining can inspect the run immediately.
  await first.call('session/close', { sessionId: one })
  await second.call('session/resume', { sessionId: one })
  const results = await completed
  assert.ok(results.every((result) => result.stopReason === 'end_turn'))
  const finished = await snapshot(second, one)
  assert.equal(finished.phase, 'idle')
  assert.ok(finished.entries.some((entry) => entry.role === 'tool' && entry.name === 'list_desk_files'))
  const admission = first.updates.find((frame) => frame.params?.update?.clientMessageId === inputId)
  assert.ok(admission)
  assert.equal(finished.entries.find((entry) => entry.role === 'user').inputId, admission.params.update.inputId)
  assert.ok(!first.updates.some((frame) => frame.params?.sessionId === two), 'independent client queues')
  const unchanged = await snapshot(second, one, { since: finished.revision })
  assert.equal(unchanged.entries, null)
  const native = await fetch(`${base}/~/scry/harness/snapshot/${one}.json`, { headers: { cookie } }).then((r) => r.json())
  assert.deepEqual(native.entries, finished.entries, 'native and ACP projections agree')
  const point = finished.entries.findLast((entry) => entry.role === 'assistant' && !entry.calls.length)
  const branchName = `conformance-${suffix}-branch`
  const branch = await second.call('harness/session/fork', { sessionId: one, name: branchName, eventCount: point.eventCount })
  names.push(branch.sessionId)
  const copy = await snapshot(first, branch.sessionId)
  assert.deepEqual(copy.entries, finished.entries.filter((entry) => entry.eventCount <= point.eventCount))
  assert.equal(copy.origin.sessionId, one)
  assert.equal(copy.origin.eventCount, point.eventCount)
  assert.equal(copy.phase, 'idle')
  await prompt(second, branch.sessionId, 'Reply with exactly: branch alive')
  assert.equal((await snapshot(first, one)).revision, finished.revision, 'branch leaves parent untouched')
  // Cancellation remains addressable from a different client and settles the
  // original caller. A late provider response must not revive the cancelled run.
  const pending = prompt(first, two, 'Write fifty short lines about trees.')
  pending.catch(() => {})
  await sleep(250)
  await second.call('session/cancel', { sessionId: two })
  assert.equal((await pending).stopReason, 'cancelled')
  const cancelled = await snapshot(second, two)
  await sleep(1500)
  assert.equal((await snapshot(second, two)).revision, cancelled.revision)
  console.log(JSON.stringify({ ok: true, admissionMs, completionMs: Date.now() - started,
    checks: ['concurrent turns', 'client isolation', 'admission identity', 'detach/resume', 'native/ACP parity', 'branch provenance', 'parent isolation', 'cross-client cancellation'] }, null, 2))
} finally {
  for (const sessionId of names) {
    try { await first.call('session/delete', { sessionId }) }
    catch (error) { console.error(`Retained test session ${sessionId}: ${error.message}`) }
  }
  const closed = await Promise.allSettled([first.close(), second.close()])
  for (const result of closed) if (result.status === 'rejected') console.error(`Client close failed: ${result.reason.message}`)
}
