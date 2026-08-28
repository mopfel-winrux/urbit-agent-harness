# harness-acp

A dependency-free stdio adapter between an [Agent Client Protocol](https://agentclientprotocol.com) client and this desk's generic `%acp` transport.

ACP clients such as Zed spawn an agent subprocess and exchange newline-delimited JSON-RPC over stdin/stdout. [`harness-acp.mjs`](harness-acp.mjs) moves those frames through Eyre to a named `%acp` connection. It does not implement ACP methods or know about sessions, prompts, tools, or model providers; the native harness on the other side does that.

The default connection is `harness`, implemented by this desk's `%harness` agent. Set `ACP_CONNECTION` to reuse the same adapter with another native harness.

```text
ACP client <-- NDJSON --> harness-acp.mjs <-- Eyre --> %acp <-- durable queue --> native harness
```

## Requirements

- Node 22 or newer (ESM and global `fetch`)
- A running ship with `%acp` and the selected harness installed
- The ship's login code

## Use

Point the ACP client at the script:

```text
command: node
args:    /path/to/urbit-agent-harness/acp/harness-acp.mjs
env:     SHIP_URL=http://localhost:8081
```

Environment variables:

| Variable | Default | Meaning |
|---|---|---|
| `SHIP_URL` | `http://localhost:8081` | Ship HTTP origin |
| `SHIP_CODE` | fakezod's default code | Ship login code |
| `ACP_CONNECTION` | `harness` | Native ACP server connection |
| `ACP_POLL_MS` | `100` | Durable client-queue polling interval |

Only one stdio client should consume a connection at a time. Each outbound frame is acknowledged after it is written to stdout; an unacknowledged frame remains in `%acp` and is replayed after an adapter restart.

## Testing without an ACP client

After installing the assembled desk, drive the adapter with NDJSON:

```sh
node acp/harness-acp.mjs
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1}}
{"jsonrpc":"2.0","id":2,"method":"session/new","params":{"cwd":"/tmp","mcpServers":[]}}
{"jsonrpc":"2.0","id":3,"method":"session/prompt","params":{"sessionId":"<from step 2>","prompt":[{"type":"text","text":"what time is it on the ship?"}]}}
```

The native `%harness` implementation currently supports initialize, new/load session, text and resource-link prompts, cancellation, terminal message chunks, and stop responses. See [`../docs-refs/acp.md`](../docs-refs/acp.md) for the transport and server contract.
