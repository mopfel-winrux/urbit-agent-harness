#!/usr/bin/env node
// Live protocol checks. Creates only uniquely named test sessions and removes
// those sessions in finally. Uses provider credentials already on the ship.
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { randomUUID } from 'node:crypto'
import { setTimeout as sleep } from 'node:timers/promises'

const base = process.env.SHIP_URL || 'http://127.0.0.1'
const cookiePath = process.env.SHIP_COOKIE
if (!cookiePath) throw new Error('Set SHIP_COOKIE to an authenticated Netscape cookie file.')
const line = (await readFile(cookiePath, 'utf8')).split('\n').find((row) => /\turbauth-~/.test(row))
if (!line) throw new Error('Ship authentication cookie not found.')
const fields = line.split('\t')
const cookie = `${fields[5]}=${fields[6]}`
const ship = fields[5].slice('urbauth-~'.length)

class Client {
  constructor() {
    this.connection = `conformance-${randomUUID()}`
    this.channel = this.connection
    this.event = 0; this.rpc = 0; this.through = 0
    this.pending = new Map(); this.updates = []; this.running = false
  }
  async poke(json) {
    const response = await fetch(`${base}/~/channel/${this.channel}`, {
      method: 'PUT', headers: { cookie, 'content-type': 'application/json' },
      body: JSON.stringify([{ id: ++this.event, action: 'poke', ship, app: 'acp', mark: 'acp-action-1', json }]),
      signal: AbortSignal.timeout(15_000),
    })
    assert.ok(response.ok, `poke HTTP ${response.status}`)
  }
  async start() {
    await this.poke({ open: { connection: this.connection } })
    this.running = true
    this.polling = this.poll().catch((error) => {
      for (const value of this.pending.values()) value.reject(error)
    })
    await this.call('initialize', { protocolVersion: 1, clientInfo: { name: 'harness-conformance', version: '1' } })
  }
  async call(method, params = {}) {
    const id = ++this.rpc
    const result = new Promise((resolve, reject) => {
      const timer = setTimeout(() => { this.pending.delete(id); reject(new Error(`${method} timed out`)) }, 90_000)
      this.pending.set(id, { resolve: (value) => { clearTimeout(timer); resolve(value) }, reject: (error) => { clearTimeout(timer); reject(error) } })
    })
    // Register rejection handling before transport can fail.
    const sent = this.poke({ send: { connection: this.connection, target: 'agent', payload: JSON.stringify({ jsonrpc: '2.0', id, method, params }) } })
    return Promise.all([sent, result]).then(([, value]) => value)
  }
  async poll() {
    while (this.running) {
      const response = await fetch(`${base}/~/scry/acp/v1/${this.connection}/client.json?_=${Date.now()}`, {
        headers: { cookie, 'cache-control': 'no-cache' }, signal: AbortSignal.timeout(15_000),
      })
      assert.ok(response.ok, `queue HTTP ${response.status}`)
      for (const message of (await response.json()).messages || []) {
        if (Number(message.sequence) <= this.through) continue
        const frame = JSON.parse(message.payload)
        if (frame.id != null && ('result' in frame || 'error' in frame)) {
          const value = this.pending.get(Number(frame.id))
          this.pending.delete(Number(frame.id))
          if (value) frame.error ? value.reject(new Error(frame.error.message)) : value.resolve(frame.result)
        } else this.updates.push(frame)
        this.through = Number(message.sequence)
      }
      if (this.through) await this.poke({ ack: { connection: this.connection, target: 'client', through: this.through } })
      await sleep(100)
    }
  }
  async close() {
    this.running = false
    await this.polling
    for (const value of this.pending.values()) value.reject(new Error('Test client closed'))
    this.pending.clear()
    await this.poke({ close: { connection: this.connection, reason: 'conformance complete' } })
  }
}

const first = new Client(), second = new Client()
const names = []
const suffix = randomUUID().slice(0, 8)
const snapshot = (client, sessionId, extra = {}) => client.call('harness/session/snapshot', { sessionId, ...extra })
const prompt = (client, sessionId, text, clientMessageId = randomUUID()) => client.call('session/prompt', { sessionId, clientMessageId, prompt: [{ type: 'text', text }] })

