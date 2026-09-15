# Work inbox

Open **Work** in the sidebar to inspect work recorded by the head.
The default **Needs attention** view includes uncertain results, blocked work,
and artifact proposals awaiting review. Running, Waiting, Finished and All
records are separate filters. A source selector narrows the records and counts.

This is a read-only projection, not another task engine. It cannot approve a
proposal, start a conversation, claim a task, cancel work, or retry a send.
Open the existing source surface to inspect the current evidence and act there.

## What the states mean

| Source | Evidence and interpretation |
| --- | --- |
| Task | Open and claimed tasks are **Waiting**, not proof of running execution. Blocked tasks need attention. Done means an outcome was recorded, not that external effects were verified. |
| Artifact proposal | Pending proposals need approval. Open the exact proposal to inspect its base, content, current access and review conditions. Accepted and rejected proposals appear under Finished; acceptance is not publication. |
| Admitted hand input | Execution and delivery are independent. Running requires a running execution record. Completed execution with pending, claimed or absent delivery stays Waiting. Failed execution or delivery is Blocked; uncertain delivery remains Uncertain even after cancellation. |
| Schedule | A schedule is a plan, not its execution. Active schedules are Waiting, paused schedules are Blocked, and ended/cancelled schedules are Finished. Admitted runs appear separately as hand inputs. |
| Pending Notes operation | Waiting or Uncertain, according to the retained native-operation record. Inspect its result; a missing result never authorizes another mutation. |

“Reply recorded delivered” means the hand recorded delivery. For Tlon DMs this
can be local Messenger acceptance, not remote arrival. Inspect the native
conversation and the existing delivery diagnostics before deciding to retry.
The inbox does not infer current tool authority from a binding's enabled flag.

Expand **Recorded evidence** for the stable record identity and applicable
execution, delivery, attempt, native reference, version or revision fields.
Task and proposal links open that exact record, even when it is beyond the
first page of its source directory. Delivery diagnostics still owns hand recovery.

Counts are **retained records, not unique tasks**: a task, its proposed
artifact, a schedule and a delivery receipt can describe related work. There is
no dismiss/read marker or inferred relationship store. Existing source retention
and explicit archive/retirement operations determine what remains available.

## Scope and freshness

The inbox includes tasks, proposals, admitted hand inputs,
schedules and pending Notes operations. It does not enumerate ordinary unbound
browser conversations, peer/subagent turns without a hand record, or adapter
work awaiting admission. Those remain in their existing conversation and Tlon
diagnostic surfaces. A zero count is not a whole-ship health certificate.

The mounted inbox refreshes on entry, focus and every 30 seconds while visible.
Hidden tabs and other routes do not run its safety poll. Focus overlaps share
one outstanding read. No document bodies or conversation transcripts are loaded
to populate the list. Row text is an excerpt of the retained work record, not a
fresh native-document read; proposal review rechecks the actual artifact.

Counts cover the selected source across the retained data, before state filtering
and pagination. Rows are ordered by descending source
evidence time and deterministic source/identity ties. Schedules and pending
Notes operations do not invent timestamps that their original records lack.

Cursor pages are fenced against changed work metadata and filter changes. If
the work changes, **Refresh from first page** starts a fresh view. A failed read
shows an error and marks any retained rows as stale; it never reports an all-clear
or presents old counts as current status. No cursor grants permission to act.

## API and implementation

Owner ACP method: `harness/inbox`.

```json
{"state":"attention","kind":"all","limit":24,"cursor":null}
```

- `state`: `attention` (default), `all`, `uncertain`, `blocked`, `approval`,
  `running`, `waiting`, or `finished`.
- `kind`: `all` (default), `task`, `proposal`, `input`, `schedule`, or `notes`.
- `limit`: 1–32; defaults to 24.
- `cursor`: an opaque continuation from the preceding page, or null.

The response contains `items`, source-scoped `counts`, the next `cursor` or null,
`observedAt` and `referenceOnly: true`. Row-specific fields refer to their
existing typed records. Administrative model dispatch is explicitly rejected;
models continue using their scoped work tools, not the owner aggregate.

`lib/harness-inbox` scans compact retained metadata and holds at most one page
plus a continuation candidate. Rows are most-recent-activity first across kinds
and states, with stable kind/identity ties. Only selected rows become JSON. It does not
replay session logs, read Notes, hash proposal bodies, mutate saved state, emit
effects or introduce a new persisted inbox/index. Read cost still scales with
the number of retained metadata records; a response bound is not an O(1) query.

## Verification

```sh
node --test fe/src/inbox.test.js
PLAYWRIGHT_CHANNEL=chrome npm --prefix fe run test:ui -- inbox.spec.js
```

From the local test ship's Dojo:

```text
-test /=harness=/tests/harness-inbox
-test /=harness=/tests-integration/harness-inbox
```

The native unit tests exercise classification, filtered pagination, stale and
cross-filter cursors, counts, timestamp provenance and excerpt-only projection.
The integration fixture inspects owner/model ACP handling in an isolated
evaluation without executing emitted cards. Browser fixtures cover source
links, errors, page recovery, hidden/unmounted polling and absence of inbox
mutations. Synthetic UI data is not evidence of native authority enforcement.

`scripts/inbox-conformance.mjs` reads the installed endpoint on a loopback ship
with `SHIP_URL`, `SHIP_COOKIE`, and `SOAK_EXPECT_SHIP` set. It validates bounded
state/source reads and parameter rejection without creating or changing work.
Its coverage depends on the existing retained data; empty sources are reported
honestly, not filled by making real external effects.

Opt-in visual evidence lives in `fe/tests/inbox.visual.spec.js`; run from `fe`
with `INBOX_VISUAL=1 PLAYWRIGHT_CHANNEL=chrome npx playwright test inbox.visual.spec.js`.
The [reliability runner](reliability.md) remains a separate sustained-operation
baseline, not a certification of every inbox source or cold restart.
