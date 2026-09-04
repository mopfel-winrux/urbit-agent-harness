// Deterministic live race test: real ACP/head/Iris, local provider + slow tool.
// No provider credentials, external writes, or modifications to user sessions.
import assert from 'node:assert/strict'
import { createServer } from 'node:http'
import { randomUUID } from 'node:crypto'
import { setTimeout as sleep } from 'node:timers/promises'
import { Client, base, cookie } from './lib/ship-client.mjs'

const client = new Client(), observer = new Client()
const requests = [], toolRequests = [], held = []
let sessionId, url
const server = createServer(async (req, res) => {
  if (req.url === '/slow') {
    toolRequests.push(req.url); held.push(res)
    return // Remains in flight until cancellation or the test releases it.
  }
  if (req.url === '/fast') {
    toolRequests.push(req.url); res.end('ALREADY_DONE'); return
  }
  let body = ''
  for await (const chunk of req) body += chunk
  requests.push(JSON.parse(body))
  const first = requests.length === 1
  res.writeHead(200, { 'content-type': 'application/json' })
  res.end(JSON.stringify({ choices: [{ finish_reason: first ? 'tool_calls' : 'stop', message: {
    role: 'assistant', content: first ? '' : 'CONTINUED_OK',
    ...(first ? { tool_calls: ['fast', 'slow'].map((name) => ({ id: `cancel-test-${name}`, type: 'function',
      function: { name: 'http_fetch', arguments: JSON.stringify({ url: `${url}/${name}` }) } })) } : {}),
  } }], usage: { prompt_tokens: 10, completion_tokens: 2 } }))
})
const snapshot = () => observer.call('harness/session/snapshot', { sessionId })
const prompt = (text) => client.call('session/prompt', { sessionId, prompt: [{ type: 'text', text }] })
async function until(fn, label) {
  const deadline = Date.now() + 15_000
  while (Date.now() < deadline) {
    const result = await fn()
    if (result) return result
    await sleep(100)
  }
  throw new Error(`Timed out: ${label}`)
}
try {
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve))
  url = `http://127.0.0.1:${server.address().port}`
  await Promise.all([client.start(), observer.start()])
  ;({ sessionId } = await client.call('session/new', { name: `cancel-test-${randomUUID().slice(0, 8)}` }))
  await client.call('harness/session/configure', { sessionId, config: {
    url: `${url}/completions`, model: 'cancellation-fixture', key: '', headers: [],
    system: 'Test fixture', 'max-context': 100_000, tools: ['web'],
  } })
  const pending = prompt('Start both tools')
  pending.catch(() => {})
  await until(async () => {
    const state = await snapshot()
    return held.length && state.phase === 'tools' && state.entries.some((e) => e.body?.includes('ALREADY_DONE'))
  }, 'one finished and one in-flight tool')
  const start = Date.now()
  await observer.call('session/cancel', { sessionId })
  assert.equal((await pending).stopReason, 'cancelled')
  const cancelMs = Date.now() - start
  const stopped = await snapshot()
  assert.equal(stopped.phase, 'idle')
  const cancelled = stopped.entries.filter((e) => e.cancelled)
  assert.equal(cancelled.length, 1)
  assert.equal(cancelled[0].callId, 'cancel-test-slow')
  assert.match(cancelled[0].body, /Execution may already have occurred/)
  assert.ok(client.updates.some((frame) => frame.params?.update?.toolCallId === 'cancel-test-slow'
    && frame.params.update.status === 'failed'), 'ACP receives a terminal tool update')
  const resumed = await prompt('A different question; do not repeat the tools')
  assert.equal(resumed.stopReason, 'end_turn')
  assert.equal(requests.length, 2, 'exactly one new inference request')
  assert.deepEqual(toolRequests.sort(), ['/fast', '/slow'], 'neither tool was dispatched again')
  const messages = requests[1].messages
  const at = messages.findIndex((m) => m.tool_calls?.length)
  assert.deepEqual(messages.slice(at + 1, at + 4).map((m) => m.role), ['tool', 'tool', 'user'], 'provider exchange is closed before new input')
  assert.match(messages[at + 1].content, /ALREADY_DONE/)
  assert.match(messages[at + 2].content, /^cancelled:/)
  const finished = await snapshot()
  assert.equal(finished.phase, 'idle')
  assert.equal(finished.entries.at(-1).body, 'CONTINUED_OK')
  for (const res of held) res.end('LATE_RESULT_MUST_NOT_APPEAR')
  await sleep(500)
  assert.deepEqual(await snapshot(), finished, 'late result cannot revive the cancelled exchange')
  const native = await fetch(`${base}/~/scry/harness/snapshot/${sessionId}.json`, { headers: { cookie } }).then((r) => r.json())
  assert.deepEqual(native.entries, finished.entries)
  console.log(JSON.stringify({ ok: true, cancelMs, checks: ['in-flight HTTP cancellation', 'completed sibling retained',
    'terminal ACP tool update', 'immediate next prompt', 'no duplicate execution', 'valid provider transcript',
    'late result fenced', 'native/ACP parity'] }, null, 2))
} finally {
  if (sessionId) await client.call('session/delete', { sessionId })
  await Promise.allSettled([client.close(), observer.close()])
  server.closeAllConnections()
  await new Promise((resolve) => server.close(resolve))
}
