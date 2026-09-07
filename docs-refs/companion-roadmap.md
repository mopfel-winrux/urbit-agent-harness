# A coherent hosted companion

This is a product and architecture contract. Checked items describe implemented
behavior; unchecked items remain commitments, not guarantees.

## Product contract

One durable companion on a ship, accessible through replaceable conversation
surfaces. The ship owns conversations, accepted work, policy and delivery evidence.
Hosting owns provisioning, release management, billing and infrastructure. Optional
workers perform bounded effects; they do not become another conversation owner.

Generality comes from clean boundaries, not a large default tool catalog. Prefer
complete, useful behaviors over more agent machinery. Preserve explicit user
configuration and primary history; do not silently rewrite old conversation logs.

## Decisions

- MCP authority is **per server**, not per tool. A server grant permits its tools;
  an ungranted server must not be discoverable or callable by the conversation.
  Registering a server is not a grant. No wildcard authority for future servers.
- Conversation identity, accessible context and current authority are separate.
  Revocation must fence work and publication without resetting unrelated chats.
- Private owner context must not become channel context just because the owner
  speaks there. Tool execution and publication need concrete resource boundaries.
- Reusable instructions remain useful. Autonomous publishing and rehearsal are
  not part of the default companion experience. A rehearsal must not claim to be
  harmless while retaining arbitrary effectful tools.
- Admission, completion, local send acceptance and remote delivery are distinct.
  An uncertain external action is never automatically safe to repeat.
- Preserve a single authoritative head. Further runtime decomposition must earn
  its cost through measurements and demonstrated recovery benefits.

## 1. Narrow authority and remove misleading guarantees

Status: bootstrap/rehearsal, per-server MCP and SearXNG slices implemented and verified.

- [x] Separate bootstrap tool policy from the complete catalog. New conversations
  should not implicitly gain self-authoring or every newly added capability.
  Preserve saved defaults, sessions, skills and staged proposals.
- [x] Make new owner Tlon conversations follow configured defaults rather than
  treating ownership as an automatic grant of the entire catalog. Trusted actors
  continue to receive only explicit grants.
- [x] Remove default instructions promoting self-authoring ceremony. Keep explicit
  owner controls; describe experimental tools accurately where still available.
- [x] Restrict retained rehearsal execution to a concrete read-only allowlist,
  with tests proving that web, MCP, code and recursive/authoring effects are absent.
  Do not suggest that a successful model reply certifies safety or correctness.
- [x] Implement per-server MCP grants in persisted policy, dispatch, discovery,
  session/default settings and Tlon grants. Existing configurations need an
  explicit compatibility policy; never silently grant newly registered servers.
- [x] Separate web reads from arbitrary network mutations. `http_fetch` is
  GET-only, with no request body, automatic redirect or retry. General HTTP
  methods, headers and bodies live in the separate, explicitly granted `curl`
  tool and its own library; adding it does not expand existing web grants. Private-network
  isolation is outside the product scope; do not advertise it as a guarantee.
- [x] Scope Clay reads before granting them broadly, without invoking desk-defined
  converters that could import resources outside the granted path.
- [x] Add SearXNG as an alternative search provider with a configurable instance
  URL, preserving the shared `web_search` contract and Brave configuration.

Acceptance: denied calls never dispatch; discovery reflects effective grants;
children cannot widen authority; old explicit settings and history survive load;
new defaults agree across native and browser clients.

## 2. Preserve social continuity without preserving revoked authority

Status: stable identity, selective revocation, bounded public-thread context and
explicit conversation-scoped preferences are implemented.

- [x] Give conversations stable identities independent of policy revisions.
- [x] Apply changed grants only to affected work; fence late results/publications.
  Adding an unrelated trusted actor must not cancel or reset the owner's DM.
- [x] Keep bounded, attributed public thread context separate from each actor's
  private history and execution grants. Do not merge private transcripts.
- [x] Define stable companion identity and explicit scoped preferences without
  turning shared skills into a private-memory side channel.

Acceptance: continuity survives unrelated settings edits; revoked capabilities
cannot return through timers, children, retries or already queued input; public
answers cannot gain private context through shared conversation identity.

## 3. Complete a small useful repertoire

Status: bounded Tlon history/reactions, UTC cron and literal reminders implemented.

- [x] Read authorized Tlon conversation history with bounded work and attributed
  results through native interfaces.
- [x] Read the actual bound DM/channel thread (parent plus bounded recent replies)
  and route reactions to those replies, excluding unrelated top-level messages.
- [x] Add bounded search and history pagination beyond the recent window,
  scoped to the bound DM/channel or exact thread, with stable continuation.
- [x] Expose explicit scoped memory updates with durable acknowledgement through
  the shared human commands; verify native DM/channel/thread state and isolation.
- [x] Provide narrow, destination-authorized writes with actual receipts:
  add/remove reactions in the bound conversation. A second model-driven message
  send path is unnecessary; normal replies use the publication ledger.
- [x] Adapt useful chat/reaction tools to native Tlon-hand effects, scoped
  grants and durable receipts; do not add another CLI or agent loop.
- [x] Add an idiomatic durable cron subsystem, integrated with admitted inputs,
  destination-bound publication and observable job state rather than a second
  conversation scheduler. Reuse Behn and the existing hand ledger.
- [x] Add requested reminders with explicit destination, timezone, timing,
  cancellation, authority, usage limits and the existing publication ledger.
  A timer that merely starts inference is not a delivered reminder.

Acceptance: demonstrate each behavior end to end through Tlon, not just the
inspector; verify resulting state/delivery evidence rather than answer text.

## 4. Make recovery understandable

Status: owner-visible recovery is implemented; retention and long-lived costs
remain explicit capacity boundaries.

- [x] Add automatic owner-only Steward Lens projection and reply pointers against
  current Groups schemas, with redacted tool metadata and acknowledged export
  state. Add native trust when saving owner/trusted ships; do not enable gateway
  liveness or turn Lens retries into blind repeats of uncertain sends.
- [x] Provide owner-visible received/working/completed/sending/uncertain states
  and concrete safe recovery actions using the existing ledger.
- [x] Add bounded activity catch-up with durable cursors and deduplication.
- [ ] Define lane retirement and history retention without deleting evidence to
  make room. Bound long-session inspection, transport queues and maintenance work.
- [ ] Test interruption during inference, tools and publication; provider outage;
  duplicate input; revoked permission; restart; delayed result; long-lived usage.

Acceptance: an owner can distinguish unfinished work from an uncertain send and
recover without SQL, Dojo surgery, or accidental duplicate external actions.

## 5. Earn the runtime and hosting shape

Status: the [versioned hosting contract](hosting-contract.md) is defined.
Representative measurements and lifecycle acceptance remain required.

- [ ] Measure admission/stop latency, replay and mirror work, idle traffic, loom
  growth and per-conversation costs on a representative hosted moon.
- [ ] Evaluate on-demand verification versus continuous mirroring. Account for
  native mirror consumers. Same-code replay is not an independent semantic oracle.
- [x] Define a small versioned hosting contract for acknowledged configuration,
  health, credentials/billing policy and release identity. Assign each field one
  authority; avoid generated-file overlay precedence and configuration repair loops.
- [ ] Pilot fresh installation, upgrade, backup/restore and controlled outages
  without making optional executor availability a prerequisite for ordinary chat.

Defer richer self-authoring, agent society, supervised per-session/run ownership,
general approval languages and feature parity until these slices are proven.
