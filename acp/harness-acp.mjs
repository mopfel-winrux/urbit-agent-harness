#!/usr/bin/env node
// harness-acp: an Agent Client Protocol (agentclientprotocol.com) server
// that bridges an ACP client (Zed, etc.) to the %harness agent on an Urbit
// ship. Speaks newline-delimited JSON-RPC over stdio to the client, and
// drives %harness over the Eyre airlock (pokes + scries).
//
// No ship-side changes: an ACP session is a %harness session, session/prompt
// is a %send, session/cancel is a %cancel, and %harness's transcript is
// polled and translated into ACP session/update notifications.
//
// env:
//   SHIP_URL    default http://localhost:8081
//   SHIP_CODE   default lidlut-tabwed-pillex-ridrup   (fakezod +code)
//   HARNESS_URL provider endpoint (default OpenRouter chat-completions)
//   HARNESS_MODEL default openai/gpt-4o-mini
//   The session's api key is left blank, so the ship's stored key (set via
//   the %harness "set key" button / %set-key) is used.
import { createInterface } from 'node:readline';

const SHIP_URL = process.env.SHIP_URL || 'http://localhost:8081';
const SHIP_CODE = process.env.SHIP_CODE || 'lidlut-tabwed-pillex-ridrup';
const PROVIDER_URL =
  process.env.HARNESS_URL || 'https://openrouter.ai/api/v1/chat/completions';
const MODEL = process.env.HARNESS_MODEL || 'openai/gpt-4o-mini';
const SYSTEM =
  process.env.HARNESS_SYSTEM ||
  'You are a helpful agent living on an Urbit ship, reached over ACP. Be concise.';

// ---- airlock -------------------------------------------------------------

let cookie = null;
let shipName = 'zod';
let channelId = `acp-${Date.now()}-${Math.floor(Math.random() * 1e6)}`;
let eventId = 0;

async function login() {
  const res = await fetch(`${SHIP_URL}/~/login`, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: `password=${SHIP_CODE}`,
  });
  if (!res.ok) throw new Error(`login failed: ${res.status}`);
  const setc = res.headers.get('set-cookie') || '';
  cookie = setc.split(';')[0];
  const m = cookie.match(/urbauth-~([\w-]+)/);
  if (m) shipName = m[1];
  if (!cookie) throw new Error('login: no cookie');
}

async function poke(action) {
  const body = [
    {
      id: ++eventId,
      action: 'poke',
      ship: shipName,
      app: 'harness',
      mark: 'harness-action',
      json: action,
    },
  ];
  const res = await fetch(`${SHIP_URL}/~/channel/${channelId}`, {
    method: 'PUT',
    headers: { 'content-type': 'application/json', cookie },
    body: JSON.stringify(body),
  });
  if (res.status !== 204 && res.status !== 200)
    throw new Error(`poke failed: ${res.status}`);
}

async function scry(path) {
  const res = await fetch(`${SHIP_URL}/~/scry/harness/${path}.json`, {
    headers: { cookie },
  });
  if (!res.ok) return null;
  return res.json();
}

async function allTools() {
  const t = await scry('tools');
  return Array.isArray(t) && t.length
    ? t
    : ['ship-time', 'clay', 'web', 'code', 'skills', 'subagents', 'peers'];
}

// ---- jsonrpc over stdio --------------------------------------------------

function send(msg) {
  process.stdout.write(`${JSON.stringify(msg)}\n`);
}
function reply(id, result) {
  send({ jsonrpc: '2.0', id, result });
}
function replyErr(id, code, message) {
  send({ jsonrpc: '2.0', id, error: { code, message } });
}
function notify(method, params) {
  send({ jsonrpc: '2.0', method, params });
}

// ---- session state -------------------------------------------------------

// sessionId -> { seen: number(items already streamed), cancelled: bool }
const sessions = new Map();

function textOf(item) {
  return item?.body || '';
}

// translate transcript items [seen..] into ACP session/update notifications
function streamItems(sessionId, items, from) {
  for (let i = from; i < items.length; i++) {
    const it = items[i];
    if (it.role === 'assistant') {
      if (it.body) {
        notify('session/update', {
          sessionId,
          update: {
            sessionUpdate: 'agent_message_chunk',
            content: { type: 'text', text: it.body },
          },
        });
      }
      for (const call of it.calls || []) {
        notify('session/update', {
          sessionId,
          update: {
            sessionUpdate: 'tool_call',
            toolCallId: `${sessionId}-${i}-${call.name}`,
            title: call.name,
            status: 'in_progress',
            rawInput: safeJson(call.args),
          },
        });
      }
    } else if (it.role === 'tool') {
      notify('session/update', {
        sessionId,
        update: {
          sessionUpdate: 'tool_call_update',
          toolCallId: `${sessionId}-tool-${i}-${it.name}`,
          status: 'completed',
          content: [{ type: 'content', content: { type: 'text', text: textOf(it) } }],
        },
      });
    }
  }
  return items.length;
}

