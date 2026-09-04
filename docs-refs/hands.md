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
`_meta["harness/hand"] = {version: 1, capabilities: ["publish"]}`.
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
  sessionId, config: { ...config, key: '', tools: ['ship-time'] },
})
await hand.bind('support-chat', {
  address: 'opaque-channel-and-thread', sessionId, actors: ['alice'],
})
await hand.observe('support-chat', {
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
| `enable` | `id`, `enabled` | Binding status |
| `remove` | `id` | Empty object; rejects unsettled work/publications |
| `observe` | `binding`, `event`, `actor`, `text` | `inputId`, `phase`, `sourceEvent` |
| `status` | `binding` | Binding and observation statuses |
| `outbox` | `hand` | Undelivered publications for enabled bindings |
| `effect` | `hand`, `effect` | Publication, including terminal receipts |
| `claim` | `hand`, `effect`, `worker` | Publication plus `acquired` |
| `receipt` | `hand`, `effect`, `worker`, `status`, `external` | Updated publication |
| `retry` | `hand`, `effect` | Confirmed failed publication reset to pending |

`effect` is the returned `effectId` string in Urbit `0v…` notation. The helper
supplies its hand/worker ids and defaults `external` to the empty string.

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
chronological `receipts`. One terminal publication is created per executed
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

Successful publication records an external message id. Repeating an identical
receipt is safe; conflicting terminal receipts are rejected. Delivery failure
and retry append receipt history without modifying the transcript or rerunning
inference. `uncertain` blocks retry until the claiming worker establishes
whether the destination accepted the message. There is no automatic claim
expiry: elapsed time alone cannot establish non-delivery.

This is not a cross-system exactly-once guarantee. Use destination idempotency
keys or lookups to close the external-send/receipt gap. If a delivered receipt
is lost in transit, repeat that receipt or inspect `effect`; do not republish.

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

A Tlon adapter maps authenticated message events to `observe`, encodes the
channel/thread as an opaque address, and implements `publish`. Its DM/channel
agent details stay in that adapter. This desk does not yet ship that connector.

Binding/queue/outbox state belongs to `%harness` and survives agent reloads.
Grubbery can host an adapter as a supervised process; losing that process need
not lose its inputs or claims. Automatic adapter supervision, road/weir
manifests, scoped ACP credentials, per-binding budgets, richer payload
references, and provider/tool effect unification remain roadmap work.

Admission limits text to 65,536 bytes, source ids to 512 bytes, bindings to 256,
and the waiting queue to 128. Observations and receipts remain retained,
including after binding removal. Removal requires settled work and delivered
publications; retired binding ids with observations cannot be reused. There is
no ledger pagination or pruning policy yet. Remove bindings before renaming or
deleting their session.
