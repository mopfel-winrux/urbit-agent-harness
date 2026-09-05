// Exercise shared tool execution through ACP with a deterministic provider.
// Does not change the MCP registry, credentials, defaults, or hand permissions.
import assert from 'node:assert/strict'
import { createServer } from 'node:http'
import { randomUUID } from 'node:crypto'
import { Client } from './lib/ship-client.mjs'

const client = new Client(), sessions = [], observed = []
let tool = 'list_mcp_servers', expectedGrant = true
const server = createServer(async (req, res) => {
  let raw = ''
  for await (const part of req) raw += part
  const body = JSON.parse(raw)
  observed.push(body)
  const reply = body.messages.find((message) => message.role === 'tool')
  const names = (body.tools || []).map((entry) => entry.function.name)
  assert.equal(names.includes(tool), expectedGrant)
  const message = reply ? { role: 'assistant', content: 'TOOLS_OK' }
    : { role: 'assistant', content: '', tool_calls: [{ id: 'fixture-call', type: 'function',
      function: { name: tool, arguments: tool === 'web_search' ? '{"query":"Urbit"}' : '{}' } }] }
  res.writeHead(200, { 'content-type': 'application/json' })
  res.end(JSON.stringify({ choices: [{ finish_reason: reply ? 'stop' : 'tool_calls', message }],
    usage: { prompt_tokens: 30, completion_tokens: 10 } }))
})
try {
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve))
  await client.start()
  const brave = await client.call('harness/status', { provider: 'brave' })
  const configured = await client.call('harness/mcp/servers')
  for (const which of ['list_mcp_servers', 'web_search']) for (const granted of [true, false]) {
    // Search with a real credential is opt-in; the default test checks that a
    // missing key gives actionable feedback without making a network request.
    if (which === 'web_search' && brave['has-key'] && granted) continue
    tool = which; expectedGrant = granted
    const { sessionId } = await client.call('session/new', { name: `tools-${randomUUID().slice(0, 8)}` })
    sessions.push(sessionId)
    await client.call('harness/session/configure', { sessionId, config: {
      url: `http://127.0.0.1:${server.address().port}/completions`, model: 'fixture',
      key: '', headers: [], system: 'Use the available tools.', 'max-context': 80000,
      tools: granted ? [which === 'web_search' ? 'web' : 'mcp'] : [],
    } })
    await client.call('session/prompt', { sessionId, prompt: [{ type: 'text', text: 'Run the tool.' }] })
    const result = observed.at(-1).messages.find((message) => message.role === 'tool').content
    if (!granted) assert.match(result, /not granted for this session/)
    else if (which === 'web_search') assert.match(result, /Add a Brave Search API key/)
    else {
      const servers = JSON.parse(result)
      assert.deepEqual(servers.map((s) => s.id).sort(), configured.filter((s) => s.enabled).map((s) => s.id).sort())
      assert.ok(servers.every((s) => Object.keys(s).sort().join(',') === 'id,name'))
    }
  }
  console.log(JSON.stringify({ ok: true, mcpDiscovery: true, permissionEnforcement: true, searchMissingKey: !brave['has-key'] }))
} finally {
  for (const sessionId of sessions) await client.call('session/delete', { sessionId }).catch(() => {})
  await client.close()
  await new Promise((resolve) => server.close(resolve))
}
