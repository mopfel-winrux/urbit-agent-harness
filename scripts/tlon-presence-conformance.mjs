// Two disposable ships, real Messenger/Activity/ACP/Presence, controlled Iris.
// Exercises provider failure and repair without needing a paid credential.
// Restores policy/defaults; test messages and their audit sessions remain.
import assert from 'node:assert/strict'
import { createServer } from 'node:http'
import { readFile } from 'node:fs/promises'
import { randomUUID } from 'node:crypto'
import { setTimeout as sleep } from 'node:timers/promises'
import { Client, cookie } from './lib/ship-client.mjs'

const peerUrl = process.env.PEER_URL
assert.ok(peerUrl && process.env.PEER_COOKIE, 'Set PEER_URL and PEER_COOKIE')
const row = (await readFile(process.env.PEER_COOKIE, 'utf8')).split('\n').find((r) => /\turbauth-~/.test(r)).split('\t')
const peerCookie = `${row[5]}=${row[6]}`, peer = row[5].slice('urbauth-'.length)
const ship = cookie.split('=')[0].slice('urbauth-'.length)
const channel = `presence-test-${randomUUID()}`, client = new Client()
let event = 0, defaults, policy, sessionId, url
const requests = [], tools = []
const server = createServer(async (req, res) => {
  if (req.url === '/slow-tool') { tools.push(res); return }
  let body = ''
  for await (const chunk of req) body += chunk
  requests.push({ url: req.url, body: JSON.parse(body), header: req.headers['x-fixture'], res })
})
async function scry(path) {
  const res = await fetch(`${peerUrl}/~/scry/${path}.json`, { headers: { cookie: peerCookie }, signal: AbortSignal.timeout(15000) })
  assert.ok(res.ok, `${path}: HTTP ${res.status}`)
  return res.json()
}
async function poke(actions) {
  const res = await fetch(`${peerUrl}/~/channel/${channel}`, { method: 'PUT',
    headers: { cookie: peerCookie, 'content-type': 'application/json' },
    body: JSON.stringify(actions), signal: AbortSignal.timeout(15000) })
  assert.ok(res.ok)
}
async function send(text) {
  const da = (((BigInt(Date.now()) * (1n << 64n)) / 1000n) + 170141184475152167957503069145530368000n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.')
  await poke([{ id: ++event, action: 'poke', ship: peer.slice(1), app: 'chat', mark: 'chat-dm-action-2', json: {
    ship, diff: { id: `${peer}/${da}`, delta: { add: { time: null, essay: {
      content: [{ inline: [text] }], author: peer, sent: Date.now(), kind: '/chat', meta: null, blob: null,
    } } } },
  } }])
}
async function until(label, check) {
  const start = Date.now()
  while (Date.now() - start < 30000) {
    const result = await check()
    if (result) { console.log(`PASS ${label} (${Date.now() - start}ms)`); return result }
    await sleep(200)
  }
  throw new Error(`Timed out: ${label}`)
}
const presence = async () => (await scry('presence/v1/init')).init?.[`/dm/${ship}`]?.computing?.[ship]
const snapshot = () => client.call('harness/session/snapshot', { sessionId })
const answer = (res, content, calls) => res.end(JSON.stringify({ choices: [{ finish_reason: calls ? 'tool_calls' : 'stop', message: {
  role: 'assistant', content, ...(calls ? { tool_calls: calls } : {}),
} }], usage: { prompt_tokens: 10, completion_tokens: 5 } }))
try {
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve))
  url = `http://127.0.0.1:${server.address().port}`
  await client.start()
  defaults = await client.call('harness/defaults')
  policy = (await client.call('harness/tlon')).policy
  const config = { url: `${url}/first`, model: 'first-model', key: '', headers: [{ name: 'x-fixture', value: 'first' }],
    system: 'Keep these instructions.', 'max-context': 80000, tools: ['web'] }
  await client.call('harness/defaults/configure', { config })
  await client.call('harness/tlon/configure', { enabled: true, owner: peer, mentions: true, trusted: [] })
  await send('Presence fixture: first request')
  await until('DM reaches inference', () => requests.length === 1)
  ;[sessionId] = (await client.call('harness/tlon')).sessions
  assert.ok(sessionId)
  const firstPresence = await until('peer sees computing', async () => (await presence())?.display.text === 'Thinking...' && await presence())
  assert.equal(JSON.parse(firstPresence.display.blob).protocol, 'tlon.computing-status.v1')
  assert.equal(firstPresence.timing.timeout, '~s30')
  requests[0].res.writeHead(401, { 'content-type': 'application/json' })
  requests[0].res.end('{"error":{"message":"User not found.","code":401}}')
  await until('provider error is visible in the shared session', async () => (await snapshot()).error?.includes('http error 401'))
  await until('failure clears computing', async () => !await presence())
  const prior = await client.call('harness/session/config', { sessionId })
  await client.call('harness/session/configure', { sessionId, config: { ...prior, key: '', tools: ['web'] } })
  await client.call('harness/defaults/configure', { config: { ...config, url: `${url}/second`, model: 'second-model',
    headers: [{ name: 'x-fixture', value: 'second' }], system: 'Do not replace the existing session instructions.', tools: [] } })
  assert.equal((await client.call('harness/session/config', { sessionId })).model, 'first-model', 'defaults are not retroactive')
  const changed = await client.call('harness/session/use-default-model', { sessionId })
  assert.equal(changed.model, 'second-model')
  assert.equal(changed.system, prior.system)
  assert.deepEqual(changed.tools, ['web'])
  console.log('PASS explicit model-default adoption preserves instructions and grants')
  await send('Presence fixture: new provider, then a slow tool')
  await until('existing DM uses new inference configuration', () => requests.length === 2)
  assert.equal(requests[1].url, '/second'); assert.equal(requests[1].body.model, 'second-model'); assert.equal(requests[1].header, 'second')
  answer(requests[1].res, '', [{ id: 'presence-slow', type: 'function', function: { name: 'http_fetch', arguments: JSON.stringify({ url: `${url}/slow-tool` }) } }])
  await until('tool starts', () => tools.length === 1)
  await until('peer sees tool activity', async () => (await presence())?.display.text === 'Using tools...')
  await client.call('session/cancel', { sessionId })
  await until('cancellation clears computing', async () => !await presence())
  tools[0].end('LATE_TOOL_RESULT')
  await send('Presence fixture: resume after cancellation')
  await until('cancelled DM accepts another message', () => requests.length === 3)
  const marker = `PRESENCE_OK_${Date.now()}`
  answer(requests[2].res, marker)
  await until('real response delivered to peer', async () => JSON.stringify(await scry(`chat/v4/dm/${ship}/writs/newest/8/light`)).includes(marker))
  await until('success clears computing', async () => !await presence())
  assert.ok(!(await snapshot()).entries.some((e) => e.body?.includes('LATE_TOOL_RESULT')))
} finally {
  if (policy) await client.call('harness/tlon/configure', policy)
  if (defaults) await client.call('harness/defaults/configure', { config: { ...defaults, key: '' } })
  await client.close()
  await poke([{ id: ++event, action: 'delete' }])
  server.closeAllConnections()
  await new Promise((resolve) => server.close(resolve))
}
