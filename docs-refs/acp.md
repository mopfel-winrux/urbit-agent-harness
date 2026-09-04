# ACP boundary

Agent Client Protocol is Harness's client boundary. `%acp` is a generic Gall
broker for opaque JSON-RPC frames; `%harness` implements agent semantics behind
it. The browser and stdio adapter are equal clients.

```text
browser ─┐
editor ──┼─> independent %acp queues ─> %harness sessions
future ──┘
```

Each connection has two monotonically sequenced queues. A client acknowledges
only frames it has consumed. Harness acknowledges agent-bound frames only after
admission. Queues survive ordinary process reloads and prevent one client from
stealing another client's updates.

## Protocol surface

- `initialize`
- `session/new`
- `session/list`
- `session/load`
- `session/resume`
- `session/close`
- `session/delete`
- `session/prompt`
- `session/cancel`
- `session/update` for user and assistant messages, tool calls, and results

Harness extensions use the same JSON-RPC connection:

- `harness/status`
- `harness/tools`
- `harness/defaults`
- `harness/defaults/configure`
- `harness/mcp/servers`
- `harness/mcp/configure`
- `harness/session/config`
- `harness/session/configure`
- `harness/session/rename`
- `harness/credential/set`
- `harness/provider/models`

`session/load` replays the durable transcript before its result. Text prompt
blocks are joined; image, audio, embedded context, and client-supplied MCP
servers are not advertised. Filesystem and terminal authority stays behind
explicit Harness tools.

While a prompt is active, the client displays a thinking indicator. Harness
projects incremental provider text as transient
`harness_agent_stream_chunk` updates whenever Iris exposes response progress.
Those chunks are presentation state: only the completed assistant item enters
the event log and the standard `agent_message_chunk` update. Providers or HTTP
paths that deliver the response as one completed body retain the thinking
indicator until that terminal update. Tool progress is emitted as the event
log changes.

## Recovery

The web client creates a fresh connection identifier for each page instance,
polls quickly without cache while visible, cumulatively acknowledges frames,
and reopens that connection when a scry reports it missing. Pending JSON-RPC
calls are resent after recovery.
Page exit closes the queue; the broker prunes closed connections before
admitting new ones.

The stdio process performs the same projection over authenticated Eyre. Its
stdout contains only ACP NDJSON, so diagnostics go to stderr.

ACP delivery is durable but does not compete with session state: `%acp` may
know that frame 12 is unacknowledged, while only `%harness` knows what the frame
means and whether a model turn is active.
