# WASM threads as an execution substrate for agent-authored code

## Responsibilities

JavaScript execution is an optional Harness tool executor, not a second agent
head. The head admits and authorizes a tool call; the executor runs it and
returns a result. Only the head can accept that result against an outstanding
call identity and append it to the conversation.

The relevant source projects are `urwasm`, `threads-js`, and `orchestra`.
They illustrate separate layers:

- **urwasm/Lia** interprets WASM in Hoon, with resumable yields and cache support.
  Matching Vere jets and Hoon batteries matter for execution performance.
- **threads-js** runs a WASM build of QuickJS. Its
  `lib/thread-builder-js.hoon` builds a thread from JavaScript source. Host
  functions bridge JavaScript to Urbit I/O through strandio.
- **orchestra** manages sources, builds, thread results and schedules around that
  executor. Harness does not need its application or UI to use the execution
  pattern.

The source contract assigns a function to `module.exports`; its return value
becomes the thread result. The thread-builder convention returns
`[%0 (each result=cord [err=cord where=cord])]` inside a vase. Structured results
should be explicitly encoded rather than relying on implicit string conversion.

## Harness boundary

Harness dispatches JavaScript through Spider and tracks the thread identity for
cancellation. The composition root owns timeout and result admission; effect
bindings construct the execution cards. See
[the head](../desk/app/harness.hoon) and
[effect bindings](../desk/lib/harness-effects.hoon).

The lifecycle is:

1. Check the conversation's tool grant and record the requested call.
2. Dispatch the executor with an identity scoped to the outstanding work.
3. Schedule a watchdog independently of the executor.
4. On success or failure, accept a result only while that call is authorized and
   outstanding, then record its terminal receipt.
5. On cancellation or timeout, withdraw the thread where possible and fence any
   late result. Cancellation cannot undo an external action already performed.

Khan can also execute a built shed, but Spider supplies explicit thread identities
and a stop operation. An alternative executor should preserve the same admission,
cancellation and receipt semantics.

## Dependency and authoring discipline

Stage the executor's dependency closure through the desk build. Use compatible
strand, strandio, Spider and WASM types; do not infer compatibility from a desk's
declared Kelvin alone. A dependency update requires compilation and execution
checks against the supported runtime.

A minimal thread-builder entry point has this shape:

```hoon
/-  spider
/+  tbjs=thread-builder-js
=*  strand  strand:spider
^-  thread:spider
|=  arg=vase
=+  !<([~ code=@t] arg)
(tbjs code)
```

The host-function table is an authority boundary. Exposing a JavaScript function
that can poke, fetch or write data is a capability decision, not merely a
convenience wrapper. Keep those functions understandable, and do not assume
model-generated source obeys prompt instructions.

## Execution limits

- **Interleaving is not preemption.** I/O yields allow other events to run.
  CPU-heavy Hoon or WASM evaluation can still occupy one Arvo event. A Behn
  watchdog or Spider stop cannot interrupt a pure-compute event before control
  returns to the event loop.
- **Timeouts still matter.** They bound abandoned I/O waits and fence late
  completion. Hard CPU isolation requires an execution mechanism with its own
  fuel, preemption or external process boundary.
- **Cache behavior is runtime-dependent.** Measure cold startup, warm execution,
  code changes and restarts separately. Do not assume persistent-cache behavior
  across boots or add unconditional warmup work without measuring the benefit.
- **Memory needs bounds.** Long-running scripts and executor history can grow.
  Prefer short invocations and explicit continuations over an unbounded script
  loop, and measure loom/cache growth.
- **Avoid self-HTTP as an internal bridge.** Use explicit on-ship capabilities
  instead of depending on routing, redirects and authentication through the
  ship's own HTTP endpoint.
- **Source execution is not a package environment.** The thread-builder contract
  does not by itself provide Node.js, npm resolution or an unrestricted module
  system.

## Verification

Use disposable test ships and uniquely named fixtures. Check a constant return,
structured output, syntax/runtime errors, permitted HTTP and Clay operations,
cancellation during I/O, timeout, late-result rejection, and continuation of the
conversation afterward.

Measure provider-independent executor latency and maximum individual-event
runtime separately from HTTP/client transport delay. Record the runtime version,
source revisions and workload with benchmark results. Do not present a warm-cache
microbenchmark as a general responsiveness guarantee.

Do not use an unbounded compute loop to test cancellation on a shared ship.
Evaluate hard execution limits in an isolated environment before granting such
an executor to untrusted callers.
