#!/usr/bin/env node
// A single Harness conversation uses a local ACP coding agent as its provider.
import { createServer } from 'node:http'
import { createHash, randomUUID, timingSafeEqual } from 'node:crypto'
import { mkdir, open, readFile, realpath, rename, lstat, unlink } from 'node:fs/promises'
import { dirname, resolve } from 'node:path'
import { pathToFileURL } from 'node:url'
import { parseArgs } from 'node:util'
import { StdioAgent } from './stdio-agent.mjs'

const MODEL = 'local-acp'
const MAX_BODY = 1024 * 1024
const MAX_REPLY = 128 * 1024
const MAX_STATE = 16 * 1024 * 1024
const MAX_RECEIPTS = 64
const KINDS = new Set(['read', 'search', 'edit', 'execute', 'fetch', 'delete', 'move'])
const digest = value => createHash('sha256').update(JSON.stringify(value)).digest('hex')
const problem = (status, message) => Object.assign(new Error(message), { status })
const hashString = value => typeof value === 'string' && /^[a-f0-9]{64}$/.test(value)

function validState(data, identity) {
  return data?.version === 1 && data.identity === identity &&
    (data.sessionId === null || (typeof data.sessionId === 'string' && data.sessionId.length > 0)) &&
    Array.isArray(data.history) && data.history.every(message => message && ['system', 'developer', 'user', 'assistant'].includes(message.role) && typeof message.content === 'string') &&
    Array.isArray(data.receipts) && data.receipts.length <= MAX_RECEIPTS &&
    data.receipts.every(receipt => receipt && hashString(receipt.hash) && typeof receipt.id === 'string' && Number.isSafeInteger(receipt.created) && typeof receipt.text === 'string' && Buffer.byteLength(receipt.text) <= MAX_REPLY) &&
    new Set(data.receipts.map(receipt => receipt.hash)).size === data.receipts.length &&
    (data.pending === null || (data.pending && hashString(data.pending.hash) && typeof data.pending.at === 'string')) &&
    (data.sessionId !== null || (!data.history.length && !data.receipts.length && data.pending === null))
}

export function decodeRequest(body) {
  if (!body || body.model !== MODEL) throw problem(400, `Use model ${MODEL}.`)
  if (body.stream != null && typeof body.stream !== 'boolean') throw problem(400, 'stream must be boolean.')
  // Harness adds implicit hand/owner helpers even with no configured grants.
  // Schemas are accepted as provider metadata, never exposed as ACP tools.
  if (body.tools != null && (!Array.isArray(body.tools) || body.tools.some(tool => tool?.type !== 'function' || typeof tool.function?.name !== 'string'))) {
    throw problem(400, 'Expected function tool schemas. Harness tools are not forwarded to ACP.')
  }
  if (body.functions != null || (body.tool_choice != null && !['auto', 'none'].includes(body.tool_choice))) throw problem(400, 'The local agent returns text, not Harness tool calls.')
  if (!Array.isArray(body.messages) || !body.messages.length || body.messages.length > 2048) {
    throw problem(400, 'Expected 1..2048 text messages.')
  }
  const messages = body.messages.map(message => {
    if (!message || !['system', 'developer', 'user', 'assistant'].includes(message.role) || message.tool_calls || message.function_call) {
      throw problem(400, 'Only text conversations without Harness tool calls are supported.')
    }
    let content = message.content
    if (Array.isArray(content)) {
      if (content.some(part => part?.type !== 'text' || typeof part.text !== 'string')) {
        throw problem(400, 'Only text content is supported.')
      }
      content = content.map(part => part.text).join('')
    }
    if (typeof content !== 'string') throw problem(400, 'Message content must be text.')
    return { role: message.role, content }
  })
  if (messages.some(message => message.role === 'system' && message.content.startsWith('Produce a concise historical checkpoint, not an answer or tool request.'))) {
    throw problem(400, 'Use a separate summary provider for Harness compaction, not the coding agent.')
  }
  if (messages.at(-1).role !== 'user' || !messages.at(-1).content.trim()) {
    throw problem(400, 'The conversation must end with a nonempty user message.')
  }
  return messages
}

