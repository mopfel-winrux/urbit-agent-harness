# Roadmap

This is both a capability ledger and the forward work list. A checked item is
part of the pinned Grubbery substrate or this distribution; unchecked details
remain requirements even when the implementation shape evolves.

## Foundation

- [x] Durable multi-chat agent state with interrupt and restart support.
- [x] Complete retained transcripts with a token-bounded model window.
- [x] Full-history search, selective recall, and targeted summarization.
- [x] Anthropic and OpenRouter proxy applications with shared credentials,
  usage state, and prompt-cache-aware requests.
- [x] Inspectable namespace/tree and ball APIs.
- [x] Isolated child-agent tasks with durable completion output.
- [x] Runtime-authored, compiled Hoon tools and application nexuses.
- [x] Cron-style prompts and autonomous scheduled assistants.
- [x] Optional channel nexuses with narrow inbox/send contracts.
- [x] ACP initialize, session create/list/load/replay/resume/close/delete,
  prompt, cancel, message updates, and tool updates over the same durable native
  chats used by the UI.

## Near term

### 1. Conformance tests

Automate the fake-ship checks used during development: build and commit a desk
named `%grubbery`, verify `/apps/harness.harness`, create and load an ACP chat,
and assert that no descendant has a crash `bang`. Advancing the pinned Grubbery
revision should require this suite.

### 2. Streaming

Provider tokens should reach interactive clients before the terminal message is
committed. Use a transient Grubbery signal or SSE path for partials; retain only
terminal results in chat history. Verify that token streaming does not perturb
prompt-cache-stable prefixes.

### 3. ACP conformance and permissions

Exercise the adapter against current ACP fixtures and real clients. Add
`session/request_permission` when it can map cleanly to a weir or an explicit
approval grub. Support richer prompt content using addressed payload grubs.
Keep filesystem and terminal authority behind agent tools rather than granting
it implicitly to every client.

### 4. Parameterized app identity

The reusable agent app hardcodes its tile name and route. Parameterize that
metadata in Grubbery so this distribution can present “Harness” without
shadowing the full app nexus.

### 5. Harness policy pack

Ship a small, reviewable set of context documents and weirs: prefer native ship
state, inspect before acting, preserve full history, make authority explicit,
and use peers without centralizing their data. Policy should remain ordinary
files rather than branches in the agent loop.

## Governed self-modification

Compilation alone is not promotion. Add a workflow that stages an authored
tool or nexus, runs a representative task in an isolated child, records tests
and output, and asks for approval before widening its weir or moving it into a
shared catalog. A failed rehearsal must leave the live capability unchanged.

Forced tool choice is also useful: allow a task or policy to require a named
tool when an answer must be verified rather than produced from model memory.

## Agent society and channels

Build addressed agent-to-agent requests on Grubbery ports and explicit
usergroups. A remote ask should carry an Urbit identity, land in a sandboxed
child, and receive a model, token budget, skills view, and capability grant
chosen by the owner. No grant means refusal.

A Tlon Messenger adapter can then be a channel over the same contracts. It
must not become a mandatory desk dependency or substitute a social
application's identity model for Urbit identity.

## Forks and provenance

Add an intentional “fork here” operation to the chat UI and APIs. A fork should
record its parent and point of divergence. Prefer structural sharing or
content-addressed transcript segments when available; do not duplicate large
histories just to simulate branching.

## Payloads and storage

Keep images, archives, and large tool results out of prompt history. Store them
as addressed grubs and place stable references in transcripts. Align retention
and garbage collection with vere64/blob facilities as their contracts settle.
Measure loom and long-session performance before choosing thresholds.

## Remote hands and key hygiene

A hosted executor, a laptop, and another ship should look like interchangeable
capability-bearing processes. Use typed ports or a dedicated Vere driver for
that seam. Provider keys should ultimately stay on the executing side and out
of broadly readable agent state.

## Operational work

- Verify prompt-cache hits and costs across long sessions.
- Exercise a second provider on identical tool transcripts.
- Keep crash `bang` inspection in the ship commit/install loop.
- Track MCP transport failures separately from Gall and Grubbery failures.
- Report generally useful MCP and Grubbery fixes upstream.

## Non-goals

- Bundling native inference in this distribution.
- Requiring the Groups desk.
- Maintaining a downstream copy of the full agent implementation.
- Adding integrations to the root harness when they can be optional grubs.
