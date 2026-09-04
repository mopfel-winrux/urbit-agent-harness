# harness-acp

`harness-acp.mjs` is a dependency-free Agent Client Protocol stdio adapter for
the Grubbery-native harness. It translates ACP JSON-RPC frames directly to the
authenticated Grubbery ball API; it does not contain an agent loop or copy chat
state off ship.

```text
ACP client <-- NDJSON --> harness-acp.mjs <-- local Eyre --> Grubbery chats
```

## Requirements

- Node 22 or newer
- a running `%grubbery` desk containing `/apps/harness.harness`
- an API provider configured in Grubbery
- the ship URL and login code

Configure an ACP client such as Zed to spawn:

```text
command: node
args:    /path/to/urbit-agent-harness/acp/harness-acp.mjs
env:
  SHIP_URL: http://localhost:8081
  SHIP_CODE: <the output of +code>
```

There is deliberately no default login code.

| Variable | Default | Meaning |
|---|---|---|
| `SHIP_URL` | `http://localhost:8081` | Ship HTTP origin |
| `SHIP_CODE` | required | Ship login code |
| `HARNESS_BALL` | `apps/harness.harness` | Absolute Grubbery instance path |
| `HARNESS_AGENT` | `main` | Agent below the instance's `agents/` directory |
| `ACP_POLL_MS` | `150` | Conversation/status polling interval |
| `ACP_HTTP_TIMEOUT_MS` | `30000` | Timeout for one ship HTTP operation |
| `ACP_PROMPT_TIMEOUT_MS` | `1800000` | Prompt timeout |
| `ACP_CWD` | adapter process directory | Working directory reported for native sessions not created by this adapter process |

## Mapping

- `initialize` advertises protocol version 1, durable session discovery,
  replay, resume, close, and deletion, plus text prompts.
- `session/new` creates a named chat below the configured agent.
- `session/list` enumerates the durable `ui/chats.json` manifest.
- `session/load` validates the chat and replays its transcript as
  `session/update` notifications before responding.
- `session/resume` validates the chat without replaying its transcript.
- `session/close` interrupts active work while keeping the durable chat.
- `session/delete` interrupts active work and removes the chat; the protected
  `main` chat cannot be deleted through ACP.
- `session/prompt` pokes the chat and follows its durable conversation and
  status files. Assistant entries become `agent_message_chunk`; tool-use and
  tool-result entries become ACP tool updates.
- `session/cancel` pokes the same interrupt action used by the native UI.

The adapter intentionally does not proxy ACP filesystem or terminal methods.
An agent reaches those capabilities through governed Grubbery tools and weirs,
so an ACP client cannot silently widen the agent's authority.
Client-supplied MCP servers are rejected for the same reason; capabilities are
installed and granted through the Grubbery process tree.

## Smoke test

The adapter speaks newline-delimited JSON on stdout. With a provider configured:

```sh
SHIP_URL=http://localhost:8081 SHIP_CODE=your-code node acp/harness-acp.mjs
```

Then enter:

```json
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1}}
{"jsonrpc":"2.0","id":2,"method":"session/new","params":{"cwd":"/tmp","mcpServers":[]}}
{"jsonrpc":"2.0","id":3,"method":"session/prompt","params":{"sessionId":"<id from new>","prompt":[{"type":"text","text":"What ship are you running on?"}]}}
```
