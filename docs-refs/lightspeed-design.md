# Harness design

Harness should feel immediate even when inference is not. That begins with a
strict separation between admission latency and completion latency.

## Deterministic head

The session event log is authoritative. Input is admitted and shown to every
client before the provider request finishes. Provider and tool results carry
request identities, so cancellation and late responses cannot corrupt a newer
turn. Replay reconstructs the view without consulting an off-ship database.

The pure loop is:

```text
event log -> replay -> decide -> explicit effects -> new events
```

This keeps provider peculiarities, network stalls, and client lifetimes out of
session ownership.

The [urbit-agent design notes](https://github.com/lukebuehler/urbit-agent/blob/main/harness-design-notes.md)
make the useful distinction between a small durable head and replaceable
hands. Harness adopts that direction: native nouns first, deterministic replay,
immutable branches, explicit authority, and expensive work outside the head.
Grubbery supplies process supervision and a capability namespace, not another
workflow engine. The effect protocol and supervised session nexus remain work
to complete; see the roadmap rather than treating these as finished properties.

## Concurrent hands

Gall remains responsive while Iris, timers, subagents, tools, and peers do
work. Sessions do not share a run lock. A tool turn may have several in-flight
calls and settle only when its recorded wait set is empty.

The UI reflects this model:

- a submitted message appears immediately with reduced opacity;
- an admission receipt maps its local submission identity to the durable input
  identity, so the canonical event replaces the optimistic message exactly;
- thinking does not disable navigation or other conversations;
- transport errors are visible and the ACP client reopens its durable queue;
- hidden tabs reduce polling without suspending on-ship work.

## Context

The full record is retained while provider input is bounded. Stable system
instructions and tool schemas should lead requests; recent transcript,
recalled context, and tool results follow. Compaction is an explicit model
effect recorded in the log, not silent deletion.

Large binary payloads should live in addressed storage with stable transcript
references. Indexes and summaries are rebuildable projections, never the sole
copy of user meaning.

## Authority

Owner-created interactive conversations receive the tool catalog through an
explicit default grant and can narrow it per session. Scheduled, delegated,
and remote work receive purpose-built grants; absence of a grant denies
execution. Grubbery roads and weirs are the intended substrate for
making future hands independently supervised and narrowly authorized.

Authored skills are staged and rehearsed before promotion. Remote asks carry a
ship identity and land under an owner-selected grant. ACP clients receive chat
control but no implied shell or host-filesystem authority.

## Clients

Conventional clients use ACP; native apps can use typed pokes, watches, scries,
and pure Hoon gates directly. The browser, an editor, or a messaging adapter can
disconnect without changing the session. Each ACP client has its own ordered
delivery queue, while the head owns one transcript and run state per session.
No interface is the primary owner of an agent's work.

Provider, model, and instruction changes are themselves session events and
take effect on the next turn. A catalog is convenience; the model field always
accepts a manually entered identifier.

## Operational target

Desk validation should measure three separate things:

1. prompt admission time;
2. first durable assistant update;
3. terminal request completion.

It should also run two sessions concurrently, reconnect a client with queued
frames, compile every declared agent, and inspect Gall for crashes. See
[`roadmap.md`](roadmap.md) for work still to land.
