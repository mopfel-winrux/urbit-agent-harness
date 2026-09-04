# Roadmap

This document is both a capability ledger and the forward work list. Checked
items are present in the desk; unchecked items remain design commitments.

## Foundation

- [x] Event-sourced, replayable sessions with independent run state.
- [x] Prompt admission before provider completion.
- [x] Cancellation, retry, compaction, session fork, rename, and deletion.
- [x] Timers, supervised child sessions, staged skills, and peer asks.
- [x] Explicit per-session tool families, disabled by default.
- [x] OpenAI Chat Completions request and tool-call encoding.
- [x] OpenRouter, OpenAI, Anthropic, and custom endpoint presets.
- [x] Per-provider credentials, session overrides, and arbitrary headers.
- [x] Live provider model catalogs with manual model entry.
- [x] Minimal `%harness-grub` runtime with no bundled application suite.
- [x] ACP create/list/load/resume/close/delete/prompt/cancel and updates.
- [x] Durable per-client ACP queues with acknowledgement and reconnection.
- [x] React ACP client with componentized chat and tabbed settings.
- [x] Optimistic prompt display, responsive sidebar, and system theme.

## Near term

### Automated fake-ship conformance

- [ ] Build directly into a clean `%harness` desk and commit through Clay.
- [ ] Compile all four declared agents and fail on any Gall crash.
- [ ] Exercise two ACP connections without cross-delivery.
- [ ] Assert prompt admission latency separately from provider latency.
- [ ] Run simultaneous turns in two sessions and verify both transcripts.
- [ ] Cover create, rename, reconfigure, reconnect, cancel, and delete.

### Streaming

- [ ] Emit provider tokens as transient ACP updates.
- [ ] Commit only the terminal semantic message to the session log.
- [ ] Keep stable prompt prefixes suitable for provider caching.

### Authentication

- [ ] Add a provider-auth capability with an explicit token handoff contract.
- [ ] Support Anthropic's interactive local login where its access token can
  be safely transferred into ship-side provider state.
- [ ] Support OpenAI interactive login only when the provider documents a token
  suitable for API inference; do not treat a product-session token as an API
  key.
- [ ] Encrypt or externalize long-lived provider credentials.

### ACP completeness

- [ ] Run current ACP conformance fixtures against the stdio adapter.
- [ ] Map `session/request_permission` to explicit tool or weir grants.
- [ ] Add richer content blocks through addressed on-ship payloads.
- [ ] Define retention for abandoned but unacknowledged ACP queues.

## Grubbery capabilities

- [ ] Move more asynchronous hands into small supervised Grubbery processes.
- [ ] Give each hand a reviewable road/weir authority manifest.
- [ ] Persist crash evidence and surface it in the Harness UI.
- [ ] Make authored capabilities installable without enlarging `%harness`.
- [ ] Upstream generally useful runtime and MCP corrections.

## Context, provenance, and storage

- [ ] Search and selective recall across the retained event history.
- [ ] Record fork parent and divergence point, then share immutable history.
- [ ] Store images, archives, and large tool output as addressed payloads.
- [ ] Make indexes and summaries rebuildable from authoritative records.
- [ ] Measure loom use and long-session replay before fixing retention limits.

## Agent society and channels

- [x] Typed ship-to-ship asks with owner-selected grants.
- [ ] Harden replay, timeout, budget, and abuse controls for peer work.
- [ ] Add optional Messenger or channel adapters over ACP or narrow typed ports.
- [ ] Keep Urbit identity authoritative rather than depending on a social desk.
- [ ] Support hosted executors and local devices as capability-bearing hands.

## UX and operations

- [ ] Add a deliberate “fork here” action with visible provenance.
- [ ] Show compaction, token usage, provider latency, and tool timing.
- [ ] Add an in-app connection diagnostic and reconnect control.
- [ ] Cache provider catalogs with a user-visible refresh action.
- [ ] Verify keyboard navigation, narrow mobile layouts, and screen-reader names.

## Non-goals

- Bundling native inference into this desk.
- Requiring the Groups desk.
- Shipping the Grubbery desktop or example applications.
- Granting ACP clients ambient terminal or host-filesystem access.
- Hiding provider or authority choices inside an opaque agent loop.
