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

| Boundary | Fixtures |
| --- | --- |
| ACP and sessions | `conformance.mjs`, `conversations-conformance.mjs`, `session-history-conformance.mjs` |
| Commands and settlement | `command-conformance.mjs`, `cancellation-conformance.mjs`, `settlement-conformance.mjs` |
| Conversation hands | `hand-conformance.mjs`, `hand-operations-conformance.mjs` |
| Grubbery verification | `shadow-conformance.mjs` |
| Context and recall | `compaction-conformance.mjs`, `lcm-conformance.mjs` |
| Provider authentication | `openai-auth-conformance.mjs` |
| Resource grants | `clay-scopes-conformance.mjs`, `mcp-scopes-conformance.mjs`, `rehearsal-conformance.mjs` |
| HTTP and search | `fetch-conformance.mjs`, `curl-conformance.mjs`, `searxng-conformance.mjs` |
| JavaScript | `js-conformance.mjs` |
| Peer work | `peers-conformance.mjs`, `peer-rpc-conformance.mjs`, `peer-tool-client-conformance.mjs` |
| Tlon | See the [Tlon testing reference](tlon.md#testing) and feature-specific fixtures |

All names in the table are under `scripts/`.
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
