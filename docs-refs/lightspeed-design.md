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

## Concurrent hands

Gall remains responsive while Iris, timers, subagents, tools, and peers do
work. Sessions do not share a run lock. A tool turn may have several in-flight
calls and settle only when its recorded wait set is empty.

The UI reflects this model:

- a submitted message appears immediately with reduced opacity;
- its local submission identity clears it only when that request settles, with
  the durable user event replacing it as soon as admitted;
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

Capabilities are absent by default. Enabling a tool family is a deliberate
conversation setting. Grubbery roads and weirs are the intended substrate for
making future hands independently supervised and narrowly authorized.

Authored skills are staged and rehearsed before promotion. Remote asks carry a
ship identity and land under an owner-selected grant. ACP clients receive chat
control but no implied shell or host-filesystem authority.

## Clients

All clients use ACP. The browser, an editor, or a future messaging adapter can
disconnect without changing the session. Each has its own ordered delivery
queue, while `%harness` owns one transcript and one run state per conversation.

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
