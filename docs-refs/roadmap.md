# Roadmap

This document is both a capability ledger and the forward work list. Checked
items are present in the desk; unchecked items remain design commitments.

## Priority: a small head, replaceable hands

The unit of the system is a durable session, not a chat window. A native app,
an editor, a scheduled task, and the React inspector must address the same
head without owning its execution. Prioritize these boundaries over expanding
the bundled interface:

1. Make replay, inspection, branching, and decision pure reusable gates;
   test them independently of transport (`harness-session`).
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
- [x] Generic conversation bindings, actor allowlists, deduplicated durable
  observations, and serial per-session admission through native nouns and ACP.
- [x] Independent publication outbox, exclusive claims, idempotent receipts,
  and explicit reconciliation of uncertain delivery without rerunning inference.
- [x] Fair per-binding/per-session admission, fenced owner recovery and explicit
  abandonment, paged hand exports, and archive-before-retirement tooling.
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

- [x] Assemble and install into a clean `%harness` desk through Clay; verify all
  five agents boot, all Harness Hoon tests pass, and native/ACP cancellation and
  supervised-verifier reload/recovery work without development-mount leftovers.
- [x] Check assembled agent imports, agent inventory, test isolation, and the
  dynamic marks needed by compiler bootstrap and noun-grub exchange.
- [ ] Automate cold installation and Gall crash detection end to end; current
  artifact and live checks run after explicit owner installation.
- [x] Exercise two ACP connections without cross-delivery.
- [x] Assert prompt admission latency separately from provider latency.
- [x] Run simultaneous turns in two sessions and verify both transcripts.
- [x] Check admission identity, detach/resume, native/ACP snapshot parity,
  branch provenance, parent isolation, and cross-client cancellation.
- [x] Interrupt in-flight tools, preserve completed siblings, settle ACP tool
  updates, and immediately continue without duplicate execution or late-result
  revival; verify cancellation labels and Stop-to-send behavior in the UI.
- [x] Pure Hoon tests for transcript retention, branch boundaries, and partial
  provider responses; client tests for lost acknowledgements and recovery.
- [x] Native/ACP hand parity with real inference, queued context continuity,
  tool use, independent hands, and publication retry/reconciliation checks.
- [ ] Cover create, rename, reconfigure, reconnect, cancel, and delete.

`scripts/conformance.mjs` uses ship-configured inference, creates uniquely named
test sessions, and deletes only those sessions. It is not yet a full install or
ACP specification-conformance suite.

`scripts/hand-conformance.mjs` tests the conversation-hand slice with two
independent adapters and native ingress. It uses real inference but simulated
external publications; it is not a Tlon connector test.

`scripts/hand-operations-conformance.mjs` exercises dead-worker recovery,
late-receipt rejection, abandonment, private durable exports and binding
retirement without changing session memory. Its delivery destinations are
test fixtures, never external channels.

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

- [x] Isolate the semantic reducer from provider/JSON dependencies; separate
  effect bindings, ACP formatting, bootstrap policy and persistence loading
  from the authoritative lifecycle, with dependency and behavior checks.
- [x] Mirror each authoritative session as a typed grub under
  `/agents/main/sessions` through the thin client boundary.
- [x] Supervise a read-only session verifier: independent replay/current-decision
  checks, narrowly scoped roads, persistent failure evidence and explicit retry.
- [ ] Compare actual dispatched effect intents and receipts at every revision,
  including provider/tool chains, cancellation, reload and late responses.
- [ ] Promote independently supervised session grubs only after the head and
  effect conformance suite agrees; keep native and ACP clients interchangeable.
- [ ] Represent each open effect as a supervised `/runs/<id>` grub with durable
  intent, progress, receipt, and crash evidence.
- [ ] Move skills, policies, prompts, and tool bundles into versioned namespace
  files rather than agent maps.
- [ ] Move more asynchronous hands into small supervised Grubbery processes.
- [ ] Give each hand a reviewable road/weir authority manifest.
- [ ] Persist crash evidence and surface it in the Harness UI.
- [ ] Make authored capabilities installable without enlarging `%harness`.
- [ ] Upstream generally useful runtime and MCP corrections.

Order the next steps by clarity of ownership, not number of features. First
make failures inspectable without blocking or retrying the head. Then give
each effect a durable identity, explicit authority and one supervised run.
Only then move execution ownership. A namespace mirror or a matching replay
digest is useful evidence, but neither proves effect dispatch conformance.

The verifier's runtime failures must checkpoint locally and wait; reporting a
denied write by attempting another denied write creates a retry loop. Keep this
as a supervision regression case. Versioned policy/skill files should follow
the same rule: durable nouns are the restart contract, not Fiber continuations.
`scripts/shadow-conformance.mjs` injects a fault only into a test verifier,
checks reload/recovery and unchanged head state, and exercises the ACP
inspection boundary. It requires an idle Dojo tmux pane for owner operations.

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
- [x] Add an optional Messenger adapter over ACP and the native hand port.
- [x] A shared native/ACP conversation-hand contract without a social-desk
  dependency; see [hands](hands.md).
- [x] Build a Tlon hand with owner/trusted actor grants, source authentication,
  self-echo suppression, destination-order delivery, and threaded Story replies.
  Its configuration and activity are available through ACP; see [Tlon](tlon.md).
- [x] Edit the bot's public nickname/avatar through Contacts, with live reads
  of external edits and acknowledged saves through ACP; no duplicate identity store.
- [ ] Add Messenger-history-assisted external-id reconciliation for uncertain
  publications; current receipts identify local acceptance, not remote delivery.
- [ ] Add scoped adapter credentials and per-binding tool/budget/rate policies;
  current adapters are owner-trusted and use their bound session's tool grants.
- [ ] Extend the text publication contract with addressed artifacts and richer
  capability schemas, preserving source and effect identity.
- [x] Page and bound operational hand ledgers; explicit owner disposition and
  export-before-retirement preserve delivery evidence without pruning sessions.
- [ ] Automate adapter binding-epoch rotation with durable source cursors and
  operator-selected archive storage; never silently relabel old source events.
- [ ] Keep Urbit identity authoritative rather than depending on a social desk.
- [ ] Support hosted executors and local devices as capability-bearing hands.

## UX and operations

- [x] Stop automatically initializing terminal, keyring, peer-directory and push
  services, binding the push endpoint, or mounting `%base`. Preserve process/code
  reloads and explicitly opened resources; check the assembled startup contract.
- [ ] Make optional runtime services follow an explicit capability declaration,
  including retirement of subscriptions from earlier development installations.
  Pruning startup must not silently delete durable service data or user mounts.
- [ ] Eliminate stale watch and Grubbery blit messages on runtime reload;
  verify a clean install separately from the working development ship.
- [x] Add a deliberate “fork here” action with visible provenance.
- [x] Show compaction state, cumulative token usage, and structured tool results.
- [x] Render Markdown replies and streaming text with copyable code, contained
  tables, and no executable HTML or automatic remote-image requests.
- [x] Browser regression checks for chat layout, scrolling, composer behavior,
  and keyboard-accessible conversation dialogs in light/dark and narrow layouts.
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
