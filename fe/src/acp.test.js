import assert from 'node:assert/strict'
import test from 'node:test'

import { AcpClient, webConnection } from './acp.js'

test('each browser instance gets a fresh valid ACP connection', () => {
  const first = webConnection()
  const second = webConnection()
  assert.notEqual(first, second)
  assert.match(first, /^harness-web-[a-z0-9-]+$/)
  assert.ok(first.length <= 128)
})

test('re-delivery after a lost acknowledgement does not duplicate updates', () => {
  const client = new AcpClient()
  const seen = []
  client.receive = (frame) => seen.push(frame)
  const first = { sequence: 1, payload: '{"method":"session/update","params":{"text":"one"}}' }
  const second = { sequence: 2, payload: '{"method":"session/update","params":{"text":"two"}}' }
  assert.equal(client.receiveBatch([first]), 1)
  assert.equal(client.receiveBatch([first, second]), 2)
  assert.equal(client.receiveBatch([first, second]), 2)
  assert.deepEqual(seen.map((frame) => frame.params.text), ['one', 'two'])
})

test('queue recovery never repeats a possibly admitted mutation', async () => {
  const client = new AcpClient()
  const sent = []
  let rejected = false
  client.poke = async (value) => sent.push(value)
  client.pending.set(1, { timer: null, frame: { method: 'session/prompt' }, reject: () => { rejected = true } })
  await client.recover()
  assert.ok(rejected)
  assert.equal(client.pending.size, 0)
  assert.equal(sent.length, 1)
  assert.ok(sent[0].open)
})

test('ACP targets the current server, ignoring other localhost cookies and globals', async (t) => {
  const savedWindow = globalThis.window, savedDocument = globalThis.document
  globalThis.window = { ship: 'lux' }
  globalThis.document = { get cookie() { throw new Error('Cookie guessing must not be used') } }
  t.after(() => { globalThis.window = savedWindow; globalThis.document = savedDocument })
  const requests = []
  t.mock.method(globalThis, 'fetch', async (path, options) => {
    requests.push({ path, options })
    return new Response(path.startsWith('/~/channel/') ? '' : '~fasbud-nomtud-sitful-hatred')
  })
  const client = new AcpClient()
  await Promise.all([client.poke({ open: { connection: 'a' } }), client.poke({ open: { connection: 'b' } })])
  assert.equal(requests.filter((r) => r.path === '/~/host').length, 1)
  assert.equal(requests.filter((r) => r.path === '/~/name').length, 1)
  for (const request of requests.filter((r) => r.path.startsWith('/~/channel/'))) {
    assert.equal(JSON.parse(request.options.body)[0].ship, 'fasbud-nomtud-sitful-hatred')
  }
})

test('invalid, unavailable or unauthenticated identity never emits an ACP poke', async (t) => {
  for (const mode of ['invalid', 'unavailable', 'signed-out']) {
    const requests = []
    const mocked = t.mock.method(globalThis, 'fetch', async (path) => {
      requests.push(path)
      if (mode === 'unavailable') return new Response('', { status: 503 })
      return new Response(mode === 'invalid' ? '<html>login</html>' : path === '/~/host' ? '~nec' : '~zod')
    })
    const client = new AcpClient()
    assert.throws(() => client.ship(), /not been identified/)
    await assert.rejects(client.poke({ open: { connection: 'a' } }), /identity|identify|Sign in/)
    assert.deepEqual(requests.sort(), ['/~/host', '/~/name'])
    assert.equal(client.identity, null)
    mocked.mock.restore()
  }
})

test('identity lookup can recover after failure without inventing a destination', async (t) => {
  let available = false
  t.mock.method(globalThis, 'fetch', async () => new Response(available ? '~nec' : '', { status: available ? 200 : 503 }))
  const client = new AcpClient()
  await assert.rejects(client.identify())
  available = true
  assert.equal(await client.identify(), 'nec')
  assert.equal(client.ship(), 'nec')
})
