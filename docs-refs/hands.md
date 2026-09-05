# Conversation hands

A hand translates between a surface and a ship-owned session. It does not own
the model loop, transcript, tool policy, or inference credentials. A Tlon chat,
mailbox, editor, or service can use the same protocol through native Gall nouns
or the `harness/hand` ACP extension. No social desk is required by Harness.

The first capability is `publish`: admit text, run the head, and deliver its
terminal answer. Provider and tool execution still use their existing paths;
this is not yet the dispatch contract for every effect in the system.

```text
surface event → binding → durable observation queue → session head
                                                        ↓
surface message ← hand ← claim + receipt ← publication outbox
```

Acceptance, inference, and publication are separate facts. Losing a connection
does not cancel the work; failing to publish does not run the model again.

## Binding and authority

A binding has an immutable id, hand id, opaque destination address, session id,
an explicit actor allowlist, and an enabled flag. Create and configure the
session first. Its model, instructions, and execution-time tool grants govern
the work. New sessions inherit global defaults, **including enabled tools**:
narrow these before accepting input from an external channel.

Use one session per conversation unless sharing memory is deliberate. Binding
two surfaces to the same session shares their model context, not just their
provider configuration. An answer to one surface can draw on the other. A
binding is not an information-flow sandbox.

These are **owner-side adapters**. Native operations require the same ship;
ACP connections authenticated with the ship login code have owner authority.
Hand and worker strings route work and correlate claims; they are not scoped
credentials. The adapter must authenticate external actors before asserting
their opaque ids, filter out its own published messages, and enforce source
membership and mention policy. Never give a ship login code to an untrusted
channel participant. Remote Urbits use the separately grant-gated peer port.

Binding identity and actor grants are immutable; use a new binding id to change
them. Enable/disable is separate. Disabling stops new observations, queued
admissions, and new delivery claims. It does not cancel an active turn or undo
a publication already claimed. Receipts can still reconcile it.

## ACP

Initialize an ordinary ACP connection. The response advertises
`_meta["harness/hand"] = {version: 2, capabilities: ["publish"]}`.
Send actions as the params of `harness/hand`:

```json
{"jsonrpc":"2.0","id":1,"method":"harness/hand","params":{"bind":{"id":"support-chat","config":{"hand":"chat-adapter","address":"opaque-channel-and-thread","sessionId":"support","actors":["alice"],"enabled":true}}}}
{"jsonrpc":"2.0","id":2,"method":"harness/hand","params":{"observe":{"binding":"support-chat","event":"source-message-17","actor":"alice","text":"What can you help me with?"}}}}
{"jsonrpc":"2.0","id":3,"method":"harness/hand","params":{"outbox":{"hand":"chat-adapter"}}}
```

The dependency-free helper accepts any initialized client implementing
`call(method, params)`, including a browser client or a JSON-RPC client over
the stdio bridge:

```js
import { HandClient } from './acp/hand-client.mjs'

const hand = new HandClient(acp, {
  hand: 'chat-adapter', worker: 'chat-worker-1',
})
const { sessionId } = await acp.call('session/new', { name: 'support' })
const config = await acp.call('harness/session/config', { sessionId })
await acp.call('harness/session/configure', {
  sessionId, config: { ...config, key: '', tools: ['clay'] },
})
const { binding } = await hand.register({
  address: 'opaque-channel-and-thread', sessionId, actors: ['alice'],
})
await hand.observe(binding, {
  event: authenticatedMessage.id,
  actor: authenticatedMessage.author,
  text: authenticatedMessage.text,
})

// Separately, in a delivery worker:
for (const intent of await hand.outbox()) {
  if (intent.status !== 'pending') continue // reconcile existing claims
  await hand.deliver(intent.effectId, async (claimed) => {
    const sent = await publish(claimed.address, claimed.text, claimed.effectId)
    return sent.id
  })
}
```

`publish` and `authenticatedMessage` belong to the adapter. Use `effectId` as
the destination's idempotency key when supported. Throw the helper's exported
`DeliveryNotSent` only when certain no external message was created. A timeout
is not that evidence.

