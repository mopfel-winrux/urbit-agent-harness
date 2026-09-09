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

## Ship-wide Tlon tool

The default-enabled **Tlon** grant exposes one model function, `tlon`, with an
`action` argument. It works from Harness conversations even while the Tlon
reply hand is disabled. It can send DMs and channel posts, list contacts and
groups, inspect a group's channels, create groups/channels, invite a ship,
and join or leave a group. It also reads and searches other conversations and
threads, lists DMs and group members, adds/removes reactions, manages contacts,
reads/updates this ship's profile, and updates group/channel names and descriptions.
`{"action":"help"}` describes the arguments.
These are native Tlon operations as this ship, subject to Tlon's own permissions.

Normal final replies are delivered to the DM/channel/thread that prompted the
agent automatically. `send_dm` and `send_channel` are for separate messages to
other DMs or parallel channels, not for answering the current prompt. An optional
`parent` targets a thread in that other conversation.
This rule is included in both the tool description and its sending-field help.

New groups default to secret (unlisted and invite-only), with no channels.
Create channels afterward; they are readable and writable by all group members.
Mutation receipts confirm local acceptance only, not remote delivery or completed
joining. Pending calls become uncertain after one minute and are never retried
automatically, including after reload. Lists return at most 100 entries.

`history` and `search_history` take exactly one of `ship` or `channel`; optional
`parent` selects a thread. Use exact `message_id` values from their results,
including the author prefix for DMs. Each page returns up to 20 messages, with
800-byte text previews and explicit truncation flags. Search scans at most 64
rows per page; follow `next_cursor` even when a page has no matches. Cursors are
bound to the destination, parent and query. `react`/`unreact` accept only messages
in the latest 20-message conversation/thread window. `list_dms` includes active
DMs and invitations, not archived conversations.

`get_profile` defaults to self, or reads a known contact when given `ship`.
`update_profile` edits only supplied nickname, bio, status, avatar or cover fields;
empty strings clear those fields. `update_group` and `update_channel` similarly
preserve omitted metadata, images, and channel permissions. These actions do not
change Harness ownership or grants. Adding a Tlon contact does not authorize it
to use the bot.

This is a broad, separately removable grant: it extends beyond the current
conversation. Existing saved defaults and conversation grants are preserved.
Trusted ships receive only the tools explicitly granted to them; their implicit
current-conversation history, reaction, upload and scheduling tools do not grant
ship-wide `tlon` access.

While the reply hand is enabled, an unpermissioned sender receives a fixed DM
explaining that the owner must add them to **Trusted ships**. This covers incoming
DM invitations, existing DMs, native channel mentions and replies to the bot.
Unaddressed channel chatter gets no notice. Notices do not run inference or grant
Harness access. Sending the notice can accept the native Tlon DM invitation;
that is separate from permission to use Harness. Notices are deduplicated and
limited to one per sender per five minutes and eight total per minute.

Native verification: `scripts/tlon-actions-conformance.mjs` exercises the broad
tool with automatic replies disabled; `scripts/tlon-denial-conformance.mjs`
checks real two-ship denial delivery, rate limiting and zero model calls.

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

### Explicit conversation notes

Use `/remember preference Keep replies short.` to save or replace a pinned note,
`/memory` to list notes, and `/forget preference` to unpin one. These are human
commands, not model tools: ordinary prose and a model reply containing `/remember`
cannot update memory. Successful saves record the note and acknowledgement in the
same head admission; Tlon sends that acknowledgement through its normal delivery
ledger. It is not a remote read receipt.

In mention-only channels, select the bot's native mention first, then type the
plain slash command in the same paragraph—for example, **@Bot /memory**. The
addressing prefix is removed before the shared command interpreter runs; it does
not bypass sender or mention authorization. Plain-text ship spellings, other
ships' mentions, formatted command text and multi-paragraph messages do not use
this shortcut. DMs and replies to the bot's own channel posts do not need it.

