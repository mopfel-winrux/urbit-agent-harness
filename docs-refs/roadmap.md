# Roadmap

This document is both a capability ledger and the forward work list. Checked
items are present in the desk; unchecked items remain design commitments.

## Priority: a small head, replaceable hands

The unit of the system is a durable session, not a chat window. A native app,
an editor, a scheduled task, and the React inspector must address the same
head without owning its execution. Prioritize these boundaries over expanding
the bundled interface:

1. Make replay, inspection, branching, and decision pure reusable gates;
   test them independently of transport. This pass adds `harness-session`.
2. Turn the declared effect intent/receipt nouns into the actual dispatch
   contract, including identity, authority, cancellation, and late receipts.
   Provider parsing and expensive transformations should be replaceable hands.
3. Wrap that contract in a supervised Grubbery session nexus and effect runs.
   Compare replay and emitted intents before changing session ownership; a
   namespace mirror alone is not process supervision.
4. Put skills, policies, and tool bundles in versioned namespace files, with
   narrow road/weir manifests. Adding a hand should not enlarge the head.
5. Use addressed payloads for large artifacts and externalize secrets where
   possible. Keep presentation traffic out of the durable semantic log—and
   eventually out of Arvo entirely when it need not be an on-ship fact.

Keep the rest of this ledger: these priorities order the work, not erase it.

## Foundation

- [x] Event-sourced, replayable sessions with independent run state.
- [x] Prompt admission before provider completion.
- [x] Append-only cancellation, retry, compaction, session fork provenance,
  rename, and deletion.
- [x] Timers, supervised child sessions, staged skills, and peer asks.
- [x] Explicit per-session tool families, enabled for new conversations and
  independently configurable thereafter.
- [x] Enforce tool families at execution, including internal self-pokes.
- [x] Admit ACP, poke, timer, webhook, peer, and child input with durable source,
  actor, reply-target, timestamp, and input identity.
- [x] Expose chronological event history and derived session views by scry.
- [x] Pure session inspection, revisioned full transcripts, and event-addressed
  branches shared by native and ACP clients.
- [x] Keep client detach separate from session cancellation; settle the owning
  prompt when any authorized client cancels.
- [x] Define transport-independent payload references and effect
  intent/receipt nouns.
- [x] OpenAI Chat Completions request and tool-call encoding.
- [x] ChatGPT Codex Responses request and SSE result encoding.
- [x] OpenRouter, OpenAI, Anthropic, and custom endpoint presets.
- [x] Per-provider credentials, session overrides, and arbitrary headers.
- [x] Live provider model catalogs with manual model entry and automatic
  context limits when providers publish them.
- [x] Durable agent defaults for provider, model, endpoint, context,
  instructions, headers, and tool grants.
- [x] Global stateless Streamable HTTP MCP registry with per-conversation
  grants, lazy tool discovery, and generic calls.
- [x] Minimal `%harness-grub` runtime with no bundled application suite.
- [x] ACP create/list/load/resume/close/delete/prompt/cancel and updates.
- [x] Durable per-client ACP queues with acknowledgement and reconnection.
- [x] React ACP client with componentized chat and tabbed settings.
- [x] Optimistic prompt display, responsive sidebar, and system theme.

## Near term

### Automated fake-ship conformance

- [ ] Assemble and install into a clean `%harness` desk through Clay.
- [ ] Compile all four declared agents and fail on any Gall crash.
- [x] Exercise two ACP connections without cross-delivery.
- [x] Assert prompt admission latency separately from provider latency.
- [x] Run simultaneous turns in two sessions and verify both transcripts.
- [x] Check admission identity, detach/resume, native/ACP snapshot parity,
  branch provenance, parent isolation, and cross-client cancellation.
- [x] Pure Hoon tests for transcript retention, branch boundaries, and partial
  provider responses; client tests for lost acknowledgements and recovery.
- [ ] Cover create, rename, reconfigure, reconnect, cancel, and delete.

`scripts/conformance.mjs` uses ship-configured inference, creates uniquely named
test sessions, and deletes only those sessions. It is not yet a full install or
ACP specification-conformance suite.

### Streaming

