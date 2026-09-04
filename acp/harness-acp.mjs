#!/usr/bin/env node
// ACP is an edge projection over durable Grubbery chats. Agent policy and
// authority stay on the ship; this process only translates JSON-RPC and HTTP.

import { isAbsolute } from 'node:path';
import { createInterface } from 'node:readline';

const SHIP_URL = (process.env.SHIP_URL || 'http://localhost:8081').replace(/\/$/, '');
const SHIP_CODE = process.env.SHIP_CODE;
const BALL = (process.env.HARNESS_BALL || 'apps/harness.harness').replace(/^\/+|\/+$/g, '');
const AGENT = process.env.HARNESS_AGENT || 'main';
const DEFAULT_CWD = process.env.ACP_CWD || process.cwd();
const POLL_MS = numberSetting('ACP_POLL_MS', 150, 25);
const HTTP_TIMEOUT_MS = numberSetting('ACP_HTTP_TIMEOUT_MS', 30_000, 1_000);
const PROMPT_TIMEOUT_MS = numberSetting('ACP_PROMPT_TIMEOUT_MS', 30 * 60_000, 1_000);

if (!SHIP_CODE) throw new Error('SHIP_CODE is required');
if (!/^[a-z0-9._/-]+$/.test(BALL)) throw new Error('invalid HARNESS_BALL');
if (!/^[a-z0-9-]+$/.test(AGENT)) throw new Error('invalid HARNESS_AGENT');
if (!isAbsolute(DEFAULT_CWD)) throw new Error('ACP_CWD must be an absolute path');

const pending = new Map();
const sessionCwds = new Map();
let cookie = '';
let sequence = 0;

class RpcError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

const invalid = (message) => new RpcError(-32602, message);
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const encodePath = (path) => path.split('/').map(encodeURIComponent).join('/');
const agentRoot = () => `${BALL}/agents/${AGENT}`;
const chatRoot = (sessionId) => `${agentRoot()}/chats/${sessionId}`;

function numberSetting(name, fallback, minimum) {
  const value = Number(process.env[name] || fallback);
  if (!Number.isFinite(value) || value < minimum) throw new Error(`${name} must be at least ${minimum}`);
  return value;
}

function write(frame) {
  process.stdout.write(`${JSON.stringify(frame)}\n`);
}

function update(sessionId, value) {
  write({ jsonrpc: '2.0', method: 'session/update', params: { sessionId, update: value } });
}

async function login() {
  const response = await fetch(`${SHIP_URL}/~/login`, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: `password=${encodeURIComponent(SHIP_CODE)}`,
    signal: AbortSignal.timeout(HTTP_TIMEOUT_MS),
  });
  if (!response.ok) throw new Error(`login failed: HTTP ${response.status}`);
  cookie = (response.headers.get('set-cookie') || '').split(';')[0];
  if (!cookie) throw new Error('login succeeded without an Urbit auth cookie');
}

async function request(path, options = {}, retry = true) {
  const response = await fetch(`${SHIP_URL}${path}`, {
    ...options,
    headers: { cookie, ...(options.headers || {}) },
    signal: AbortSignal.timeout(HTTP_TIMEOUT_MS),
  });
  if (retry && response.status === 403) {
    await login();
    return request(path, options, false);
  }
  return response;
}

const jsonRoute = (kind, path) =>
  `/grubbery/api/${kind}/${encodePath(path)}?blot=${encodeURIComponent('/json')}`;

async function readJson(path) {
  const response = await request(jsonRoute('file', path));
  if (response.status === 404) return null;
  if (!response.ok) throw new Error(`read ${path}: HTTP ${response.status}`);
  return response.json();
}