Notes belong to the current sender/conversation: private DM notes are not injected
into channel or thread requests. They remain verbatim across compaction and head
reloads. Limits are 16 notes, 1,024 UTF-8 bytes per body and 8,192 bytes total,
including names; overflow is rejected, never silently evicted. Unpinning does not
erase earlier messages, note events or checkpoints. Conversation identity and
notes survive permission edits, revocation/regrant, and disable/re-enable. An
affected conversation must establish fresh authorization before new input runs;
retaining a note never retains a revoked capability.

### One companion, scoped conversations

The companion's stable social identity is the ship, not a model, nickname,
provider, permission revision or shared transcript. Contacts owns its public
name and avatar. Defaults supply initial behavior; existing conversations retain
their chosen instructions and model. There is no second personality database.

Preferences are explicit pinned notes in one sender/destination conversation.
Saving a preference in a DM does not authorize publishing it into a channel.
Skills are an owner-managed shared instruction library, not personal memory.
Social conversations and their descendants cannot write, stage or publish into
that library, even if an old saved configuration contains those grants. An
operator can deliberately install reusable instructions outside a social
conversation; existing library contents are not silently removed.

For a channel thread, ordinary message admission captures the native parent
and up to eight recent replies as attributed public reference material. The
snapshot records destination, message IDs, ships, timestamps and clipped text
separately from the current input. It never reads another actor's Harness log or
notes, and it grants no execution authority. Its encoded message budget is 6 KB;
each message has the history reader's 800-byte text limit. Snapshots may omit
older replies. Commands do not retrieve or interpret this material. DMs and
top-level channel conversations receive no automatic cross-message context.

## Thinking and tool activity

Chat computing indicators use `%presence-action-1` and the
`tlon.computing-status.v1` display payload, matching the versioned Groups
Presence protocol.
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

Run inspection stays on the ship in Harness. Replies carry no external inspector
pointers, and saving Harness policy does not configure another agent's trust.

## Images and storage

Final replies support standalone `![description](https://image-url)` lines as
native Story image blocks in DMs, channels and both thread types. Fenced examples
remain literal code. Images use the existing publication ledger; there is no
separate image-message send path.

`tlon_upload_image` is an implicit in-conversation Tlon write tool. It downloads
a public image and uploads it using the ship's existing Tlon storage selection.
It returns a URL without publishing a message. The final reply chooses whether
to include that URL as an image. No separate media grant or S3 credential form is
needed in Harness. Both custom S3 credentials and Tlon-hosted presigned URLs are
supported; the `service` toggle in Tlon chooses the path.

Configure custom S3 credentials, bucket, region and optional public URL base in
Tlon's storage settings, or select presigned-URL hosting on a hosted ship.
Public readability of custom storage is the operator's responsibility.
There is no separate Harness storage setup, download worker, token or service.

The ship downloads PNG, JPEG, GIF and WebP directly through Iris, checks their
file signatures and MIME types, and limits them to 8 MiB. Source URLs must be
HTTPS with a qualified DNS hostname, no credentials, custom port, fragment or
local-name suffix. IP literals are rejected. Downloads send no ship credentials.
All HTTP requests disable redirects and transport retries. Iris does not expose
DNS-answer validation or connection pinning, so hostname checks do not guarantee
that a domain resolves to a public IP; this is not a private-network isolation
boundary. There are at most four pending uploads and a one-minute call deadline.

Hosted mode reads the ship's `%genuine` identity and asks the fixed
`https://memex.tlon.network/v1/<ship>/upload` endpoint for an upload URL, with the
exact file name, byte count and MIME type. Memex owns cloud authentication/signing;
no static cloud keys or workload-identity credentials are copied into Harness.
The returned GCS upload URL is used unchanged, with matching content type and
cache-control headers. Only its separate public file URL reaches the model.
The identity token is never sent to the image source or storage PUT. Arbitrary
custom presigning endpoints are not supported, even if `presignedUrl` is populated.

