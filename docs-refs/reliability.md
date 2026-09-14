# Sustained operation and recovery

The next development milestone is dependable unattended operation before broader
agent responsibility. This acceptance workload builds on the existing focused
conformance tests; it is not a new runtime, scheduler or health authority.

## Local acceptance runner

`scripts/reliability-soak.mjs` runs the actual browser ACP client in Node, using
multiple independent connections and a separately observed read workload.
It refuses non-loopback URLs and checks both the host and authenticated ship
against `SOAK_EXPECT_SHIP` before creating transport connections. Use a disposable
local ship. Do not run native compilation alongside latency measurements.

Start with application reads only:

```sh
SHIP_URL=http://127.0.0.1 SHIP_COOKIE=/path/to/local-cookie \
SOAK_EXPECT_SHIP='~your-test-ship' node scripts/reliability-soak.mjs
```

The read probes cover basic HTTP responsiveness, Settings, the Notes-backed
artifact directory and unified search status. Additional connections remain open
and exercise the browser transport's idle subscription behavior. This is **not**
a rendered-tab test: it does not exercise React polling, layout, service workers
or browser memory.

To exercise accepted work and recovery, add `SOAK_WORK=1`:

```sh
SHIP_URL=http://127.0.0.1 SHIP_COOKIE=/path/to/local-cookie \
SOAK_EXPECT_SHIP='~your-test-ship' SOAK_WORK=1 \
SOAK_DURATION_MS=120000 SOAK_TURN_INTERVAL_MS=1500 \
node scripts/reliability-soak.mjs
```

Work mode creates uniquely named conversations and configures **only those
conversations** with a local synthetic provider and a local HTTP POST tool.
There are no paid provider calls, public posts, Notes mutations or global
configuration changes. It counts each local effect before returning its receipt.
That makes duplicate execution observable rather than hiding it with fixture
deduplication. Growing conversation histories remain on the real Harness head.

The first worker cycles through these cases; other workers continue ordinary
local tool turns concurrently:

| Case | Required evidence |
| --- | --- |
| Ordinary turn | One effect, its actual tool receipt and completed inference |
| Silent watch loss | Polling delivers the result; the real heartbeat guard restores the watch without resending an RPC |
| Originating client closes after the effect | A new client observes completion; the already accepted effect occurs once |
| Provider returns 503 | No effect or implicit provider retry; subsequent turns can still run |
| Cancellation after the effect | Uncertain cancellation is retained; the late reply cannot revive work |
| Grant revoked before tool dispatch | No effect; the continuation receives a denied-tool receipt |

Work mode must cover all six cases to pass. A short observation window or too
small a round cap is insufficient coverage, not a green recovery test. Silent
watch loss intentionally uses the production 45-second heartbeat timeout and
10-second resubscription backoff. The runner does not shorten either timeout.

## Long observation windows

The same runner supports up to 24 hours:

```sh
SHIP_URL=http://127.0.0.1 SHIP_COOKIE=/path/to/local-cookie \
SOAK_EXPECT_SHIP='~your-test-ship' SOAK_WORK=1 \
SOAK_DURATION_MS=86400000 SOAK_MAX_ROUNDS=256 \
node scripts/reliability-soak.mjs
```

This creates a bounded amount of conversation history, then continues read/idle
observation after the round cap. It does **not** generate active work all day once
that cap is reached. Maximums are four workers, 1,024 rounds and 24 hours; requests
to the local model are capped at 4 MiB to prevent an accidental unbounded replay
workload. The configured context is large enough for this bounded synthetic
history; any unexpected compaction request fails the fixture instead of selecting
a real provider.

`--help` lists all options. `SOAK_MAX_READ_MS` adds a machine-calibrated budget for
the complete read batch. A failure stops new work; it does not retry a mutation.
`SOAK_WORKER_PID` optionally samples a specifically selected local Urbit worker's
RSS. Process-start identity is checked so PID reuse cannot silently measure a
different process. No ship restart or process signal is injected by the runner.

## Evidence and cleanup

Before connecting, the runner prints a newly created private temporary directory.
`events.jsonl` records fixture identities **before** their creation requests,
per-turn cases, probe timings and failures. `report.json` is written once at the
end with the verdict, coverage, transport counts, bounded latency summaries and
cleanup failures. Reports do not include cookies, transcripts or provider keys.
Source Git revision, dirty-worktree state and host characteristics describe the
test source and machine; the installed ship release is explicitly not inferred
from the working tree.

Ctrl-C stops this Node runner, not the ship. Cleanup uses a fresh connection,
cancels only the exact fixture session identities, verifies they have no pending
inference/tools, and removes them. It never deletes other conversations or Notes.
An unavailable ship or uncertain cleanup is reported with the retained identity;
inspect it before repeating anything. Interrupted runs are not passes. If the
runner is forcibly killed, the journal remains; there may be no final report.

Latency counts, means and maxima cover the full run. Percentiles cover the most
recent 512 samples, explicitly labeled as such. Report memory is bounded; the
on-disk journal grows with the capped observation duration. HTTP/RPC wall time
includes queues and transport: **it is not a measurement of Arvo event CPU time**.
RSS is not live loom occupancy and cannot by itself establish a memory leak.

## Separate boundaries

Run deterministic runner tests with:

```sh
node --test scripts/reliability.test.mjs
```

The full-agent `/tests-integration/harness-reload` checks subscription recovery
and re-observation of an already-sent Notes request without another mutation
poke. Its cards are inspected in an isolated evaluation, never executed. It is
not proof of durability across a real process restart.
Assertions execute inside that evaluation and return only compact test results:
revalidating complete emitted card types outside it can itself be expensive
enough to block the ship's event loop.

Keep these checks distinct:

- Real process restart and cold installation, on a disposable ship.
- Cold Notes/Groups compilation and updates; a Harness soak cannot certify a
  neighboring desk's compilation performance.
- Native Notes result recovery and publication (`notes-workspace-conformance.mjs`).
- Actual browser tabs and service-worker behavior, including idle/hidden states.
- Scheduled delivery and peer/subagent settlement, covered by focused fixtures.
- Full replay scaling and live loom measurement, covered by dedicated benchmarks.

A short passing run establishes the exercised cases and duration only. It does
not establish 24-hour stability or replace the boundaries above.

## Development sequence

1. Establish sustained-operation, fault-recovery and cold-start baselines;
   fix measured failures and bound replay/storage growth.
2. Project existing receipts into a practical work inbox: running, blocked,
   awaiting approval, finished and uncertain delivery, each with evidence.
3. Add narrowly delegable project-maintainer authority and scoped client access,
   auditing equivalent effects through Workspace and native tools.
4. Complete one explicit social request → accepted task → worker conversation →
   reviewed artifact → reply workflow, using the existing head and scheduler.
5. Add sourced project decisions, constraints and open questions with explicit
   correction/supersession, without mixing private conversation histories.

The runner and reload checks are the first increment of item 1, not completion
of this roadmap.

Item 2 provides the [read-only work inbox](inbox.md). The first increment of item 3
provides [project maintainers and read-only client keys](project-access.md), with an
explicit audit of equivalent native/tool authority. It adds no delegated
approval/publication or client execution. Item 4 has an owner-directed
[request-to-reviewed-reply procedure and local end-to-end check](social-workflow.md).
Its social transport and delivery sink are synthetic; real social transport,
integrated workflow controls and typed request/task relationships remain open.
Sourced project knowledge is item 5.
