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