The hand checks current conversation authority and unchanged storage credentials
before each PUT. A positive `AccessControlListNotSupported` rejection permits
one retry without the signed `public-read` ACL, using the same object key. Other
ACL incompatibilities are reported as failures, not blindly retried.
DigitalOcean Spaces also receives a signed `x-amz-acl: public-read` header;
its uploads cannot rely on the ACL query parameter alone. The owner maintenance
script `scripts/spaces-media-repair.mjs` inspects this ship's `harness-*` image
objects, with `--apply` limited to repairing owner-only ACLs. It never changes
bucket policy or replaces custom object grants.
Reloads and permission changes retire unfinished downloads; a dispatched PUT
without acceptance evidence stays uncertain and is never automatically repeated.
An interrupted hosted URL request is also uncertain: the broker may have allocated
quota, but the result explicitly states that no image PUT was sent.
Already dispatched storage writes cannot be undone by revoking permissions.
An accepted upload does not guarantee public readability or remote message delivery.

The live fixture is `scripts/tlon-media-conformance.mjs`; it requires
`MEDIA_TEST_STORAGE=1`, the usual two-ship test variables, and optionally
`TEST_PANE` for adapter suspension/reload checks. It downloads a real public
image through the ship, temporarily configures a local independently verifying
S3 endpoint, and restores the test ship's storage configuration.

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
- Sender and exact destination/thread determine the stable conversation. A shared
  channel does not share the owner's private DM transcript or execution grants.
  Channel answers are still public to that channel's members: granting file,
  web, skills, peer, or MCP access can expose whatever those tools can read.

Permission changes retire only affected authorization routes. Adding an unrelated
trusted actor leaves existing conversations, in-flight work, notes, saved model
settings and schedules alone. Changing the mention requirement affects channels,
not DMs; changing an actor's role or effective grants affects that actor's work.
Grant order alone is not a revocation. Disabling Tlon affects every route.

Affected queued/running work is cancelled, old bindings are disabled, native
timers and delegated work are fenced, and source schedules are paused until
explicitly rescheduled. The head retains its transcript, pinned notes and chosen
configuration. New authorized input resumes that same head only after cancellation
and a tools-only configuration update have been acknowledged, using a fresh
binding. Old publications cannot move to the new binding. Actor-specific admission
cutoffs reject queued pre-grant messages without dropping unrelated input.

Publication checks the exact current binding and actor again after claiming,
before sending. Async callbacks and self-dispatched work carry request generations,
so reusing a tool-call ID cannot revive an old request. Previously emitted network
operations cannot be undone; their receipts and uncertainty remain evidence.
Saving unchanged policy leaves routes and sessions alone. Migration retains each
currently routed conversation's existing head ID; it does not merge transcripts
from earlier retired policy epochs or alias scheduled runs as conversations.

`scripts/tlon-continuity-conformance.mjs` exercises native DM/channel threads,
unrelated and affected permission edits, notes, chosen settings, timers, schedules,
late HTTP/child results, and reload. It requires `CONTINUITY_TEST_MESSAGES=1`, the
usual ship/peer/nest variables, and `TEST_PANE` for the test ship's Dojo. It restores
policy, defaults and original native trust; marked test messages and audit records
remain in the disposable conversations.

The adapter watches `/v4` with the version-8 activity vocabulary. Top-level
messages and replies are normalized once, using the durable source message key.
Channel replies retain their parent activity time; DM replies retain the author's
writ id, **not** its local activity timestamp. Styled input retains text, links,
ship mentions, code, lists and image descriptions. Replies translate Markdown
paragraphs, emphasis, headings, quotes, links, standalone images and fenced code into Story. This is
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
| `harness/tlon/work` | Optional `before` cursor | At most 16 admission/ledger records, continuation cursor and head availability |
| `harness/tlon/admission/retry` | Admission job `id` | Resume setup/admission against current authority; original source identity is retained |

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

The head forwards the authenticated `harness/tlon` namespace through
`harness-adapter`'s tiny request envelope; the adapter owns its method vocabulary.
Adapter errors become ACP errors instead of indefinite waits.
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