- [x] Show an immediate thinking state and relay incremental provider text as
  presentation-only ACP updates when Iris supplies response progress.
- [x] Commit only the terminal semantic message to the session log.
- [ ] Make incremental HTTP delivery consistent across provider and runtime
  combinations that currently return one completed body.
- [ ] Provide an executor-to-client presentation stream: current chunks still
  cross Arvo and durable ACP queues even though they are not session events.
- [ ] Keep stable prompt prefixes suitable for provider caching.

### Authentication

- [x] Add a provider-auth capability with an explicit token handoff contract.
- [x] Support Anthropic browser login through `claude setup-token` or imported
  CLI credential JSON, transferred directly into ship-side provider state.
- [x] Support OpenAI device login and route its product token only to the
  ChatGPT Codex Responses endpoint.
- [ ] Refresh expiring OpenAI and Anthropic OAuth credentials on ship.
- [ ] Encrypt or externalize long-lived provider credentials.

### ACP completeness

- [ ] Run current ACP conformance fixtures against the stdio adapter.
- [ ] Map `session/request_permission` to explicit tool or weir grants.
- [ ] Add richer content blocks through addressed on-ship payloads.
- [ ] Define retention for abandoned but unacknowledged ACP queues.

### MCP hands

- [ ] Add sessionful Streamable HTTP initialization and session-id handling.
- [ ] Consume server notifications and resumable event streams.
- [ ] Add an MCP OAuth acquisition and refresh hand without exposing tokens to
  conversation transcripts.

## Grubbery capabilities

- [x] Mirror each authoritative session as a typed grub under
  `/agents/main/sessions` through the thin client boundary.
- [ ] Add a Harness session nexus that wraps the pure reducer, then shadow-run
  it against `%harness` until replay and emitted-effect conformance is exact.
- [ ] Represent each open effect as a supervised `/runs/<id>` grub with durable
  intent, progress, receipt, and crash evidence.
- [ ] Move skills, policies, prompts, and tool bundles into versioned namespace
  files rather than agent maps.
- [ ] Move more asynchronous hands into small supervised Grubbery processes.
- [ ] Give each hand a reviewable road/weir authority manifest.
- [ ] Persist crash evidence and surface it in the Harness UI.
- [ ] Make authored capabilities installable without enlarging `%harness`.
- [ ] Upstream generally useful runtime and MCP corrections.

## Context, provenance, and storage

- [ ] Emit the generic effect intent/receipt protocol for every provider, tool,
  peer, and executor boundary.
- [ ] Search and selective recall across the retained event history.
- [x] Record fork parent and divergence point without rewriting the child log.
- [x] Share an immutable noun tail when branching at a completed reply;
  no serialization or re-execution of earlier effects.
- [ ] Store images, archives, and large tool output as addressed payloads.
- [ ] Make indexes and summaries rebuildable from authoritative records.
- [ ] Measure loom use and long-session replay before fixing retention limits.
- [ ] Page large transcripts and cache revision-derived projections; reduce
  durable transport traffic from idle inspectors without giving clients ownership.

## Agent society and channels

- [x] Typed ship-to-ship asks with owner-selected grants.
- [ ] Harden replay, timeout, budget, and abuse controls for peer work.
- [ ] Add optional Messenger or channel adapters over ACP or narrow typed ports.
- [ ] Keep Urbit identity authoritative rather than depending on a social desk.
- [ ] Support hosted executors and local devices as capability-bearing hands.

## UX and operations

- [ ] Eliminate stale watch and Grubbery blit messages on runtime reload;
  verify a clean install separately from the working development ship.
- [x] Add a deliberate “fork here” action with visible provenance.
- [x] Show compaction state, cumulative token usage, and structured tool results.
- [ ] Show provider latency and tool timing.
- [ ] Add an in-app connection diagnostic and reconnect control.
- [ ] Cache provider catalogs with a user-visible refresh action.
- [ ] Verify keyboard navigation, narrow mobile layouts, and screen-reader names.

## Non-goals

- Bundling native inference into this desk.
- Requiring the Groups desk.
- Shipping the Grubbery desktop or example applications.
- Granting ACP clients ambient terminal or host-filesystem access.
- Hiding provider or authority choices inside an opaque agent loop.
