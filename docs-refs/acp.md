# ACP boundary

ACP is the harness's editor/client boundary. It should expose an Urbit-native
agent without forcing the durable agent to adopt an editor's lifecycle or
duplicating its state in a protocol-specific Gall core.

The adapter maps ACP straight onto the harness instance's native grubs. A
generic durable frame queue would add a second ownership boundary around state
that already has stable, authenticated paths:

| ACP concept | Grubbery representation |
|---|---|
| session | `/apps/harness.harness/agents/main/chats/<id>/` |
| transcript | `chat.json` |
| run state | `status.json` (`idle`, `api`, or `tool`) |
| new session | JSON poke to the agent's `main.sig` |
| list/resume | durable chat manifest and chat directories |
| load | transcript replay as ordered `session/update` notifications |
| close | interrupt active work and retain the chat |
| delete | interrupt active work and remove the chat |
| prompt | JSON poke to the chat's `chat.json` |
| cancel | `interrupt` poke to the same chat |
| message/tool update | newly materialized transcript entry |

This preserves the important properties:

- Chat IDs and full transcripts survive adapter and ship restarts.
- The browser UI, ACP clients, schedules, and channels all address the same
  conversation process.
- Provider keys and tool authority remain behind Grubbery proxies and weirs.
- The adapter is replaceable edge code. It can crash without becoming the
  system of record.

## Supported protocol surface

The dependency-free Node adapter implements this version-1 surface:

- `initialize`
- `session/new`
- `session/list`
- `session/load`
- `session/resume`
- `session/close`
- `session/delete`
- `session/prompt`
- `session/cancel`
- `session/update` notifications for assistant messages, tool calls, and tool
  results

Text prompt blocks are concatenated. Resource links are admitted as explicit
textual references. Images, audio, embedded context, client-side MCP servers,
filesystem methods, and terminal methods are not advertised.

The model response itself is currently materialized at message granularity.
Tool progress is visible whenever the durable transcript changes. True token
streaming should eventually be a transient Grubbery signal; only terminal
messages belong in durable chat history.

## Why there is no mandatory ACP queue

Durable opaque queues are useful when an off-ship worker must disconnect and
later resume delivery. A stdio ACP client already owns one live transport, and
Grubbery owns the durable session, transcript, and effects. Keeping an extra
queue in this distribution provided no recovery that the client could use
without also reconstructing in-flight JSON-RPC state.

If a future remote ACP gateway needs store-and-forward delivery, it should be a
separate Grubbery nexus or channel with explicit retention and identity policy,
not mandatory machinery in every harness installation.