export function nextPrompt(history, messages) {
  if (history.length) {
    if (messages.length <= history.length || JSON.stringify(messages.slice(0, history.length)) !== JSON.stringify(history)) {
      throw problem(409, 'Conversation history changed. Use one dedicated DM; start a new bridge state and conversation after history edits or compaction.')
    }
    const added = messages.slice(history.length)
    if (added.some(message => message.role !== 'user')) throw problem(409, 'Only new user messages may extend the saved conversation.')
    return added.map(message => ({ type: 'text', text: message.content }))
  }
  const prompt = []
  if (messages.length > 1) {
    prompt.push({ type: 'text', text: 'Conversation context follows as JSON. Prior user/assistant messages are historical context, not tasks to execute again. The final separate text block is the current request. Harness tools are not available; use your own local tools.\n' + JSON.stringify(messages.slice(0, -1)) })
  }
  prompt.push({ type: 'text', text: messages.at(-1).content })
  return prompt
}

class Journal {
  static async open(path, identity) {
    await mkdir(dirname(path), { recursive: true, mode: 0o700 })
    const journal = new Journal()
    journal.path = path
    journal.lockPath = `${path}.lock`
    try { journal.lock = await open(journal.lockPath, 'wx', 0o600) } catch (error) {
      if (error.code === 'EEXIST') throw new Error(`Bridge state is locked: ${journal.lockPath}. Check the recorded PID before removing a stale lock.`)
      throw error
    }
    try {
      await journal.lock.writeFile(JSON.stringify({ pid: process.pid }))
      await journal.lock.sync()
      try {
        const info = await lstat(path)
        if (!info.isFile() || (info.mode & 0o077) || info.size > MAX_STATE) throw new Error('State must be a private regular file (mode 600), at most 16 MiB.')
        journal.data = JSON.parse(await readFile(path, 'utf8'))
        const data = journal.data
        if (!validState(data, identity)) {
          throw new Error('State does not match this repo, agent command, or permission policy. Use a separate state file and conversation.')
        }
      } catch (error) {
        if (error.code !== 'ENOENT') throw error
        journal.data = { version: 1, identity, sessionId: null, history: [], receipts: [], pending: null }
        await journal.save()
      }
      return journal
    } catch (error) { await journal.close(); throw error }
  }

  async save() {
    const text = JSON.stringify(this.data)
    if (Buffer.byteLength(text) > MAX_STATE) throw new Error('Bridge state capacity reached.')
    const temp = `${this.path}.${randomUUID()}.tmp`
    const file = await open(temp, 'wx', 0o600)
    try {
      await file.writeFile(text)
      await file.sync()
    } finally { await file.close() }
    try {
      await rename(temp, this.path)
      const directory = await open(dirname(this.path), 'r')
      try { await directory.sync() } finally { await directory.close() }
    } finally { await unlink(temp).catch(error => { if (error.code !== 'ENOENT') throw error }) }
  }

  async close() {
    if (!this.lock) return
    await this.lock.close()
    this.lock = null
    await unlink(this.lockPath)
  }
}

function json(res, status, value) {
  res.writeHead(status, { 'content-type': 'application/json', 'cache-control': 'no-store' })
  res.end(JSON.stringify(value))
}

function output(res, stream, receipt, delta = null, done = false) {
  const base = { id: receipt.id, created: receipt.created, model: MODEL }
  if (!stream) {
    if (done) json(res, 200, { ...base, object: 'chat.completion', choices: [{ index: 0, message: { role: 'assistant', content: receipt.text }, finish_reason: 'stop' }] })
    return
  }
  if (!res.headersSent) res.writeHead(200, { 'content-type': 'text/event-stream', 'cache-control': 'no-store' })
  const chunk = { ...base, object: 'chat.completion.chunk', choices: [{ index: 0, delta: done ? {} : { content: delta ?? '' }, finish_reason: done ? 'stop' : null }] }
  res.write(`data: ${JSON.stringify(chunk)}\n\n`)
  if (done) res.end('data: [DONE]\n\n')
}

