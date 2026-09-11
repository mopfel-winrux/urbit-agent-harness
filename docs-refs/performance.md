# Performance

Harness performance involves session processing, runtime verification, delivery
reconciliation and client transport. The benchmark fixtures isolate these costs
from external model latency.

## Runtime mark dispatch

The runtime prepares a mark's validator and type once and stores them in the
compiled artifact. It retains extraction failures and raises them when the
corresponding arm is used. Each input noun is validated independently; prepared
dispatch does not cache validation answers for different inputs.

File writes execute in short-lived virtual evaluations. Keeping dispatch in
the compiled artifact makes it available across those evaluation boundaries.
The runtime resolves marks through their code namespaces and enforces permission
checks independently of dispatch preparation. The verifier executes its own
checks against the head's published state.

The pinned-runtime adaptation lives in `build.zig` and fails closed if the
upstream integration point changes.

## Publication selection

Tlon reconciliation filters for this hand's pending publications before sorting.
It resolves admission timestamps once per candidate and uses effect ID as a
deterministic tie-breaker. Delivered records serve as audit evidence rather than
runnable work. Claims, uncertain outcomes and failed records are not retried
implicitly. Destination blocking and authority checks govern delivery.

## Sources of latency

- The browser receives ACP results through an authenticated Eyre subscription.
  Safety polls cover missed events and unavailable subscriptions.
- Runtime file updates propagate tree versions and notify subscribers. Their
  cost depends on namespace contents and subscription structure.
- Session replay and history projections depend on event count. Session-index
  and corpus maintenance contribute additional work when session state changes.
- External inference, network requests and native Tlon publication add latency
  beyond Harness's local processing.

## Browser idle work and subscriptions

An open conversation checks snapshots every 600 ms while loading or running,
and every 10 seconds while idle. Hidden tabs use 2.5 seconds and 30 seconds,
respectively. Session notifications, focus, reconnection, sending and completion
refresh sooner. Token chunks do not each trigger a snapshot request. Reads are
single-flight; an invalidation during a read gets a trailing read so a stale
response cannot hide the newer state until the next idle interval.

ACP watches `/v1/<connection>/client` through a separate disposable Eyre event
channel. The command channel and durable ACP queue retain their identities.
Eyre events and ACP messages have separate cumulative acknowledgements, batched
over 250 ms during push delivery. RPC results do not wait for those ACKs or for
their send's HTTP response to finish. Concurrent watch/scry deliveries cannot
advance acknowledgement past an unseen ACP frame.

With a healthy watch, queue safety reads use a one-second cadence for pending
RPCs and 15 seconds while idle (30 seconds in hidden tabs). Unavailable watches
restore the existing faster polling and retry subscription after 10 seconds.
Missing Eyre heartbeats for 45 seconds also restore fallback; this is a watch
health check, never an RPC deadline. Reconnecting a watch does not replay RPCs.
A genuinely missing or closed ACP queue uses a fresh connection identity and
rejects unresolved calls with the existing check-before-repeating guidance.

The watch covers this ACP connection's updates, not every native hand's state
changes. Idle snapshot polling remains necessary for changes without a matching
notification. Native hand execution and delivery authorization are unchanged.

## Performance regression checks

Run deterministic request-count and retention checks without a ship:

```sh
npm run test:performance --prefix fe
```

Use `PLAYWRIGHT_CHANNEL=chrome` when testing with an installed Chrome. The suite
covers idle/active snapshot budgets with 95 and 4,096 retained messages,
10,000-entry unchanged-history reuse, notification races, stream framing,
ACK coalescing, replay/gap handling, and catalog/conversation-list read budgets.
These checks constrain work and preserve behavior without fragile CPU timings.

For the real subscription/recovery boundary on a local development ship:

```sh
SHIP_URL=http://127.0.0.1 SHIP_COOKIE=/path/to/private-cookie \
  node scripts/acp-subscription-conformance.mjs
```

This creates and removes only temporary transport channels. It checks live push,
silent watch loss, fallback, reconnection, and no RPC replay. No conversation,
configuration, inference, or external publication is created.

## Scheduler maintenance

Scheduler maintenance follows changes to jobs, sessions, hand evidence and
permission inputs, or the scheduler's armed deadline. Routine ACP reads and
acknowledgements do not sweep active schedules. The deadline includes busy-job
backoff; a receipt can trigger an earlier reassessment. Active jobs without an
armed timer are checked and re-armed after reload or a consumed wake. Settled
jobs alone do not require a timer.

This cadence does not cache authorization. Scheduled execution and hand delivery
check live authority at their effect boundaries. Local source binding and grant
changes trigger maintenance, and re-enabling a revoked source does not resume
paused jobs automatically.

## Full-turn benchmark

The full-turn fixture uses the actual browser ACP client, an immediate local
model, one local HTTP tool, and a second immediate model response. It creates
unique sessions, changes only their configuration, and deletes them afterward.
No paid inference or external publication is involved.

The fixture reports admission, tool dispatch, tool resumption, completion and
total elapsed time, with median, p95 and maximum values. These are client-observed
wall times, not CPU-only measurements or production latency guarantees.

Build and install Harness on a development ship before running the fixture.
Do not run native compilation or other live workloads alongside measurements.

```sh
SHIP_URL=http://127.0.0.1 SHIP_COOKIE=/path/to/private-cookie \
  node scripts/performance-turn-benchmark.mjs
```

Use `BENCH_TURNS=0,64,256`, `BENCH_REPEATS=5`, and `BENCH_RAW=1` to select
history sizes, repetitions and per-turn samples. Re-run after cold compilation
has settled when comparing steady-state performance. Keep outliers visible.
Measure cold-start behavior separately, and use enough repetitions to assess
tail latency. Synthetic history and local endpoints do not represent external
model, network or Tlon publication costs.

Optional `BENCH_MAX_P95_MS` and `BENCH_MAX_GROWTH` fail the full-turn fixture when
any workload exceeds an absolute p95 budget or its median exceeds the first
workload by the given factor. Calibrate these on the same development machine;
they are not production latency promises. Budget failures still clean up the
fixture sessions. Keep the first workload at zero prior turns for growth checks.

The read-only transport fixture is `scripts/performance-read-benchmark.mjs`.
It reports initialization, the parallel Settings read batch, subsequent RPCs
and idle traffic separately. Model-catalog I/O and browser rendering are outside
these timings. Include active schedules when measuring a scheduler workload;
an empty scheduler does not exercise live job-authority checks.

## Native benchmarks and correctness

Pure native benchmarks cover mark dispatch, publication selection, session
replay, history projections, session indexing and corpus synchronization.
Comparisons include output-equivalence assertions; their timing ratios apply
to the measured operations, not the entire runtime. Run them from Dojo:

```text
-test /=harness=/tests-integration/harness-performance
-test /=harness=/tests-integration/harness-mark-performance
```

`tests/harness-marks` covers mark/input isolation and deferred extraction
failures. `tests/harness-hand-pending` covers chronological selection, ties,
missing admissions and non-runnable delivery states. Hand, shadow and
live cancellation/fault-injection checks cover the surrounding semantics.
