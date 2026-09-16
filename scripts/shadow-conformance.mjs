// Fault injection only into this run's verifier grub, never the head/session.
// SHIP_COOKIE=... SHIP_DOJO_PANE=0:1.1 node scripts/shadow-conformance.mjs
// The supplied tmux pane must be idle at a Dojo prompt.
import assert from 'node:assert/strict'
import { randomUUID } from 'node:crypto'
import { execFile } from 'node:child_process'
import { promisify } from 'node:util'
import { setTimeout as sleep } from 'node:timers/promises'
import { Client } from './lib/ship-client.mjs'

const pane = process.env.SHIP_DOJO_PANE
if (!pane) throw new Error('Set SHIP_DOJO_PANE to an idle Dojo tmux pane for fault injection')
const run = promisify(execFile)
const client = new Client()
const name = `shadow-test-${randomUUID().slice(0, 8)}`
let sessionId, completed = false

async function dojo(command) {
  await run('tmux', ['send-keys', '-t', pane, '--', command])
  await sleep(300)
  await run('tmux', ['send-keys', '-t', pane, 'Enter'])
}
async function until(fn, label) {
  const deadline = Date.now() + 60_000
  while (Date.now() < deadline) {
    const result = await fn()
    if (result) return result
    await sleep(150)
  }
  throw new Error(`Timed out: ${label}`)
}
const verify = () => client.call('harness/session/verify', { sessionId })
const matched = async () => {
  const result = await verify()
  return result.check?.matched && result.check.revision === result.authoritativeRevision && result.check.actual === result.authoritativeDigest && result
}
try {
  await client.start()
  ;({ sessionId } = await client.call('session/new', { name }))
  assert.equal(sessionId, name)
  const before = await until(matched, 'initial replay')
  const snapshot = await client.call('harness/session/snapshot', { sessionId })
  await dojo(`:harness-grub &grub-cmd ['shadow-test' %make-file /agents/main/shadow-inputs %${name} %noun 42 %.y]`)
  const crashed = await until(async () => {
    const result = await verify()
    return result.check?.crashed && result
  }, 'durable crash evidence')
  await sleep(500)
  assert.deepEqual(await verify(), crashed, 'no automatic retry loop')
  assert.deepEqual(await client.call('harness/session/snapshot', { sessionId }), snapshot, 'head unaffected by verifier fault')
  await dojo(':harness-grub &noun %reload')
  // Wait for the command to be processed, not merely for an already-true check.
  await sleep(1500)
  assert.deepEqual(await verify(), crashed, 'crash checkpoint survives runtime reload')
  await client.call('harness/session/recheck', { sessionId })
  const after = await until(matched, 'explicit recheck from authoritative state')
  assert.equal(after.check.input, before.check.input)
  assert.deepEqual(await client.call('harness/session/snapshot', { sessionId }), snapshot, 'recheck creates no semantic event or inference')
  await dojo(`:harness-grub &grub-cmd ['shadow-test' %make-file /agents/main/checks %${name} %noun 42 %.y]`)
  await until(async () => (await verify()).check === null, 'malformed diagnostic is safely unavailable')
  await client.call('harness/session/recheck', { sessionId })
  await until(matched, 'diagnostic repaired')
  completed = true
  console.log(JSON.stringify({ ok: true, sessionId, checks: ['live replay', 'isolated fault', 'durable crash evidence', 'no retry loop', 'runtime reload', 'explicit ACP recovery', 'malformed diagnostic isolation', 'head unchanged'] }, null, 2))
} finally {
  if (completed) await client.call('session/delete', { sessionId })
  else if (sessionId) console.error(`Retained ${sessionId} for inspection; only its verifier was modified.`)
  await client.close()
}
