# Agent Client Protocol

This desk separates ACP transport from harness behavior.

`%acp` is a generic Gall agent that stores opaque JSON-RPC frames in two
ordered, durable queues for each named connection. It does not parse ACP,
create sessions, call a model, or know which harness owns a connection. A
native Gall harness, a local adapter process, or another worker can implement
either side of a connection.

`%harness` is one ACP server implementation. It opens connection `harness`,
subscribes to the `%agent` queue, persists in-flight `session/prompt` request
ids with its session state, and sends responses to the `%client` queue.

## Generic transport contract

Poke `%acp` with `%acp-action-1`:

```json
{ "open": { "connection": "harness" } }
{ "send": { "connection": "harness", "target": "agent", "payload": "{...}" } }
{ "ack": { "connection": "harness", "target": "agent", "through": 12 } }
{ "close": { "connection": "harness", "reason": "worker exited" } }
{ "drop": { "connection": "harness" } }
```

Connection ids are 1–128 lowercase ASCII letters, digits, or hyphens. Payloads
are opaque `@t` values capped at 1 MiB. The transport allows 32 connections and
10,000 unacknowledged messages per receiving peer.

Subscribe to `/v1/<connection>/client` or `/v1/<connection>/agent`. The first
facts report connection state and replay all queued messages; subsequent facts
contain newly queued messages. Facts use `%acp-update-1`. A consumer must
process messages in sequence order and cumulatively acknowledge the target
queue only after admitting the frame to its own durable state.

Scry `/x/v1/<connection>/<peer>` to recover that peer's current queue.
Closing stops new sends but retains unacknowledged traffic. Dropping is allowed
only after the connection is closed and both queues are empty.

All pokes, watches, and scries are restricted to the local ship. An external
client reaches them through its authenticated Urbit connection; ACP frames do
not become public Eyre endpoints.

## Native `%harness` server

The `harness` connection currently implements ACP protocol version 1:

- `initialize`
- `session/new`
- `session/load`
- `session/prompt`
- `session/cancel`
- `session/update` notifications with `agent_message_chunk`

New ACP sessions use the same OpenRouter defaults as the web UI and resolve a
blank session key through the harness-level key set by `%set-key`. Text prompt
blocks are admitted directly. Resource-link blocks are preserved as textual
resource references. Other content block types are not advertised.

The current provider call is non-streaming, so the server emits one terminal
`agent_message_chunk` followed by the `session/prompt` response. The transport
and ACP boundary already support multiple updates; provider token streaming can
be added without changing `%acp`.

Cancellation removes the harness request marker and replies to the original
prompt request with `stopReason: "cancelled"`. Provider failures become JSON-RPC
internal errors. Prompt ids survive Gall save/load, and incoming transport
frames are acknowledged only after processing, so replay across restarts is
safe.

## Adding another harness

A harness chooses a stable connection id, opens it, watches its `%agent` queue,
and implements whichever ACP capabilities it advertises. It sends client-bound
frames back through `%send`, then acknowledges each admitted agent-bound
sequence. No changes to `%acp`, its marks, or another harness are required.

