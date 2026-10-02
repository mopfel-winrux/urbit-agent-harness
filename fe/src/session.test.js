import assert from 'node:assert/strict'
import test from 'node:test'
import { admitted, applySnapshot, applyHistory, applyStream, transcriptEntries } from './session.js'

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

test('unchanged snapshots reuse retained history instead of copying or merging it', () => {
  const entries = Array.from({ length: 10_000 }, (_, index) => ({ id: String(index), eventCount: index, body: 'retained message' }))
  let snapshot = { revision: 10_000, phase: 'idle', entries, before: 1 }
  for (let i = 0; i < 1000; i++) {
    snapshot = applySnapshot(snapshot, { revision: 10_000, phase: 'idle', entries: null })
    assert.equal(snapshot.entries, entries)
    assert.equal(snapshot.before, 1)
  }
})

test('stream frames render immediately and snapshots cannot roll them back', () => {
  const chunk = (revision, offset, text) => ({ revision, offset, content: { type: 'text', text } })
  const idle = { revision: 3, phase: 'idle', streaming: '', entries: [] }
  const first = applyStream(idle, chunk(5, 0, 'Hello 🙂'))
  assert.equal(first.revision, 3, 'a stream does not advance the transcript cursor')
  assert.equal(first.phase, 'thinking')
  const next = applyStream(first, chunk(5, 10, '!'))
  assert.equal(next.streaming, 'Hello 🙂!')
  assert.equal(applyStream(next, chunk(5, 0, 'Hello 🙂')), next)
  assert.equal(applyStream(next, chunk(4, 0, 'old')), next)
  assert.equal(applyStream(next, chunk(5, 20, 'gap')), null)
  const delayed = applySnapshot(next, { ...idle, revision: 5, streaming: 'Hello 🙂', entries: null })
  assert.equal(delayed.streaming, 'Hello 🙂!')
  assert.equal(delayed.streamRevision, 5)
  const complete = applySnapshot(delayed, { ...idle, revision: 6, entries: [{ id: '6', body: 'Hello 🙂!' }] })
  assert.equal(complete.streaming, '')
  assert.equal(complete.phase, 'idle')
  assert.equal(applyStream(complete, chunk(5, 10, '!')), complete)
  assert.equal(applyStream(complete, chunk(8, 0, 'Next turn')).streaming, 'Next turn')
})

test('a fresh snapshot recovers a missing stream prefix', () => {
  const snapshot = { revision: 4, phase: 'thinking', entries: [], streaming: '🙂' }
  const chunk = { revision: 4, offset: 4, content: { type: 'text', text: ' done' } }
  assert.equal(applyStream(snapshot, chunk).streaming, '🙂 done')
  assert.equal(applyStream(snapshot, { ...chunk, offset: 2 }), null)
  assert.equal(applyStream(snapshot, { ...chunk, revision: undefined }), null)
})
