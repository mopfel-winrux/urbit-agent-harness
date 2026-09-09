# Companion workflows

A Harness companion is an agent on a ship, available through multiple interfaces.
Its durable identity is the ship; its model, public nickname and interfaces can
change without moving conversation ownership.

Conversations are separate working contexts, not one shared private memory.
That makes it possible to serve an owner, collaborators and public channels
without automatically mixing their transcripts.

## Set up a companion

1. Configure the provider and model in Settings, then review default tools.
2. Set reusable behavior in instructions or shared skills. Keep private
   preferences in conversation notes.
3. For Tlon, select an owner, add trusted ships and grant only the resources
   each participant needs. Enable the reply hand and review mention policy.
4. Edit the ship's public nickname/avatar through the Tlon page if desired.
   Contacts remains the source of that profile.
5. Test a conversation, a relevant tool and its actual result. A plausible
   model answer is not proof that an external action succeeded.

Fresh-install defaults include broad tools. A companion connected to other
people needs deliberate permission choices. Incoming channel content remains
untrusted input, even when a permitted actor sends it.

## Research with recoverable evidence

Use web search, authorized files or configured MCP servers to collect evidence.
The conversation retains tool arguments, results and answers. Pin explicit
requirements with `/remember`; use `/context` to inspect the working budget.

As the conversation grows, summaries preserve source links and the recent tail
remains available to the model. Search content finds retained records; model
recall stays local unless an owner conversation has the cross-conversation
corpus grant. A summary is a lossy account, not a substitute for reading its
sources before making an exact claim.

Fork a completed reply to explore another approach. The branch inherits that
history boundary without rerunning prior effects; subsequent changes are independent.

## Work with a Tlon community

The agent can answer DMs, mentions and replies to its own posts. Each actor and
destination/thread has a distinct conversation. Public thread context includes
an attributed, bounded snapshot of the native parent and recent replies; it
does not import anyone's private Harness conversation.

With the ship-wide Tlon grant, an authorized task can create a group, invite
members, organize channels, edit Notes or manage roles. Discover arguments with
`tlon({action: "help"})` and read native state before making changes.
Exact-target confirmations and revision checks apply to destructive operations
and publishing.

Normal answers return to the initiating conversation automatically. Use explicit
send actions for separate messages elsewhere. Group-DM tools are available, but
incoming group-DM messages do not start automatic replies.

## Schedule a report or reminder

Use cron for a model task that runs a bounded number of times at the original
conversation destination. A scheduled session receives selected instructions and
grants, not the parent's transcript. Cron expressions use UTC.

Use a literal reminder when the desired output is already known. It needs an
explicit time offset and destination, but no model or provider credits when due.
A scheduling acknowledgement confirms the saved job, not delivery of its message.

Inspect Scheduled work for execution, delivery and pause state. Permission
changes can pause affected schedules; cancellation cannot retract a send already
dispatched. See [scheduling](tlon.md#conversation-tools-and-scheduled-work).

## Publish and automate deliberately

Native Notes supports shared notebooks, imports and diary-copy workflows.
Plans and revision checks bind writes to inspected content and permissions.
Publishing a post or note makes the selected content publicly accessible under
the ship's hosting; it requires explicit approval.

Channel hooks are persistent Hoon programs, not conversation-local callbacks.
They can keep acting after Harness work ends or its tool grant is revoked.
Inspect, stop and remove them explicitly. Neither hook execution nor the
JavaScript tool provides hard CPU isolation.

## Recover without repeating uncertain actions

The Work panel separates received input, running work, completed inference,
sending and uncertain delivery. Inspect the session for model failures and the
publication ledger for send failures.

Correcting credentials or changing a model affects subsequent requests; it does
not automatically retry failed work. A known-unsent publication can be explicitly
retried without rerunning inference. An uncertain send needs destination
evidence before a retry decision.

Operational ledgers can be exported and retired after settlement. That preserves
the session and its notes; it is not primary-history deletion or proof of
remote archival durability. See [hand recovery](hands.md#claims-and-receipts)
and [Tlon operation](tlon.md#delivery-and-operation).

## Connect more surfaces

An editor uses ACP; another Urbit app uses native nouns; a mailbox or chat
connector implements the hand protocol. Remote ships can ask the agent or call
granted tools directly under authenticated Urbit identity.

These are integration possibilities around existing contracts, not bundled
mailbox connectors, hosting infrastructure or an extra agent loop.
[Architecture](architecture.md) describes the ownership model, and
[integrations](integrations.md) helps select the right boundary.
