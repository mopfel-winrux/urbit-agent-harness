# Conversation work management

`/work` manages projects, tasks, and artifact review through human conversation
ingress: ACP, native sends, and hands. The Harness GUI is optional for these
operations. `/work` and `/work help` show a short introduction. Use
`/work help projects`, `/work help tasks`, or `/work help review` for focused
examples. `/work projects` and `/work tasks` work without an empty JSON object.
Human help, reads, and approval receipts use ordinary language. Replies name the
task and the relevant outcome, then offer a useful next action. Approval previews
show the meaningful change, full draft or reply body, and destination. Canonical
arguments and execution records are available through Details; Workspace tool
results retain structured JSON.

In an owner Tlon DM, these replies also carry native A2UI navigation: project
and task selection, pagination, archive filters, task creation entry points,
task outcomes, draft review, saved documents, and explicitly selected
send actions. Buttons send the same `/work` commands into the DM.
Use `/work project-new Weekend plans` to name a project, or
`/work task-new Draft a packing list` to name a standalone task without JSON.
The entire text after `task-new` is the title. Use `task-create` with an optional
`project` field to group a task. Project creation and task bookkeeping execute
immediately. The merged Tlon
catalog provides buttons, not a general text-entry form; naming happens in chat.
The human reply precedes its controls inside the card. Verified cards use the
merged renderer's `storyMode: "fallback"` so supporting clients show one reply,
not a card followed by duplicate command text. Other clients and text-only hands
receive the ordinary reply with short command references. An uninspected model
preparation never hides the model's message and only offers Review change.

Native headings identify the task or outcome. Project and task names use wrapping
choice rows; short utility actions share a wrapping button row. Task views show
the title, status, description, and outcome, then Refresh task or Read result
and More actions. Refresh task is a wrapping choice row. A standalone task has
no Open project action. Technical fields are not ordinary chat copy. Native
styling comes from Tlon's merged components.

Navigation cards require a matching head command result and current owner
authority. If the displayed read changes before delivery, the card offers
refreshing instead of actions against mismatched content. Button clicks recheck
current permissions and versions through normal command admission. Read cards
do not depend on a pending approval request and cannot confer approval authority.

Project and task lists, and individual project/task reads, use readable chat
responses with inspection and pagination commands. `/work projects` excludes
archived projects; `/work tasks` includes standalone tasks and excludes tasks
whose project is archived.
Use `/work projects all` or `/work tasks all` to include them. Completed tasks
in active projects remain visible. No records are deleted by these view filters.
Filtering precedes pagination and uses current permissions. JSON arguments support
`includeArchived`, `project` (tasks), `offset`, and `limit`; next-page commands retain
the supplied filters. `/work project PROJECT_ID` and `/work task TASK_ID` open
details without requiring JSON. Workspace tool/API reads remain structured and
include archived records unless `includeArchived: false` is supplied.

Reads, project creation, and task bookkeeping run immediately with current
agent or human authority. Task tracking and project metadata do not require
document membership. Other management changes prepare an exact payload
and offer an action-specific confirmation, Cancel, and optional Details:

```
/work result <id>
/work confirm <id>
/work reject <id>
/work details <id>
```

`result` shows the exact pending preview or the durable execution receipt.
`confirm` submits the prepared change once; `reject` settles a pending request
without executing it. Neither rejection nor cancellation undoes a submitted
external operation. Confirmations expire after fifteen minutes. Changed work
requires a new preview and confirmation.

Human navigation uses short references for projects, tasks, documents, and drafts.
Approval tokens retain the full content digest. Canonical IDs remain accepted.
A reference must resolve uniquely;
collisions fail closed. References do not grant authority. Approval references
bind the canonical request ID, action, and arguments; the retained request,
same-person/conversation checks, current permissions, expiry, and state fence
remain authoritative. Details explicitly reads the canonical JSON record.

For example:

```
/work tasks {"project":"meeting","limit":4}
/work task-create {"id":"agenda","project":"meeting","title":"Draft the agenda"}
/work task-create {"title":"Check tomorrow's forecast"}
/work task-assign {"id":"agenda","version":1,"assignee":"researcher"}
```

