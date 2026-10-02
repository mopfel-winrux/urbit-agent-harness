import assert from 'node:assert/strict'
import test from 'node:test'
import { createModelCatalogs, resolveContextWindow } from './modelCatalogs.js'

test('saving a typed model awaits its advertised capacity', async () => {
  let complete
  const loading = new Promise((resolve) => { complete = resolve })
  let settled = false
  const config = { url: '/responses', model: 'gpt-6-luna', 'max-context': 80_000 }
  const result = resolveContextWindow(config, config, () => loading).then((value) => { settled = true; return value })
  await Promise.resolve()
  assert.equal(settled, false)
  complete({ contexts: { 'gpt-6-luna': 872_000 } })
  assert.equal(await result, 872_000)
})

test('missing catalog metadata preserves only the same saved model and route', async () => {
  const saved = { url: '/responses', model: 'luna', headers: [], 'max-context': 872_000 }
  for (const read of [async () => ({ contexts: {} }), async () => { throw Error('unavailable') }]) {
    assert.equal(await resolveContextWindow(saved, saved, read), 872_000)
    assert.equal(await resolveContextWindow({ ...saved, model: 'unknown' }, saved, read), 800_000)
    assert.equal(await resolveContextWindow({ ...saved, url: '/other' }, saved, read), 800_000)
    assert.equal(await resolveContextWindow({ ...saved, headers: [{ name: 'auth-mode', value: 'other' }] }, saved, read), 800_000)
  }
})

test('reported capacity replaces the default even for a smaller model', async () => {
  const config = { url: '/responses', model: 'small', 'max-context': 800_000 }
  assert.equal(await resolveContextWindow(config, config, async () => ({ contexts: { small: 32_000 } })), 32_000)
})

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
