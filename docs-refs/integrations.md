# Connecting systems to Harness

Harness is a ship-resident agent substrate, not a browser backend. External
systems submit work through a narrow boundary; the resulting inputs, tool
effects, and answers belong to the same durable session records regardless of
which interface is present later.

## Choose a boundary

| Need | Boundary | What it provides |
|---|---|---|
| Interactive agent client, editor, or service | ACP | Sessions, replay, prompts, cancellation, configuration, and live updates |
| Small HTTP producer | Webhook | Fast admission of a text prompt into a named session |
| Another app on the same ship | Gall poke, watch, and scry | Typed nouns with no JSON or HTTP dependency |
| Scheduled work | `%timer-set` action | A durable Behn wakeup that admits a prompt later |
| Another Urbit | `%harness-a2a-0` | Typed asks tied to ship identity and an explicit peer grant |
| Remote tool service | MCP | Global endpoint registry plus per-conversation capability grant |

ACP is the broad client boundary. Prefer a smaller typed boundary when the
caller needs only one operation.

## ACP over authenticated Eyre

Each client opens a unique connection in `%acp`, sends JSON-RPC frames to its
agent queue, and polls its client queue. Frames have monotonically increasing
sequence numbers and are acknowledged cumulatively. A client reconnecting to
the same identifier resumes its unacknowledged queue; a new page should choose
a fresh identifier.

The browser uses these endpoints:

```text
PUT /~/channel/<channel>                         poke %acp with %acp-action-1
GET /~/scry/acp/v1/<connection>/client.json     read outbound frames
```

Use `Cache-Control: no-cache` or a query nonce for polls. The poke actions are
`open`, `send`, `ack`, and `close`; see `desk/sur/acp.hoon` for their exact noun
shape. Initialize the JSON-RPC connection before invoking session methods.

For editors and command-line integrations, the dependency-free adapter exposes
the same connection as NDJSON:

```sh
SHIP_URL=http://localhost:8081 \
SHIP_CODE=your-ship-code \
ACP_CONNECTION=my-editor \
node acp/harness-acp.mjs
```

Its stdin and stdout carry only ACP frames. Use a distinct
`ACP_CONNECTION` for each simultaneously running client.

Harness extensions include:

```text
harness/defaults
harness/defaults/configure
harness/mcp/servers
harness/mcp/configure
harness/status
harness/tools
harness/session/config
harness/session/configure
harness/session/rename
harness/credential/set
harness/provider/models
```

`session/prompt` returns after the admitted turn reaches a terminal state.
Observe `session/update` notifications for the admitted user item, tool
progress, and answer. Admission is durable before provider inference begins.

## Native Gall integration

Poke `%harness` with mark `%harness-action` and an `action` from
`desk/sur/harness.hoon`. `%noun` accepts the same noun for convenient Dojo and
development use. A native client can then:

- watch `/session/<session-id>` for `%harness-update` facts;
- scry `/x/sessions` for session ids;
- scry `/x/session/<session-id>` for a derived view;
- scry `/x/events/<session-id>` for chronological events.

HTTP projections of those scries are available at:

```text
/~/scry/harness/sessions.json
/~/scry/harness/session/<session-id>.json
/~/scry/harness/events/<session-id>.json
/~/scry/harness/defaults.json
/~/scry/harness/mcp.json
```

The typed action surface includes creation, prompt admission, fork, compact,
cancel, retry, configuration, timers, skills, peer grants, global defaults,
and MCP configuration. Native callers should depend on these nouns rather than
the React component state.

## Webhooks

`POST /harness-api/webhook/<session-id>` with JSON `{"text":"..."}` admits a
prompt and returns `{"ok":true}`. It does not wait for or return the model
answer; consume the session through ACP, a watch, or a scry.

The webhook is an ingress primitive, not a public authentication scheme. Keep
it behind an authenticated reverse proxy, private network, or a purpose-built
channel adapter when exposing the ship beyond a trusted host.

## MCP client configuration

Settings → MCP stores a global registry of stateless Streamable HTTP servers.
Each entry has a stable id, display name, URL, enabled flag, and endpoint-bound
headers. Conversations granted the `mcp` tool family receive two generic
functions:

- `list_mcp_tools(server)` sends JSON-RPC `tools/list`;
- `call_mcp_tool(server, name, arguments)` sends JSON-RPC `tools/call`.

The model discovers a server's current schema only when needed, keeping remote
tool catalogs out of every prompt. Headers are sent only to the configured URL.
MCP results return through Iris and become ordinary tool-result events. The
current hand targets stateless endpoints; session negotiation, server-sent
notifications, and OAuth acquisition are separate optional hands.

## Properties integrations can rely on

- **Durability:** the event transcript is authoritative and survives client
  disconnects and agent reloads.
- **Independent progress:** provider and remote-tool requests are asynchronous;
  one waiting session does not serialize another.
- **Replayable meaning:** views are derived from a closed event vocabulary.
- **Explicit authority:** provider schemas and configured MCP endpoints are
  discovery; execution still checks the conversation's tool-family grant.
- **Provenance:** admitted inputs carry identity, source, timestamp, and reply
  route; forks record their divergence point.
- **Replaceable hands:** ACP, React, providers, MCP, timers, peers, and native
  apps surround the same session head rather than owning it.
- **Global policy, local divergence:** new conversations snapshot agent defaults;
  subsequent per-conversation model, context, instructions, and tool changes are
  recorded independently.

This split is the extension rule: add a small adapter or supervised hand, admit
typed facts, and leave session ownership in Harness.