| Action | Parameters | Result |
|---|---|---|
| `bind` | `id`, `config` as above | Binding status |
| `register` | `config` | Binding status with a ship-allocated, never-reused id |
| `enable` | `id`, `enabled` | Binding status |
| `remove` | `id` | Empty object; only for bindings with no observations |
| `observe` | `binding`, `event`, `actor`, `text` | `inputId`, `phase`, `sourceEvent` |
| `status` | `binding` | Binding and observation statuses |
| `outbox` | `hand` | Undelivered publications for enabled bindings |
| `publications` | `hand`, `after` (id or null), `limit` | Bounded `records` and `next` cursor |
| `effect` | `hand`, `effect` | Publication, including terminal receipts |
| `claim` | `hand`, `effect`, `worker` | Publication plus `acquired` and `attempt` |
| `receipt-at` | `hand`, `effect`, `worker`, `attempt`, `status`, `external` | Updated publication; rejects stale attempts |
| `retry` | `hand`, `effect` | Confirmed failed publication reset to pending |
| `resolve` | `hand`, `effect`, `attempt`, `status`, `external`, `reason` | Owner disposition, fenced attempt, audit entry |
| `health` | `hand` | Claimed/uncertain work with ages, queue usage and limits |
| `archive` | `binding` | Disabled, settled binding's snapshot digest and record count |
| `records` | `binding`, `after` (id or null), `limit` | Export page, snapshot digest and `next` cursor |
| `retire` | `binding`, `digest`, `location` | Release exported operational records; retain session |

`effect` is the returned `effectId` string in Urbit `0v…` notation. The helper
supplies its hand/worker ids and defaults `external` to the empty string.
Pages clamp `limit` to 1–4; the helper defaults to one and `outbox()` follows
pages. Numeric id ordering is for traversal, not chronological delivery. A
changing outbox is not a frozen snapshot: start another pass to discover new
effects whose ids sort before a cursor. `receipt` without an attempt remains
accepted only for the first claim generation; new clients use `receipt-at`.

## Admission and recovery

The pair `(binding, source event id)` determines `inputId`. Repeating an
identical observation returns its status; changing its actor or text is an
error. Use the source's durable message id, not a fresh UUID on each retry.
Message edits require a new event id. This idempotency is independent of ACP
transport sequence numbers and ordinary prompt `clientMessageId`.

Observations queue durably before inference. Admission returns promptly;
status progresses through `queued`, `running`, and `completed`, `failed`, or
`cancelled`. Turns serialize within a session and proceed independently across
sessions. A queued turn sees preceding completed context. Native sends cannot
splice input into an active hand turn; timer wakes wait for it. Webhooks cannot
write bound sessions: use the authenticated hand protocol and its actor checks.

Poll `status` for admission recovery and `outbox` for delivery work. Inspect
native snapshots or `harness/session/snapshot` for progress and diagnostics.
No client connection owns the run. `session/cancel` cancels both the active turn
and queued observations for that session. Queued cancellations appear in status
without creating a reply; active cancellations produce a cancellation publication.

Publications carry `version`, `effectId`, `inputId`, `binding`, `hand`, `address`,
`sessionId`, `capability`, `kind`, `text`, `status`, `worker`, `externalId`, and
`attempt`, chronological `receipts`, and owner `resolutions`. One terminal publication is created per executed
observation, with `effectId = inputId`. Kinds are `reply`, `failure`, or
`cancelled`. Failures expose a generic message, not internal diagnostics.

The outbox is a set, **not a presentation-ordered feed**. For chat surfaces
requiring ordered delivery, correlate `inputId` with the session snapshot's
chronological user entries and serialize publication per destination. Do not
assume array order or publish all entries concurrently. Cross-surface ordering
and edit/reaction semantics belong to the adapter.

## Claims and receipts

```text
pending → claimed → delivered
                  → failed → explicit retry → pending
                  → uncertain → reconcile → delivered or failed
```

Only the first claim returns `acquired: true`. A repeat by the same worker
returns false; another worker is rejected. Repeating a claim is not permission
to repeat the external operation. Workers need stable, distinct identities and
must reconcile abandoned claims after a restart.
Keep the attempt returned by that particular claim through its entire external
operation. The helper does this even if another operation updates its cache.
After reconnecting, inspect `effect` and pass its attempt explicitly to
`receipt(effectId, status, externalId, attempt)`.

Successful publication records an external message id. Repeating an identical
receipt is safe; conflicting terminal receipts are rejected. Delivery failure
and retry append receipt history without modifying the transcript or rerunning
inference. `uncertain` blocks retry until the claiming worker establishes
whether the destination accepted the message. There is no automatic claim
expiry: elapsed time alone cannot establish non-delivery.

If the worker cannot return, the owner can `resolve` the current attempt to
`uncertain`, `failed`, `delivered`, or `abandoned`, with an explicit reason.
Resolution advances the attempt and clears the worker; receipts from the old
attempt are rejected, even if the replacement uses the same worker name.
Use `failed` only after confirming non-delivery. `abandoned` means intentionally
not pursuing delivery, not proof that an external message never appeared. It
is terminal, disappears from the work outbox, and remains in the export audit.

