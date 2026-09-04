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
- `harness/session/snapshot`
- `harness/session/fork`
- `harness/credential/set`
- `harness/provider/models`
- `harness/hand`

`harness/hand` is the bidirectional conversation-adapter extension. It projects
the same native binding, observation, publication, and receipt contract—not a
second agent loop. `initialize` advertises version 1 and the `publish`
capability under `_meta["harness/hand"]`. See [hands](hands.md) for exact action
shapes and recovery semantics. These clients have owner authority; hand ids
are not independently authenticated capability tokens.

`session/load` replays the full durable transcript, not the compacted model
context, before its result. `session/resume` attaches without replay;
`session/close` detaches without cancelling. Text prompt
blocks are joined; image, audio, embedded context, and client-supplied MCP
servers are not advertised. Filesystem and terminal authority stays behind
explicit Harness tools.

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
