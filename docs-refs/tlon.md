# Tlon hand

Tlon is one client surface for the harness. `%harness-tlon` consumes the local
Groups desk's activity feed, authenticates the source actor against its social
policy, and uses the same conversation-hand ledger available through ACP.
It does not run an inference loop or hold provider credentials.

Open **Tlon** above Settings in the sidebar. Select an owner, add trusted ships,
choose their tools, then enable the hand. Nicknames search the Contacts directory;
every selection shows and saves the actual `@p`. Suggestions search known ships,
with contacts before other peers. An exact valid ship name takes precedence and
can be entered without a contact. `urbit-ob` validates it; incomplete names never
generate invented ship identities or fuzzy matches at the permission boundary.

**Bot profile** edits this ship's public nickname and avatar URL in Contacts.
It reads the existing profile, including changes made in Tlon, and refreshes while
idle without overwriting an unsaved draft. Saving waits for Contacts to acknowledge
the edit. Empty fields clear the corresponding attributes; other profile fields
are untouched. Identity edits are independent of social policy and do not revoke
grants or restart conversations.

## Models and failures

Tlon uses the same providers and credentials as every other Harness client.
New conversations snapshot **Settings → Defaults**. Changing defaults does not
retroactively change an existing DM or thread.

The Tlon page shows the current default provider/model, links to each active
conversation's settings, and offers **Apply defaults to Tlon conversations**.
This explicitly copies the default endpoint, model, provider headers and reported
context limit. It preserves instructions, transcripts and tool grants. Each
conversation can also choose its own provider/model through its settings.
Configuration changes affect subsequent requests; they do not interrupt an
in-flight request or restart failed work. Send another message after correcting
a failure. No provider configuration is duplicated in the adapter.

Failures have safe public explanations for authentication, credits, rate limits
and other provider problems. Open the session in Harness for the raw error;
provider bodies are not forwarded into a public channel.
An HTTP `401` is an inference authentication failure, not an Activity or Story
mark error. Check the conversation's endpoint and its matching saved credential,
not just the defaults for new conversations. Refreshing the page does not retry
the provider request.

