// Live native + ACP hand checks. Never posts into a real external channel.
// Only uniquely named sessions/bindings created by this run are removed.
import assert from 'node:assert/strict'
import { randomUUID } from 'node:crypto'
import { setTimeout as sleep } from 'node:timers/promises'
import { Client, base, cookie } from './lib/ship-client.mjs'
import { HandClient, DeliveryNotSent } from '../acp/hand-client.mjs'

const suffix = randomUUID().slice(0, 8)
const first = new Client(), second = new Client()
const chat = new HandClient(first, { hand: `chat-${suffix}`, worker: 'chat-worker' })
const mail = new HandClient(second, { hand: `mail-${suffix}`, worker: 'mail-worker' })
const competitor = new HandClient(second, { hand: chat.hand, worker: 'other-worker' })
const sessions = [], bindings = []
const snapshot = (sid) => first.call('harness/session/snapshot', { sessionId: sid })

async function until(fn, label) {
  const deadline = Date.now() + 90_000
  while (Date.now() < deadline) {
    const result = await fn()
    if (result) return result
    await sleep(150)
  }
  throw new Error(`Timed out: ${label}`)
}

try {
  await Promise.all([first.start(), second.start()])
  for (const hand of [chat, mail]) {
    const name = `hand-test-${suffix}-${sessions.length}`
    const { sessionId } = await first.call('session/new', { name })
    sessions.push(sessionId)
    const config = await first.call('harness/session/config', { sessionId })
    await first.call('harness/session/configure', { sessionId, config: {
      ...config, key: '', tools: hand === chat ? ['ship-time'] : [],
    } })
    await hand.bind(name, { address: `opaque:${hand.hand}/thread-7`, sessionId, actors: ['alice'] })
    bindings.push([hand, name])
  }
  const [one, two] = sessions
  await assert.rejects(chat.observe(one, { event: 'forbidden', actor: 'mallory', text: 'Do something' }), /Actor/)
  const observation = { event: 'message-1', actor: 'alice', text: 'Remember the word cedar. Use get_ship_time, then reply briefly including the word cedar and the time.' }
  const start = Date.now()
  const admitted = await chat.observe(one, observation)
  const admissionMs = Date.now() - start
  assert.ok(admissionMs < 5000, `admission took ${admissionMs}ms`)
  assert.equal((await chat.observe(one, observation)).inputId, admitted.inputId)
  await assert.rejects(chat.observe(one, { ...observation, text: 'different' }), /different content/)
  await Promise.all([
    chat.observe(one, { event: 'message-2', actor: 'alice', text: 'What word did I ask you to remember? Reply with just that word.' }),
    mail.observe(two, { event: 'mail-1', actor: 'alice', text: 'Reply with exactly MAIL_OK.' }),
  ])
  await first.pokeAgent('harness', 'harness-hand', {
    id: `native-${suffix}`, action: { observe: { binding: one, event: 'native-1', actor: 'alice', text: 'Reply with exactly NATIVE_OK.' } },
  })
  const chatOutput = await until(async () => {
    const outputs = await chat.outbox()
    return outputs.length === 3 && outputs
  }, 'three serialized chat replies, including native admission')
  const mailOutput = await until(async () => {
    const outputs = await mail.outbox()
    return outputs.length === 1 && outputs
  }, 'independent mail reply')
  assert.ok(chatOutput.every((effect) => effect.hand === chat.hand && effect.address === `opaque:${chat.hand}/thread-7` && effect.kind === 'reply'))
  assert.ok(mailOutput.every((effect) => effect.hand === mail.hand && effect.text.includes('MAIL_OK')))
  assert.ok(chatOutput.some((effect) => effect.text.includes('NATIVE_OK')))
  const history = await snapshot(one)
  assert.equal(history.entries.filter((entry) => entry.role === 'user').length, 3, 'no duplicate admission')
  assert.ok(history.entries.some((entry) => entry.role === 'tool'), 'the head performed a tool call')
  const ordered = history.entries.filter((entry) => ['user', 'assistant'].includes(entry.role) && !entry.calls?.length)
  assert.deepEqual(ordered.map((entry) => entry.role), ['user', 'assistant', 'user', 'assistant', 'user', 'assistant'])
  assert.match(ordered[3].body, /cedar/i, 'queued turn sees earlier completed context')
  const native = await fetch(`${base}/~/scry/harness/hands/${one}.json`, { headers: { cookie } }).then((response) => response.json())
  assert.deepEqual(native, await chat.status(one), 'native and ACP hand projections agree')

  // A failed delivery is retried independently; not one head event is added.
  const effect = chatOutput[0].effectId
  await assert.rejects(chat.deliver(effect, async () => { throw new DeliveryNotSent('not sent') }))
  await chat.retry(effect)
  const claimed = await chat.claim(effect)
  assert.equal(claimed.acquired, true)
  assert.equal((await chat.claim(effect)).acquired, false)
  await assert.rejects(competitor.claim(effect), /not available/)
  await chat.receipt(effect, 'uncertain')
  await assert.rejects(chat.retry(effect), /uncertain/)
  await chat.receipt(effect, 'delivered', 'reconciled-message')
  const terminal = await chat.effect(effect)
  assert.equal(terminal.receipts.length, 6)
  assert.deepEqual(await chat.receipt(effect, 'delivered', 'reconciled-message'), terminal)
  assert.equal((await snapshot(one)).revision, history.revision)
  const published = []
  for (const output of chatOutput.slice(1)) await chat.deliver(output.effectId, async (intent) => { published.push(intent.text); return `chat-${published.length}` })
  for (const output of mailOutput) await mail.deliver(output.effectId, async (intent) => { published.push(intent.text); return `mail-${published.length}` })
  assert.equal(published.length, 3)
  assert.deepEqual(await chat.outbox(), [])
  assert.deepEqual(await mail.outbox(), [])

  // A new ACP client can recover the same durable effect receipt.
  const resumed = new HandClient(second, { hand: chat.hand, worker: chat.worker })
  assert.deepEqual(await resumed.effect(effect), terminal)
  await chat.enable(one, false)
  await assert.rejects(chat.observe(one, { event: 'disabled', actor: 'alice', text: 'No' }), /disabled/)
  await chat.enable(one, true)
  await assert.rejects(first.call('session/delete', { sessionId: one }), /bindings/)
  await assert.rejects(first.call('harness/session/rename', { sessionId: one, name: `${one}-renamed` }), /bindings/)

  // Cancellation is session-wide, including work waiting in the hand queue.
  const running = await chat.observe(one, { event: 'cancel-active', actor: 'alice',
    text: 'Use get_ship_time, then write a long, detailed essay about that time.' })
  const queued = await chat.observe(one, { event: 'cancel-queued', actor: 'alice', text: 'This must not execute.' })
  const blocked = await fetch(`${base}/harness-api/webhook/${one}`, {
    method: 'POST', headers: { cookie, 'content-type': 'application/json' },
    body: JSON.stringify({ text: 'This must not splice into a hand turn.' }),
    signal: AbortSignal.timeout(15_000),
  })
  assert.equal(blocked.status, 409, 'webhook cannot change an active hand turn')
  await first.call('session/cancel', { sessionId: one })
  const cancelled = await chat.status(one)
  for (const input of [running, queued]) {
    assert.equal(cancelled.observations.find((obs) => obs.inputId === input.inputId).phase, 'cancelled')
  }
  const cancellationOutput = await chat.outbox()
  assert.equal(cancellationOutput.length, 1, 'queued cancellation does not fabricate a publication')
  assert.equal(cancellationOutput[0].kind, 'cancelled')
  await chat.deliver(cancellationOutput[0].effectId, async () => 'cancellation-notice')
  console.log(JSON.stringify({ ok: true, admissionMs, elapsedMs: Date.now() - start,
    checks: ['actor grants', 'deduplicated admission', 'native/ACP parity', 'queued turn continuity', 'independent hands', 'exclusive claims', 'uncertain delivery', 'receipt recovery', 'delivery retry without inference', 'bound-session lifecycle', 'active and queued cancellation', 'webhook isolation'] }, null, 2))
} finally {
  // Cleanup errors are reported, not hidden: unresolved deliveries must not be
  // silently discarded just to make a failing test look tidy.
  for (const [hand, binding] of bindings) {
    try { await hand.remove(binding) } catch (error) { console.error(`Retained test binding ${binding}: ${error.message}`) }
  }
  for (const sessionId of sessions) {
    try { await first.call('session/delete', { sessionId }) } catch (error) { console.error(`Retained test session ${sessionId}: ${error.message}`) }
  }
  await Promise.allSettled([first.close(), second.close()])
}
