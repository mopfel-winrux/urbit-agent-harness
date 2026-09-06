# A coherent hosted companion

Working roadmap, 2026-09-05. Keep this document untracked while work proceeds.
This records implementation progress, not a claim that the replacement is ready
for hosted deployment. No changes to the existing hosted bots are in scope.

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
- [ ] Separate public-web access from arbitrary network mutations and protect
  hosting-private destinations.
- [x] Scope Clay reads before granting them broadly, without invoking desk-defined
  converters that could import resources outside the granted path.
- [x] Add SearXNG as an alternative search provider with a configurable instance
  URL, preserving the shared `web_search` contract and Brave configuration.

Acceptance: denied calls never dispatch; discovery reflects effective grants;
children cannot widen authority; old explicit settings and history survive load;
new defaults agree across native and browser clients.

## 2. Preserve social continuity without preserving revoked authority

Status: queued after the authority boundary.

- [ ] Give conversations stable identities independent of policy revisions.
- [ ] Apply changed grants only to affected work; fence late results/publications.
  Adding an unrelated trusted actor must not cancel or reset the owner's DM.
- [ ] Keep bounded, attributed public thread context separate from each actor's
  private history and execution grants. Do not merge private transcripts.
- [ ] Define stable companion identity and explicit scoped preferences without
  turning shared skills into a private-memory side channel.

Acceptance: continuity survives unrelated settings edits; revoked capabilities
cannot return through timers, children, retries or already queued input; public
answers cannot gain private context through shared conversation identity.

## 3. Complete a small useful repertoire

Status: bounded Tlon history/reactions and UTC cron implemented and verified.

- [x] Read authorized Tlon conversation history with bounded work and attributed
  results through native interfaces.
- [ ] Add bounded search and deeper thread-history navigation.
- [ ] Expose explicit scoped memory updates with durable acknowledgement.
- [ ] Add a narrow Tlon write operation with destination authorization and an
  actual receipt. Do not infer permission from model-generated prose.
- [x] Adapt useful chat/reaction tools from `~/gits/np/claw` to native Tlon-hand
  effects, scoped grants and durable receipts; do not copy its CLI/agent loop.
- [x] Add an idiomatic durable cron subsystem, integrated with admitted inputs,
  destination-bound publication and observable job state rather than a second
  conversation scheduler. Reuse Behn and the existing hand ledger.
- [ ] Add requested reminders with explicit destination, timezone, timing,
  cancellation, authority, usage limits and the existing publication ledger.
  A timer that merely starts inference is not a delivered reminder.

Acceptance: demonstrate each behavior end to end through Tlon, not just the
inspector; verify resulting state/delivery evidence rather than answer text.

## 4. Make recovery understandable

Status: queued; existing no-blind-resend behavior must remain intact.

- [ ] Add explicit opt-in Steward Lens projection and reply pointers against
  current Groups schemas, with redacted tool metadata and acknowledged export
  state. Preserve existing owner/trust configuration; do not enable gateway
  liveness or turn Lens retries into blind repeats of uncertain sends.
- [ ] Provide owner-visible received/working/completed/sending/uncertain states
  and concrete safe recovery actions using the existing ledger.
- [ ] Add bounded activity catch-up with durable cursors and deduplication.
- [ ] Define lane retirement and history retention without deleting evidence to
  make room. Bound long-session inspection, transport queues and maintenance work.
- [ ] Test interruption during inference, tools and publication; provider outage;
  duplicate input; revoked permission; restart; delayed result; long-lived usage.

Acceptance: an owner can distinguish unfinished work from an uncertain send and
recover without SQL, Dojo surgery, or accidental duplicate external actions.

## 5. Earn the runtime and hosting shape

Status: queued; no production deployment or hosting changes yet.

- [ ] Measure admission/stop latency, replay and mirror work, idle traffic, loom
  growth and per-conversation costs on a representative hosted moon.
- [ ] Evaluate on-demand verification versus continuous mirroring. Account for
  native mirror consumers. Same-code replay is not an independent semantic oracle.
- [ ] Define a small versioned hosting contract for acknowledged configuration,
  health, credentials/billing policy and release identity. Assign each field one
  authority; avoid generated-file overlay precedence and configuration repair loops.
- [ ] Pilot fresh installation, upgrade, backup/restore and controlled outages
  without making optional executor availability a prerequisite for ordinary chat.

Defer richer self-authoring, agent society, supervised per-session/run ownership,
general approval languages and feature parity until these slices are proven.

## Implementation journal

- 2026-09-05: reviewed Harness against the local tlonbot, OpenClaw Tlon plugin
  and Ylem hosting sources. Roadmap approved in principle; MCP explicitly limited
  to per-server scoping. Starting with bootstrap authority and rehearsal safety.
- 2026-09-05: fresh-install defaults now grant only `web` and `skills`; configured
  defaults remain authoritative. Removed the settings' bulk "Enable all" action
  and default encouragement to publish skills. Existing saved policies, skills,
  proposals and histories are unchanged. Existing installations with broad saved
  defaults remain broad until the owner deliberately changes them.
- 2026-09-05: new owner Tlon sessions inherit configured defaults. Trusted actors
  retain their explicit grants. Verified through a real two-ship DM with only
  `web` configured, plus provider failure, model repair, tool cancellation and
  resumed delivery. Test policy/defaults were restored afterward.
