# Tasks, projects, and artifacts

Tasks keep track of work. Projects group related tasks. Artifacts are documents
you can edit, share, and publish.

Ask your agent for what you need. It can keep track of larger jobs and coordinate
with other agents without asking you to manage tasks. Simple questions need no
task at all.

## Use it

Open **Work** in the sidebar when you want to look in. The top-right navigation
has four views:

- **Inbox** shows work that needs attention, including blocked tasks and proposals.
- **Tasks** lets you inspect, create, and update tasks, with or without a project.
- **Artifacts** lets you write documents, review agent proposals, and publish.
- **Projects** groups tasks and documents. A project's **Sharing** tab controls
  [document access](project-access.md) for conversations and read-only clients.

You can also manage work in chat; `/work help` lists the commands.
See [conversation work management](work-control.md) for details.
Agents need the **Workspace** tool, which is included in default tool settings.

To work on a document, create an artifact or ask an agent to draft one. Your edits
save directly; agent proposals wait for your review in **Proposals**. **History**
shows saved revisions. **Publish…** lets you preview a saved revision and make it
public. Saving alone does not publish anything. Documents require Groups' native
Notes app.

Unsaved drafts stay in this browser tab when session storage is available; save
them to keep a revision on the ship. If someone else saves first, your save is
rejected and your draft stays intact. Copying a revision to another project
creates a separate artifact without sharing the original's private history;
sharing its source references requires confirmation.

## Ownership

Notes owns artifact bodies, body revision history, current titles and published
HTML. Harness keeps native note identities, projects, proposals, source references
and task assignments. Notes content is projected for reads, not maintained as a second
canonical document store. Changes made directly in Notes appear in Harness.
An artifact is a Markdown document, whether used privately, in a project, or as
a public page. A project collects related tasks and can separately share documents;
it does not own a conversation or confer execution authority.
Conversation membership uses immutable corpus scope identities, not mutable names.
Membership never shares the conversation's transcript or adds resource tools.
Notes notebook permissions are independent: changing Harness project membership
does not grant or revoke native notebook access. New artifacts use a private
Harness notebook; sharing that notebook in Notes can expose its other documents.

Models with the workspace tool grant share task records and project metadata
without task or project membership checks. They may read their own artifacts and
documents in projects to which their conversation belongs. Project contributors
may propose document changes. A live delegated child may use its parent's document
scope within the parent's current tool ceiling; it does not acquire approval or
publication authority. Removing document membership fences subsequent document access.

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

Publication through Workspace is a separate owner action selecting and previewing a saved snapshot.
Notes gives it a fixed public address:
`https://your-ship-domain/notes/pub/~host/notebook/note-id`.
Readers do not sign in. Your reverse proxy must forward this path to the ship;
Harness does not configure DNS, TLS, or the proxy.
Independently granted native Notes/Tlon permissions can permit equivalent edits
or publication outside Workspace; project roles do not restrict those grants.
The preview token fences the exact title/body/HTML, including native title changes.
Harness submits that HTML through Notes' existing publish action; it does not
serve a parallel public endpoint. The published snapshot does not change when the document is
edited. Public reads return only the published title and rendered body, never
project membership, proposals, task records, provenance or private revisions.
Unpublishing removes the Notes HTML snapshot; Notes may return its app shell at
the address instead of a 404. It cannot erase copies held by other people.
Rendered HTML is inert, with escaped raw HTML and a restrictive meta CSP.
Notes owns the HTTP response headers; Harness supplies the rendered document.

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

The task is the unit of work. A project is an optional collection: `task-create`
accepts a title, description, and optional project. Ungrouped tasks persist with
an empty project string and appear as `project: null` in JSON.

Agents maintain tasks when pursuing goals or coordinating independent work.
For complex or open-ended goals, they identify the outcome and constraints,
record concrete deliverables and completion checks, and break down only the
next useful pieces. Independent work can be delegated; coupled steps stay
together. The coordinating agent verifies results and reassesses what remains.
Simple questions need no task, and internal coordination stays out of ordinary
human replies unless the user asks to inspect it. Meaningful blockers and
decisions still surface to the user.

