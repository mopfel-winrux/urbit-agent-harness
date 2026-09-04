# Architecture: a harness as a Grubbery application

The harness is a small distribution layer over Grubbery. It pins a complete
runtime and seeds `/apps/harness.harness` as an instance of its reusable agent
nexus.

The key choice is composition. Grubbery's agent nexuses already provide the
agent mechanics this project needs, so this repository owns policy, ACP edge
integration, design documents, and conformance tests rather than a copy of the
agent loop.

## Names and locations

- `harness.harness` is this distribution's installed instance and durable ball
  path.
- `%grubbery` is the Gall runtime and required Clay desk name.

The runtime tree is:

```text
%grubbery
└── /apps/harness.harness
    ├── /agents/main
    │   ├── /chats/<name>
    │   ├── /context
    │   ├── /children
    │   ├── /apps/code
    │   └── /proc
    ├── /apis
    ├── /channels
    └── /assistants
```

Each stateful file or directory can be a supervised process. The namespace is
both durable state and a legible API.

## Grubbery mechanics

A nexus declares its directory through `on-load`. `%fall` entries are seeded
only when the owner has not already supplied a value; they are appropriate for
durable user state such as chats and configuration. `%over` entries remain
owned by the nexus code and are appropriate for shipped assets and derived
interfaces. This distinction lets upgrades refresh application material
without replacing the user's record.

Record grubs and caches remain separate siblings. A chat transcript,
configuration file, or assistant output is a system of record. Search indexes,
status summaries, and UI manifests may be rebuilt from those records. A cache
must never be the only location of information needed to resume a process.

Fibers describe asynchronous effect programs. Darts cross the runtime boundary
for HTTP, timers, Clay, cross-app calls, and other effects; roads identify
resources and weirs constrain which roads a process may reach. Each Arrow is a
transaction: failure annuls that invocation's state and effects, while earlier
successful work remains committed. A crashed fiber therefore leaves an
inspectable `bang` at its grub rather than half-applying its current step.

## Harness invariants

| Goal | Grubbery realization |
|---|---|
| deterministic head | file/nexus processes whose state is a typed noun |
| asynchronous hands | Fiber programs yielding typed Darts to system services |
| durable history | complete per-chat transcript plus materialized state files |
| non-blocking loop | API and tool work in supervised child fibers |
| inspectability | namespace peeks, typed files, manifests, status, and crash `bang`s |
| least authority | path-local weirs and explicit tool installation |
| subagents | child agent nexuses with durable outboxes and completion status |
| self-modification | authored source under `apps/code`, compiled into grubs |
| timers | schedule processes and autonomous assistant fibers |
| providers | shared API proxy nexuses with credentials, rates, and usage |
| channels | narrow, optional inbox/send processes |
| browser and ACP clients | authenticated ball API over the same record grubs |
| on-ship consumers | thin `%grub-client` Gall surface and materialized subscriptions |
| cross-ship ingress | typed `/port` endpoints with explicit Urbit identity |

Supervision and replay belong to the parent/child process tree. Local processes
have independent lifecycles and failure domains, while source, state, effects,
and crash reports remain visible in one durable namespace.

## Context and memory

The full conversation stays on the ship while only a token-bounded sliding
window is sent to a provider. The agent can search all history, recall selected
ranges into context, and summarize targeted ranges. Forgetting is therefore an
explicit, inspectable context choice rather than destructive data loss.

Prompts, reference documents, and memories are separate files under
`/context`. This keeps policy reviewable and permits updates without branching
the agent loop.

## Agents and assistants

Chats, agents, child tasks, assistants, and channels are directories with
narrow contracts. A new assistant does not require another Gall app or another
runtime copy. Child agents run in their own subtree and publish durable output,
which makes delegation observable and limits the blast radius of failure.

## Tools and self-modification

Tools can be small Hoon programs compiled beneath an agent. Longer-lived
capabilities can be nexuses with their own files and workers. Both inherit a
weir and leave durable state.

Compilation is not promotion. A governed workflow should test authored code in
an isolated child, record the evidence, and require approval before widening a
weir or sharing the capability with other agents.

## Providers and hands

Provider credentials, model metadata, rate information, and accounting live in
API proxy applications rather than sessions. An agent names a proxy. The same
boundary can target a local service, a hosted executor, or another ship without
changing chat ownership.

This distribution does not bundle native inference or an embedded JavaScript
runtime. Both can be optional hands behind typed interfaces if they become
useful; neither belongs in the durable head.

## Channels and identity

Channels are optional adapters with narrow inbox/send contracts. The harness
does not depend on the Groups desk. Messenger, Telegram, ACP, or another client
may deliver messages without becoming the owner of the conversation.

Remote agent-to-agent work is distinct from client messaging. It should use
Urbit identity, addressed ports, explicit usergroups, and a sandboxed child
whose budget and capabilities are chosen by the owner.

## ACP boundary

ACP is edge transport. The adapter authenticates to the local ship and maps
ACP sessions onto durable chat directories. It reads and pokes the same files
as the browser UI, so there is exactly one transcript and one run state.

The adapter is replaceable and may crash without becoming the system of
record. Filesystem and terminal authority stays behind governed agent tools and
weirs rather than being granted implicitly to an ACP client.

## Integration surfaces

The React UI and ACP adapter use authenticated ball reads, subscriptions, and
pokes because they run at the HTTP edge. They are projections over the same
record grubs, so neither owns a transcript or a competing run queue.

On-ship applications should prefer the thin `%grub-client` Gall surface when
they need conventional pokes, subscriptions, or lifecycle acknowledgements.
Cross-ship protocols should use typed `/port` ingress so the source ship stays
part of the request and authorization decision. These are complementary
transports over one process tree, not separate application models.

## Trust boundaries

The root `/apps` tier is trusted distribution code. Agent-authored code belongs
under its agent and receives only roads permitted by its weir. Provider secrets
belong to API proxy state. Optional channels reduce an external identity to a
message in and a response out; they do not silently inherit the agent's full
capabilities.

## Upgrade discipline

1. Advance the Grubbery commit in `build.zig`.
2. Diff upstream `desk/lib/root.hoon` against this overlay and retain only the
   harness seed as a local policy change.
3. Assemble to a mounted `%grubbery` desk.
4. Commit through the ship so Ford reports Hoon build errors.
5. Install or revive `%grubbery`, verify `/apps/harness.harness`, create an ACP
   chat, and inspect the process tree for `bang`s.

The literal desk name matters because Grubbery's mark bootstrap scries Clay at
`%grubbery`. Tests should guard this operational invariant.
