# WASM threads as an execution substrate for agent-authored code

The evaluation used a fakezod on base `[%zuse 408]` with vere 4.6. The relevant
repositories were supplied as source trees for `orchestra`, `threads-js`, and
`urwasm`.

## Verdict: VIABLE — proven end-to-end, fast enough today

JS snippets execute as spider threads on this exact stack (zuse 408 + vanilla vere
4.6) with **~115 ms wall per run** once warm, including brand-new scripts. JS can do
HTTP fetches and clay reads/writes mid-script. No vere patching, no kelvin surgery
beyond copying files — the 408 base already ships urwasm, and vere 4.6 already ships
the jets.

## How the pieces fit

- **urwasm** (Quodss/urwasm, now `dozreg-toplud/urwasm`): WASM interpreter suite in
  Hoon. Merged into Arvo at kelvin 409; our 408 base desk carries it as
  `lib/wasm/{lia,parser,validator,runner/*}.hoon` + `sur/wasm/*` + `mar/wasm.hoon`.
  "Lia" is its monadic invocation layer with resumable yields and state caching.
- **vere jets**: the 4.6 release binary contains the urwasm jets
  (`pkg/noun/jets/e/urwasm.c`; symbols `_137_hex_lia_run_v1_a`,
  `_137_hex_wasm_engine_d`, … for hoon kelvins 137/136/135). The pier is already
  launched with the Lia cache flags (`--temporary-cache-size 50000
  --persistent-cache-size 50000`), which matter enormously (see Performance).
- **threads-js** (`dozreg-toplud/threads-js`, kelvin 409): a desk whose core is
  `lib/thread-builder-js.hoon` — a gate `|=(code=cord ^-(shed:khan ...))`. It runs
  **QuickJS compiled to wasm** (`quick-js-emcc.wasm`, 875 KB, bundled in the desk)
  under Lia. Host functions are bridged two ways: wasm-level imports handled inside
  the Lia script monad, and `call-ext` yields resolved by strandio (real Urbit I/O:
  iris HTTP, clay warp, pokes, behn). Provided JS API: `console.*`,
  `fetch_sync`/`fetch`, `require("urbit_thread")` →
  `load_txt_file`/`store_txt_file`/`sleep`/`restart` + a Tlon Messenger and %pals
  API (irrelevant on a bare fakezod but compiles fine).
- **orchestra** (`dozreg-toplud/orchestra`, kelvin 409): gall agent + web UI that
  *manages* such threads: stores sources (`[%hoon deps txt]` or `[%js txt]`), builds
  them in a khan `%lard`, runs them via spider (`%spider-inline` poke, watches
  `/thread-result/[tid]`), keeps a `products` map of results, and does cron
  (`run-every=(unit @dr)` + behn). Contract convention: the JS gate returns
  `!>([%0 (each result=cord [err=cord where=cord])])`.

Authoring contract: the script must assign a function to `module.exports`; its
return value (stringified) is the thread's result.

## What I installed (exact steps)

Created desk `%jsdemo` (`|new-desk %jsdemo`, `|mount %jsdemo`), then copied into
`zod/jsdemo/`:

- from `zod/base` (408-native, jet-matching): `lib/strand.hoon`, `lib/strandio.hoon`,
  `lib/wasm/*`, `sur/wasm/*`, `sur/spider.hoon`, `mar/wasm.hoon`, `mar/mime.hoon`
- from `threads-js/desk`: `lib/thread-builder-js.hoon`, `lib/{channel,groups,story,cite}-json.hoon`,
  `lib/mop-extensions.hoon`, all Tlon `sur/*.hoon` (activity, channels, chat*,
  groups*, cite, epic, meta, story, ui, joint, contacts), `quick-js-emcc.wasm`
- two new teds (below); `sys.kelvin` stays `[%zuse 408]`; `|commit %jsdemo`.

