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

### Conversation commands

Send commands as ordinary `session/prompt` text. Harness advertises `/help`,
`/status`, `/model`, `/context`, `/compact`, `/memory`, `/remember`, `/forget`, and
`/stop` using ACP's `available_commands_update` on
session creation, load, and resume. React, native `%send`, and all conversation
hands use the same command interpreter; adapters do not implement command logic.

| Command | Effect |
| --- | --- |
| `/help` | List commands and usage. |
| `/status` | Show provider/model, tool-grant count, recorded token usage and a safe description of the last failure. |
| `/model` | Show the conversation's provider and model. |
| `/model <id>` | Change the model within the current provider. |
| `/model default` | Copy the current default provider/model settings into this conversation. |
| `/context` | Inspect the encoded-request estimate, input/output budgets, retained context and compaction usage. |
| `/compact` | Summarize older complete exchanges with the current provider; retain the recent turn and full transcript. |
| `/memory` | List the current conversation's pinned notes. |
| `/remember <name> <text>` | Save or replace a note, retained verbatim across compaction. |
| `/forget <name>` | Unpin a note; earlier messages and checkpoints are not erased. |
| `/stop` | Cancel the current turn and queued hand work; acknowledge locally. |

Only `/compact` calls a model; none requires a tool grant. Model changes retain
the conversation's instructions, history and tool permissions. A typed model
name is not an access check; the provider may reject it on the next real prompt.
Changing to an uncatalogued model uses the same 80,000-token context fallback as
the settings client. `/model default` copies the default's context limit.

Memory commands require admission to the conversation, not a tool grant. They
do not grant cross-session access. Current notes are limited to 16 entries,
1,024 UTF-8 bytes per body and 8,192 name/body bytes total; overflow is explicit.
Snapshots and views expose `memory: [{name, body}]`. Edits append `memory-set`
events (`body: null` unpins) in the same admission as the command reply.

Only an exact `/stop` (ignoring surrounding whitespace) interrupts active work.
Other commands submitted through ACP while busy get the normal busy error;
hands queue them until settlement. Hand authorization and source-event
deduplication happen before interruption: replaying an old stop cannot cancel
a newer turn. Admission/storage limits still apply. Cancellation fences late
results but cannot undo external actions already started.

Commands are recognized only at human ingress, not in model/tool output, timers
or subagent instructions. Lowercase slash words reserve the command namespace;
unknown commands reply with help guidance. Paths such as `/tmp/file` and `//`
escapes remain ordinary text. Each accepted command records its input and a
`command-completed` audit event linked by input ID. Successful `/compact` instead
records its acknowledgement in `checkpoint-completed`, following the frozen
`compaction-planned` event. Replies appear in the shared transcript and ordinary
ACP/hand output. Summary usage is included in cumulative usage and separately
reported as `compactionUsage`; failed summaries retain the prior context and do
not automatically retry. See the [ACP slash-command protocol](https://agentclientprotocol.com/protocol/v1/slash-commands).

### Methods

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
`compactions`, `compactionUsage`, `origin`, and chronological `entries`. When `since` equals the
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

## Provider authentication

Built-in provider settings select an authentication method, not an arbitrary
URL. The stored configuration URL encodes the selected route, so there is no
second mode field that can disagree with the request codec. Custom providers
retain editable endpoints and custom headers.

| OpenAI authentication | Credential slot | Inference route |
| --- | --- | --- |
| API key | `openai` | `https://api.openai.com/v1/chat/completions` |
| Device login | `openai-device` | `https://chatgpt.com/backend-api/codex/responses` |

`harness/credential/set` stores a credential under its `provider` slot. Device
refresh tokens and account identity use `openai-refresh` and `openai-account`;
they are not model credentials. Account headers are attached at dispatch only
for the ChatGPT route, including its model catalog. API and device model-list
requests use the same credential separation as inference. There is no fallback
between API and device credentials. A missing selected OpenAI credential stops
inference locally with an authentication error.

For already-stored device tokens in `openai`, a JWT-shaped token is eligible
only for device requests; it is never sent as an API key. Saving an API key
preserves that device token in its own slot. Shape recognition is compatibility
routing, not token validation; the provider still validates the credential.

`harness/status` for `provider: "openai"` returns `has-api-key`,
`has-device-login`, and a suggested `auth-method` (`api-key` or `device`) in
addition to `has-key`. The suggestion honors OpenAI defaults when configured,
otherwise prefers an available device login. An existing conversation retains
its explicit selection. React uses this status when selecting OpenAI from a
different provider, rather than resetting unconditionally to the API route.

Completing device login in the provider settings saves the credential and then
the selected conversation/default configuration. The login is not shown as
connected if saving that configuration fails. Existing incorrectly configured
conversations can select Device login in their model settings and save; no
transcript rewrite or automatic mass reconfiguration is performed.

Subscription and API-key authentication are separate access modes; see
[OpenAI authentication](https://learn.chatgpt.com/docs/auth). OpenAI device
credentials renew on the ship when a request arrives within five minutes of
expiry, including model-catalog and compaction requests. There is no browser
refresh loop or idle polling. Concurrent requests share one renewal; up to 64
credential-free requests can wait for at most 30 seconds. Cancellation removes
waiting work. A new login fences old responses, and rotated access/refresh tokens
are saved together. Temporary failures have a one-minute retry cooldown;
rejected credentials require a new login. Failures settle the waiting requests
and appear in the conversation or catalog, without exposing the token response.

An OpenAI device login should call `harness/credential/set` once with
`provider: "openai-device"`, `key`, `refreshToken`, and `account`. Empty optional
strings explicitly clear values from a previous login. Status also exposes
`auto-renew`, `renewing`, and a sanitized `renewal-error`, never token values.

## Shared web search and MCP discovery

`harness/credential/set` with `provider: "brave"` stores the Brave Search key;
an empty key removes it. `harness/status` with the same provider reports only
`has-key`. The React client exposes this under Settings → Search.

The `web_search` tool takes `query` and uses the existing `%web` capability.
It returns at most five titles, URLs and excerpts; `http_fetch` can read a result.
The endpoint is fixed, and only the ship supplies the subscription header.
Queries use the [Brave JSON POST API](https://api-dashboard.search.brave.com/api-reference/web/search/post),
so spaces, Unicode and query punctuation never pass through URL reconstruction.
Some Vere builds decode escaped query components before emitting the HTTP
request line; generic `http_fetch` remains subject to that runtime behavior.
Search results are untrusted reference material, not executable instructions.
The same tool is available through every hand; configuring a key grants no
additional permissions to an existing conversation or trusted Tlon user.

With `%mcp`, `list_mcp_servers` discovers enabled IDs and names without exposing
URLs or headers. The bot then uses `list_mcp_tools` and `call_mcp_tool` with those
IDs. Discovery reads the current registry on demand, so changing configuration
does not require rewriting system prompts or opening a new conversation.

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