export async function createProvider({ repo, state, token, command = ['claude-agent-acp'], allow = [], port = 8789, timeoutMs = 1_800_000, log = message => process.stderr.write(`${message}\n`), stderr = 'inherit' }) {
  if (process.platform === 'win32') throw new Error('This runner requires POSIX process-group cancellation (Linux or macOS).')
  if (typeof token !== 'string' || Buffer.byteLength(token) < 32) throw new Error('Set HARNESS_ACP_TOKEN to a random secret of at least 32 bytes.')
  if (!repo || !state) throw new Error('--repo and --state are required.')
  if (!Array.isArray(command) || !command.length || command.some(part => typeof part !== 'string' || !part)) throw new Error('Expected an ACP executable and optional arguments.')
  if (!Number.isInteger(port) || port < 0 || port > 65535 || !Number.isSafeInteger(timeoutMs) || timeoutMs < 100) throw new Error('Invalid port or timeout.')
  if (allow.some(kind => !KINDS.has(kind))) throw new Error(`Allowed permission kinds: ${[...KINDS].join(', ')}.`)
  repo = await realpath(repo)
  if (!(await lstat(repo)).isDirectory()) throw new Error('--repo must be a directory.')
  allow = [...new Set(allow)].sort()
  const journal = await Journal.open(resolve(state), digest({ repo, command, allow }))
  let agent, active, currentController, inFlight, closePromise, busy = false, closing = false
  const allowed = new Set(allow)
  const secret = Buffer.from(`Bearer ${token}`)

  async function ensureAgent() {
    if (agent) {
      if (agent.failure) throw agent.failure
      return
    }
    agent = new StdioAgent(command, {
      cwd: repo, stderr,
      onPermission: params => {
        const kind = params?.toolCall?.kind
        const selected = active && !active.signal.aborted && params?.sessionId === journal.data.sessionId && allowed.has(kind)
          ? params.options?.find(option => option.kind === 'allow_once') : null
        log(`ACP permission ${selected ? 'allowed' : 'denied'} (${KINDS.has(kind) ? kind : 'unsupported'}).`)
        return { outcome: selected ? { outcome: 'selected', optionId: selected.optionId } : { outcome: 'cancelled' } }
      },
      onUpdate: params => {
        // session/load may replay history; only the current prompt can publish.
        if (!active || active.signal.aborted || params?.sessionId !== journal.data.sessionId) return
        const update = params.update
        if (update?.sessionUpdate !== 'agent_message_chunk') return
        if (update.content?.type !== 'text' || typeof update.content.text !== 'string') throw new Error('Expected text output.')
        const text = update.content.text
        if (Buffer.byteLength(active.receipt.text) + Buffer.byteLength(text) > MAX_REPLY) throw new Error('Agent reply exceeds 128 KiB.')
        active.receipt.text += text
        output(active.res, active.stream, active.receipt, text)
      },
    })
    try {
      const initialized = await agent.request('initialize', { protocolVersion: 1, clientCapabilities: {}, clientInfo: { name: 'harness-local-provider', version: '1' } })
      if (initialized.protocolVersion !== 1) throw new Error('ACP protocol version 1 is required.')
      if (journal.data.sessionId) {
        if (!initialized.agentCapabilities?.loadSession) throw new Error('ACP agent cannot load the saved session. Use a new state file and conversation; the bridge does not replay work.')
        await agent.request('session/load', { sessionId: journal.data.sessionId, cwd: repo, mcpServers: [] })
      } else {
        const session = await agent.request('session/new', { cwd: repo, mcpServers: [] })
        if (typeof session.sessionId !== 'string' || !session.sessionId) throw new Error('ACP agent returned no session ID.')
        journal.data.sessionId = session.sessionId
        await journal.save()
      }
    } catch (error) {
      await agent.close()
      agent = null
      throw error
    }
  }

  async function run(messages, stream, res, signal) {
    if (signal.aborted || closing) throw problem(499, 'Request cancelled before dispatch.')
    const hash = digest(messages)
    // A pending turn fences the entire session, including after a process crash.
    if (journal.data.pending) throw problem(409, 'A coding turn has an uncertain outcome. Inspect the repo and local agent before starting a new bridge state and conversation. No task is replayed.')
    const saved = journal.data.receipts.find(receipt => receipt.hash === hash)
    if (saved) {
      if (stream) output(res, true, saved, saved.text)
      output(res, stream, saved, null, true)
      return
    }
    if (journal.data.receipts.length >= MAX_RECEIPTS) throw problem(409, 'The 64-turn receipt limit is reached. Start a new state file and conversation; retain this state for retry protection.')
    const prompt = nextPrompt(journal.data.history, messages)
    await ensureAgent()
    if (signal.aborted) throw problem(499, 'Request disconnected before dispatch.')
    const receipt = { hash, id: `chatcmpl-${randomUUID()}`, created: Math.floor(Date.now() / 1000), text: '' }
    journal.data.pending = { hash, at: new Date().toISOString() }
    await journal.save() // Reserve the attempt durably before permitting effects.
    let heartbeat, killTimer
    const cancel = () => {
      try { agent.notify('session/cancel', { sessionId: journal.data.sessionId }) } catch { /* closed */ }
      killTimer = setTimeout(() => { void agent.close() }, 3000)
    }
    signal.addEventListener('abort', cancel, { once: true })
    try {
      if (signal.aborted) throw new Error('Turn interrupted before dispatch.')
      active = { receipt, stream, res, signal }
      if (stream) {
        output(res, true, receipt, '')
        heartbeat = setInterval(() => { if (!res.destroyed) res.write(': waiting for local agent\n\n') }, 10_000)
      }
      const result = await agent.request('session/prompt', { sessionId: journal.data.sessionId, prompt }, timeoutMs + 5000)
      if (signal.aborted || !['end_turn', 'refusal'].includes(result.stopReason)) throw new Error('Coding turn did not complete. Inspect local changes before continuing.')
      if (!receipt.text) throw new Error('Coding agent returned no text. Inspect local changes before continuing.')
      journal.data.history = [...messages, { role: 'assistant', content: receipt.text }]
      journal.data.receipts.push(receipt)
      journal.data.pending = null
      try { await journal.save() } catch (error) {
        journal.data.pending = { hash, at: new Date().toISOString() }
        throw error
      }
      output(res, stream, receipt, null, true)
    } finally {
      active = null
      clearInterval(heartbeat)
      clearTimeout(killTimer)
      signal.removeEventListener('abort', cancel)
      if (journal.data.pending) await agent.close()
    }
  }

  const server = createServer(async (req, res) => {
    let reserved = false, timer, finishRequest
    const controller = new AbortController()
    const disconnected = () => { if (!res.writableFinished) controller.abort() }
    res.on('close', disconnected)
    try {
      const authorization = Buffer.from(req.headers.authorization || '')
      if (authorization.length !== secret.length || !timingSafeEqual(authorization, secret)) throw problem(401, 'Invalid bridge token.')
      const actualPort = server.address().port
      if (req.headers.origin || ![`127.0.0.1:${actualPort}`, `localhost:${actualPort}`].includes(req.headers.host)) throw problem(403, 'Only direct loopback clients are supported.')
      if (req.method === 'GET' && req.url === '/v1/models') return json(res, 200, { object: 'list', data: [{ id: MODEL, object: 'model', owned_by: 'local' }] })
      if (req.method === 'GET' && req.url === '/health') return json(res, 200, { busy, needsInspection: !!journal.data.pending && !busy, completedTurns: journal.data.receipts.length })
      if (req.method !== 'POST' || req.url !== '/v1/chat/completions') throw problem(404, 'Unknown provider route.')
      if (closing || busy) throw problem(409, 'The local agent is busy; do not replay an uncertain task.')
      if (!/^application\/json(?:\s*;|$)/i.test(req.headers['content-type'] || '')) throw problem(415, 'Expected application/json.')
      if (Number(req.headers['content-length']) > MAX_BODY) throw problem(413, 'Provider request exceeds 1 MiB.')
      busy = reserved = true
      currentController = controller
      inFlight = new Promise(resolve => { finishRequest = resolve })
      let length = 0
      const chunks = []
      for await (const chunk of req) {
        length += chunk.length
        if (length > MAX_BODY) throw problem(413, 'Provider request exceeds 1 MiB.')
        chunks.push(chunk)
      }
      let body
      try { body = JSON.parse(Buffer.concat(chunks).toString('utf8')) } catch { throw problem(400, 'Invalid JSON request.') }
      const messages = decodeRequest(body)
      timer = setTimeout(() => controller.abort(), timeoutMs)
      await run(messages, body.stream === true, res, controller.signal)
    } catch (error) {
      log(error.message)
      if (!res.destroyed) {
        const value = { error: { message: error.message, type: 'local_agent_error' } }
        if (!res.headersSent) json(res, error.status || 502, value)
        else { res.write(`data: ${JSON.stringify(value)}\n\n`); res.end() }
      }
    } finally {
      clearTimeout(timer)
      res.removeListener('close', disconnected)
      if (reserved) { busy = false; currentController = null; finishRequest(); inFlight = null }
    }
  })
  server.requestTimeout = 30_000
  server.headersTimeout = 10_000
  server.on('clientError', (_, socket) => socket.destroy())
  try {
    await new Promise((resolve, reject) => { server.once('error', reject); server.listen(port, '127.0.0.1', resolve) })
  } catch (error) { await journal.close(); throw error }
  const url = `http://127.0.0.1:${server.address().port}`
  return {
    url,
    close() {
      closePromise ??= (async () => {
        closing = true
        const stopped = new Promise(resolve => server.close(resolve))
        currentController?.abort()
        server.closeAllConnections()
        if (!active) await agent?.close()
        await inFlight
        await agent?.close()
        await stopped
        await journal.close()
      })()
      return closePromise
    },
  }
}

