// Two disposable ships: native Lens + four reply surfaces; restore policy,
// defaults and exactly the original native bot-trust membership afterward.
import assert from 'node:assert/strict'
import { createServer } from 'node:http'
import { readFile } from 'node:fs/promises'
import { randomUUID } from 'node:crypto'
import { execFile } from 'node:child_process'
import { promisify } from 'node:util'
import { setTimeout as sleep } from 'node:timers/promises'
import ob from '../fe/node_modules/urbit-ob/src/index.js'
import { Client, cookie, base } from './lib/ship-client.mjs'

assert.equal(process.env.LENS_TEST_TRUST, '1', 'LENS_TEST_TRUST=1 explicitly permits temporary test-owner trust changes')
const peerUrl = process.env.PEER_URL, nest = process.env.TEST_NEST
assert.ok(peerUrl && nest && process.env.PEER_COOKIE)
const row = (await readFile(process.env.PEER_COOKIE, 'utf8')).split('\n').find((r) => /\turbauth-~/.test(r)).split('\t')
const peerCookie = `${row[5]}=${row[6]}`, peer = row[5].slice('urbauth-'.length)
const ship = cookie.split('=')[0].slice('urbauth-'.length), client = new Client(), marker = `lens-${randomUUID()}`
let event = 0, mode = 'dm', requests = 0, originals, originalTrust, trustTouched = false
const failures = []
const server = createServer(async (req, res) => {
  try {
    let raw = ''; for await (const part of req) raw += part
    const body = JSON.parse(raw), last = body.messages.findLastIndex((m) => m.role === 'user')
    requests++
    const done = body.messages.slice(last + 1).some((m) => m.role === 'tool')
    const message = done ? { role: 'assistant', content: `${marker}-${mode}-PRIVATE_REPLY` }
      : { role: 'assistant', content: '', tool_calls: [{ id: `PRIVATE_CALL_${mode}`, type: 'function', function: { name: 'current_time', arguments: '{}' } }] }
    res.writeHead(200, { 'content-type': 'application/json' })
    res.end(JSON.stringify({ choices: [{ finish_reason: done ? 'stop' : 'tool_calls', message }] }))
  } catch (error) { failures.push(error); res.writeHead(500); res.end() }
})
async function scry(path, remote = false, optional = false) {
  const res = await fetch(`${remote ? peerUrl : base}/~/scry/${path}.json`, { headers: { cookie: remote ? peerCookie : cookie }, signal: AbortSignal.timeout(15000) })
  if (optional && res.status === 404) return null
  assert.ok(res.ok, `scry ${path}: ${res.status}`); return res.json()
}
async function until(label, check) {
  const end = Date.now() + 45000
  while (Date.now() < end) {
    if (failures.length) throw new AggregateError(failures)
    const value = await check()
    if (value) { console.log(`PASS ${label}`); return value }
    await sleep(250)
  }
  throw new Error(`Timed out: ${label}`)
}
async function poke(app, mark, json) {
  const res = await fetch(`${peerUrl}/~/channel/${marker}`, { method: 'PUT', headers: { cookie: peerCookie, 'content-type': 'application/json' }, body: JSON.stringify([{ id: ++event, action: 'poke', ship: peer.slice(1), app, mark, json }]), signal: AbortSignal.timeout(15000) })
  assert.ok(res.ok)
}
// Test-only dbug vase decoding. Never log the state or private Lens payloads.
async function trusted() {
  const res = await fetch(`${peerUrl}/~/scry/steward/dbug/state.noun`, { headers: { cookie: peerCookie } })
  assert.ok(res.ok)
  const bytes = new Uint8Array(await res.arrayBuffer()), refs = new Map(); let bit = 0
  function bits(n) { let out = 0n; for (let i = 0; i < n; i++) { assert.ok(bit < bytes.length * 8); out |= BigInt((bytes[bit >> 3] >> (bit++ & 7)) & 1) << BigInt(i) } return out }
  function rub() { let k = 0; while (bits(1) === 0n) k++; if (!k) return 0n; return bits(Number((1n << BigInt(k - 1)) + bits(k - 1))) }
  function cue() { const at = bit; let value; if (bits(1) === 0n) value = rub(); else if (bits(1) === 0n) value = [cue(), cue()]; else { value = refs.get(Number(rub())); assert.notEqual(value, undefined) } refs.set(at, value); return value }
  const state = cue()[1]; assert.equal(state[0], 0n)
  const who = BigInt(ob.patp2dec(ship))
  function has(tree) { return tree !== 0n && (tree[0] === who || has(tree[1][0]) || has(tree[1][1])) }
  return has(state[1][1][0])
}
async function trust(value) {
  trustTouched = true
  await poke('steward', 'steward-action-1', { [value ? 'trust-bot' : 'untrust-bot']: { ship } })
  await until(`native owner trust ${value ? 'enabled' : 'disabled'}`, async () => (await trusted()) === value)
}
const da = () => (((BigInt(Date.now()) * (1n << 64n)) / 1000n) + 170141184475152167957503069145530368000n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.')
async function send(surface, parent) {
  const content = [{ inline: [...(surface === 'channel' ? [{ ship }] : []), `${marker}-${mode}-PRIVATE_PROMPT`] }]
  const essay = { content, author: peer, sent: Date.now(), kind: '/chat', meta: null, blob: null }
  const reply = { content, author: peer, sent: Date.now(), blob: null }, inChannel = surface.startsWith('channel')
  const json = inChannel ? { channel: { nest, action: { post: parent ? { reply: { id: parent, action: { add: reply } } } : { add: essay } } } }
    : { ship, diff: { id: parent || `${peer}/${da()}`, delta: parent ? { reply: { id: `${peer}/${da()}`, meta: null, delta: { add: { 'reply-essay': reply, time: null } } } } : { add: { essay, time: null } } } }
  await poke(inChannel ? 'channels' : 'chat', inChannel ? 'channel-action-2' : 'chat-dm-action-2', json)
}
const dmPage = () => scry(`chat/v4/dm/${ship}/writs/newest/32/heavy`, true)
const channelPage = () => scry(`channels/v5/${nest}/posts/newest/32/post`, true)
function matches(essay) { return essay?.author === ship && JSON.stringify(essay.content).includes(`${marker}-${mode}-PRIVATE_REPLY`) }
function pointer(essay) {
  const [p] = JSON.parse(essay.blob)
  assert.equal(p.type, 'tlon-context-lens'); assert.equal(p.version, 1); assert.equal(p.botShip, ship)
  return p
}
async function verify(essay) {
  const p = pointer(essay)
  const lens = await until(`${mode} native owner summary and final delivery evidence`, async () => {
    const entry = (await scry(`steward/v1/lens/run/${ship}/${p.lensId}`, true, true))?.entry
    return entry?.payload?.lens?.delivery?.status === 'delivered' && entry.payload.lens
  })
  assert.equal(lens.lensId, p.lensId); assert.equal(lens.visibility, 'owner'); assert.equal(lens.status, 'completed')
  assert.equal(lens.tools.callCount, 1); assert.equal(lens.tools.runs[0].name, 'current_time'); assert.equal(lens.tools.runs[0].status, 'completed')
  assert.equal(lens.lifecycle.deliveredMessageCount, 1); assert.equal(lens.outputs.length, 1)
  assert.ok(lens.outputs[0].messageId.startsWith(`${ship}/`))
  // Native Messenger rounds its millisecond JSON projection; Lens floors it.
  assert.ok(Math.abs(lens.outputs[0].sentAt - essay.sent) <= 1)
  assert.ok(!JSON.stringify(lens).includes('PRIVATE_')); assert.equal(lens.retrySupported, false)
  return p
}
try {
  originalTrust = await trusted()
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve)); await client.start()
  originals = { defaults: await client.call('harness/defaults'), policy: (await client.call('harness/tlon')).policy }
  await trust(false)
  await client.call('harness/defaults/configure', { config: { ...originals.defaults, url: `http://127.0.0.1:${server.address().port}/completions`, model: 'fixture', key: '', headers: [], tools: [] } })
  await client.call('harness/tlon/configure', { enabled: true, owner: peer, mentions: true, trusted: [] })
  await send('dm')
  const dm = await until('Lens rejection does not block real DM', async () => Object.values((await dmPage()).writs).find((p) => matches(p.essay)))
  pointer(dm.essay)
  await until('untrusted owner explicitly rejects Lens export', async () => (await scry('harness-tlon/status')).lens.failed > 0)
  const before = requests
  await trust(true); await client.call('harness/tlon/lens/retry')
  await verify(dm.essay)
  assert.equal(requests, before)
  assert.equal(Object.values((await dmPage()).writs).filter((p) => matches(p.essay)).length, 1)
  console.log('PASS export retry neither reruns inference/tools nor resends a reply')
  mode = 'dm-thread'; await send(mode, dm.seal.id)
  const dmReply = await until('native DM-thread Lens pointer', async () => Object.values((await dmPage()).writs).flatMap((p) => Object.values(p.seal?.replies || {})).find((p) => matches(p['reply-essay'])))
  await verify(dmReply['reply-essay'])
  mode = 'channel'; await send(mode)
  const post = await until('native channel Lens pointer', async () => Object.entries((await channelPage()).posts).find(([, p]) => matches(p.essay)))
  await verify(post[1].essay)
  mode = 'channel-thread'; await send(mode, post[0])
  const reply = await until('native channel-thread Lens pointer', async () => Object.values((await channelPage()).posts[post[0]]?.seal?.replies || {}).find((p) => matches(p['reply-essay'])))
  await verify(reply['reply-essay'])
  await until('Lens export queue drained', async () => !(await scry('harness-tlon/status')).lens.pending)
  if (process.env.TEST_PANE) {
    const count = requests, run = promisify(execFile)
    for (const enabled of ['n', 'y']) {
      await run('tmux', ['send-keys', '-t', process.env.TEST_PANE, '-l', '--', `|rein %harness [%.${enabled} %harness-tlon]`])
      await run('tmux', ['send-keys', '-t', process.env.TEST_PANE, 'Enter']); await sleep(1000)
    }
    await until('native adapter reload preserves accepted Lens evidence', async () => (await scry('harness-tlon/status')).headConnected)
    await sleep(1500); assert.equal(requests, count)
    await verify(reply['reply-essay'])
  }
  assert.deepEqual(failures, [])
} finally {
  if (originals) {
    await client.call('harness/tlon/configure', originals.policy)
    await client.call('harness/defaults/configure', { config: { ...originals.defaults, key: '' } })
  }
  if (trustTouched) await trust(originalTrust)
  await client.close(); server.closeAllConnections(); await new Promise((resolve) => server.close(resolve))
}
