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

Send `/help`, `/status`, `/model`, `/model <id>`, `/model default`, or `/stop`
directly in the DM or thread. These are shared Harness commands, not Tlon bot
shortcuts, and work for the owner and trusted actors without tool grants.
Channel mention policy still applies. `/stop` interrupts current work and clears
that session's queued inputs; other commands wait for the current turn to settle.
See [conversation commands](acp.md#conversation-commands) for semantics.

## Thinking and tool activity

Tlon revision `938f0c4` exposes chat computing indicators through `%presence`,
using `%presence-action-1` and the `tlon.computing-status.v1` display payload.
`%steward` provides run inspection and gateway liveness, not chat typing.
The adapter publishes “Thinking...” or “Using tools...” in the DM/channel
context, without prompts, tool arguments, or reasoning content.

Activity is aggregated across actors and threads sharing a context. One thread
finishing cannot clear another's indicator. The existing adapter poll updates
phase changes, renews active leases every ten seconds, and clears settled or
revoked work. Leases expire after thirty seconds if the adapter stops. Presence
is presentation only: it neither admits work nor determines settlement.

## Authority and conversation scope

- The owner has every tool family in the harness catalog.
- Trusted ships can chat with no tools; each grant is explicit.
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
  "trusted": [{ "ship": "~sampel-sipnup", "tools": ["clay"] }]
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

Admission, inference, and publication are separate. The adapter claims a terminal
publication and records its claim attempt before emitting the Messenger poke.
Its receipt records Messenger's **local acceptance**, not remote reading or even
remote network delivery. A local negative acknowledgement records failure.
Timeouts or restarts never authorize automatic resending of uncertain sends.
Reconcile them using `harness/hand` health, effect, and resolve operations.

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

## Testing

`desk/tests/harness-tlon.hoon` exercises the pure authority, scope and Story rules.
`scripts/tlon-conformance.mjs` exercises real DMs, channel mentions, threads,
ACP activity, global session discovery, and revocation between two ships. Supply
`SHIP_COOKIE`, `PEER_COOKIE`, `PEER_URL`, and `TEST_NEST` (an existing peer-owned
test channel such as `chat/~nec/harness-hand-test`). It temporarily grants the
peer ownership, uses the configured inference provider, and restores policy in
`finally`. Use disposable test ships: messages and auditable sessions are retained.
Neither the test nor the adapter modifies the Groups desk's source code.

`scripts/tlon-presence-conformance.mjs` uses the same two-ship cookie variables
(no channel needed) and a controlled local provider. It checks a real DM's
provider failure, explicit adoption of changed defaults, thinking/tool presence
on the peer, cancellation, and resumed delivery. It restores the test ship's
defaults and social policy. Do not run it concurrently with another test changing
those settings or with a desk compilation.

`scripts/tlon-profile-conformance.mjs` needs only `SHIP_URL` and `SHIP_COOKIE`.
On a disposable ship it checks direct Contacts edits, acknowledged ACP writes,
validation, clearing, and preservation of unrelated fields and policy. It restores
the touched profile fields in `finally`; test identity changes may already have
been published to peers. The React tests cover external refresh and draft safety.
