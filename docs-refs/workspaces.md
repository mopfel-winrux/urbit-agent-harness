# Artifacts and projects

Editable, ship-owned documents, shared project work, and explicitly published
pages. Artifact storage requires the ship's native `%notes` agent (provided by
Tlon's Groups desk). This feature adds no inference loop or scheduler.

## Use it

Open **Artifacts** in the sidebar to create a Markdown document. Save a revision,
inspect History, and use **Publish…** to choose a saved revision.
Review the exact public preview and confirm publication. The public address is
`https://your-ship-domain/notes/pub/~host/notebook/note-id`; Notes assigns this
fixed address and readers do not sign in. Your
reverse proxy must forward this path to the ship. This feature does not configure
DNS, TLS or your proxy.

Open **Projects** to group documents and tasks. In **Access**, add conversations
as readers or contributors. Separately enable **Workspace** in each participating
conversation's tool settings. Existing saved tool settings are not expanded by
an upgrade or by project membership. Fresh-install defaults include Workspace.
Ask an enabled agent to use the `workspace` tool's `help` action, inspect shared
tasks, claim one, and propose a document revision with its result. You review and
accept or reject its exact changes in the artifact's **Proposals** tab.

Unsaved editor drafts are kept in this browser tab's session storage when
available; they are not server revisions or backups. Concurrent saves are
rejected without overwriting the local draft. Copying a saved revision to another
project creates a new artifact, with confirmation for sharing its source
references; it does not expose the original artifact's private history.

## Ownership

Notes owns artifact bodies, body revision history, current titles and published
HTML. Harness keeps native note identities, projects, proposals, source references
and task claims. Notes content is projected for reads, not maintained as a second
canonical document store. Changes made directly in Notes appear in Harness.
An artifact is a Markdown document, whether used privately, in a project, or as
a public page. A project is an explicit sharing scope, not a conversation owner.
Conversation membership uses immutable corpus scope identities, not mutable names.
Membership never shares the conversation's transcript or adds resource tools.
Notes notebook permissions are independent: changing Harness project membership
does not grant or revoke native notebook access. New artifacts use a private
Harness notebook; sharing that notebook in Notes can expose its other documents.

Models with the workspace tool grant may read their own artifacts and projects
to which their conversation belongs. Project contributors may propose document
changes and coordinate tasks. A live delegated child may use its parent's project
scope within the parent's current tool ceiling; it does not acquire approval or
publication authority. Removing membership fences subsequent access.

## Revisions, review and publication

Human body edits save in Notes using an expected current revision. Harness shows
native revision zero as saved revision one. A body-identical save does not create
a native revision. **Rename…** separately updates the unversioned Notes title;
it neither saves the local body draft nor republishes the document. Source
references are Harness metadata, not native body history.
Agent edits create proposals containing the exact replacement, source references,
author and base revision. Accepting a proposal checks that base and live access;
stale proposals cannot overwrite newer work. Existing-note proposals must retain
the current title; title changes use the explicit owner rename action. Rejection
preserves the proposal.
Shared accepted documents are knowledge, not system instructions.

Publication is a separate owner action selecting and previewing a saved snapshot.
The preview token fences the exact title/body/HTML, including native title changes.
Harness submits that HTML through Notes' existing publish action; it does not
serve a parallel public endpoint. The published snapshot does not change when the document is
edited. Public reads return only the published title and rendered body, never
project membership, proposals, task records, provenance or private revisions.
Unpublishing removes the Notes HTML snapshot; Notes may return its app shell at
the address instead of a 404. It cannot erase copies held by other people.
Rendered HTML is inert, with escaped raw HTML and a restrictive meta CSP. Notes
owns HTTP headers; Harness cannot add its previous response-header sandbox.

Native writes wait for the Notes result, not just transport acknowledgement.
An uncertain result blocks further document mutations. Use **Check result again**
to reattach to that result without repeating the write. If the result cannot be
recovered, inspect Notes before explicitly releasing the wait. Releasing does not
cancel or undo a native write; the unsaved browser draft remains available.

## Unified search

**Search content** combines conversation evidence, accepted Notes body history,
project titles/descriptions and task titles/descriptions/outcomes. One artifact
appears once even when many versions match; expand its matching revisions and
read a specific historical body without replacing the current editor. All query
terms must occur in the same revision. Unsaved drafts and pending proposals are
not indexed. Archived records are labeled.

