// Deterministic ACP subprocess for provider tests. No model, shell, or repo edits.
import { createInterface } from 'node:readline'
import { appendFileSync } from 'node:fs'

const trace = process.argv[2]
const options = new Set(process.argv.slice(3))
const send = frame => process.stdout.write(`${JSON.stringify({ jsonrpc: '2.0', ...frame })}\n`)
const result = (id, value) => send({ id, result: value })
const update = (sessionUpdate, content, sessionId = 'fixture-session') => send({ method: 'session/update', params: { sessionId, update: { sessionUpdate, content } } })
let pending, permission
const finish = (id, text, stopReason = 'end_turn') => {
  if (text) update('agent_message_chunk', { type: 'text', text })
  result(id, { stopReason })
}
for await (const line of createInterface({ input: process.stdin })) {
  const frame = JSON.parse(line)
  appendFileSync(trace, `${JSON.stringify(frame)}\n`)
  const { id, method, params } = frame
  if (method === 'initialize') {
    result(id, { protocolVersion: options.has('bad-version') ? 2 : 1, agentCapabilities: { loadSession: !options.has('no-load') } })
  } else if (method === 'session/new') {
    result(id, { sessionId: 'fixture-session' })
  } else if (method === 'session/load') {
    update('agent_message_chunk', { type: 'text', text: 'REPLAY MUST NOT LEAK' })
    result(id, {})
  } else if (method === 'session/prompt') {
    const text = params.prompt.at(-1).text
    if (text === 'hang') pending = id
    else if (text === 'crash') process.exit(12)
    else if (text === 'bad-json') process.stdout.write('not json\n')
    else if (text === 'oversized-frame') process.stdout.write('x'.repeat(1024 * 1024 + 1))
    else if (text === 'oversized-reply') finish(id, 'x'.repeat(128 * 1024 + 1))
    else if (text === 'fail') send({ id, error: { code: -32000, message: 'secret-upstream-credential' } })
    else if (text === 'no-text') finish(id, '')
    else if (text === 'cutoff') finish(id, 'partial', 'max_turn_requests')
    else if (text.startsWith('permission:')) {
      permission = id
      send({ id: 'permission-1', method: 'session/request_permission', params: {
        sessionId: text.includes('wrong-session') ? 'another-session' : 'fixture-session',
        toolCall: { toolCallId: 'tool-1', kind: text.split(':')[1], title: 'Fixture action' },
        options: [{ optionId: 'once', kind: 'allow_once', name: 'Allow once' }, { optionId: 'always', kind: 'allow_always', name: 'Always' }],
      } })
    } else if (text === 'unsupported-client-method') {
      permission = id
      send({ id: 'unsupported-1', method: 'fs/write_text_file', params: { path: '/not-written', content: 'no' } })
    } else {
      update('agent_message_chunk', { type: 'text', text: 'WRONG SESSION' }, 'another-session')
      update('agent_thought_chunk', { type: 'text', text: 'PRIVATE THOUGHT' })
      finish(id, `Reply: ${text} 🤖`)
    }
  } else if (method === 'session/cancel') {
    if (pending != null && !options.has('ignore-cancel')) { finish(pending, '', 'cancelled'); pending = null }
  } else if (id === 'permission-1' || id === 'unsupported-1') {
    finish(permission, JSON.stringify(frame.result || frame.error))
  }
}
