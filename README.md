# Urbit Agent Harness

A durable personal-agent harness built as a small
[Grubbery](https://github.com/gwbtc/grubbery) application.

The repository pins Grubbery and seeds `/apps/harness.harness` from its
reusable agent nexus. Grubbery supplies the agent loop, process tree,
capability model, and effects; this project adds harness policy, a focused web
interface, ACP integration, and design guidance.

```text
%grubbery
└── /apps/harness.harness
    ├── /agents/main
    │   ├── /chats/<name>       durable conversations
    │   ├── /context            prompts, documents, memories
    │   ├── /children           isolated delegated work
    │   ├── /apps/code          agent-authored capabilities
    │   └── /proc               transient workers
    ├── /apis                   provider proxies and accounting
    ├── /channels               optional messaging adapters
    └── /assistants             scheduled autonomous programs
```

The tree is both state and API. Fibers perform asynchronous work, Darts carry
effects, and weirs constrain authority by path. A failed process leaves an
inspectable `bang` in its own subtree.

## Capabilities

- Multiple chats with complete retained transcripts, bounded model context,
  history search, selective recall, summarization, interrupt, and reload.
- Anthropic and OpenRouter proxies with shared credentials and usage data.
- Sandboxed child agents, authored Hoon tools and apps, scheduled prompts, and
  autonomous assistants.
- Optional channel nexuses behind narrow inbox/send contracts.
- React conversations and configuration at `/apps/harness`.
- ACP v1 sessions mapped directly onto native chats, including discovery,
  replay, resume, close, deletion, prompts, tool updates, and cancellation.
- `%grub-client`, generic ball APIs, and typed `/port` ingress for other
  on-ship and cross-ship consumers.

Native inference and a required Groups desk are deliberately outside the
harness. Either can be connected behind a typed capability without changing
chat ownership.

## Build

Grubbery currently bootstraps marks from a Clay desk named `%grubbery`, so use
that literal desk name:

```text
|new-desk %grubbery
|mount %grubbery
```

Assemble and copy the desk:

```sh
zig build -Ddesk=/path/to/pier/grubbery
```

Then commit and install it in Dojo:

```text
|commit %grubbery
|install our %grubbery
```

Open `/apps/harness`. Agent and provider configuration live together under its
Settings tabs.

`zig build` writes to `zig-out/`, `zig build clean` removes that output, and
`zig build clear` also removes the pinned Grubbery checkout.

## ACP

The dependency-free adapter is an edge projection over the same durable chats
used by the browser and channels:

```sh
SHIP_URL=http://localhost:8081 \
SHIP_CODE=your-ship-code \
node acp/harness-acp.mjs
```

`HARNESS_BALL` and `HARNESS_AGENT` select another instance or agent. See
[`acp/README.md`](acp/README.md) for client setup and protocol details.

## Repository

```text
build.zig                       reproducible desk assembly
desk/lib/root.hoon              harness instance seed
desk/app/harness-fileserver.hoon authenticated SPA server
fe/                             React interface
acp/harness-acp.mjs             ACP stdio adapter
docs-refs/                      architecture, rationale, and roadmap
```

- [`architecture.md`](docs-refs/architecture.md) defines the process, state,
  and trust boundaries.
- [`lightspeed-design.md`](docs-refs/lightspeed-design.md) records the durable
  harness invariants.
- [`a2a-design.md`](docs-refs/a2a-design.md) develops identity and agent
  society.
- [`acp.md`](docs-refs/acp.md) defines the ACP boundary.
- [`roadmap.md`](docs-refs/roadmap.md) tracks present capabilities and focused
  remaining work.

The central design claim is simple: Urbit's deterministic event log, explicit
effects, durable state, and structural sharing are unusually good foundations
for a long-lived personal agent. Grubbery gives those properties a small,
composable application model.