Send `/help`, `/status`, `/context`, `/compact`, `/model`, `/model <id>`,
`/model default`, `/memory`, `/remember <name> <text>`, `/forget <name>`, or `/stop`
directly in the DM or thread. These are shared Harness commands, not Tlon bot
shortcuts, and work for the owner and trusted actors without tool grants.
Channel mention policy still applies. `/stop` interrupts current work and clears
that session's queued inputs; other commands wait for the current turn to settle.
See [conversation commands](acp.md#conversation-commands) for semantics.

## Thinking and tool activity

Chat computing indicators use `%presence-action-1` and the
`tlon.computing-status.v1` display payload. The pinned Presence noun is identical
to Lux's installed Groups noun; the payload was also checked against the current
Groups client (`95dee1d917f0`), not just the older Claw integration.
The adapter publishes “Thinking...” or named tool activity (for example,
“Searching the web” or “Reading chat history”) in the DM/channel context.
Only unfinished calls in the latest tool batch contribute. Names are restricted
to the native catalog; unknown calls get a generic label. No prompts, arguments,
MCP server/tool identifiers, results, or reasoning content are included.

Activity is aggregated across actors and threads sharing a context. One thread
finishing cannot clear another's indicator. Head events update tool/phase changes
and clear settled or revoked work. A lease deadline renews active presence every
ten seconds. Leases expire after thirty seconds if the adapter stops. Presence
is presentation only: it neither admits work nor determines settlement.

Steward's separate Lens module supports durable run/tool inspection via
`%steward-lens-action-1` (`entry`, with a JSON payload and final flag). Current
Groups expects a `{schemaVersion: 1, lens: ...}` payload and optional
`tlon-context-lens` post pointers containing `lensId` and `botShip`.
Harness does not yet export those traces or stamp pointers. Steward forwards
local entries to its configured owner, and cross-ship storage requires explicit
trust on that owner ship. Its shared owner configuration also affects gateway
behavior: enabling chat status must not silently configure it or start an
external-process heartbeat for this on-ship harness. A future opt-in projection
should use the existing head/hand records and distinguish completion, local send
acceptance, and uncertain delivery; it must not create a second run authority or
blind retry path.

## Authority and conversation scope

- New owner conversations inherit the tools in **Settings → Defaults**, not the
  entire catalog. Existing conversations keep their configured grants. Ownership
  still permits conversation admission and invitation acceptance without tools.
- Trusted ships can chat with no tools; each grant is explicit.
  MCP entries grant individual registered server IDs, for example
  `{"mcp":"calendar"}` in the `tools` array. Registering another server never
  adds it to trusted actors' grants. A granted server permits all of its tools.
- Other ships and the bot's own messages do not enter inference.
- Group invitations are accepted only when sent by the owner. DM invitations
  from the owner or a trusted ship are accepted.
- Channels require a mention by default. Replies to the bot's own posts count
  as addressed; DMs do not require mentions. Turn the requirement off to answer
  every message from allowed actors in channels the ship has joined.
- Sender, destination/thread, and policy epoch determine the session. A shared
  channel does not share the owner's private DM transcript or execution grants.
  Channel answers are still public to that channel's members: granting file,
  web, skills, peer, or MCP access can expose whatever those tools can read.

Saving changed policy stops queued/running Tlon work, disables existing bindings,
and clears those sessions' tool grants. New input starts a fresh session epoch.
Revoked routing records are discarded; the head retains bindings, transcripts and
delivery evidence. Saving unchanged policy leaves routes and sessions alone.
Previously emitted network operations cannot be undone. Publication checks the
current epoch and actor again after claiming, before sending.

The adapter watches `/v4` with the version-8 activity vocabulary. Top-level
messages and replies are normalized once, using the durable source message key.
Channel replies retain their parent activity time; DM replies retain the author's
writ id, **not** its local activity timestamp. Styled input retains text, links,
ship mentions, code, lists and image descriptions. Replies translate Markdown
paragraphs, emphasis, headings, quotes, links and fenced code into Story. This is
a small codec, not a complete CommonMark renderer; unsupported syntax remains text.

The first DM is an invitation rather than a post notification. After accepting,
the adapter admits up to 64 recent posts newer than the policy's activation time.
It preserves original message keys so overlap with live notifications deduplicates
in the head. This bounded invitation catch-up is not general offline replay.

## ACP configuration and activity

These owner-authenticated extensions work from any initialized ACP client:

| Method | Params | Result |
| --- | --- | --- |
| `harness/tlon` | `{}` | Policy, connection status, queue counts, recent activity |
| `harness/tlon/configure` | Policy below | Acknowledged adapter state |
| `harness/tlon/contacts` | `{}` | `ship`, `nickname`, `contact` directory entries |
| `harness/tlon/profile` | `{}` | Public `nickname` and `avatar` from Contacts |
| `harness/tlon/profile/set` | `{ "nickname": "Bot", "avatar": "https://…" }` | Profile read back after Contacts acknowledges the two-field edit |
| `harness/tlon/watch` | `{}` | State plus subsequent `harness/tlon/activity` notifications |

```json
{
  "enabled": true,
  "owner": "~sampel-palnet",
  "mentions": true,
  "trusted": [{ "ship": "~sampel-sipnup", "tools": [{ "clay": "/harness/lib" }] }]
}
```

An activity notification has `sequence`, `kind`, `actor`, `address`, and `event`.
Message, invitation, and relevant group/contact notifications share this envelope;
notifications do not themselves grant tools or instruct the model. Recent activity
is a bounded 128-entry diagnostic feed, not a second transcript. Use session
snapshots and the [hand ledger](hands.md) for admitted work and delivery audit.

The head forwards only the named Tlon methods through `harness-adapter`'s tiny
request envelope. Adapter errors become ACP errors instead of indefinite waits.
Transport authentication has owner authority; do not give untrusted chat
participants the ship login code.

## Delivery and operation

Messages are event-driven. The head emits a native `/hand-events` invalidation
after a ledger or session change, and the adapter reads the durable outbox.
Every subscription starts with an invalidation, so reload/reconnect recovers
pending replies without another incoming message. Receipt events release the
next reply at that destination. There is no message polling timer.

The adapter retains a monotonic native message stamp: multiple replies in one
Gall event must not reuse `now.bowl` as their Messenger ID. This counter survives
reloads and does not delay delivery. When the adapter is stopped, the head can
still save completed replies; unavailable Tlon authority grants no tool effects.

Admission, inference, and publication are separate. The adapter claims a terminal
publication and records its claim attempt before emitting the Messenger poke.
DM receipts record Messenger's **local acceptance**, not remote network delivery
or reading. Channel publications keep Groups' versioned client action and wait
for a host-confirmed post/reply on its native response subscription. The receipt
identifies that channel post, not the local client's optimistic queue entry.
This does not mean that every subscriber has received or read it. Suppressed or
unconfirmed posts remain unresolved; a negative local acknowledgement records
failure, and an unknown outcome never authorizes a resend.
Timeouts or restarts never authorize automatic resending of uncertain sends.
Reconcile them using `harness/hand` health, effect, and resolve operations.

Reload recovery distinguishes an unprocessed claim, an emitted send with unknown
outcome, and a recorded receipt. It can finish a provably undispatched claim or
replay a receipt, but never blindly repeat a Messenger send. Late claim and
receipt responses are fenced by dispatch stage and attempt. Claimed or uncertain
ledger records block their destination even if this adapter has no cached entry.

Timers are reserved for actual cron deadlines, presence-lease renewal, tool
acknowledgement timeouts, and Activity subscription recovery. An idle connected
hand without a schedule has no wake. Status exposes `deliveryMode: "events"`,
`headConnected`, `publicationsConnected`, and nullable `maintenanceWake`;
`connected` continues to describe the Activity subscription.

Only one publication per destination is sent at a time; unrelated conversations
proceed independently. Pending admission is capped at 64 adapter jobs and 128
session lanes in the current permission epoch, in addition to the head's ledger
limits. Capacity errors are reported, not solved by deleting history. Binding export/retirement and adapter
lane rotation need explicit operational care; there is no automatic history
pruning or offline activity-feed backfill yet.

## Source boundaries

- `sur/harness-tlon`: policy, addresses, adapter state.
- `lib/harness-tlon-policy`: pure actor grants and activity normalization.
- `lib/harness-tlon-story`: pure text/Story conversion.
- `lib/harness-tlon-profile`: pure public-profile projection and edit validation.
- `lib/harness-tlon-io`: versioned Messenger effects and Contacts projection.
- `lib/harness-tlon-presence`: pure context aggregation and leased display effects.
- `app/harness-tlon`: subscription, admission and delivery lifecycle.
- React `TlonSettings`, `TlonModels`, `TlonProfile`, `ShipPicker`, `ToolOptions`: replaceable configuration UI.

`zig build` runs `scripts/stage-tlon.mjs`, which pins Tlon protocol dependencies
at `938f0c44d693f6f7391cca8107c7b3a40b834a01` and stages only their source closure,
prefixed `tlon-`. It imports no applications, desk bill, frontend, or ACP agent.
The harness's generic ACP transport is unchanged. The protocol patterns draw on
the `reid/tlon-acp` work in `tlon-apps`; the Story codec adapts the reusable
`story-parse` library in `np/claw`, with thread addressing and fenced-code handling
implemented here.

## Conversation tools and scheduled work

Three separate opt-in grants are available: `tlon-read`, `tlon-write`, and `cron`.
None is added to bootstrap defaults. A grant alone is insufficient: these tools
require a current Tlon lane and a matching outstanding head request. They do not
work in an unrelated browser session or a child without a Tlon binding.

`tlon_read_history` returns at most 20 recent top-level messages in the bound DM
or channel, with durable IDs, authors and clipped text. `tlon_react` and
`tlon_unreact` operate on those IDs in that same chat, adding/removing the ship's
own reaction. No model argument can select another destination. Reactions use a
persisted invocation receipt and report local Messenger acknowledgement, not
remote delivery. Missing acknowledgements become uncertain after a minute and
are not automatically retried. Ordinary final replies still use the publication
ledger; there is no arbitrary cross-chat send or group-management grant here.

The owner can use `cron_add`, `cron_list`, and `cron_remove` from a conversation
granted `cron`. Creation requires `schedule`, `timezone: "UTC"`, `prompt`, and
`runs` (a decimal string, 1–100). Five-field expressions support `*`, steps,
ranges and lists; weekdays are 0=Sunday through 6=Saturday. Restricted
day-of-month and weekday fields use OR semantics. Local/IANA timezones and DST
are not supported yet; convert deliberately to UTC, never guess. Invalid or
impossible schedules fail rather than becoming a more frequent schedule.
The next occurrence must fall within the bounded four-year search horizon.

Each schedule owns a separate session at the exact original destination,
including its thread address. It receives the configured instructions and grants,
but no parent transcript, no cron grant, and no subagent grant. The source grant
ceiling remains effective even if the scheduled session's configuration is edited.
The source snapshot is rechecked at admission, tool dispatch and publication; changing source
grants pauses the schedule and requires explicit rescheduling. Changing Tlon
policy currently pauses schedules along with retiring the old lanes.

Behn drives the existing hand maintenance loop. A due occurrence becomes an
idempotent hand observation and follows the normal execution/publication ledger.
Downtime coalesces to one due run, without replaying a missed backlog. Runs do not
overlap pending execution or an uncertain publication. The schedule advances in
the same state transition that records its pending admission. The first version
retains at most 64 schedule records; it never deletes old head evidence to free
capacity. Richer archival and resumption controls remain future work.

Settings → Tlon → Scheduled work shows the schedule, remaining runs, execution,
delivery and pause reason. Cancellation is immediate for pending work but cannot
retract an already dispatched effect. A locally fired or completed run is not
represented as a delivered reminder. ACP exposes `harness/tlon/cron` and
`harness/tlon/cron/cancel` (`{"id":"…"}`) for owner inspection and cancellation.

## Testing

`desk/tests/harness-tlon.hoon` exercises the pure authority, scope and Story rules.
`scripts/tlon-conformance.mjs` exercises real DMs, channel mentions, threads,
ACP activity, global session discovery, and revocation between two ships. Supply
`SHIP_COOKIE`, `PEER_COOKIE`, `PEER_URL`, and `TEST_NEST` (an existing peer-owned
test channel, in the form `chat/<peer-ship>/<channel-name>`). It temporarily grants the
peer ownership, uses the configured inference provider, and restores policy in
`finally`. Set `CONTROLLED_MODEL=1` to use a deterministic local provider and
restore the previous defaults afterward. Use disposable test ships: messages and
auditable sessions are retained.
Neither the test nor the adapter modifies the Groups desk's source code.

`scripts/tlon-delivery-conformance.mjs` additionally needs `SHIP_DOJO_PANE` for
real Gall suspension/revival. It checks offline completion, explicit retry,
uncertainty, ordered outbox draining, distinct IDs, whole-desk revival and an idle
hand with no timer. `SURFACE=channel` plus `TEST_NEST` selects channels. Supplying
`CHANNEL_HOST_DOJO_PANE` also temporarily suspends the channel host to test a lost
confirmation and recovery from native publication evidence. Every suspended
agent is revived in cleanup; fixture messages and receipts remain.

`scripts/tlon-presence-conformance.mjs` uses the same two-ship cookie variables
(no channel needed) and a controlled local provider. It checks a real DM's
provider failure, explicit adoption of changed defaults, thinking/tool presence
on the peer, renewal during long inference, cancellation, and resumed delivery.
It restores the test ship's
defaults and social policy. Do not run it concurrently with another test changing
those settings or with a desk compilation.

`scripts/tlon-profile-conformance.mjs` needs only `SHIP_URL` and `SHIP_COOKIE`.
On a disposable ship it checks direct Contacts edits, acknowledged ACP writes,
validation, clearing, and preservation of unrelated fields and policy. It restores
the touched profile fields in `finally`; test identity changes may already have
been published to peers. The React tests cover external refresh and draft safety.

`scripts/tlon-tools-conformance.mjs` uses a local provider and the same two-ship
variables plus an existing `TEST_NEST`. It checks unbound-call denial, bounded
history, real DM/channel reaction state, cron delivery, transcript isolation,
recursive-schedule denial and mid-flight source revocation. It restores defaults
and policy and cancels fixture schedules; messages and their receipts remain.
`desk/tests/harness-cron.hoon` covers the pure UTC calendar and strict parser.
