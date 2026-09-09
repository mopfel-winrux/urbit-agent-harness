# Shared scheduled work

Schedules belong to the Harness head, not to Tlon or another delivery adapter.
Open **Settings → Schedules** to inspect and cancel work from every hand. A job
records its originating hand, immutable source binding, actor, exact destination,
isolated run conversation, remaining runs, execution and delivery evidence.

Any authorized [conversation hand](hands.md) can use the scheduler. Tlon is one
such hand; it is not required for another hand's schedules. An active bound
conversation receives `cron_add`, `cron_list`, `cron_remove` and `reminder_add`.
These are implicit conversation capabilities, not configurable resource grants.
Unbound browser conversations, delegated work and scheduled runs cannot acquire
them merely by saving a `cron` flag in their configuration.

## Tasks and literal reminders

`cron_add` requires `schedule`, `timezone: "UTC"`, `prompt` (1–4,096 UTF-8 bytes),
and `runs` (a decimal string, 1–100). Five-field expressions support wildcards,
steps, ranges and lists. Weekdays are Sunday=0 through Saturday=6; restricted
day-of-month and weekday fields use OR semantics. The next occurrence must be
within the bounded four-year search horizon. Invalid or impossible expressions
are rejected. Recurring local time, IANA zones and DST are not supported.

`reminder_add` takes the exact conversation `destination`, literal `text`
(1–4,096 UTF-8 bytes), and a future RFC3339 `at` within 365 days. An explicit
offset or `Z` is required; unknown `-00:00` is rejected. Ask for the intended
offset rather than guessing. When due, the head admits a literal notification
and publication without inference or command parsing. `/cancel` in its text
remains text. Provider availability and credits are not needed at delivery time.

A model task receives its source configuration and a bounded snapshot of its
effective tool grants, but no source transcript. Scheduled runs cannot create
more schedules, delegate, execute JavaScript, or acquire administrative tools.
Editing a run's configuration cannot expand this ceiling. The head checks the
source binding and grants before admission and effect dispatch; a Tlon source
also retains its live actor and conversation authority checks.

Disabling or replacing a source binding, or changing its effective grants,
pauses affected jobs and fences their work. Re-enabling the source does not
resurrect a paused schedule: explicitly reschedule it. Ordinary hand workers
still own delivery claims and receipts, and must authenticate external actors.
Hand names and actor strings are routing identities, not credentials.

## Timing, delivery and retention

One head-owned Behn wake follows the earliest outstanding schedule deadline.
Downtime coalesces to one run, never a missed-run backlog. The run budget advances
in the same Gall transaction as ledger admission. Pending execution or pending,
claimed or uncertain publication blocks another run of that schedule.

Scheduled output uses the existing addressed hand outbox. A completed model run
is not a delivered reply; a scheduling acknowledgement is not a reminder receipt.
No automatic retry repeats an uncertain external send. The adapter's normal
claim, receipt and explicit reconciliation protocol remains authoritative.

The head retains up to 64 schedule records across all hands. Cancel stops future
work but cannot retract dispatched effects. Clear is allowed only for completed
or cancelled jobs whose work is settled. An unfired cancellation's unused run
budget does not prevent clearing. Run conversations, observations and delivery
receipts remain; clearing disables the run binding and strips its tool grants.

## Native and ACP API

Owner-authenticated ACP clients use:

| Method | Parameters | Result |
| --- | --- | --- |
| `harness/cron` | optional `binding` | Schedule rows, optionally scoped to a source binding |
| `harness/cron/add` | `id`, `binding`, `actor`, `kind`, `args` | Created schedule row |
| `harness/cron/cancel` | `id` | Updated schedule rows |
| `harness/cron/clear` | `id` | Remaining schedule rows |

`id` is a canonical native `@uv` string, such as `0v1`; use a fresh id for new
work. Repeating a create with the same id and payload returns the existing job;
a conflicting payload is rejected. `kind` is `prompt` or `reminder`, and `args`
contains that tool's fields. The source binding supplies the hand, destination
and source session; callers cannot replace these through the job arguments.

Native applications watch `/crons/[request-id]` on `%harness`, then poke mark
`%harness-cron` with `request:harness-cron`. A `%noun` fact returns
`(each json @t)`. The mark also accepts JSON `{id, action}`, with action keys
`add`, `list`, `cancel`, or `clear`. The read-only `/cron/json` scry projects
the same rows. These are same-ship/owner APIs, like the existing hand boundary.
Model tools additionally require an exact outstanding request and source input;
listing and cancellation cannot expose another source binding's schedules.

The JavaScript `HandClient` supplies `schedule(binding, options)`,
`schedules(binding)`, `cancelSchedule(id)` and `clearSchedule(id)`. It adds no
timer, model loop or separate delivery queue.

## Upgrade from Tlon-owned schedules

The upgraded Tlon adapter relinquishes its schedule wake and transfers its
retained records to the head once. Existing ids, run conversations, budgets,
last-input identities and publication receipts are retained. Missing source
authority or unfinished initialization is paused for inspection rather than
silently rebuilt. Legacy `harness/tlon/cron`, `/cancel` and `/clear` methods are
compatibility aliases to the shared head, not a second scheduler.

## Verification

`desk/tests/harness-cron.hoon` tests strict calendar parsing;
`desk/tests/harness-schedule.hoon` tests shared validation, isolation, evidence
gates, bounded advancement and store migration. The opt-in
`desk/tests-integration/harness-schedule.hoon` exercises full-agent reload,
single-timer replacement and the once-only legacy handoff. Run
`scripts/cron-conformance.mjs` with `SHIP_URL` and `SHIP_COOKIE` on a development
ship to exercise a non-Tlon hand, native/ACP parity, model-created schedules,
literal delivery, recursive-call denial and source revocation. It uses a local
deterministic model, leaves marked conversation/receipt evidence and cancels its
fixture schedules without changing global defaults or Tlon policy.