The owner-facing Work panel projects received, working, completed, sending,
uncertain and terminal states from that same ledger. It includes failed
pre-admission work and retains old-binding evidence. Recovery requires a reason,
explicit evidence confirmation and the observed attempt number. A stale attempt
is rejected without discarding the draft. Marking an action failed does not
resend it: retry is a separate, explicit operation, available only for current
authority and a known-unsent failed publication. Uncertain sends never get an
automatic retry. Closing the panel stops its inspection polling.

Reload recovery distinguishes an unprocessed claim, an emitted send with unknown
outcome, and a recorded receipt. It can finish a provably undispatched claim or
replay a receipt, but never blindly repeat a Messenger send. Late claim and
receipt responses are fenced by dispatch stage and attempt. Claimed or uncertain
ledger records block their destination even if this adapter has no cached entry.

Timers are reserved for actual cron deadlines, presence-lease renewal, tool
acknowledgement timeouts, Activity subscription recovery and bounded catch-up.
An idle connected
hand without a schedule has no wake. Status exposes `deliveryMode: "events"`,
`headConnected`, `publicationsConnected`, and nullable `maintenanceWake`;
`connected` continues to describe the Activity subscription.

Activity catch-up uses a durable native ingestion-time cursor. Each turn walks
at most 16 selected events plus one lookahead in the current native ordered
tree; it does not serialize or convert the whole feed. Recovery starts on
reconnection, then uses bounded wakes only while behind. It pauses before
advancing past an input when the adapter or head waiting queue lacks room,
counting in-flight admissions as reservations. Current actor/channel cutoffs,
mentions and grants still apply. The normal source-event identity prevents
re-admission across restart; quoted messages and new nonconversational Activity
variants do not acquire command authority.

The cursor recovers events still retained by native Activity. It is not a promise
to recover deleted or expired native history. Migration starts at its own time
instead of answering old conversations retroactively; already retained jobs
remain recoverable. `activityThrough` and `catchingUp` expose the checkpoint and
whether more work remains.

### Retention and capacity

