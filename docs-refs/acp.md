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
- `harness/session/use-default-model` — adopt model defaults for an existing
  session without changing its instructions or grants; does not retry work.
- `harness/mcp/servers`
- `harness/mcp/configure`
- `harness/session/config`
- `harness/session/configure`
- `harness/session/rename`
- `harness/session/snapshot`
- `harness/session/verify`
- `harness/session/recheck`
- `harness/session/fork`
- `harness/credential/set`
- `harness/provider/models`
- `harness/hand`

`harness/hand` is the bidirectional conversation-adapter extension. It projects
the same native binding, observation, publication, and receipt contract—not a
second agent loop. `initialize` advertises version 2 and the `publish`
capability under `_meta["harness/hand"]`. See [hands](hands.md) for exact action
shapes and recovery semantics. These clients have owner authority; hand ids
are not independently authenticated capability tokens.

`harness/session/verify` returns `{authoritativeRevision, authoritativeDigest,
check}` for a `sessionId`. Require a matched check at the same revision with
`check.actual === authoritativeDigest`; null means unavailable. This also
catches changed skill visibility. `harness/session/recheck` queues an independent
check from the authoritative source and returns `{queued, revision}` without
running inference. See [architecture](architecture.md#grubberys-role) for its
sandbox, crash checkpoint and limits; it does not yet verify all dispatched
effects.

`session/load` replays the full durable transcript, not the compacted model
context, before its result. `session/resume` attaches without replay;
`session/close` detaches without cancelling. Text prompt
blocks are joined; image, audio, embedded context, and client-supplied MCP
servers are not advertised. Filesystem and terminal authority stays behind
explicit Harness tools.

`session/cancel` settles the active prompt with `stopReason: "cancelled"`.
Unfinished tool calls receive terminal `tool_call_update` frames with status
`failed` and a cancellation explanation (ACP has no separate cancelled tool
status). Snapshot tool receipts additionally expose `cancelled: true`, so
clients can label interruption distinctly. Completed sibling results remain
intact. The next prompt does not repeat the interrupted calls; cancellation
is not a guarantee of external rollback. Request-form cancellation is
acknowledged as well as supporting the protocol notification form.

While a prompt is active, the client displays a thinking indicator. Harness
projects incremental provider text as presentation-only
`harness_agent_stream_chunk` updates whenever Iris exposes response progress.
Those chunks are presentation state: only the completed assistant item enters
the event log and the standard `agent_message_chunk` update. Providers or HTTP
paths that deliver the response as one completed body retain the thinking
indicator until that terminal update. Tool progress is emitted as the event
log changes.

`harness/session/snapshot` takes `sessionId` and optional numeric `since`.
It returns `revision`, `phase`, `model`, `error`, cumulative `usage`,
`compactions`, `origin`, and chronological `entries`. When `since` equals the
current revision, `entries` is null: retain the prior entries. An empty array
means the transcript is empty. ACP also includes accumulated `streaming` text
while a normal provider turn is active. Snapshots are readable from any
authorized connection, not just the one that started a prompt.

Entries carry a stable `id` (the decimal event count), numeric `eventCount`,
and optional `inputId`. Pass optional `clientMessageId` with `session/prompt`;
the `harness_prompt_admitted` update echoes it alongside the durable `inputId`.
Match that id against the snapshot to remove optimistic display. Text matching
is not an admission check: identical prompts are legitimate distinct inputs.

`harness/session/fork` takes `sessionId`, a new unused `name`, and `eventCount`
from a tool-free completed assistant reply. It returns the child `sessionId`.
The child retains that prefix and records its origin without replaying effects.

## Recovery

The web client creates a fresh connection identifier for each page instance,
polls quickly without cache while visible, cumulatively acknowledges frames,
and reopens that connection when a scry reports it missing. Already consumed
frames are not processed again if acknowledgement was lost. Pending calls are
rejected on queue loss, not automatically resent: a missing queue does not
prove a mutation was never admitted. Read the session snapshot before retrying.
Page exit closes the queue; the broker prunes closed connections before
admitting new ones.

The stdio process performs the same projection over authenticated Eyre. Its
stdout contains only ACP NDJSON, so diagnostics go to stderr.

ACP delivery is durable but does not compete with session state: `%acp` may
know that frame 12 is unacknowledged, while only `%harness` knows what the frame
means and whether a model turn is active.
