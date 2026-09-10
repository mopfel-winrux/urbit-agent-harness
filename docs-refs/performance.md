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

- The browser polls for ACP results. Completion latency includes the wait for
  a poll as well as the request round trip; shorter intervals increase traffic.
- Runtime file updates propagate tree versions and notify subscribers. Their
  cost depends on namespace contents and subscription structure.
- Session replay and history projections depend on event count. Session-index
  and corpus maintenance contribute additional work when session state changes.
- External inference, network requests and native Tlon publication add latency
  beyond Harness's local processing.

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

The read-only transport fixture is `scripts/performance-read-benchmark.mjs`.

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
