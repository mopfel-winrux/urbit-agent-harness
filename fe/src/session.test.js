import assert from 'node:assert/strict'
import test from 'node:test'
import { admitted, applySnapshot, applyHistory, transcriptEntries } from './session.js'

test('history joins preserve live state, stable ordering and the oldest cursor', () => {
  const row = (eventCount) => ({ id: String(eventCount), eventCount, body: String(eventCount) })
  const old = { revision: 90, before: 50, phase: 'thinking', entries: [row(50), row(80)] }
  const next = applySnapshot(old, { revision: 92, before: 80, phase: 'idle', entries: [row(80), row(92)] })
  assert.equal(next.before, 50)
  assert.deepEqual(next.entries.map((r) => r.eventCount), [50, 80, 92])
  const page = { revision: 90, before: null, entries: [row(1), row(49)] }
  const joined = applyHistory(next, page, 50)
  assert.equal(joined.revision, 92)
  assert.equal(joined.phase, 'idle')
  assert.equal(joined.before, null)
  assert.deepEqual(joined.entries.map((r) => r.eventCount), [1, 49, 50, 80, 92])
  assert.equal(applyHistory(joined, page, 50), joined, 'duplicate or stale page cannot move cursor')
  assert.equal(applyHistory(next, { ...page, revision: 93 }, 50), next, 'refresh before merging newer history')
})

test('disconnected snapshot gaps stay pageable and unchanged polls retain the cursor', () => {
  const old = { revision: 50, before: 20, entries: [{ id: '50', eventCount: 50 }] }
  const same = applySnapshot(old, { revision: 50, entries: null, before: null })
  assert.equal(same.before, 20)
  const fresh = { revision: 200, before: 160, entries: [{ id: '160', eventCount: 160 }] }
  assert.equal(applySnapshot(old, fresh), fresh)
})

test('admission uses ship input identity even for repeated identical prompts', () => {
  const entries = [{ body: 'same', inputId: 'first' }]
  assert.equal(admitted({ text: 'same' }, entries), false)
  assert.equal(admitted({ text: 'same', inputId: 'second' }, entries), false)
  assert.equal(admitted({ text: 'same', inputId: 'first' }, entries), true)
})

test('unchanged snapshots retain transcript and stale replies cannot undo it', () => {
  const prior = { revision: 5, entries: [{ id: '4', body: 'hello' }], phase: 'thinking' }
  const same = applySnapshot(prior, { revision: 5, entries: null, streaming: 'world' })
  assert.equal(same.entries, prior.entries)
  assert.equal(applySnapshot(same, { revision: 4, entries: [] }), same)
  const finished = applySnapshot(same, { revision: 6, phase: 'idle', streaming: '', entries: [...prior.entries, { id: '6', body: 'world' }] })
  assert.equal(finished.entries.length, 2)
  assert.equal(finished.streaming, '')
})

test('tool results join the matching call without mutating the canonical snapshot', () => {
  const items = [
    { id: '2', role: 'assistant', body: '', calls: [{ id: 'c', name: 'list_desk_files', args: '{}' }] },
    { id: '4', role: 'tool', callId: 'c', name: 'list_desk_files', body: 'noon' },
    { id: '5', role: 'assistant', body: 'noon', calls: [] },
  ]
  const entries = transcriptEntries(items)
  assert.equal(entries.length, 2)
  assert.equal(entries[0].status, 'completed')
  assert.equal(entries[0].body, 'noon')
  assert.equal(items[0].calls[0].args, '{}')
})

test('interrupted tools are terminal while completed siblings retain their result', () => {
  const entries = transcriptEntries([
    { id: '3', role: 'assistant', calls: [{ id: 'a', name: 'http_fetch' }, { id: 'b', name: 'http_fetch' }] },
    { id: '5', role: 'tool', callId: 'a', body: 'HTTP 200' },
    { id: '6:b', role: 'tool', callId: 'b', body: 'cancelled: by client', cancelled: true },
    { id: '7', role: 'user', body: 'continue' },
  ])
  assert.deepEqual(entries.map((entry) => entry.status), ['completed', 'cancelled', undefined])
  assert.equal(entries[0].body, 'HTTP 200')
})
