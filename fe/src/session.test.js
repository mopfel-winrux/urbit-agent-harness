import assert from 'node:assert/strict'
import test from 'node:test'
import { admitted, applySnapshot, transcriptEntries } from './session.js'

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
    { id: '2', role: 'assistant', body: '', calls: [{ id: 'c', name: 'get_ship_time', args: '{}' }] },
    { id: '4', role: 'tool', callId: 'c', name: 'get_ship_time', body: 'noon' },
    { id: '5', role: 'assistant', body: 'noon', calls: [] },
  ]
  const entries = transcriptEntries(items)
  assert.equal(entries.length, 2)
  assert.equal(entries[0].status, 'completed')
  assert.equal(entries[0].body, 'noon')
  assert.equal(items[0].calls[0].args, '{}')
})
