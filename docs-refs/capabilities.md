# Capabilities and boundaries

Harness combines durable conversations with replaceable clients, model
providers and tools. This guide describes the available surface; exact method
and argument contracts live in the linked references and runtime tool schemas.

## Conversations and clients

Each conversation has its own event history, configuration, notes and run state.
The web app, ACP clients and native apps inspect the same records. Inputs carry
source identity, admission time and reply routing.

- Create, list, rename, configure and delete conversations.
- Resume or detach a client without cancelling work.
- Cancel an active turn from another authorized client.
- Fork at a completed, tool-free assistant reply without repeating its effects.
- Inspect revisioned snapshots and event-addressed history pages.
- Use shared slash commands through the web app, ACP and conversation hands.

Admission precedes provider completion. Tool and provider receipts are accepted
only for outstanding work. Cancellation preserves accepted results and rejects
late completion, but is not external rollback.

See [ACP](acp.md) and [architecture](architecture.md#session-ownership).

## Artifacts and projects

Artifacts are native Notes Markdown documents with accepted body history and
reviewable agent proposals. Titles are separate, unversioned Notes metadata.
Projects explicitly share documents and versioned
tasks with selected conversation identities; claims belong to individual workers.
Project access does not share transcripts or grant additional tools. Live
delegated workers may participate within their parent's current authority.

Owners can publish a reviewed saved snapshot through Notes at
`/notes/pub/~host/notebook/note-id` for readers
without authentication. Editing does not republish. Public responses omit private
history, source-reference metadata and project records. Pages are inert Markdown,
not arbitrary HTML applications. Search content combines conversation evidence,
accepted artifact history, projects and tasks, grouping each artifact's matching
revisions into one expandable result. See [artifacts and projects](workspaces.md).

## Providers and context

OpenRouter, OpenAI, Anthropic and compatible custom endpoints share the same
session lifecycle. Configuration includes model, endpoint, headers, instructions,
context window and tools. New conversations snapshot global defaults; changing
defaults does not silently reconfigure existing conversations.

OpenAI API keys and device login use separate credentials and request routes.
Device credentials renew on use on the ship. Anthropic login supports a token
handoff. Credentials are stored separately from session events; owner-supplied
custom headers are configuration data, not a secret vault.

Provider catalogs supply model choices and context limits when available.
Manual model entry remains available. Prompt budgets use byte-based estimates,
output headroom and a margin; they are not exact token counts.

Automatic compaction creates source-linked summaries while retaining the full
transcript. Optional separate models serve leaf compaction and parent summaries.
Explicit pinned notes survive compaction. Lexical corpus search and bounded
source expansion support evidence-based recall without an embedding service.

See [provider authentication](acp.md#provider-authentication) and
[context and memory](context-and-memory.md).

## Tools and permissions

`current_time` is always available. Other functions are exposed and checked
against their resource grants or an authorized conversation hand.

| Capability | Scope |
| --- | --- |
| Clay reads | Explicit desk/path prefixes; no desk-defined converter execution |
| Web | Brave or SearXNG search and GET-only `http_fetch` |
| General HTTP | Separate `curl` grant; explicit methods, headers and body |
| MCP | Named, enabled servers; each grant permits that server's tools |
| Shared skills | Reusable instructions; writing and authoring are separate authorities |
| Subagents | Bounded delegated work under the parent's authority ceiling |
| Peers | Authenticated ship-to-ship asks and direct tool RPC |
| Corpus recall | Local by default; cross-conversation recall for granted owner conversations |
| Ship-wide Tlon | Native social, content, administration, media and publishing operations |
| JavaScript | Opt-in `run_js` with broad host APIs |

Fresh-install defaults enable the standard local families, including broad Clay,
HTTP, skill authoring, corpus and Tlon access. Named MCP grants and JavaScript
execution require explicit configuration. Social, scheduled, delegated and
rehearsal work have additional provenance restrictions; copying a grant into a
configuration does not bypass them.

A tool grant establishes capability, not user approval for every destructive or
public action. Shared skills are not a place for private conversation memory.
Rehearsals permit inherited Clay and skill reads, consume inference, and provide
no safety certificate or automatic publication approval.

See [trust boundaries](architecture.md#trust-boundaries),
[MCP configuration](integrations.md#mcp-client-configuration),
[peers](peers.md) and [JavaScript execution](execution.md).

## Tlon

The optional Tlon hand supports owner/trusted-ship DMs, channel mentions and
threaded replies with separate actor context and live permissions. It shares
providers and the session head with other clients. The ship's Contacts profile
supplies its public identity.

The ship-wide `tlon` tool provides:

- Messaging, history, full message reads, search, reactions and activity.
- Contacts, profiles, groups, channels, roles, invitations and moderation.
- Explicit group-DM operations.
- Native Notes notebooks, folders, Markdown edits, revisions, imports and
  permission-checked diary-to-Notes copying.
- Image/file uploads through the ship's configured storage.
- Persistent native channel hooks and public post/note publishing.

Authorized Tlon conversations also receive destination-scoped history,
reaction, image-upload and scheduling tools. These do not imply ship-wide access.
Normal final replies are published automatically; explicit sends are for
separate messages.

See the [Tlon reference](tlon.md), particularly its
[tool catalog](tlon.md#ship-wide-tlon-tool),
[authority rules](tlon.md#authority-and-conversation-scope).

## Shared scheduled work

Every authorized conversation hand can create bounded UTC cron tasks and
literal one-shot reminders. The Harness head owns the scheduler; each job
retains its original hand and destination. Tlon is not required. Open
Settings → Schedules to inspect or cancel jobs from all hands.

Model runs have an isolated conversation and cannot recursively schedule or
delegate. Reminders publish literal text without inference. Execution and
delivery are tracked separately, and uncertain sends require reconciliation.
See the [scheduling contract](scheduling.md).

## Integration and extension possibilities

The existing boundaries support a research workspace, a Tlon companion, an
editor assistant, a scheduled reporting service or a ship-to-ship tool service.
A new conversation surface implements the hand protocol; a tool service can use
MCP; an Urbit app can use native nouns without ACP.

Grubbery supplies supervised processes and constrained resource access. Harness
uses it for separate replay verification and session mirrors. A verifier cannot
dispatch inference or take ownership of the authoritative transcript.

Extensions preserve the same rule: admit identified work, check authority,
record results and leave conversation ownership with the head. See
[integrations](integrations.md), [hands](hands.md) and
[companion workflows](companion.md).

## Limits to account for

- Primary logs remain retained. Compaction and history paging do not bound
  full replay cost, total transcript storage or loom growth.
- Grubbery verification checks replay and the current decision using the same
  reducer; it does not verify every dispatched effect.
- Provider text can stream when Iris exposes progress. Presentation chunks
  still pass through Arvo and durable ACP queues.
- MCP supports stateless Streamable HTTP and a local native server bridge;
  session negotiation, notifications and OAuth acquisition are not provided.
- ACP transport credentials have owner authority, not per-worker scope.
  Rich client input blocks and ambient terminal/filesystem methods are not advertised.
- HTTP and JavaScript tools are not private-network or hard CPU isolation
  boundaries. Revocation cannot retract an external write.
- Persistent Tlon hooks can continue after a conversation or grant ends.
  Public content can be copied or cached outside the ship.
- Cron uses UTC, not recurring local-time/DST rules. Retained schedules,
  social identities and operational ledgers have explicit capacity limits.
- A local acknowledgement is not a remote delivery or read receipt.
  There is no cross-system exactly-once guarantee.

[Development and verification](development.md) describes checks for these
boundaries and the operational effects of running them.