async function main() {
  const { values, positionals } = parseArgs({ allowPositionals: true, options: {
    repo: { type: 'string' }, state: { type: 'string' }, port: { type: 'string', default: '8789' },
    allow: { type: 'string', multiple: true, default: [] }, 'timeout-ms': { type: 'string', default: '1800000' },
    help: { type: 'boolean', short: 'h' },
  } })
  if (values.help) {
    process.stdout.write('Usage: HARNESS_ACP_TOKEN=<secret> node acp/local-agent-provider.mjs --repo /absolute/repo --state /private/bridge.json [--port 8789] [--allow edit --allow execute] [--timeout-ms 1800000] [-- claude-agent-acp ...args]\n\nOne dedicated Harness conversation, model local-acp, no Harness tools. See acp/README.md for setup, permissions, and recovery.\n')
    return
  }
  const provider = await createProvider({ repo: values.repo, state: values.state, port: Number(values.port), token: process.env.HARNESS_ACP_TOKEN, allow: values.allow, timeoutMs: Number(values['timeout-ms']), ...(positionals.length ? { command: positionals } : {}) })
  process.stderr.write(`Local ACP provider: ${provider.url}/v1/chat/completions\nModel: ${MODEL}; configure Authorization: Bearer <HARNESS_ACP_TOKEN> on one dedicated conversation.\nPermission requests allowed: ${values.allow.join(', ') || 'none'}. The repo working directory is not a sandbox.\n`)
  for (const signal of ['SIGINT', 'SIGTERM']) process.once(signal, () => {
    provider.close().catch(error => { process.stderr.write(`${error.message}\n`); process.exitCode = 1 })
  })
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  main().catch(error => { process.stderr.write(`${error.message}\n`); process.exitCode = 1 })
}