try {
  await Promise.all([first.start(), second.start()])
  for (const label of ['one', 'two']) {
    const name = `conformance-${suffix}-${label}`
    const result = await first.call('session/new', { name, cwd: '/', mcpServers: [] })
    names.push(result.sessionId)
  }
  const [one, two] = names
  const initial = await snapshot(first, one)
  assert.equal(initial.phase, 'idle')
  assert.deepEqual(initial.entries, [])
  const started = Date.now()
  const inputId = randomUUID()
  const turns = [prompt(first, one, 'Use get_ship_time, then answer with the exact time returned.', inputId),
    prompt(second, two, 'Reply with one short sentence about the Moon.')]
  const completed = Promise.all(turns)
  completed.catch(() => {})
  let observed
  for (let i = 0; i < 30; i++) {
    observed = await snapshot(second, one)
    if (observed.entries.some((entry) => entry.role === 'user')) break
    await sleep(100)
  }
  assert.ok(observed.entries.some((entry) => entry.role === 'user'), 'second client sees admitted input')
  const admissionMs = Date.now() - started
  assert.ok(admissionMs < 5000, `admission took ${admissionMs}ms`)
  // Detaching is not cancellation. Rejoining can inspect the run immediately.
  await first.call('session/close', { sessionId: one })
  await second.call('session/resume', { sessionId: one })
  const results = await completed
  assert.ok(results.every((result) => result.stopReason === 'end_turn'))
  const finished = await snapshot(second, one)
  assert.equal(finished.phase, 'idle')
  assert.ok(finished.entries.some((entry) => entry.role === 'tool' && entry.name === 'get_ship_time'))
  const admission = first.updates.find((frame) => frame.params?.update?.clientMessageId === inputId)
  assert.ok(admission)
  assert.equal(finished.entries.find((entry) => entry.role === 'user').inputId, admission.params.update.inputId)
  assert.ok(!first.updates.some((frame) => frame.params?.sessionId === two), 'independent client queues')
  const unchanged = await snapshot(second, one, { since: finished.revision })
  assert.equal(unchanged.entries, null)
  const native = await fetch(`${base}/~/scry/harness/snapshot/${one}.json`, { headers: { cookie } }).then((r) => r.json())
  assert.deepEqual(native.entries, finished.entries, 'native and ACP projections agree')
  const point = finished.entries.findLast((entry) => entry.role === 'assistant' && !entry.calls.length)
  const branchName = `conformance-${suffix}-branch`
  const branch = await second.call('harness/session/fork', { sessionId: one, name: branchName, eventCount: point.eventCount })
  names.push(branch.sessionId)
  const copy = await snapshot(first, branch.sessionId)
  assert.deepEqual(copy.entries, finished.entries.filter((entry) => entry.eventCount <= point.eventCount))
  assert.equal(copy.origin.sessionId, one)
  assert.equal(copy.origin.eventCount, point.eventCount)
  assert.equal(copy.phase, 'idle')
  await prompt(second, branch.sessionId, 'Reply with exactly: branch alive')
  assert.equal((await snapshot(first, one)).revision, finished.revision, 'branch leaves parent untouched')
  // Cancellation remains addressable from a different client and settles the
  // original caller. A late provider response must not revive the cancelled run.
  const pending = prompt(first, two, 'Write fifty short lines about trees.')
  pending.catch(() => {})
  await sleep(250)
  await second.call('session/cancel', { sessionId: two })
  assert.equal((await pending).stopReason, 'cancelled')
  const cancelled = await snapshot(second, two)
  await sleep(1500)
  assert.equal((await snapshot(second, two)).revision, cancelled.revision)
  console.log(JSON.stringify({ ok: true, admissionMs, completionMs: Date.now() - started,
    checks: ['concurrent turns', 'client isolation', 'admission identity', 'detach/resume', 'native/ACP parity', 'branch provenance', 'parent isolation', 'cross-client cancellation'] }, null, 2))
} finally {
  for (const sessionId of names) await first.call('session/delete', { sessionId }).catch(() => {})
  await Promise.all([first.close(), second.close()])
}
