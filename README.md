# Urbit Agent Harness

Harness is an Urbit-native durable agent head and effect router. Conversations
are event logs owned by the ship; providers, tools, channels, peers, sandboxes,
and user interfaces are replaceable hands around the same sessions. Native
nouns are the internal contract, and ACP projects that contract to conventional
software—including the included React inspector.

The desk uses Grubbery as a compact application substrate. `%harness-grub`
provides its supervised process and effect services without installing a
pseudo-desktop or a second chat application. Authoritative sessions are
projected into `/agents/main/sessions` as typed grubs, keeping native consumers
independent of the React inspector.

```text
%harness desk
├── %harness             sessions, policy, providers, tools
├── %acp                 ordered multi-client ACP queues
├── %harness-grub        process and effect substrate
└── %harness-fileserver  React application
```

## What works

- Independent, durable conversations with replay, append-only cancellation,
  fork provenance, retry, compaction, timers, subagents, skills, and peer calls.
- OpenRouter, OpenAI, Anthropic, and custom OpenAI-compatible endpoints, with
  API keys, OpenAI device login, Anthropic browser-login handoff, and arbitrary
  request headers. ChatGPT login uses its Codex Responses endpoint.
- Provider model discovery, automatic published context limits, and free-form
  model entry; a conversation can change provider or model between turns.
- Durable global defaults snapshotted into new conversations, plus a shared
  Streamable HTTP MCP registry whose use remains capability-gated per thread.
- Typed input provenance across ACP, pokes, timers, webhooks, peers, and child
  sessions, with an explicit response route.
- Scryable derived views and chronological event histories for native clients.
- Execution-time capability checks in addition to provider-visible schemas.
- An ACP React inspector with optimistic message admission, live tool
  updates, rename/delete, responsive settings, and system/light/dark themes.
- A dependency-free ACP stdio adapter for editors and other local clients.
- Per-conversation tools for ship time, Clay, HTTP, skills, authored
  capabilities, subagents, and explicitly granted peers. New conversations
  begin with the full catalog enabled and can narrow it independently.

Native inference and a required Groups installation are outside this desk.
Either can be added behind a typed capability without changing session
ownership.

## Build and install

Mount or create a `%harness` desk, then assemble directly into it:

```sh
zig build -Ddesk=/path/to/pier/harness
```

Commit and install from Dojo:

```text
|commit %harness
|install our %harness
```

Open `/apps/harness`. Agent and provider configuration are tabs in Settings.

The build pins a Grubbery revision, builds the React application, assembles the
minimal runtime, renames its Gall process to `%harness-grub`, and overlays the
Harness code. `zig build clean` removes `zig-out`; `zig build clear` also
removes the dependency checkout.

## ACP adapter

```sh
SHIP_URL=http://localhost:8081 \
SHIP_CODE=your-ship-code \
node acp/harness-acp.mjs
```

The browser is one ACP client. Each client has an independent ordered queue
while all of them address the same on-ship session records. See
[`acp/README.md`](acp/README.md).

## Repository map

```text
build.zig                  reproducible desk assembly
desk/app/harness.hoon      event-sourced agent and ACP methods
desk/app/acp.hoon          durable duplex transport
desk/lib/harness.hoon      pure replay, decision, and provider encoding
desk/lib/root.hoon         minimal Grubbery service tree
fe/                        componentized React ACP client
acp/harness-acp.mjs        ACP stdio-to-Eyre adapter
docs-refs/                 design, protocol, and roadmap
```

- [`architecture.md`](docs-refs/architecture.md) explains ownership and
  boundaries.
- [`lightspeed-design.md`](docs-refs/lightspeed-design.md) records the design
  invariants.
- [`a2a-design.md`](docs-refs/a2a-design.md) develops identity and peer work.
- [`acp.md`](docs-refs/acp.md) defines the client boundary.
- [`integrations.md`](docs-refs/integrations.md) shows how editors, services,
  on-ship apps, webhooks, peers, timers, and MCP servers connect.
- [`roadmap.md`](docs-refs/roadmap.md) tracks completed and planned work.

The central design claim is that an Urbit event log makes a good long-lived
agent head: deterministic, inspectable, restartable, and independent of any
particular model or client.
