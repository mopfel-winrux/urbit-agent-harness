# Conversation work and selected document delivery

A human asks for work in a conversation. The agent uses that conversation's
granted tools and returns the answer there. It does not require a project,
task creation, worker launch, claim, or saved artifact to answer. If it lacks
a needed capability, it explains the specific limitation in the conversation.

For independent subtasks, granted delegation returns the answer to the caller.
The calling agent integrates it and replies through the existing hand flow.
There is no task-specific execution loop or automatic permission expansion.
A final answer uses the conversation's normal response authority; it is not
publication to an unrelated destination.

## Agent-managed tasks

A task is a unit of work with a brief, status, assignment, outcome, and optional
document link. A project collects related tasks and is optional. Agents create
and maintain tasks toward goals when durable tracking helps; the conversation
remains the human's place to request work and receive results.

Agents with the Workspace tool share task tracking and project metadata.
Project creation and task bookkeeping execute immediately, without membership
or per-task permission gates. Current versions prevent stale writes. A claim
and a result artifact are optional; another agent's assignment is coordination
data, not an editing permission boundary.

`task-assign` records an existing agent by session name, or clears the assignment
with null. The head verifies that agent's Workspace grant. Assignment changes
neither tools nor task status and does not dispatch execution. The current agent
runtime and granted delegation execute the work; `run_subagent` returns the
child's answer to its caller.

A task's status records progress; it does not prove that inference is active or
that an external action happened. Agents read current task state before reporting
it. A blocked task does not schedule a future wakeup. Agents do not promise a
later update without an active execution or delivery mechanism.

## Selected document delivery

Saving a shared document, accepting an exact proposal, publishing a public page,
and sending a selected saved result are distinct from answering a question.
Document membership shares selected documents, not private source transcripts.
Agents must not copy private conversation material into shared task records without
authorization. Saved document acceptance and publication retain owner authority.

An owner can explicitly select a saved task result for reviewed delivery. The
preview includes the exact accepted body, recipient, and destination. Confirmation
queues literal hand output; completion of a task does not establish delivery.
Current source authority, destination, content, and incarnation are checked at
delivery claim. Uncertain effects require reconciliation, never a blind resend.
Later document edits do not rewrite an existing output.

The [work inbox](inbox.md) exposes tasks, pending drafts, and selected delivery
receipts. [Workspace](workspaces.md) owns task tracking and document access;
[conversation controls](work-control.md) handle inspection and exact protected
changes. The [scheduler](scheduling.md) handles explicitly arranged future work.

## Local verification

```sh
SHIP_URL=http://127.0.0.1 SHIP_COOKIE=/path/to/test-ship-cookie \
  SOAK_EXPECT_SHIP='~your-test-ship' node scripts/social-workflow-conformance.mjs
```

The fixture requires matching loopback host and owner identity. It uses a local
deterministic model, a uniquely named hand with no Tlon adapter route, and an
in-memory delivery sink. Real head, Workspace, native Notes, scheduler and inbox
operations exercise admission deduplication, worker attribution, owner-only
review/publication, exact selected reply text, destination fencing and uncertain
delivery recovery. No remote provider, real social send or public page is used.

Cleanup cancels fixture schedules, disables fixture bindings and archives the
fixture project and artifact. Conversations, tasks, proposals and receipts stay
available as audit evidence under the printed fixture prefix. An incomplete
run leaves its task blocked and reports cleanup failures rather than hiding
unresolved work. The fixture does not change global model settings or policy.
