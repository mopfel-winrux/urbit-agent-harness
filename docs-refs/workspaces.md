# Artifacts and projects

Editable, ship-owned documents, shared project work, and explicitly published
pages. This feature adds no inference loop or scheduler and does not require Tlon.

## Use it

Open **Artifacts** in the sidebar to create a Markdown document. Save a revision,
inspect History, and use **Publish…** to choose a saved revision and URL name.
Review the exact public preview and confirm publication. The public address is
`https://your-ship-domain/harness-pages/<slug>`; readers do not sign in. Your
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

Harness owns artifacts, immutable revisions, projects, proposals and task claims.
An artifact is a Markdown document, whether used privately, in a project, or as
a public page. A project is an explicit sharing scope, not a conversation owner.
Conversation membership uses immutable corpus scope identities, not mutable names.
Membership never shares the conversation's transcript or adds resource tools.

Models with the workspace tool grant may read their own artifacts and projects
to which their conversation belongs. Project contributors may propose document
changes and coordinate tasks. A live delegated child may use its parent's project
scope within the parent's current tool ceiling; it does not acquire approval or
publication authority. Removing membership fences subsequent access.

## Revisions, review and publication

Human edits save an immutable revision using an expected current revision.
Agent edits create proposals containing the exact replacement, source references,
author and base revision. Accepting a proposal checks that base and live access;
stale proposals cannot overwrite newer work. Rejection preserves the proposal.
Shared accepted documents are knowledge, not system instructions.

Publication is a separate owner action selecting an exact accepted revision and
public URL slug. The published snapshot does not change when the document is
edited. Public reads return only the published title and rendered body, never
project membership, proposals, task records, provenance or private revisions.
Unpublishing removes the endpoint; it cannot erase copies held by other people.
HTML is inert, has no scripts, and cannot access the authenticated application.

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

Limits are explicit rejections: 512 artifacts, 128 projects, 2,048 proposals,
2,048 tasks, 64 members per project, 256 accepted revisions per artifact, 256
title bytes, 256 KiB body bytes, 16 source references and 64 MiB conservatively
accounted retained content. Archiving hides records; it does not delete them or
reclaim capacity. Accepted revisions and proposals remain retained; the audit
stream retains the most recent 2,048 changes. Claims require explicit release
or owner intervention if a worker stops. Removing access cannot recall copies.

Public Markdown supports headings, paragraphs, lists, quotes, code fences,
simple tables and limited inline formatting. Raw HTML is escaped, remote images
are not embedded, and scripts/forms/external resources are blocked by response
policy. It is intentionally not a general-purpose HTML host. Links written in
the document body are public content; separate source references stay private.
Inspect the publication preview rather than assuming full editor/GFM parity.

## Local verification

Run `npm test` and `PLAYWRIGHT_CHANNEL=chrome npm run test:ui` in `fe`, then
`zig build` and `node --test scripts/*.test.mjs` at the repository root. Native
tests include `/tests/harness-workspace` and `/tests/harness-boundaries`, with
version-20 migration preserving the prior envelope and existing tool settings.

`SHIP_URL=http://127.0.0.1 SHIP_COOKIE=/path/to/local-cookie node scripts/workspace-conformance.mjs`
checks real local Gall, ACP, deterministic model tools and anonymous public HTTP.
It refuses remote hosts, creates uniquely named local fixtures and archives its
documents/projects after unpublishing any pages. Fixture conversations and
historical records remain for inspection. It makes no paid provider requests
and changes no global configuration.

The opt-in installed-UI smoke test is
`WORKSPACE_LIVE=1 SHIP_URL=http://127.0.0.1 SHIP_COOKIE=/path/to/local-cookie PLAYWRIGHT_CHANNEL=chrome npx playwright test workspace-live.spec.js`
from `fe`. It creates, edits, reloads and archives a private local artifact, checks
App navigation and the publication confirmation, and publishes nothing.