- 2026-09-05: rehearsal grants are an allowlist of inherited `clay` and `skills`.
  Dispatch and internal self-pokes enforce this ceiling even for older or edited
  rehearsal configs. Local-provider conformance rejected web POST, MCP and skill
  writes, including an attempted mid-run grant expansion; zero external effects.
  The test removed its temporary proposals and sessions. Publication remains an
  explicit experimental grant, not an implemented owner-approval gate.
- 2026-09-05: build, 161 Hoon tests, 42 JavaScript tests and 30 browser tests
  passed. Browser regressions include narrow defaults and explicit opt-in persistence.
  Only the local test desk received the Hoon changes; no hosted deployment.

- 2026-09-05: MCP grants now name server IDs (`{"mcp":"calendar"}` in JSON),
  not individual tools. Dispatch and discovery enforce exact grants; a late
  response from a revoked, disabled or removed server becomes a rejection without
  its body entering context. Children inherit the same server scope. Registration
  does not grant access; default, conversation and trusted-Tlon settings select
  servers individually. IDs retain authority across endpoint edits; do not reuse
  them for unrelated servers.
- 2026-09-05: version-10 head / version-2 Tlon migrations snapshot broad legacy
  MCP grants to already registered IDs, including disabled entries, exactly once.
  Session migration appends a config event while preserving old history and request
  counters. Historical broad grants are readable but inactive. Migration tests
  cover defaults, peer policy, sessions, Tlon trust and lane epochs.
- 2026-09-05: SearXNG joins Brave under Settings → Search. Version 11 defaults
  upgrades to Brave without changing credentials. The configured instance base
  URL receives form POST at `/search`; JSON output must be enabled on the instance.
  Both providers keep `web_search` and its Web grant. Pending calls retain their
  original provider across edits/reloads; model arguments cannot select endpoints.
- 2026-09-05: build, 173 Hoon tests, 42 JavaScript tests and 31 browser tests
  passed. Local MCP fixtures proved guessed/future servers never dispatch, any
  tool on a granted server can run, late receipts are fenced, and children retain
  scope. Local SearXNG fixtures verified Unicode/form round-tripping, no Brave-key
  header, JSON-disabled feedback and mid-flight provider changes. Temporary global
  settings and registrations are restored; no paid model/search calls or hosted
  deployment. Local test desk updated only.

Next slice: separate public-web reads/search from arbitrary HTTP mutations and
protect hosting-private destinations; scope Clay reads. Then address social
continuity without retaining revoked authority. No per-tool MCP allowlists.

Clay slice complete: path-scoped grants, component-wise dispatch checks, scoped
discovery and raw-data reads without desk-defined converters. Existing broad
grants migrate to explicit broad root scopes without deleting history. Build,
185 Hoon tests, 42 JavaScript tests, the 31 existing browser checks and two new
Clay persistence checks pass. A local provider fixture verified actual source
reads/listing and denial of parent, sibling and other-desk paths. Test sessions
were removed; only the local test ship was updated.

General
web-fetch transport needs a decision: an optional public-IP-enforcing fetch worker
or deferred generic fetching; the current Iris interface cannot pin/check resolved
destination IPs in this app. A hostname blocklist alone is not a sufficient boundary.
Cron/Tlon slice: three opt-in grants (`tlon-read`, `tlon-write`, `cron`); bounded
top-level history and acknowledged add/remove reactions in the bound DM/channel.
Generic head-to-hand tool requests include provider generation, with durable
hand-owned receipts. Unbound sessions cannot borrow Tlon authority.

Pure UTC cron calendar/parser plus hand-owned schedule records. Owner-created,
1–100 runs, 64 retained schedules, separate purpose-bound sessions with no parent
transcript and no recursive scheduling/delegation. Source changes pause work;
publication rechecks authority. Behn feeds idempotent hand observations, with
coalesced downtime and no overlap of pending/uncertain work. Settings exposes
execution separately from delivery, plus cancellation. Local timezones, schedule
archival/resumption, deep history search and cross-chat posting remain deferred.

Live two-ship fixtures confirmed DM/channel history and reaction state, actual
scheduled delivery, transcript isolation, recursive-call denial and revocation
during inference. A deliberately broadened scheduled-session configuration could
not bypass its grant ceiling. Existing MCP, SearXNG and rehearsal fixtures pass.
Final build, 198 Hoon tests, 42 JavaScript tests and 34 browser tests pass. The
version-4 reload retained schedule records; version-3 migration preserves lanes,
presence and uncertain delivery evidence. Fixture schedules were cancelled and
defaults/policy restored. Only the local test ship received code; no hosted or
Lux deployment, no commits, and this roadmap remains untracked.

Lux deployment: verified cron/Tlon, scoped Clay/MCP and SearXNG build deployed
with overwritten files backed up. All 40 pre-existing session transcript/memory
hashes and non-tool defaults matched after migration. No Groups configuration,
hosted-bot deployments, or commits. Current Groups investigation confirmed the
Presence protocol is unchanged; Steward now has separately versioned Lens and
Gateway modules. Next immediate slice adds safe named live tool status; durable
Lens export needs an explicit privacy/configuration contract as recorded above.

Named Presence slice verified: current native tool names and friendly labels,
deduplicated across active threads, latest unfinished calls only, no arbitrary
model names or tool payloads. Version-5 migration refreshes ephemeral leases while
preserving authority, scheduled work and delivery evidence. Build, 203 Hoon tests,
42 JavaScript checks and 34 Chrome browser checks pass. Real peer test verifies
the exact named payload and clears on failure, cancellation and completion;
late tool output stays fenced. Fixture policy/defaults restored. This verified
adapter is also deployed to Lux (desk revision 148), alongside the previous
completed feature slices.
