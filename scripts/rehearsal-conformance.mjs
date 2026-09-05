// Real ACP/head/Iris with a deterministic local provider. Creates only uniquely
// named test sessions/proposals; does not change credentials, defaults or MCP.
import assert from 'node:assert/strict'
import { createServer } from 'node:http'
import { randomUUID } from 'node:crypto'
import { Client, base, cookie } from './lib/ship-client.mjs'

const client = new Client(), sessions = [], proposals = [], failures = []
const broad = ['clay', 'skills', 'web', { mcp: 'not-granted' }, 'author', 'skill-write', 'subagents', 'peers', 'code']
let sessionId, skill, url, config, editChild = false, childTurns = 0, effects = 0
const call = (id, name, args) => ({ id, type: 'function', function: { name, arguments: JSON.stringify(args) } })
const read = async (path) => {
  const response = await fetch(`${base}/~/scry/harness/${path}.json`, { headers: { cookie }, signal: AbortSignal.timeout(15_000) })
  assert.ok(response.ok, `scry ${path}: ${response.status}`)
  return response.json()
}
const server = createServer(async (req, res) => {
  try {
    if (req.url !== '/completions') { effects++; res.end('UNEXPECTED_EFFECT'); return }
    let raw = ''
    for await (const part of req) raw += part
    const body = JSON.parse(raw)
    const child = body.messages.some((m) => m.role === 'system' && m.content.includes('read-only rehearsal'))
    const receipts = body.messages.filter((m) => m.role === 'tool')
    let calls = [], content = 'PARENT_OK'
    if (child) {
      childTurns++
      assert.deepEqual(body.tools.map((t) => t.function.name).sort(), ['list_desk_files', 'read_desk_file', 'read_skill'])
      if (!receipts.length) {
        // Even an explicit config edit cannot turn the special-purpose child
        // into an effectful executor while its provider request is outstanding.
        if (editChild) await client.call('harness/session/configure', {
          sessionId: `rehearse--${sessionId}--try-skill`,
          config: { ...config, system: 'This is a read-only rehearsal fixture.', tools: broad },
        })
        calls = [
          call('try-web', 'http_fetch', { url: `${url}/must-not-post`, method: 'POST', body: '{}' }),
          call('try-mcp', 'call_mcp_tool', { server: 'not-granted', name: 'mutate', arguments: '{}' }),
          call('try-write', 'write_skill', { name: `${skill}-mutation`, description: 'must not exist', body: 'must not exist' }),
          call('read-staged', 'read_skill', { name: skill }),
        ]
      } else {
        assert.equal(receipts.length, 4)
        for (const receipt of receipts.slice(0, 3)) assert.match(receipt.content, /not granted for this session/)
        assert.equal(receipts[3].content, 'READ_ONLY_FIXTURE')
        content = 'REHEARSAL_OK'
      }
    } else if (!receipts.length) {
      calls = [
        call('stage-skill', 'propose_skill', { name: skill, description: 'temporary test proposal', body: 'READ_ONLY_FIXTURE' }),
        call('try-skill', 'rehearse_skill', { name: skill, input: 'Try the fixture.' }),
      ]
    } else {
      assert.equal(receipts.find((r) => r.tool_call_id === 'try-skill')?.content, 'REHEARSAL_OK')
    }
    res.writeHead(200, { 'content-type': 'application/json' })
    res.end(JSON.stringify({ choices: [{ finish_reason: calls.length ? 'tool_calls' : 'stop', message: {
      role: 'assistant', content: calls.length ? '' : content, ...(calls.length ? { tool_calls: calls } : {}),
    } }], usage: { prompt_tokens: 30, completion_tokens: 10 } }))
  } catch (error) {
    failures.push(error)
    res.writeHead(500, { 'content-type': 'application/json' })
    res.end(JSON.stringify({ error: 'Fixture assertion failed' }))
  }
})
try {
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve))
  url = `http://127.0.0.1:${server.address().port}`
  await client.start()
  const defaults = await client.call('harness/defaults')
  for (const widen of [false, true]) {
    editChild = widen; childTurns = 0
    skill = `rehearsal-${randomUUID()}`; proposals.push(skill)
    ;({ sessionId } = await client.call('session/new', { name: `rehearsal-${randomUUID().slice(0, 8)}` }))
    sessions.push(sessionId, `rehearse--${sessionId}--try-skill`)
    config = { url: `${url}/completions`, model: 'fixture', key: '', headers: [],
      system: 'Parent test fixture', 'max-context': 80000, tools: broad }
    await client.call('harness/session/configure', { sessionId, config })
    await client.call('session/prompt', { sessionId, prompt: [{ type: 'text', text: 'Stage and rehearse the fixture.' }] })
    assert.equal(childTurns, 2)
    assert.equal(effects, 0, 'no effectful HTTP request dispatched')
    const skills = await read('skills')
    assert.ok(!skills.some((s) => s.name === `${skill}-mutation` || s.name === skill), 'rehearsal cannot write or publish shared skills')
    const snapshot = await client.call('harness/session/snapshot', { sessionId })
    assert.equal(snapshot.entries.at(-1).body, 'PARENT_OK')
  }
  assert.deepEqual(await client.call('harness/defaults'), defaults, 'test preserves saved defaults')
  assert.deepEqual(failures, [])
  console.log(JSON.stringify({ ok: true, readOnlyRehearsal: true, editedConfigCeiling: true, externalEffects: effects }))
} finally {
  for (const name of proposals) {
    await client.pokeAgent('harness', 'harness-action', { 'discard-skill': { name } })
    await client.pokeAgent('harness', 'harness-action', { 'skill-del': { name: `${name}-mutation` } })
  }
  for (const id of sessions.reverse()) await client.call('session/delete', { sessionId: id }).catch(() => {})
  await client.close()
  server.closeAllConnections()
  await new Promise((resolve) => server.close(resolve))
  if (failures.length) throw new AggregateError(failures, 'Provider fixture assertions failed')
}