Task creation records a unit of work immediately, with an optional project.
It creates no agent, membership grant, or confirmation request. Agents with
the Workspace tool can update tasks directly, regardless of assignment or
document membership; claiming is optional coordination. Task updates, claims,
and assignments check the current version. Assignment names an existing agent with the Workspace
tool; `assignee: null` clears it. The head resolves the agent identity. Assignment
changes neither task status nor tools and does not dispatch execution.

`task-update {id,version,title?,description?,project?,status?,outcome?,artifact?}`
changes only supplied fields. Use `project: null` for ungrouped work.
`task-delete {id,version}` permanently removes only the task record; it does
not cancel execution or delete documents. These operations execute immediately
under Workspace authority, without a protected-change confirmation request.

## Conversation execution and reviewed replies

Do the requested work in the current conversation, using its granted tools.
Ordinary questions need no workspace record. For independent work, a granted
`run_subagent` call returns the child's answer to its caller. The calling agent
reports results and blockers in the conversation. Task records do not provision
sessions, start inference, grant tools, or arrange future delivery.

For a separately selected accepted document, owner conversations can prepare
an exact reviewed send through `/work` or the `manage` path:

```
/work task-reply {"id":"agenda","version":3,"artifact":"agenda-result","revision":1,"binding":"my-hand-binding","actor":"alice"}
```

`task-reply` requires a done task with a linked artifact and an exact accepted
revision. Its preview shows the complete body and destination. Confirmation queues
that literal body, limited to 1–4096 bytes, through the existing hand ledger. It
does not invoke a model, interpret slash commands, or publish a public Notes page.
The receipt's `done` status means submission completed; its separate `delivery`
field reports pending, claimed, delivered, failed, uncertain, or abandoned.

Open `/work task TASK_ID` to read the recorded outcome or linked result. More actions
contains **Review drafts**, **Read saved document**, and **Mark complete**.
`/work finish TASK_REF` records completion against the current task version
without a confirmation step. Draft reading is paged;
acceptance opens a separate complete preview before confirmation. Acceptance
saves a revision but does not mark the task done. Marking done records task
completion but does not approve a draft or send anything.

For a done task with a saved result, **Send here** sends
`/work task-send TASK_ID`. The head prepares `task-reply` using the current task
version, linked artifact's accepted head revision, and the current owner hand's
binding and actor. It does not infer a destination from task text. The preview
must still be inspected and confirmed; the shortcut never sends immediately.
Use explicit `task-reply` arguments to prepare another authorized destination.

The head rechecks the approving conversation's authority, its incarnation, the
destination, and accepted content when a transport claims or retries delivery.
The approval binds the selected task, document, document project, and destination,
not unrelated workspace writes. Changes to those dependencies while a reply waits
in the queue require reconciliation and a new approval. Reconcile
the existing effect first: pending, claimed, uncertain, and delivered replies block
another reply for the same task, revision, binding, and actor. An explicitly failed
or abandoned effect permits a new approval; an approved replacement fences retries
of the earlier failed effect. An uncertain effect never retries
automatically. Authorized hand diagnostics retain receipts for reconciliation after
delivery authority changes; `/work result` still requires its original conversation
and current management authority. Reading a receipt does not send anything.

## Natural-language requests

The `workspace` tool accepts `action: "manage"` with an encoded arguments object
such as `{"action":"task-create","args":{"project":"meeting","title":"Draft the agenda"}}`.
It uses the human origin's current work permissions. Reads, project creation,
and task bookkeeping run immediately. Other changes prepare a request. The human sends the returned `inspect` command
to obtain the head-generated exact preview before confirmation is accepted.
Model prose and tool results do not count as that preview, and model-generated
slash commands are never executed as human input.
The model administration path cannot submit hand observations or delivery
receipts. It cannot use an administrative ACP prompt as human work authority.

Normal agent Workspace operations share task tracking and project metadata
under their tool grant. Document operations retain their scoped membership and
proposal semantics. Project edits through an agent's own authority require the
maintainer role and cannot archive a project. Project editing and archival
through human management retain exact preparation because they also affect
shared documents. Delegated and scheduled work cannot use human management.

## Optional Tlon controls

Owner DM replies can include native A2UI buttons alongside the complete ordinary
message. A head-generated pending protected preview offers an operation-specific
confirmation, **Cancel**, and **Details**. A natural-language preparation offers
**Review** first; model prose cannot enable confirmation. Settled requests offer
an appropriate next action and Details. Changed or expired inspected requests
offer Tasks and Projects recovery navigation. Buttons send the same literal `/work` commands
into the conversation, subject to all current server-side checks.