`health` flags claims or uncertain outcomes older than five minutes for
inspection. It never expires or resends them. A generation fence protects
ship-side receipts, **not an already running external send**. Stop or reconcile
that worker before authorizing a replacement. Owner credentials still grant
all these administrative actions; worker strings do not authenticate them.

This is not a cross-system exactly-once guarantee. Use destination idempotency
keys or lookups to close the external-send/receipt gap. If a delivered receipt
is lost in transit, repeat that receipt or inspect `effect`; do not republish.

## Fair admission and explicit retention

Waiting work is limited to 8 observations per binding, 16 per session across
its bindings, and 128 globally. One stalled conversation cannot consume the
whole waiting queue. Duplicate admissions are checked before capacity limits,
so retrying an already admitted event still recovers its identity.

The operational ledger admits at most 256 observations per binding and 2,048
globally, with at most 256 active bindings. These are backpressure limits, not
silent deletion rules. Data already present during an upgrade is preserved.
Text is limited to 65,536 bytes and source ids to 512 bytes; binding metadata,
receipt fields, retries and recovery histories have bounded admission too.
The semantic session log is separate and is not pruned by these limits.

Rotate a binding epoch before it fills:

1. Stop consuming new source events and disable that binding.
2. Settle or cancel its queued/running work. Reconcile every publication to
   `delivered` or explicitly `abandoned`.
3. Export its descriptor and all `records` pages, checking the digest and
   count. Persist that archive, then `retire` with its digest and location.
4. `register` another binding to the **same session** and resume at the
   adapter's saved source cursor. Its conversation memory is unchanged.

Never relabel old source events with the new binding: deduplication is scoped
to the binding epoch. Retired binding ids reject all further observations.
Ship-allocated `hand--…` ids use a monotonic counter instead of an ever-growing
tombstone set. Manually named ids remain available, but their combined active
and retired identity capacity is 4,096; use `register` for continuous rotation.

The owner-side command performs the export-before-release sequence:

```sh
SHIP_COOKIE=/path/to/auth-cookie.txt \
  node scripts/archive-hand.mjs BINDING /safe/archive/binding.jsonl
```

It requires a disabled, settled binding, creates a private file without
overwriting anything, writes a completion footer, and fsyncs both file and
directory before retirement. Partial exports remain on disk for inspection;
they do not authorize retirement. A completed archive is sensitive: it contains
source text and publication/receipt history. Choose durable storage and backups;
`/tmp` is appropriate only for test fixtures.

The digest is a ship-side snapshot compare-and-set token, not a checksum of
the JSONL encoding. The ship cannot prove a remote archive was persisted: the
trusted owner attests that through `location`. Retirement removes only this
binding's duplicated admission/delivery records and binding config; it neither
deletes nor reruns the session. The latest 128 retirement receipts remain on
ship; identical retries within that window are idempotent. Remove unused
bindings or export/retire used bindings before renaming/deleting their session.

## Native nouns

Import `hh=harness-hand` from `/sur`, then poke `%harness` with mark
`%harness-hand` and a `request:hh`:

```hoon
['request-17' %observe 'support-chat' 'source-message-17' 'alice' 'Hello']
```

Watch `/hands/request-17` before the poke. Its `%noun` fact is
`(each json @t)`, sharing ACP's result/error semantics. Use distinct request ids
for concurrent requests, unwatch after the result, and recover through scries
when a response is lost. A successful poke ack alone is not admission success.

- `/x/hands/<binding>`: binding/observation JSON status.
- `/x/hand-outbox/<hand>`: publication JSON outbox.
- `/x/hand-state`: owner-only typed bookkeeping state.

Eyre projects the JSON scries at `/~/scry/harness/hands/<binding>.json` and
`/~/scry/harness/hand-outbox/<hand>.json`. Both transports call the same pure
gates in `desk/lib/harness-hand.hoon`.

## Scope and next hands

The [Tlon hand](tlon.md) maps authenticated activity to `observe`, encodes the
channel/thread as an opaque address, and implements `publish`. Its DM/channel
protocols and social permissions stay in `%harness-tlon`, outside the head.

Binding/queue/outbox state belongs to `%harness` and survives agent reloads.
Grubbery can host an adapter as a supervised process; losing that process need
not lose its inputs or claims. Automatic adapter supervision, road/weir
manifests, scoped ACP credentials, per-binding budgets, richer payload
references, and provider/tool effect unification remain roadmap work.
