# harness-acp

An [Agent Client Protocol](https://agentclientprotocol.com) (ACP) server that bridges an ACP client — a code editor like Zed, or any ACP-speaking surface — to the `%harness` agent running on an Urbit ship.

ACP is a JSON-RPC protocol (like LSP, but for agents): a client spawns the agent as a subprocess and talks to it over stdio. `harness-acp.mjs` implements the **agent/server** side and translates every ACP call into an action on `%harness` over the ship's Eyre airlock — so an on-ship, event-sourced, self-modifying agent shows up as an ordinary ACP agent in any compatible client.

No ship-side changes are needed: `%harness` already exposes the whole surface this bridge uses.

## Mapping

| ACP | %harness |
|---|---|
| `initialize` | static capabilities |
| `session/new` | `%new` — creates a harness session (blank key → the ship's stored key) |
| `session/load` | resumes an existing session id |
| `session/prompt` | `%send`, then the transcript is polled and streamed back as `session/update` notifications (`agent_message_chunk`, `tool_call`, `tool_call_update`); resolves with a `stopReason` when the turn goes idle |
| `session/cancel` | `%cancel` |

Streaming is currently item-level (a whole assistant message / tool result at a time), because `%harness` doesn't yet stream tokens. When token streaming lands (roadmap #1), the same `session/update` channel carries finer chunks with no protocol change.

## Requirements

- **Node ≥ 22** (uses ESM + global `fetch`). No dependencies.
- A running ship with `%harness` installed and an API key set (the "set key" button in the web UI, or a `%set-key` poke). The bridge sends a blank per-session key so the ship's stored key is used — no key touches this process.

## Use

Point your ACP client at the script. For example, a client that spawns agents by command would use:

```
command: node
args:    /path/to/urbit-agent-harness/acp/harness-acp.mjs
env:     SHIP_URL=http://localhost:8081
```

Environment:

| var | default |
|---|---|
| `SHIP_URL` | `http://localhost:8081` |
| `SHIP_CODE` | `lidlut-tabwed-pillex-ridrup` (fakezod +code) |
| `HARNESS_URL` | OpenRouter chat-completions endpoint |
| `HARNESS_MODEL` | `openai/gpt-4o-mini` |
| `HARNESS_SYSTEM` | a default system prompt |

## Testing without a client

Drive it with newline-delimited JSON-RPC on stdin:

```sh
node acp/harness-acp.mjs
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1}}
{"jsonrpc":"2.0","id":2,"method":"session/new","params":{"cwd":"/tmp","mcpServers":[]}}
{"jsonrpc":"2.0","id":3,"method":"session/prompt","params":{"sessionId":"<from step 2>","prompt":[{"type":"text","text":"what time is it on the ship?"}]}}
```

You'll see `session/update` notifications stream, then a `{"stopReason":"end_turn"}` result.

## Relation to Reid's tlon-acp

This is inspired by [`reid/tlon-acp`](https://github.com/tloncorp/tlon-apps/compare/develop...reid/tlon-acp), which pairs a ship-side `%acp` gall agent with a reusable `@tloncorp/acp` node package and a Tlon-channel bridge. Here the ship side is just the existing `%harness` agent and the bridge is a single dependency-free script; the ACP method/notification shapes follow the same protocol.