The payload uses the `tlon.a2ui.basic.v1` catalog's `Text`, `Column`, `Row`,
`Divider`, `Choice`, and `Button` components and `tlon.sendMessage`. It uses the renderer merged into
`tlon-apps/develop`; it does not require a client patch. The ordinary message
remains in the post; supporting clients use the complete card's fallback mode
to show its human content once. Channels and other hands remain text-only, and an
unavailable optional projection cannot block reply delivery. Posted cards are
snapshots, not live status: inspect again for a current receipt.

The merged web renderer's buttons do not expose keyboard-button semantics.
Visible text commands provide the complete keyboard-accessible management path;
the optional controls are not required to prepare, inspect, confirm, or reject.

## Authority and persistence

Local human ingress uses local owner authority. Tlon uses its live owner DM
policy; a public channel or a trusted non-owner does not acquire owner access.
An enabled generic hand can receive an explicit owner management grant:

```
/work hand-access {"binding":"my-hand-binding","actor":"alice","owner":true}
```

The grant itself requires owner preparation and confirmation. Use `owner:false`
to revoke it. A non-owner hand requires its current Workspace tool grant for task
tracking and project metadata. Document operations also require their current
document permissions. Membership shares documents, never private transcripts;
task assignments grant neither document access nor execution tools.

Confirmation binds the exact session incarnation, source, binding, address, and
actor. Permissions and document content are checked again at execution. Stored
results also require current authority; knowing an ID grants nothing. Each approval
binds its operation's records: project changes bind the selected project; document
changes bind the selected document, proposal where applicable, and document project;
replies also bind the selected task and destination. Hand-access grants bind the
destination and existing grant. Unrelated work does not invalidate an approval.
Native Notes content is checked independently.

Requests and results survive reload. Notes writes use the existing asynchronous
Notes request ledger; a submission acknowledgement is not a successful result.
Inspect `/work result <id>` for completion. At most 2,048 approvals can be active:
unexpired pending requests and all running requests count toward admission.
Completed, failed, rejected, and expired pending requests do not consume active
capacity. Receipt history remains retained for inspection and delivery deduplication;
the active limit does not bound historical storage or silently delete receipts.
Arguments are limited to 32 KiB; reads and exact preparation previews are limited
to 48,000 encoded bytes. Preparation also bounds the readable receipt to 48,000
bytes. Reads use at most four list items and paged document bodies.
Review and publication previews show complete selected content; an oversized
preview is rejected rather than silently truncated. Confirmation requires a
head-generated preview whose complete text matches the current preview within
the latest 64 conversation events; inspect again
if intervening conversation moves it outside that window.

## Verification

`desk/tests/harness-work-control.hoon` checks origin, expiry, changed content,
one-shot settlement, exact-preview provenance, and current result visibility.
The focused full-head test is
`desk/tests-integration/harness-work-control.hoon`.

`desk/tests/harness-tlon-work-card.hoon` covers optional card selection and states;
`desk/tests-integration/harness-tlon-work-card.hoon` exercises the head projection
with synthetic live Tlon authority. `desk/tests/harness-tlon.hoon` verifies that
native DMs retain the optional payload while channel sends omit it.
`+harness!harness-work-card-fixtures` produces synthetic ready, inspect, settled,
and expired renderer fixtures directly from the shipping Hoon projection. They
can be validated against the merged Tlon schema and rendered by its existing
`ChatMessage` fixture without delivering messages.
`+harness!harness-work-navigation-fixtures` supplies project/task browsing,
task outcomes, draft review, and saved-document examples from the same shipping
read and card functions.

Run the loopback-only live fixture with:

```sh
SHIP_COOKIE=/path/to/test-ship-cookie SOAK_EXPECT_SHIP='~test-ship' \
  node scripts/work-control-conformance.mjs
```

It checks human-only confirmation, cross-actor denial, revocation, stale content,
task creation, real Notes review, literal reviewed replies, delivery receipts,
uncertain-effect reconciliation, and a synthetic model that prints a confirmation
command without executing it. The full-head task-note test checks direct creation
and completion with no claim, artifact, approval, membership grant, or new agent. The live
fixture disables its hand and archives its project and
artifact while retaining audit records. It sends no social messages and uses no
paid inference.
