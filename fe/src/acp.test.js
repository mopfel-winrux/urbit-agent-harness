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
  client.pending.set(1, { frame: { method: 'session/prompt' }, reject: () => { rejected = true } })
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

test('slow RPC replies have no elapsed-time deadline, including prompts', async (t) => {
  t.mock.timers.enable({ apis: ['setTimeout'] })
  const client = new AcpClient()
  const sent = []
  client.poke = async (value) => sent.push(value)
  const methods = ['initialize', 'session/list', 'session/prompt']
  const replies = methods.map((method) => client.call(method))
  await Promise.resolve()
  t.mock.timers.tick(31 * 60_000)
  assert.equal(client.pending.size, 3)
  assert.equal(sent.length, 3, 'a slow request is never resent')
  for (const [index, method] of methods.entries()) client.receive({ id: index + 1, result: method })
  assert.deepEqual(await Promise.all(replies), methods)
  assert.equal(client.pending.size, 0)
})

test('identity and HTTP pokes wait past the old 15 second timeout', async (t) => {
  t.mock.timers.enable({ apis: ['setTimeout'] })
  const waiting = []
  t.mock.method(globalThis, 'fetch', (path, options) => new Promise((resolve, reject) => {
    waiting.push({ path, options, resolve })
    options.signal.addEventListener('abort', () => reject(options.signal.reason), { once: true })
  }))
  const client = new AcpClient()
  const pending = client.poke({ open: { connection: client.connection } })
  assert.equal(waiting.length, 2)
  t.mock.timers.tick(45_000)
  for (const request of waiting) {
    assert.equal(request.options.signal.aborted, false)
    request.resolve(new Response('~nec'))
  }
  await client.identity
  // Allow the poke continuation after the shared identity promise to run.
  for (let i = 0; i < 5 && waiting.length < 3; i++) await Promise.resolve()
  assert.equal(waiting.length, 3)
  t.mock.timers.tick(45_000)
  assert.equal(waiting[2].options.signal.aborted, false)
  waiting[2].resolve(new Response(''))
  await pending
})

test('closing aborts a slow queue read without reporting a transport error', async (t) => {
  t.mock.timers.enable({ apis: ['setTimeout'] })
  let signal
  t.mock.method(globalThis, 'fetch', (path, options) => {
    if (path.startsWith('/~/channel/')) return Promise.resolve(new Response(''))
    signal = options.signal
    return new Promise((resolve, reject) => signal.addEventListener('abort', () => reject(signal.reason), { once: true }))
  })
  const client = new AcpClient()
  client.host = 'nec'
  client.running = true
  const polling = client.poll()
  t.mock.timers.tick(45_000)
  assert.equal(signal.aborted, false)
  client.close()
  await polling
  assert.equal(signal.aborted, true)
  assert.equal(client.lastError, null)
})

test('closing settles pending calls even before startup completes', async () => {
  const client = new AcpClient()
  client.poke = async () => {}
  const pending = client.call('session/prompt')
  const rejected = assert.rejects(pending, /Connection closed/)
  client.close()
  await rejected
  assert.equal(client.pending.size, 0)
  client.receive({ id: 1, result: 'late reply' })
  await assert.rejects(client.call('session/list'), /Connection closed/)
  await assert.rejects(client.identify(), /Connection closed/)
})

test('transport failures still reject immediately without resending', async () => {
  const client = new AcpClient()
  let sends = 0
  client.poke = async () => { sends++; throw new Error('offline') }
  await assert.rejects(client.call('session/list'), /offline/)
  assert.equal(sends, 1)
  assert.equal(client.pending.size, 0)
})
