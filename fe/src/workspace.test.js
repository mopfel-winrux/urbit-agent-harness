import assert from 'node:assert/strict'
import test from 'node:test'
import { createWorkspaceReads, readDraft, persistDraft, changedContent, documentDiff, workspaceCall } from './workspace.js'
import { acp } from './acp.js'

const deferred = () => { let resolve; const promise = new Promise((yes) => { resolve = yes }); return { promise, resolve } }
const settle = async () => { for (let i = 0; i < 12; i++) await Promise.resolve() }

test('workspace invalidations share one read and owe exactly one trailing refresh', async () => {
  const flights = [], a = [], b = []
  let changed, started = 0, stopped = 0
  const reads = createWorkspaceReads(() => { const flight = deferred(); flights.push(flight); return flight.promise }, (notify) => { changed = notify; started++; return () => { stopped++ } })
  const key = JSON.stringify(['artifact', { id: 'doc' }])
  const offA = reads.subscribe(key, (value) => a.push(value))
  const offB = reads.subscribe(key, (value) => b.push(value))
  assert.equal(flights.length, 1)
  changed(); changed(); changed()
  assert.equal(flights.length, 1)
  flights[0].resolve({ head: 1 }); await settle()
  assert.equal(flights.length, 2)
  flights[1].resolve({ head: 2 }); await settle()
  assert.deepEqual(a, b)
  assert.equal(a.at(-1).value.head, 2)
  assert.equal(started, 1)
  offA(); assert.equal(stopped, 0)
  offB(); assert.equal(stopped, 1)
})

test('unmounted or replaced workspace reads cannot deliver old data', async () => {
  const flights = [], seen = []
  const reads = createWorkspaceReads(() => { const flight = deferred(); flights.push(flight); return flight.promise }, () => () => {})
  const key = JSON.stringify(['artifact', { id: 'one' }])
  reads.subscribe(key, (value) => seen.push(value))()
  const off = reads.subscribe(key, (value) => seen.push(value))
  flights[0].resolve('old'); await settle()
  assert.equal(seen.length, 0)
  flights[1].resolve('current'); await settle()
  assert.equal(seen[0].value, 'current')
  off()
})

test('draft storage preserves the revision fence and reports quota failure', () => {
  const values = new Map()
  const storage = { getItem: (key) => values.get(key), setItem: (key, value) => values.set(key, value) }
  const draft = { base: 8, title: 'Plan', body: 'Unsaved', sources: [] }
  assert.equal(persistDraft(storage, 'doc', draft), true)
  assert.deepEqual(readDraft(storage, 'doc'), draft)
  assert.equal(persistDraft({ setItem() { throw new Error('quota') } }, 'doc', draft), false)
  assert.equal(readDraft({ getItem: () => '{' }, 'doc'), null)
  assert.equal(changedContent(draft, { ...draft, body: 'Changed' }), true)
  assert.equal(changedContent(draft, { ...draft }), false)
})

test('replacement diff preserves context and shows added or removed lines without reordering', () => {
  assert.deepEqual(documentDiff('A\nold\nZ', 'A\nnew\nZ'), { same: false, prefix: ['A'], removed: ['old'], added: ['new'], suffix: ['Z'] })
  assert.equal(documentDiff('same', 'same').same, true)
  assert.deepEqual(documentDiff('x', 'x\ny').added, ['y'])
  assert.deepEqual(documentDiff('x\ny', 'x').removed, ['y'])
})

test('workspace mutations use one owner RPC without a transport-side retry', async (t) => {
  const sent = []
  t.mock.method(acp, 'start', async () => {})
  t.mock.method(acp, 'call', async (...args) => { sent.push(args); throw new Error('uncertain result') })
  await assert.rejects(workspaceCall('publish', { id: 'doc', revision: 2 }), /uncertain result/)
  assert.deepEqual(sent, [['harness/workspace', { action: 'publish', args: { id: 'doc', revision: 2 } }]])
})