async function poke(path, body) {
  const response = await request(jsonRoute('poke', path), {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (response.ok) return;
  const detail = await response.text().catch(() => '');
  throw new Error(`poke ${path}: HTTP ${response.status}${detail ? `: ${detail}` : ''}`);
}

async function listSessions() {
  const sessions = await readJson(`${agentRoot()}/ui/chats.json`);
  return Array.isArray(sessions) ? sessions : [];
}

async function requireSession(sessionId) {
  if (typeof sessionId !== 'string' || !(await listSessions()).includes(sessionId)) {
    throw invalid('Unknown session');
  }
  return sessionId;
}

async function waitForSession(sessionId, present) {
  for (let attempt = 0; attempt < 100; attempt += 1) {
    if ((await listSessions()).includes(sessionId) === present) return;
    await sleep(POLL_MS);
  }
  throw new Error(`session ${sessionId} was not ${present ? 'materialized' : 'deleted'}`);
}

function setupCwd(params) {
  if (typeof params?.cwd !== 'string' || !isAbsolute(params.cwd)) {
    throw invalid('cwd must be an absolute path');
  }
  if (!Array.isArray(params.mcpServers)) throw invalid('mcpServers must be an array');
  if (params.mcpServers.length) {
    throw invalid('client MCP servers are not supported; install governed Grubbery tools instead');
  }
  return params.cwd;
}

function promptText(params) {
  if (!Array.isArray(params?.prompt)) return null;
  const chunks = params.prompt.flatMap((block) => {
    if (block?.type === 'text' && typeof block.text === 'string') return [block.text];
    if (block?.type === 'resource_link' && typeof block.uri === 'string') {
      return [`[resource ${block.name || 'link'}: ${block.uri}]`];
    }
    return [];
  });
  return chunks.length ? chunks.join('\n') : null;
}

function asText(value) {
  if (typeof value === 'string') return value;
  return JSON.stringify(value ?? '');
}

function emitEntry(sessionId, entry, replay = false, index = 0) {
  const messageId = replay ? { messageId: `grub-${index}` } : {};
  if (replay && entry?.role === 'user' && typeof entry.content === 'string') {
    update(sessionId, {
      sessionUpdate: 'user_message_chunk',
      ...messageId,
      content: { type: 'text', text: entry.content },
    });
  } else if (entry?.role === 'assistant' && typeof entry.content === 'string') {
    update(sessionId, {
      sessionUpdate: 'agent_message_chunk',
      ...messageId,
      content: { type: 'text', text: entry.content },
    });
  } else if (entry?.type === 'tool_use') {
    update(sessionId, {
      sessionUpdate: 'tool_call',
      toolCallId: String(entry.id || ''),
      title: String(entry.name || 'tool'),
      status: 'in_progress',
      rawInput: entry.input ?? {},
    });
  } else if (entry?.type === 'tool_result' || entry?.type === 'tool_result_media') {
    update(sessionId, {
      sessionUpdate: 'tool_call_update',
      toolCallId: String(entry.tool_use_id || ''),
      status: 'completed',
      content: [{ type: 'content', content: { type: 'text', text: asText(entry.content ?? entry.text) } }],
    });
  } else {
    return false;
  }
  return true;
}

async function createSession(cwd) {
  const sessionId = `acp-${Date.now().toString(36)}-${(++sequence).toString(36)}`;
  await poke(`${agentRoot()}/main.sig`, { action: 'create-chat', name: sessionId });
  await waitForSession(sessionId, true);
  sessionCwds.set(sessionId, cwd);
  return sessionId;
}

async function cancelSession(sessionId) {
  const token = pending.get(sessionId);
  if (token) token.cancelled = true;
  const status = await readJson(`${chatRoot(sessionId)}/status.json`);
  if (!status || status.state === 'idle') return;
  await poke(`${chatRoot(sessionId)}/chat.json`, status.state === 'tool' && status.id
    ? { action: 'interrupt', id: status.id }
    : { action: 'interrupt' });
}

async function runPrompt(sessionId, text) {
  const baseline = await readJson(`${chatRoot(sessionId)}/chat.json`);
  if (!Array.isArray(baseline)) throw invalid('Unknown session');

  const token = { cancelled: false };
  pending.set(sessionId, token);
  try {
    await poke(`${chatRoot(sessionId)}/chat.json`, { action: 'message', content: text });
    let cursor = baseline.length;
    let active = false;
    let output = false;
    const deadline = Date.now() + PROMPT_TIMEOUT_MS;

    while (!token.cancelled && Date.now() < deadline) {
      const root = chatRoot(sessionId);
      const [conversation, status] = await Promise.all([
        readJson(`${root}/chat.json`),
        readJson(`${root}/status.json`),
      ]);
      if (!Array.isArray(conversation)) throw new Error(`session disappeared: ${sessionId}`);

      conversation.slice(cursor).forEach((entry, offset) => {
        output = emitEntry(sessionId, entry, false, cursor + offset) || output;
      });
      cursor = conversation.length;

      const state = status?.state || 'idle';
      active ||= state !== 'idle';
      if (state === 'idle' && (output || (active && cursor > baseline.length))) {
        return { stopReason: 'end_turn' };
      }
      await sleep(POLL_MS);
    }

    if (token.cancelled) return { stopReason: 'cancelled' };
    throw new Error(`prompt timed out after ${PROMPT_TIMEOUT_MS}ms`);
  } finally {
    pending.delete(sessionId);
  }
}

async function dispatch({ method, params }) {
  switch (method) {
    case 'initialize':
      return {
        protocolVersion: 1,
        agentCapabilities: {
          loadSession: true,
          promptCapabilities: { image: false, audio: false, embeddedContext: false },
          mcpCapabilities: { http: false, sse: false },
          sessionCapabilities: { list: {}, delete: {}, resume: {}, close: {} },
          auth: {},
        },
        authMethods: [],
        agentInfo: { name: 'urbit-harness', title: 'Urbit Agent Harness', version: '0.2.0' },
      };
    case 'session/new':
      return { sessionId: await createSession(setupCwd(params)) };
    case 'session/list': {
      const filter = params?.cwd;
      if (filter != null && (typeof filter !== 'string' || !isAbsolute(filter))) {
        throw invalid('cwd filter must be an absolute path');
      }
      const sessions = (await listSessions()).map((sessionId) => ({
        sessionId,
        cwd: sessionCwds.get(sessionId) || DEFAULT_CWD,
        title: sessionId,
        _meta: { durable: true, ball: BALL, agent: AGENT },
      }));
      return { sessions: filter ? sessions.filter((session) => session.cwd === filter) : sessions };
    }
    case 'session/load': {
      const cwd = setupCwd(params);
      const sessionId = await requireSession(params?.sessionId);
      const conversation = await readJson(`${chatRoot(sessionId)}/chat.json`);
      if (!Array.isArray(conversation)) throw invalid('Unknown session');
      sessionCwds.set(sessionId, cwd);
      conversation.forEach((entry, index) => emitEntry(sessionId, entry, true, index));
      return {};
    }
    case 'session/resume': {
      const cwd = setupCwd(params);
      const sessionId = await requireSession(params?.sessionId);
      sessionCwds.set(sessionId, cwd);
      return {};
    }
    case 'session/close':
      await cancelSession(await requireSession(params?.sessionId));
      return {};
    case 'session/delete': {
      const sessionId = await requireSession(params?.sessionId);
      if (sessionId === 'main') throw invalid('The main session is protected');
      await cancelSession(sessionId);
      await poke(`${agentRoot()}/main.sig`, { action: 'delete-chat', name: sessionId });
      await waitForSession(sessionId, false);
      sessionCwds.delete(sessionId);
      return {};
    }
    case 'session/prompt': {
      const sessionId = params?.sessionId;
      const text = promptText(params);
      if (typeof sessionId !== 'string' || !text) throw invalid('Expected sessionId and a text prompt');
      if (pending.has(sessionId)) throw new RpcError(-32600, 'A prompt is already running for this session');
      return runPrompt(sessionId, text);
    }
    case 'session/cancel':
      if (typeof params?.sessionId === 'string') await cancelSession(params.sessionId);
      return {};
    default:
      throw new RpcError(-32601, 'Method not found');
  }
}

async function main() {
  await login();
  const lines = createInterface({ input: process.stdin, crlfDelay: Infinity });
  for await (const line of lines) {
    if (!line.trim()) continue;
    let frame;
    try {
      frame = JSON.parse(line);
    } catch {
      write({ jsonrpc: '2.0', id: null, error: { code: -32700, message: 'Parse error' } });
      continue;
    }

    // Keep prompt polling concurrent so cancellation and other sessions remain responsive.
    void dispatch(frame).then(
      (result) => frame.id != null && write({ jsonrpc: '2.0', id: frame.id, result }),
      (error) => frame.id != null && write({
        jsonrpc: '2.0',
        id: frame.id,
        error: { code: error?.code || -32603, message: error?.message || String(error) },
      }),
    );
  }
}

main().catch((error) => {
  process.stderr.write(`harness-acp fatal: ${error?.stack || error}\n`);
  process.exit(1);
});
