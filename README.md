# urbit-agent-harness

An **AI agent harness that runs as a Gall agent on Urbit** — the durable, event-sourced *head* of an agent loop, with the heavy *hands* (LLM calls, code execution, web) borrowed from the runtime and other ships.

It follows the ["Urbit is for your personal agent harness"](https://github.com/lukebuehler/urbit-agent/blob/main/README.md) proposal: the agent loop is a deterministic state machine over an event log — exactly Arvo's shape — so the parts that make Urbit awkward for ordinary apps (one event log, computation split from I/O, state as a value) are precisely what a long-lived, forkable, self-modifying agent wants.

> Working name of the desk is `%harness`. It'll probably get a better one.

## The shape

- **The head** is the `%harness` Gall agent. A *session* is an event log (a closed vocabulary of events); replaying it yields a view; a pure decider chooses the next step (plan a turn, run tools, compact, or halt). No I/O lives in the core.
- **The hands** are borrowed: LLM turns and web fetches go out through **Iris**, code runs as **wasm/spider threads**, sub-agents and peers are just more sessions. Results re-enter the log as events. The head never blocks.
- Everything the agent is — its config, tools, skills, memory — is **data in state**, mutable at runtime without a Clay commit.

```
  Eyre (web UI, webhooks) ─┐
  Ames (peer agents) ──────┤     ┌─────────────── %harness (the head) ───────────────┐
  Behn (timers) ───────────┼───▶ │  session log (noun) → view → decider → step        │
  pokes / urbit-mcp ───────┘     │  skills, config, peers, staged proposals (state)   │
                                 └───────────────────────┬────────────────────────────┘
                                          intents (refs) │ receipts re-enter as events
                                 ┌───────────────────────▼────────────────────────────┐
                                 │  hands: Iris (LLM/web) · spider+wasm (run_js) ·      │
                                 │  Ames (ask_peer) · Behn (timers)                     │
                                 └──────────────────────────────────────────────────────┘
```

## What works today

**Core loop** — event-sourced sessions, provider-native turns (OpenAI-compatible / OpenRouter via Iris), provider-executed **compaction** with verbatim tail retention, **forking** (a session is one noun; a fork shares structure and diverges freely), **cancel/retry**, and **loop detection** (halts a session that repeats a failing tool call or runs too many turns without resolving).

**Tools** (families, granted per session; new sessions default to all):
| family | tools | notes |
|---|---|---|
| `ship-time` | `get_ship_time` | on-ship, sync |
| `clay` | `read_desk_file`, `list_desk_files` | reads the ship filesystem |
| `web` | `http_fetch` | **async** via Iris; result re-enters as an event |
| `code` | `run_js` | JavaScript as a wasm/spider thread; QuickJS errors feed back for self-correction; loop-guarded (see below) |
| `skills` | `read_skill` | reads the agent's skill library; the catalog rides in context |
| `skill-write` | `write_skill`, `delete_skill` | direct (ungoverned) authoring |
| `author` | `propose_skill`, `rehearse_skill`, `commit_skill`, `discard_skill` | **governed self-modification** (see below) |
| `subagents` | `run_subagent` | a child session; answer returns via `+settle` |
| `peers` | `ask_peer` | ask another ship's agent over Ames |

**Skills in state** — the agent's knowledge is a `(map name skill)` in agent state (not desk files, to avoid OTA/ownership tangles). The catalog (names + descriptions) is injected into context when `skills` is granted; bodies are read on demand.

**Governed self-modification** — the flagship loop: the agent `propose_skill`s a new skill, `rehearse_skill`s it in a **sandboxed child session** that can see the staged skill and run code against a sample task, and `commit_skill`s it to the live library only if the rehearsal works. The rehearsal is stripped of state-mutating and outward tools, and if it crashes nothing touches the parent — a failed event leaves no trace. Proven: an agent authored a JS `fib` skill, rehearsed it (N=20 → 6765), and committed it.

**Agent-to-agent over Ames** — `ask_peer(ship, prompt)` sends a typed ask (`%harness-a2a-0` mark) to another ship's harness. The answer crosses the wire; the data doesn't. The serving side runs the ask in a **durable, sandboxed per-peer session** under an **identity-based grant** (`peer-grant`: which tools, which model, a token budget, which skills are visible). Absent grant = refused. Verified across two fakeships, including grant/revoke.

**Agent Client Protocol** — `%acp` is a harness-neutral, durable duplex transport for opaque ACP JSON-RPC frames. `%harness` uses the `harness` connection as an ACP server and supports initialization, new/load session, text and resource-link prompts, cancellation, agent-message and tool-call updates, and stop responses. Other native or external harnesses can use their own connection id without changing `%acp`; see [`docs-refs/acp.md`](docs-refs/acp.md).

**Timers** — `%timer-set` schedules a Behn wakeup whose prompt is admitted as input; the agent can wake itself.

**Safety** — `run_js` infinite loops are guarded two ways: a static guard rejects `while(true)`/`for(;;)` before dispatch (the runtime has no preemption), and a 30s Behn watchdog `%spider-stop`s a thread that hangs while yielding. API keys live in agent state, resolved at send time (a session's config key can be blank).

## Surfaces

- **Web chat UI** at `http://<ship>/harness` (served from `/web` by `%harness-fileserver`, Fang's fileserver pattern). New/fork/delete/compact/retry/cancel, set ship key, per-tool grants.
- **Pokes** — `%harness-action` (or `%noun`) with the `action` type in [`sur/harness.hoon`](desk/sur/harness.hoon).
- **Scry namespace** — `/x/sessions`, `/x/session/[sid]`, `/x/skills`, `/x/staged`, `/x/timers`, `/x/peers`, `/x/tools`, `/x/status`. The session view is legible JSON; any front-end renders from it.
- **Webhooks** — `POST /harness-api/webhook/[sid]` with `{"text": …}` admits external input.
- **urbit-mcp** — drive it from an MCP client via pokes/scries.
- **ACP clients** — use the dependency-free [`acp/harness-acp.mjs`](acp/harness-acp.mjs) stdio adapter, or send to and subscribe through `%acp` directly at connection `harness`.

## Layout

```
desk/
  app/acp.hoon            generic durable ACP transport (no harness policy)
  sur/harness.hoon        types: events, config, actions, a2a protocol
  lib/harness.hoon        the pure core: play · decide · request-body · parse-response
  app/harness.hoon        the Gall agent (sessions, tool dispatch, the hands)
  sur/acp.hoon + mar/acp/* transport types and JSON marks
  app/harness-fileserver.hoon + app/fileserver/config.hoon   serves the UI
  web/index.html          the chat UI
  mar/harness/{action,update,a2a-0}.hoon   marks
  lib/wasm/*, sur/wasm/*, lib/thread-builder-js.hoon, quick-js-emcc.wasm
                          imported JS-on-wasm runtime in the assembled desk
docs-refs/                design docs and spike notes (see below)
```

## Running it

Build the complete desk (including pinned sparse imports from Urbit and
`threads-js`), then install it on a fake ship:

```
|new-desk %harness
|mount %harness
# from this repository:
zig build -Ddesk=/path/to/zod/harness
# back in the dojo:
|commit %harness
|install our %harness
```

Use `zig build` to assemble into `zig-out/`, `zig build clean` to remove the
install tree, and `zig build clear` to also clear cached dependency imports.
The dependency files intentionally do not live under the tracked `desk/` tree:
the build pins and imports them into the complete desk, including the unchanged
WASM runner used by `run_js`.

Open `http://localhost:8081/harness` (fakezod code `lidlut-tabwed-pillex-ridrup`), click **set key** to store an OpenRouter key, then **new** to start a session. Reliable test model: `openai/gpt-4o-mini`. Free models on OpenRouter (`minimax/minimax-m3:free`, etc.) work but rate-limit heavily.

## Design docs

- [lukebuehler/urbit-agent — README](https://github.com/lukebuehler/urbit-agent/blob/main/README.md) — the proposal
- [lukebuehler/urbit-agent — harness-design-notes](https://github.com/lukebuehler/urbit-agent/blob/main/harness-design-notes.md) — the technical design this implements
- [`docs-refs/lightspeed-design.md`](docs-refs/lightspeed-design.md) — the prior-art harness (Rust/Temporal) whose invariants we follow
- [`docs-refs/a2a-design.md`](docs-refs/a2a-design.md) — the agent-to-agent design
- [`docs-refs/threads-substrate-notes.md`](docs-refs/threads-substrate-notes.md) — the wasm-threads spike behind `run_js`
- [`docs-refs/roadmap.md`](docs-refs/roadmap.md) — **what's next**

## Status

A working Phase-0/Phase-2 prototype on 32-bit vere 4.6 (base kelvin 408). The pieces the proposal calls "the things to prove" — long-lived sessions, forking, compaction, self-modification, agent society — run today. Not yet: streaming, prompt-cache-stable prefixes, payload offload to the blob store (that's the vere64 precondition), a second provider API, and a real client protocol. See the roadmap.
