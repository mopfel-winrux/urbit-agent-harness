import assert from 'node:assert/strict'
import test from 'node:test'
import { createModelCatalogs } from './modelCatalogs.js'

test('concurrent consumers, remounts and expiry share one request per catalog', async () => {
  let reads = 0, now = 0
  const catalogs = createModelCatalogs(async () => ({ models: [++reads] }), { ttl: 100, now: () => now })
  assert.deepEqual(await Promise.all([catalogs.load('a', '/a'), catalogs.load('a', '/a')]), [{ models: [1] }, { models: [1] }])
  assert.deepEqual(await catalogs.load('a', '/a'), { models: [1] })
  now = 100
  assert.deepEqual(await catalogs.load('a', '/a'), { models: [2] })
  assert.deepEqual(await catalogs.load('a', '/a', { force: true }), { models: [3] })
  await catalogs.load('b', '/b')
  await catalogs.load('a', '')
  assert.equal(reads, 4)
})

test('failures retry and a credential invalidation fences older catalog writes', async () => {
  let fail = true, resolve
  const catalogs = createModelCatalogs(() => {
    if (fail) throw new Error('offline')
    return new Promise((yes) => { resolve = yes })
  })
  await assert.rejects(catalogs.load('a', '/a'), /offline/)
  fail = false
  const old = catalogs.load('a', '/a')
  await Promise.resolve()
  catalogs.invalidate()
  resolve({ models: ['old'] }); await old
  assert.equal(catalogs.peek('a:/a'), undefined)
  const fresh = catalogs.load('a', '/a')
  await Promise.resolve()
  resolve({ models: ['new'] }); await fresh
  assert.deepEqual(catalogs.peek('a:/a'), { models: ['new'] })
})
