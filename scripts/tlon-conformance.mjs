// Real two-ship integration test; never injects synthetic Activity facts or
// changes Groups code. The peer must own an existing test group/channel.
// Requires SHIP_COOKIE, PEER_COOKIE, PEER_URL, TEST_NEST, and a configured model.
// Temporarily changes Tlon policy, restoring it even if an assertion fails.
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { randomUUID } from 'node:crypto'
import { setTimeout as sleep } from 'node:timers/promises'
import { Client, cookie as harnessCookie, base as harnessUrl } from './lib/ship-client.mjs'

const peerUrl = process.env.PEER_URL
const nest = process.env.TEST_NEST
assert.ok(peerUrl && nest && process.env.PEER_COOKIE, 'Set PEER_URL, PEER_COOKIE and TEST_NEST')
const row = (await readFile(process.env.PEER_COOKIE, 'utf8')).split('\n').find((line) => /\turbauth-~/.test(line)).split('\t')
const peer = row[5].slice('urbauth-'.length)
const ship = harnessCookie.split('=')[0].slice('urbauth-'.length)
const peerCookie = `${row[5]}=${row[6]}`
const channel = `tlon-test-${randomUUID()}`
let event = 0
const client = new Client()
async function poke(app, mark, json) {
  const response = await fetch(`${peerUrl}/~/channel/${channel}`, {
    method: 'PUT', headers: { cookie: peerCookie, 'content-type': 'application/json' },
    body: JSON.stringify([{ id: ++event, action: 'poke', ship: peer.slice(1), app, mark, json }]),
    signal: AbortSignal.timeout(15_000),
  })
  assert.ok(response.ok, `${app}: HTTP ${response.status}`)
}
async function scry(path, local = false) {
  const response = await fetch(`${local ? harnessUrl : peerUrl}/~/scry/${path}.json`, {
    headers: { cookie: local ? harnessCookie : peerCookie }, signal: AbortSignal.timeout(15_000),
  })
  assert.ok(response.ok, `scry ${path}: HTTP ${response.status}`)
  return response.json()
}
async function until(label, check) {
  const start = Date.now()
  while (Date.now() - start < 90_000) {
    const value = await check()
    if (value) { console.log(`PASS ${label} (${Date.now() - start}ms)`); return value }
    await sleep(500)
  }
  throw new Error(`Timed out: ${label}`)
}
const marker = `grove-${Date.now()}`
const essay = (content) => ({ content, author: peer, sent: Date.now(), kind: '/chat', meta: null, blob: null })
const prompt = (word, mention = false) => [{ inline: [...(mention ? [{ ship }] : []), ` Reply with exactly ${marker}-${word}. Do not use tools.`] }]
const has = (value, word) => JSON.stringify(value).includes(`${marker}-${word}`)
const fromBot = (post, word) => post?.essay?.author === ship && has(post.essay.content, word)
const channelPosts = () => scry(`channels/v5/${nest}/posts/newest/32/post`)
const dmPosts = () => scry(`chat/v4/dm/${ship}/writs/newest/32/light`)
const post = (content) => poke('channels', 'channel-action-1', { channel: { nest, action: { post: { add: essay(content) } } } })
const da = () => (((BigInt(Date.now()) * (1n << 64n)) / 1000n) + 170141184475152167957503069145530368000n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.')
await client.start()
console.log(`Connected: ${peer} → ${ship}, ${nest}`)
const original = (await client.call('harness/tlon')).policy
try {
  await client.call('harness/tlon/configure', { enabled: true, owner: peer, mentions: true, trusted: [] })
  await client.call('harness/tlon/watch')
  console.log('Testing DM admission and remote delivery')
  await poke('chat', 'chat-dm-action-2', { ship, diff: { id: `${peer}/${da()}`, delta: { add: { essay: essay(prompt('dm')), time: null } } } })
  const dmAnswer = await until('DM model answer delivered to peer', async () => Object.values((await dmPosts()).writs).find((p) => fromBot(p, 'dm')))
  await poke('chat', 'chat-dm-action-2', { ship, diff: { id: dmAnswer.seal.id, delta: { reply: {
    id: `${peer}/${da()}`, meta: null, delta: { add: { 'reply-essay': {
      content: prompt('dm-thread'), author: peer, sent: Date.now(), blob: null,
    }, time: null } },
  } } } })
  await until('DM thread answer uses its author-qualified parent', async () => {
    const page = await scry(`chat/v4/dm/${ship}/writs/newest/32/heavy`)
    return Object.values(page.writs).some((p) => Object.values(p.seal?.replies || {}).some((r) => r['reply-essay']?.author === ship && has(r, 'dm-thread')))
  })
  await post(prompt('channel', true))
  const answer = await until('mentioned channel answer delivered to peer', async () => Object.entries((await channelPosts()).posts).find(([, p]) => fromBot(p, 'channel')))
  await poke('channels', 'channel-action-1', { channel: { nest, action: { post: { reply: { id: answer[0], action: { add: {
    content: prompt('thread'), author: peer, sent: Date.now(),
  } } } } } } })
  await until('reply to bot is admitted without another mention', async () => {
    const posts = (await channelPosts()).posts
    return Object.values(posts[answer[0]]?.seal?.replies || {}).some((p) => p?.['reply-essay']?.author === ship && has(p, 'thread'))
  })
  const status = await client.call('harness/tlon')
  assert.equal(status.error, '')
  assert.equal((await client.call('harness/tlon/configure', status.policy)).lanes, status.lanes, 'saving unchanged policy preserves routes')
  await assert.rejects(client.call('harness/tlon/configure', { ...status.policy, owner: null }), /Invalid owner/)
  assert.deepEqual((await client.call('harness/tlon')).policy, status.policy, 'invalid policy leaves authority unchanged')
  assert.ok(client.updates.some((frame) => frame.method === 'harness/tlon/activity'), 'ACP activity notification')
  const list = (await client.call('session/list')).sessions
  assert.ok(list.some((s) => s.sessionId.startsWith(`${peer.slice(1)}-dm-`)), 'DM visible to any ACP session client')
  assert.ok(list.some((s) => s.sessionId.includes('-thread-')), 'thread has a separate session')
  console.log('PASS ACP activity and global session discovery')
  await client.call('harness/tlon/configure', { enabled: true, owner: ship, mentions: true, trusted: [{ ship: peer, tools: [] }] })
  assert.equal((await client.call('harness/tlon')).lanes, 0, 'revoked routes do not consume the next policy epoch')
  await poke('chat', 'chat-dm-action-2', { ship, diff: { id: `${peer}/${da()}`, delta: { add: { essay: essay(prompt('trusted')), time: null } } } })
  await until('trusted ship with no tools can still chat', async () => Object.values((await dmPosts()).writs).find((p) => fromBot(p, 'trusted')))
  const sessions = (await client.call('session/list')).sessions.filter((s) => s.sessionId.startsWith(`${peer.slice(1)}-dm-`))
  assert.ok(list.every((s) => sessions.some((current) => current.sessionId === s.sessionId) || !s.sessionId.startsWith(`${peer.slice(1)}-dm-`)), 'route retirement preserves conversation history')
  for (const { sessionId } of sessions) {
    const config = await client.call('harness/session/config', { sessionId })
    assert.deepEqual(config.tools, [], 'policy changes clear old grants as well as creating restricted sessions')
  }
  await client.call('harness/tlon/configure', { enabled: true, owner: ship, mentions: true, trusted: [] })
  const count = (await client.call('harness/tlon')).events.filter((e) => e.kind === 'message').length
  await poke('chat', 'chat-dm-action-2', { ship, diff: { id: `${peer}/${da()}`, delta: { add: { essay: essay(prompt('revoked')), time: null } } } })
  await until('revoked message reached the bot’s Chat agent', async () => has(await scry(`chat/v4/dm/${peer}/writs/newest/4/light`, true), 'revoked'))
  await sleep(3000)
  assert.equal((await client.call('harness/tlon')).events.filter((e) => e.kind === 'message').length, count)
  console.log('PASS revocation denies admission and clears executable grants')
} finally {
  await client.call('harness/tlon/configure', original)
  await client.close()
  // Close the HTTP channel as well; no subscriptions or authenticated queues leak.
  await fetch(`${peerUrl}/~/channel/${channel}`, { method: 'PUT', headers: { cookie: peerCookie, 'content-type': 'application/json' }, body: JSON.stringify([{ id: ++event, action: 'delete' }]) })
}