For [cross-ship work](peers.md#coordinating-work-across-ships), keep a task on
one home ship. Mutually workspace-trusted peers claim and update it through
peer tools, and `ask_peer` provides execution. No mirrored task list or new
administrative grant is required.
Any agent with the Workspace tool can create projects and create, assign, or
update tasks immediately. Task tracking has no per-task or project-membership
permission gate. Task updates, claims, assignments, and deletion check the current
version. Use the returned version, not an assumed starting value: a recreated ID
receives a version above its deleted incarnation, so stale commands cannot alter
the replacement. Unrelated writes leave an existing task's version unchanged. An outcome,
blocker, or completion requires neither a prior claim nor a result artifact.
A new or replacement result-document link must be readable by the agent linking
it. Keeping or clearing an existing link does not require document access, so a
private or archived result cannot block task bookkeeping. A link grants no access.

`task-assign {id,version,assignee}` records an existing agent's session name, or
clears the assignment when `assignee` is null. The head resolves its identity and
checks its current Workspace tool grant. Assignment records an actor without
changing task status, granting tools, creating a session, or dispatching work.
`task-claim {id,version}` atomically claims open work; assignment does not create
an exclusive permission to edit the task. Reopening a task clears its assignment.

`task-update` edits title, description, project, status, outcome, and linked
artifact in one version-checked write. Omitted fields stay unchanged; a null
project ungroups the task. Metadata-only edits preserve assignment.
`task-delete {id,version}` permanently removes the tracking record without
stopping an agent or deleting its documents. Agents retain useful outcomes;
deletion is not automatic cleanup of completed work.

Task forms support creation, editing, project moves, and deletion. Artifacts and
projects support editing and archive/restore; archiving preserves their history.
The task list hides tasks in archived projects; standalone tasks remain visible.
`#/tasks` opens the list and `#/tasks/TASK_ID` opens a task.

Execution belongs to the agent runtime. Agents do work with their granted tools,
or use granted `run_subagent` delegation and incorporate the returned answer.
Ordinary requests require no human task administration, project, or saved result.
Task records do not start or cancel inference, schedule an idle agent, or prove
external effects. A later update requires an active execution or delivery path.

[Conversation work controls](work-control.md) perform task bookkeeping and project
creation directly through current authority. Document membership, acceptance,
publication, and explicitly selected reviewed delivery retain their own checks.
Project editing and archival retain their protected management path because
projects also contain shared documents; the maintainer's document role permits
only its scoped metadata edits.

The [conversation work and selected delivery workflow](social-workflow.md)
separates ordinary answers from proposal review and a selected literal reply.
It retains source identities and delivery evidence without treating task
completion as approval or publication.

## Interfaces and bounds

The owner [work inbox](inbox.md) collects task and proposal metadata alongside
scheduled and admitted hand work. It links to exact source records without
starting inference or approving changes; a claimed task is not shown as running.

Owner ACP calls use `harness/workspace` with `{action, args}`. Native local-owner
pokes use mark `harness-workspace` with `{id, action, args}` and replies on
`/workspace/<id>`; subscribe before poking. `/workspace-events` emits a revision
invalidation, not private document contents. Owner `/x/workspace` scry retains
the typed workspace state. Models use `workspace` with `{action, args}`, where
`args` is a JSON object. The `help` action lists supported operations.
Models cannot use approval, publication or membership actions, including through
the administration tool. Scheduled work can inherit Workspace for task
bookkeeping; rehearsal runs do not receive it.

Work directories are most-recently-updated first, with stable identity ordering
for equal timestamps. Filtering and ordering precede pagination. Artifact and
project recency is saved independently of the bounded audit history. Metadata
lists use the watched Notes projection without fetching document bodies; opening
document content refreshes Notes and fails closed if it is unavailable.

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
external Notes edits are subject to its own limits. Assignment remains recorded
until agents update it; it does not expire when execution stops. Removing document
access cannot recall copies.

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
`/tests/harness-boundaries`, `/tests/harness-workspace-maintainer` and
`/tests/harness-project-client`.

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
