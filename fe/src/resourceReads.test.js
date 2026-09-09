import assert from 'node:assert/strict'
import test from 'node:test'
import { createResourceReads } from './resourceReads.js'

test('overlapping consumers share a read and both receive saved replacements', async () => {
  let resolve, calls = 0
  const reads = createResourceReads(() => { calls++; return new Promise((done) => { resolve = done }) })
  const a = [], b = []
  const offA = reads.subscribe('settings', (next) => a.push(next))
  const offB = reads.subscribe('settings', (next) => b.push(next))
  const first = reads.refresh('settings')
  assert.equal(reads.refresh('settings'), first)
  await Promise.resolve()
  assert.equal(calls, 1)
  reads.replace('settings', 'saved')
  resolve('stale')
  await first
  assert.deepEqual(a, [{ value: 'saved', error: '' }])
  assert.deepEqual(b, a)
  offA(); offB()
})

test('a read after save is fresh and old completion cannot clear it', async () => {
  const pending = [], values = []
  const reads = createResourceReads(() => new Promise((resolve) => pending.push(resolve)))
  const off = reads.subscribe('a', (next) => values.push(next.value))
  const old = reads.refresh('a')
  await Promise.resolve()
  reads.replace('a', 'saved')
  const fresh = reads.refresh('a')
  await Promise.resolve()
  pending[0]('stale'); await old
  assert.equal(reads.refresh('a'), fresh)
  pending[1]('new'); await fresh
  assert.deepEqual(values, ['saved', 'new'])
  off()
})

test('unmounted consumers are ignored and failed reads can be retried', async () => {
  let fail = true
  const reads = createResourceReads(async () => { if (fail) throw new Error('offline'); return 'ready' })
  const values = []
  const off = reads.subscribe('a', (next) => values.push(next))
  await reads.refresh('a')
  fail = false
  await reads.refresh('a')
  off()
  await reads.refresh('a')
  assert.deepEqual(values, [{ error: 'offline' }, { value: 'ready', error: '' }])
})

test('returning to a closed view starts a fresh read and fences its old response', async () => {
  const pending = [], values = []
  const reads = createResourceReads(() => new Promise((resolve) => pending.push(resolve)))
  const off = reads.subscribe('a', () => {})
  const old = reads.refresh('a')
  await Promise.resolve()
  off()
  await Promise.resolve()
  const close = reads.subscribe('a', (next) => values.push(next.value))
  const fresh = reads.refresh('a')
  await Promise.resolve()
  pending[0]('stale'); await old
  assert.deepEqual(values, [])
  pending[1]('current'); await fresh
  assert.deepEqual(values, ['current'])
  close()
})
