# Development and verification

The build assembles an installable `%harness` desk from Harness sources, the
React app and pinned runtime dependencies. Live tests exercise the installed
desk; JavaScript and artifact tests also run without a ship.

## Repository map

| Path | Responsibility |
| --- | --- |
| `desk/app` | Gall lifecycle, ACP transport, static serving and Tlon adapter |
| `desk/sur` | Typed contracts and saved-state envelopes |
| `desk/lib` | Pure semantics, codecs, grants, projections and effect bindings |
| `desk/tests` | Default native unit tests |
| `desk/tests-integration` | Heavy agent evaluation and corpus benchmark fixtures |
| `fe` | Replaceable React ACP client |
| `acp` | Stdio adapter and conversation-hand helper |
| `scripts` | Dependency staging, artifact checks and live conformance fixtures |
| `docs-refs` | Architecture, usage guides and protocol references |

[Architecture](architecture.md#code-boundaries) maps the main libraries.
New integrations should use an existing typed boundary before adding a new
lifecycle event.

## Assemble and install

```sh
zig build
```

Zig fetches the pinned Grubbery source, builds the frontend, assembles the minimal
runtime, names its Gall agent `%harness-grub` and overlays this desk. Tlon staging
includes only the required protocol source closure, not the Groups application.
Build files and staging scripts define the dependency revisions.

For a fresh installation, use the [README instructions](../README.md#build-and-install).
`zig build -Ddesk=/path/to/pier/harness` synchronizes the assembled desk into
that mount, removing files absent from the output. Do not use a full sync over
development files or local test dependencies you intend to keep.

For incremental development, build to `zig-out`, inspect the result and copy
only the intended changed overlay files into the mounted desk. Commit changes
through Clay before testing them. `zig build clean` removes `zig-out`;
`zig build clear` also removes the dependency checkout.

## Local checks

```sh
npm test --prefix fe
node --test acp/hand-client.test.mjs
node --test scripts/modules.test.mjs
zig build
node --test scripts/distribution.test.mjs
```

Frontend tests cover client state and interface behavior. Module checks enforce
dependency boundaries. Distribution checks inspect assembled agents, imports,
test isolation and dynamic marks.

Production assembly excludes the runtime's development test suite and its Ford
imports. The dynamic namespace includes compiler bootstrap marks and `%noun`,
which the head/verifier exchange requires. An artifact check does not replace
a cold installation and real Gall compilation.

## Native tests

In Dojo on a development desk:

```text
-test /=harness=/tests
```

Full-agent reload, endpoint fixtures and the 32K-document benchmark live in
`tests-integration`. Run them one at a time, for example:

```text
-test /=harness=/tests-integration/harness-reload
```

These tests use virtualized agent evaluation and can be slow and memory-intensive
on a 2 GB loom. Pure policy, persistence and media checks remain in the default
suite. Avoid running heavy compilation concurrently with timing measurements.

For runtime performance characteristics and benchmark instructions, see
[performance](performance.md).

## Live conformance

Use disposable test ships. Read a fixture's header and environment options
before running it: some tests change defaults, permissions, profile fields or
storage; some suspend agents; some make paid provider calls or leave native
messages and durable audit records.

The common invocation is:

```sh
SHIP_URL=http://localhost:8081 SHIP_COOKIE=/path/to/auth-cookie.txt \
  node scripts/conformance.mjs
```

Keep cookie files private. Use unique fixtures and do not run tests that mutate
the same settings concurrently. Cleanup restores selected configuration; it
does not imply remote messages, public identity updates or audit evidence never
existed.

### Practical goal acceptance

`scripts/work-goal-practical.mjs` gives one supply-planning request to a real
agent through a file-backed hand. Two local development ships use their
configured HTTPS model providers and real HTTP tools. The runner serves input
data, not model responses: confirmed prices remain unavailable until a future
time. Agents must create and complete the home project's jobs, get a mutually
trusted peer to independently check the work, and arrange a one-time scheduled
agent to deliver the final recommendation without another user prompt.

```sh
SHIP_URL=http://127.0.0.1:8092 SHIP_COOKIE=/private/home.cookie \
WORK_GOAL_REAL_MODELS=1 \
WORK_GOAL_PEER_URL=http://127.0.0.1:8093 \
WORK_GOAL_PEER_COOKIE=/private/peer.cookie \
WORK_GOAL_HOME_SHIP='~home-ship' WORK_GOAL_PEER_SHIP='~peer-ship' \
  node scripts/work-goal-practical.mjs
```

Use the actual ship names and a pair without an existing peer conversation.
To reuse this test's peer history, set `WORK_GOAL_PREVIOUS_REPORT` to its retained
report. The runner requires matching ships and unchanged recorded input history;
it does not clear conversation state. Fresh remote inference and tool events are
measured against the recorded starting point.
The peer admission allowance includes retained test usage, so repeating the test
does not require erasing history or resetting token accounting.
For a controlled model comparison, `WORK_GOAL_HOME_MODEL` selects a model through
the home's configured provider for the test coordinator and its scheduled worker
only. It does not change ship defaults or the peer model. The report records the
selected models, and acceptance checks the actual coordinator and scheduled model.
Keep baseline failures alongside comparison results; another model's pass does
not establish that the baseline model reliably completes the task.
The test makes paid model calls and temporarily installs reciprocal Workspace,
Peers and Curl grants; it does not promote either ship to owner. Cleanup restores
those grants, disables its hand and cancels its schedules and executions. Work
records, conversations and private evidence files remain available for inspection.
Do not run concurrent trust edits on this pair.
Before starting model work, both ships must return fresh peer-discovery reports.
Matching grants alone do not prove network reachability; cached reports cannot
satisfy this preflight.

The quote opens ten minutes after setup, leaving time for real model latency;
`WORK_GOAL_QUOTE_DELAY_MS` accepts 60,000–600,000 milliseconds. The request gives
an explicit follow-up window, and the runner stops after eight further minutes.
Signals cancel the fixture's work and preserve its evidence. The independent
oracle checks the initial total, final quantities, shipping and budget shortfall.
Acceptance also requires one delegation without an uncertain resend,
authenticated peer task ownership, a future worker starting within the requested
two-minute window, completed future work, a real delivered message and no
internal task IDs in human replies. The
runner does not create or advance tasks, synthesize agent answers, or trigger
scheduled work manually. Native and scripted conformance tests supplement this
test; they do not establish practical goal completion. A passing report applies
to its recorded model pair and workflow, not to arbitrary models. Retain failed
runs when evaluating reliability, including incorrect arithmetic, tool-argument
loops, late scheduling and incomplete cross-ship bookkeeping.

Inspect both delivered messages against the source data as part of acceptance.
The deterministic oracle checks required quantities and totals, not every prose
claim; correct totals do not excuse invented comparisons or contradictory advice.

| Boundary | Fixtures |
| --- | --- |
| ACP and sessions | `conformance.mjs`, `conversations-conformance.mjs`, `session-history-conformance.mjs` |
| Work inbox | Read-only `inbox-conformance.mjs`; native `/tests/harness-inbox` and `/tests-integration/harness-inbox`; browser `fe/tests/inbox.spec.js` (see [inbox](inbox.md)) |
| Project access | `project-client-conformance.mjs`; native `/tests/harness-workspace-maintainer`, `/tests/harness-project-client`, `/tests-integration/harness-project-client`; browser `fe/tests/project-access.spec.js` (see [project access](project-access.md)) |
| Request to reviewed reply | `social-workflow-conformance.mjs`: owner-directed local workflow with synthetic model and delivery sink (see [workflow and limits](social-workflow.md)) |
| Human work controls | `work-control-conformance.mjs`: text-only hand authority, exact previews, task creation, native Notes review, and model-text non-execution (see [conversation work management](work-control.md)) |
| Commands and settlement | `command-conformance.mjs`, `cancellation-conformance.mjs`, `settlement-conformance.mjs` |
| Conversation hands | `hand-conformance.mjs`, `hand-operations-conformance.mjs` |
| Grubbery verification | `shadow-conformance.mjs` |
| Context and recall | `compaction-conformance.mjs`, `lcm-conformance.mjs` |
| Provider authentication | `openai-auth-conformance.mjs` |
| Resource grants | `clay-scopes-conformance.mjs`, `mcp-scopes-conformance.mjs`, `rehearsal-conformance.mjs` |
| HTTP and search | `fetch-conformance.mjs`, `curl-conformance.mjs`, `searxng-conformance.mjs` |
| JavaScript | `js-conformance.mjs` |
| Peer work | `peers-conformance.mjs`, `peer-rpc-conformance.mjs`, `peer-tool-client-conformance.mjs` |
| Sustained operation | `reliability-soak.mjs` (local-only; application reads by default, bounded synthetic work opt-in) |
| Tlon | See the [Tlon testing reference](tlon.md#testing) and feature-specific fixtures |

Script filenames in the table are under `scripts/`; native and browser tests
show their own paths.

See [sustained operation and recovery](reliability.md) for workload bounds,
fault coverage, interrupted-run evidence and the separate cold-start/restart
checks. Run `node --test scripts/reliability.test.mjs` without a ship.
`conformance.mjs` uses ship-configured inference and checks independent clients,
admission and session behavior. It is not a complete installation or ACP
specification-conformance suite.

Hand conformance uses real inference with simulated external publication; it is
not a Tlon connector test. Hand operations conformance uses fixture destinations
for recovery, export and retirement. The shadow fixture injects faults into a
test verifier and needs an idle Dojo tmux pane for owner operations.

Context fixtures use local deterministic providers and temporarily select
summary settings. Run them alone. The
[context reference](context-and-memory.md#verification) distinguishes those
checks from the paid-provider smoke test.

## Measure the right boundary

Measure prompt admission, provider completion and external publication separately.
For responsiveness, also inspect maximum event-loop work, replay cost, loom
growth, idle traffic and behavior under concurrent sessions. An asynchronous
request does not make Hoon CPU work preemptible.

`scripts/performance-read-benchmark.mjs` performs read-only timings through the
browser transport, including idle request counts. Supply `SHIP_URL` and
`SHIP_COOKIE`. Optional `BENCH_BASE=<git revision>` compares that revision's
client with the worktree in both execution orders. It sends no prompts or
configuration writes and closes temporary ACP connections.

The native corpus benchmark measures synthetic index construction and queries
separately. Record hardware, runtime, dataset and warm/cold conditions with
results. Neither a synthetic query timing nor a matching replay digest proves
end-to-end production responsiveness or correct external effects.