**Kelvin finding**: threads-js/orchestra declare `[%zuse 409]`, but the 409 wasm
libs are **byte-identical** to the 408 base's copies, and `thread-builder-js`
compiled at 408 with zero changes. The only 409→408 delta found anywhere relevant
was cosmetic ames scry paths in strandio (used base's copy). Not fundamentally
incompatible — the opposite: 408 is the friendliest possible base for this.

### The working example

`zod/jsdemo/ted/run-js.hoon` (dojo entry):

```hoon
/-  spider
/+  tbjs=thread-builder-js
=*  strand  strand:spider
^-  thread:spider
|=  arg=vase
=+  !<([~ code=@t] arg)
(tbjs code)
```

```
> -jsdemo!run-js 'module.exports = () => 6 * 7'
[%0 [%.y p='42']]
```

`zod/jsdemo/ted/run-js-http.hoon` (JSON-in/JSON-out for machine driving) — unwraps
the `[%0 (each ...)]` and returns `{"ok":true,"result":...}` /
`{"ok":false,"error":...,"where":...}`. Driven via spider's HTTP API:

```
curl -X POST -H 'Cookie: urbauth-~zod=...' \
  --data '{"code":"module.exports = () => 6 * 7"}' \
  http://localhost:8081/spider/jsdemo/json/run-js-http/json
→ {"ok":true,"result":"42"}          (0.23 s first call, ~0.11 s after)
```

Proven from JS, via curl against that endpoint:

| test | result | wall |
|---|---|---|
| `6 * 7` (warm) | `"42"` | **0.11 s** |
| brand-new script (map/join) | `"A-B-C"` | 0.11 s |
| `fetch_sync("https://example.com/")` | `status=200 len=559` | 0.59 s |
| `store_txt_file` + `load_txt_file` (clay round trip) | file lands in `zod/jsdemo/out/hello.txt` | 0.31 s |
| `throw new Error("boom")` | `{"ok":false,"error":"Error: boom from js","where":"failed to call the exported function"}` | 0.14 s |
| syntax garbage | `{"ok":false,"error":"SyntaxError: expecting ';'", ...}` | 0.11 s |
| loop 1e6 adds | `"sum=500000500000"` | 1.03 s |
| loop 1e7 adds | correct | 9.4 s |

## Performance notes

- **Jets: required and present.** Vere 4.6 (vanilla release) has them; nothing to
  build. Without them this would be pure-nock wasm interpretation and unusable.
  Jets match by battery hash, so a userspace desk carrying identical lib sources
  hits them fine.
- **First run after boot is expensive: ~60 s CPU** (observed via `/proc` tick
  deltas during the first `-jsdemo!run-js`). That is QuickJS-in-wasm instantiation
  populating the Lia persistent cache. Every subsequent run — including *different*
  JS code — is ~0.1–0.2 s, i.e. the cached instantiated module state is reused and
  only the script eval is paid. The pier's `--persistent-cache-size` /
  `--temporary-cache-size` flags are what make this work; a pier launched without
  them would presumably pay quadratic replay costs. Budget one warmup run at boot.
- **Marginal JS compute ≈ 1 µs per trivial loop iteration** (1e6 → 1.0 s,
  1e7 → 9.4 s; nicely linear). Roughly 10–30× slower than native QuickJS. Fine for
  glue code, parsing, API orchestration; wrong tool for number crunching.
- **Compute runs as a single arvo event.** The 9.4 s loop blocked the serial event
  loop for its duration. There is no fuel/preemption in the Lia runner.
- Measurement noise warning: timings taken through the dojo MCP tool were wildly
  inflated (sole session queueing, dropped transports). The spider HTTP endpoint +
  curl gives honest numbers.

## Quirks and failure modes found

- `fetch_sync` against the ship's **own** eyre (`http://localhost:8081/`) hung the
  thread indefinitely (iris→own-eyre; possibly the 307 redirect). External URLs are
  fine. Don't let scripts call back into their own ship over HTTP; use the
  `urbit_thread` bridges instead.
- A thread that hangs holds its spider slot until `%spider-stop`; the HTTP caller
  just never gets a response. Any `run_js` tool needs a timeout + cancel poke.
- Errors surface cleanly (each-typed), including QuickJS syntax errors with
  messages — good raw material to feed back to the LLM for self-correction.
- `module.exports` result is coerced to a string. Structured results should be
  `JSON.stringify`'d by convention and parsed on the Hoon side.

## Recommended integration shape for %harness

Skip orchestra as a dependency; lift the pattern. A `%code` tool family in the
harness agent:

1. `run_js(code, timeout_s)` tool → emit `%tool-requested`, then either
   - **khan `%lard`**: `[%pass wir %arvo %k %lard %harness-desk (thread-builder-js code)]`,
     result/failure arrives as `%arow` on the wire (this is exactly what orchestra
     does — no spider agent involvement, no tid bookkeeping), or
   - **spider `%spider-inline`** if you want tid-based cancellation
     (`%spider-stop`) for the timeout path. Prefer this given the hang risk.
2. On result: unwrap `[%0 (each cord [cord cord])]` → `%tool-completed` with the
   string (success) or the error+where pair (failure, feed back to the model).
3. Ship `thread-builder-js` + deps on the harness desk exactly as done in
   `%jsdemo` (file list above); do one warmup `run_js("module.exports=()=>1")` at
   agent init to populate the Lia cache.
4. Later, for LLM-authored *persistent* tools: store scripts as clay files, rebuild
   the shed per invocation (build cost is negligible — ford caches; the wasm side
   is cache-warm). Orchestra's `sur` is a good reference for the source/product/
   cron data model if scheduled jobs become a requirement; the desk itself would
   need its `sys.kelvin` dropped to 408 (likely trivial, untested) and brings a
   docket web UI we don't need.
5. Extending the JS API is straightforward but is Hoon work: add entries to
   `function-table` in `thread-builder-js.hoon` (each is a JS-side wasm arrow + a
   strand for the actual I/O). Natural candidates for %harness: `scry(path)`,
   `poke(agent, mark, json)`, and a bridge to the harness's own tool bus.

## Risks and unknowns

- **No preemption**: an LLM-written `while(true){}` wedges the arvo event loop
  (only recoverable by killing the event from the console). Untested deliberately
  on this shared ship. Mitigations: prompt constraints, spider timeouts (kill only
  helps between events... a stuck *pure-compute* event needs vere-level ctrl-c),
  eventually a fuel-metered Lia. This is the biggest real risk.
- **Memory**: each run's state lives in the Lia cache; `urbit_thread.restart`
  exists because long-running scripts grow the urwasm event log. Long/looping
  scripts should be discouraged in favor of re-invocation.
- **Kelvin drift**: threads-js/orchestra track 409; we're on 408. Today they're
  source-compatible; upstream may drift toward 409-only idioms. Vendoring
  `thread-builder-js.hoon` (as %jsdemo does) insulates us.
- **First-boot warmup** (~60 s CPU) must be re-paid per pier boot (persistent cache
  is a runtime cache; not verified whether it survives restart — untested since the
  ship is shared).
- **Single JS runtime per thread, no modules**: CommonJS-style, one file, no npm;
  bundling is the user's problem. Fine for LLM-generated snippets.
- The dojo/MCP sole path is unreliable for driving this; use the spider HTTP
  endpoint (`/spider/<desk>/json/<ted>/json`) or khan from inside the agent.

## Artifacts

- Working desk: `zod/jsdemo/` (live on the ship, committed).
- Teds: `zod/jsdemo/ted/run-js.hoon`, `zod/jsdemo/ted/run-js-http.hoon`.
- Vendored sources: `orchestra/`, `threads-js/`, `urwasm/` (tarball extracts,
  not git clones; safe to delete or re-fetch).
- JS-written clay proof: `zod/jsdemo/out/hello.txt`.