function safeJson(s) {
  try {
    return JSON.parse(s);
  } catch {
    return { raw: s };
  }
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// poll the session until the turn ends, streaming updates as items arrive
async function driveTurn(sessionId) {
  const st = sessions.get(sessionId);
  const deadline = Date.now() + 5 * 60 * 1000;
  while (Date.now() < deadline) {
    if (st.cancelled) return 'cancelled';
    const v = await scry(`session/${sessionId}`);
    if (!v) return 'refusal';
    st.seen = streamItems(sessionId, v.items || [], st.seen);
    const busy = v.pending || (v.wait && v.wait.length);
    if (!busy) {
      if (v.err) {
        notify('session/update', {
          sessionId,
          update: {
            sessionUpdate: 'agent_message_chunk',
            content: { type: 'text', text: `⚠ ${v.err}` },
          },
        });
        return 'refusal';
      }
      const last = (v.items || [])[v.items.length - 1];
      if (last && last.role === 'assistant' && !(last.calls || []).length)
        return 'end_turn';
    }
    await sleep(600);
  }
  return 'max_tokens';
}

// ---- method handlers -----------------------------------------------------

async function onInitialize(id) {
  reply(id, {
    protocolVersion: 1,
    agentCapabilities: { loadSession: true, promptCapabilities: { image: false } },
    agentInfo: { name: 'harness-acp', title: 'Urbit %harness (ACP)', version: '0.1.0' },
    authMethods: [],
  });
}

async function onNewSession(id, params) {
  const sessionId = `acp-${Date.now()}-${Math.floor(Math.random() * 1e6)}`;
  const tools = await allTools();
  await poke({
    new: {
      sid: sessionId,
      config: {
        url: PROVIDER_URL,
        model: MODEL,
        key: '',
        system: SYSTEM,
        'max-context': 12000,
        tools,
      },
    },
  });
  sessions.set(sessionId, { seen: 0, cancelled: false });
  reply(id, { sessionId });
}

async function onLoadSession(id, params) {
  const sessionId = params?.sessionId;
  const v = sessionId && (await scry(`session/${sessionId}`));
  if (!v) return replyErr(id, -32602, 'no such session');
  sessions.set(sessionId, { seen: (v.items || []).length, cancelled: false });
  reply(id, {});
}

async function onPrompt(id, params) {
  const sessionId = params?.sessionId;
  const st = sessions.get(sessionId);
  if (!st) return replyErr(id, -32602, 'unknown session');
  st.cancelled = false;
  const text = (params.prompt || [])
    .filter((b) => b.type === 'text')
    .map((b) => b.text)
    .join('\n')
    .trim();
  if (!text) return replyErr(id, -32602, 'empty prompt');
  // sync seen to current transcript so we only stream this turn's items
  const before = await scry(`session/${sessionId}`);
  st.seen = before ? (before.items || []).length : st.seen;
  await poke({ send: { sid: sessionId, text } });
  const stopReason = await driveTurn(sessionId);
  reply(id, { stopReason });
}

async function onCancel(params) {
  const sessionId = params?.sessionId;
  const st = sessions.get(sessionId);
  if (st) st.cancelled = true;
  if (sessionId) await poke({ cancel: { sid: sessionId } }).catch(() => {});
}

// ---- main loop -----------------------------------------------------------

async function handle(req) {
  try {
    switch (req.method) {
      case 'initialize':
        return onInitialize(req.id);
      case 'authenticate':
        return reply(req.id, {});
      case 'session/new':
        return onNewSession(req.id, req.params);
      case 'session/load':
        return onLoadSession(req.id, req.params);
      case 'session/prompt':
        return onPrompt(req.id, req.params);
      case 'session/cancel':
        return onCancel(req.params);
      default:
        if (req.id !== undefined)
          replyErr(req.id, -32601, `method not found: ${req.method}`);
    }
  } catch (e) {
    if (req.id !== undefined) replyErr(req.id, -32603, String(e?.message || e));
  }
}

async function main() {
  await login();
  const lines = createInterface({ input: process.stdin, crlfDelay: Infinity });
  for await (const line of lines) {
    if (!line.trim()) continue;
    let req;
    try {
      req = JSON.parse(line);
    } catch {
      send({ jsonrpc: '2.0', id: null, error: { code: -32700, message: 'Parse error' } });
      continue;
    }
    handle(req);
  }
}

main().catch((e) => {
  process.stderr.write(`harness-acp fatal: ${e?.stack || e}\n`);
  process.exit(1);
});