The incremental index reports backfill status. Notes availability is checked
before returning its content; an unavailable backend produces explicit partial
results, not a stale private body. Query/index/workspace changes invalidate old
result tokens and require refreshing. These owner search methods do not expand
the model's workspace permissions or conversation-only corpus recall.

## Coordination

Projects contain explicit tasks with versioned state and atomic claims. Agents
can claim available work and record outcomes without competing workers silently
overwriting each other. Claims do not start inference, expire on a timer, or
prove that an external effect happened. Existing conversation/subagent execution
remains the owner of model work.

## Initial scope

Markdown editing, source references, revision inspection, proposal review,
explicit project membership, task coordination, and publish/unpublish through a
ship-relative public endpoint. No automatic memory extraction, autonomous
maintenance, arbitrary JavaScript pages, or production deployment is implied.

## Interfaces and bounds

Owner ACP calls use `harness/workspace` with `{action, args}`. Native local-owner
pokes use mark `harness-workspace` with `{id, action, args}` and replies on
`/workspace/<id>`; subscribe before poking. `/workspace-events` emits a revision
invalidation, not private document contents. Owner `/x/workspace` scry retains
the typed workspace state. Models use `workspace` with `{action, args}`, where
`args` is a JSON-encoded string. The `help` action lists supported operations.
Models cannot use approval, publication or membership actions, including through
the administration tool. Scheduled and rehearsal runs do not receive Workspace.

Read lists are paginated. Models receive at most four entries and 8,000 UTF-8
body bytes per page; follow `nextOffset` using `revision` with the returned
revision number. Source references have separate paging. Owner lists default to
24 entries, with a maximum of 64. The UI mounts one shared invalidation watch
and refreshes visible queries on change, focus, or a 30-second fallback.

Harness mutation limits are explicit rejections: 512 artifacts, 128 projects, 2,048 proposals,
2,048 tasks, 64 members per project, 256 accepted revisions per artifact, 256
title bytes, 256 KiB body bytes, 16 source references and 64 MiB conservatively
accounted retained content. Archiving hides records; it does not delete them or
reclaim capacity. Accepted revisions and proposals remain retained; the audit
stream retains the most recent 2,048 changes. Native Notes remains authoritative;
external Notes edits are subject to its own limits. Claims require explicit release
or owner intervention if a worker stops. Removing access cannot recall copies.

Public Markdown supports headings, paragraphs, lists, quotes, code fences,
simple tables and limited inline formatting. Raw HTML is escaped, remote images
are not embedded, and scripts/forms/external resources are blocked by document
policy. It is intentionally not a general-purpose HTML host. Links written in
the document body are public content; separate source references stay private.
Inspect the publication preview rather than assuming full editor/GFM parity.

## Local verification

Run `npm test` and `PLAYWRIGHT_CHANNEL=chrome npm run test:ui` in `fe`, then
`zig build` and `node --test scripts/*.test.mjs` at the repository root. Native
tests include `/tests/harness-workspace`, `/tests/harness-notes`,
`/tests/harness-workspace-search`, `/tests/harness-unified-search` and
`/tests/harness-boundaries`. Storage version 23 preserves native Notes identities
and existing conversation/tool settings. Pre-Notes Harness documents are
intentionally ignored, not imported or published.

`SHIP_URL=http://127.0.0.1 SHIP_COOKIE=/path/to/local-cookie node scripts/workspace-conformance.mjs`
checks real local Gall, ACP, deterministic model tools and anonymous public HTTP.
It refuses remote hosts, creates uniquely named local fixtures and archives its
documents/projects after unpublishing any pages. Fixture conversations and
historical records remain for inspection. It makes no paid provider requests
and changes no global configuration.

`SHIP_URL=http://127.0.0.1 SHIP_COOKIE=/path/to/local-cookie node scripts/notes-workspace-conformance.mjs`
checks direct native edits, history, separate rename, stale preview rejection,
native publishing/unpublishing, preserved project metadata and request isolation.
It retains one archived private test note and its project, and withdraws its
temporary public snapshot. Neither script modifies the Tlon desk.

The opt-in installed-UI smoke test is
`WORKSPACE_LIVE=1 SHIP_URL=http://127.0.0.1 SHIP_COOKIE=/path/to/local-cookie PLAYWRIGHT_CHANNEL=chrome npx playwright test workspace-live.spec.js`
from `fe`. It creates, edits, reloads and archives a private local artifact, checks
App navigation and the publication confirmation, and publishes nothing.