Conversation identities and their notes outlive route authorization. Revocation
disables the old binding and fences its work; it does not delete its evidence or
assign its old publications to a new binding. Operational limits are admission
backpressure, never permission to prune primary history: 128 retained social
identities, 64 pending admissions and 64 retained schedules, in addition to the
[shared hand limits and archive protocol](hands.md#fair-admission-and-explicit-retention).

To reclaim a settled binding's operational ledger, stop admission by disabling
the adapter, resolve its unfinished work, and export/retire the disabled binding
through that protocol. Re-enabling creates a fresh authorization binding for
future input while preserving the same conversation head and notes. Do not
relabel old events into the new binding. The activity cutoff deliberately starts
a new admission period when the adapter is re-enabled; disabling is not the
same as downtime recovery.

Retiring a ledger binding does not release a social identity or delete a session
log. At identity capacity, existing conversations remain usable and new ones
are rejected visibly. Automatic identity eviction and primary-history pruning
are not implemented. Do not present a ledger archive as an export of the full
conversation or as proof that external storage is durable.

Only one publication per destination is sent at a time; unrelated conversations
proceed independently. Pending admission is capped at 64 adapter jobs; the stable
conversation directory retains up to 128 identities, including inactive ones.
Schedules have their own 64-entry cap, in addition to the head's ledger limits.
Capacity errors are reported, not solved by deleting history. Binding
export/retirement and conversation-directory capacity need explicit operational
care; there is no automatic history
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

Tlon reads, writes and cron are implicit within an authorized Tlon conversation.
These tools require a current Tlon lane and a matching outstanding head request. They do not
work in an unrelated browser session or a child without a Tlon binding.

`tlon_read_history` returns at most 20 messages with durable IDs, authors and
clipped text. Top-level conversations return recent top-level messages. A bound
DM/channel thread returns its parent followed by up to 19 recent replies, omitting
deleted replies and unrelated top-level messages. Native tree traversal and
channel reply requests are bounded; no whole-thread JSON conversion is needed.

`tlon_history_page` walks older messages in the same conversation. Pass an empty
`cursor` for the newest page, then the returned `next_cursor`. Each page inspects
at most 20 entries and returns at most 20 messages in chronological order.
`tlon_search_history` takes a nonblank `query` (at most 128 bytes) and optional
`cursor`. It performs literal ASCII-case-insensitive matching within the first
800 rendered text bytes per message, inspecting at most 64 entries and returning
at most 20 matches per call. This is bounded local history search, not a complete
index. An empty page with `has_more: true` is not an exhaustive no-match.

Both return `messages`, a separate thread `parent`, `next_cursor`, `has_more`,
`scanned`, `scan_limit`, and `text_limit_bytes`; search also reports the parent's
match through `parent_matches`. Deleted entries advance the cursor without
returning deleted text. Serialized result size can reduce the message count;
the next cursor preserves the first unreturned match. Positions use native local
history keys, not author timestamps, so new arrivals do not shift older pages.
Cursors are scoped to the conversation, actor, authorization generation, tool and
normalized query. Unrelated policy edits leave them valid; affected authorization
changes invalidate them. They never select another destination or confer authority.
The two-ship `scripts/tlon-history-conformance.mjs` fixture requires
`HISTORY_TEST_MESSAGES=1` and the usual peer/nest variables. It leaves uniquely
marked native test messages, while restoring defaults, policy and native trust.

`tlon_react` and `tlon_unreact` operate on those IDs in that same conversation,
including the parent or individual thread replies. No model argument can select
another destination or expand the recent reaction window. Reading older pages
or search results does not authorize reactions to older messages. Reactions use a
persisted invocation receipt and report local Messenger acknowledgement, not
remote delivery. Missing acknowledgements become uncertain after a minute and
are not automatically retried. Ordinary final replies still use the publication
ledger; there is no arbitrary cross-chat send or group-management grant here.

An admitted actor can use `cron_add`, `cron_list`, and `cron_remove` within their
bound conversation. Creation requires `schedule`, `timezone: "UTC"`, `prompt`, and
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
grants pauses the schedule and requires explicit rescheduling. Unrelated social
policy edits preserve the schedule; affected authorization changes fence it.

`reminder_add` creates a one-shot literal reminder, not a scheduled model prompt.
Supply the exact conversation `destination`, `text` (1–4,096 UTF-8 bytes), and
an `at` timestamp such as `2026-09-07T09:00:00-05:00`. A timezone is mandatory:
`Z` is UTC; explicit offsets range through ±14:00. Missing offsets, the unknown
offset `-00:00`, invalid calendar dates, past times and times more than 365 days
ahead are rejected. IANA timezone inference and recurring local-time/DST rules
are deliberately absent. Ask for the intended offset when it is not known.

Reminders share cron's retained-record limit, Behn wake, cancellation controls,
authorization fences and publication ledger. The scheduling acknowledgement
reports the resolved time and exact destination; it is not a delivery receipt.
When due, the head records a completed literal notification and a pending
publication without inference, private transcript inheritance or command parsing.
Text beginning with `/remember` remains message text. Provider availability and
credits are not required at delivery time. An uncertain send is never repeated
automatically, including after a restart or permission change.

Behn drives the existing hand maintenance loop. A due occurrence becomes an
idempotent hand observation and follows the normal execution/publication ledger.
Downtime coalesces to one due run, without replaying a missed backlog. Runs do not
overlap pending execution or an uncertain publication. The schedule advances in
the same state transition that records its pending admission. The first version
retains at most 64 schedule records. Clear completed or cancelled schedules in the
GUI to free capacity; unused runs do not prevent clearing a cancellation, even
before its first run. Transcripts and delivery evidence remain. Running, pending or
uncertain work cannot be cleared. Clearing disables the binding and removes its
execution authority. Schedule resumption remains future work.

Settings → Tlon → Scheduled work shows the schedule, remaining runs, execution,
delivery and pause reason. Cancellation is immediate for pending work but cannot
retract an already dispatched effect. A locally fired or completed run is not
represented as a delivered reminder. ACP exposes `harness/tlon/cron` and
`harness/tlon/cron/cancel` and `harness/tlon/cron/clear` (`{"id":"…"}`). The
server's `clearable` field controls the GUI and is rechecked on every clear.

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
