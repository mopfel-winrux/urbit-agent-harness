# Harness ACP adapter

`harness-acp.mjs` projects the on-ship `%acp` queues onto newline-delimited
JSON over stdin/stdout. It contains no agent loop and stores no transcript.

```text
ACP client <-- NDJSON --> harness-acp.mjs <-- authenticated Eyre --> %acp
```

## Run

Requirements are Node 22 or newer, an installed `%harness` desk, the ship URL,
and the output of `+code`.

```sh
SHIP_URL=http://localhost:8081 \
SHIP_CODE=your-ship-code \
node /path/to/urbit-agent-harness/acp/harness-acp.mjs
```

An editor such as Zed can spawn that command with the same environment. There
is deliberately no embedded login code.

| Variable | Default | Meaning |
|---|---|---|
| `SHIP_URL` | `http://localhost:8081` | Ship HTTP origin |
| `SHIP_CODE` | required | Ship login code |
| `ACP_CONNECTION` | random `harness-stdio-…` | Durable connection identifier |
| `ACP_POLL_MS` | `100` | Queue polling interval |

Independent processes get distinct connections by default. Set a stable
`ACP_CONNECTION` only when intentionally resuming the same ordered queue;
do not share an active identifier between independent clients.

## Behavior

The adapter logs in, opens its connection, forwards every valid input frame to
the agent queue, writes client frames to stdout in sequence order, and
acknowledges them after writing. Invalid input receives a JSON-RPC parse error.
Diagnostics are written to stderr.

ACP session methods and Harness extensions are documented in
[`docs-refs/acp.md`](../docs-refs/acp.md). The adapter does not proxy ambient
filesystem or terminal methods; those capabilities are granted to a session as
Harness tools.

## Smoke test

Start the adapter and enter:

```json
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1}}
{"jsonrpc":"2.0","id":2,"method":"session/new","params":{"name":"editor-test"}}
{"jsonrpc":"2.0","id":3,"method":"session/prompt","params":{"sessionId":"editor-test","prompt":[{"type":"text","text":"Reply with ACP_OK"}]}}
```

The prompt first yields a `user_message_chunk`, then an assistant update and a
terminal result.
