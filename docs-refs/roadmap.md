# Roadmap

What's next, roughly in priority order. See [`../README.md`](../README.md) for what already works and [`../urbit-agent/harness-design-notes.md`](../urbit-agent/harness-design-notes.md) for the design these trace back to.

## Near term

### 1. Streaming to the UI
Design note §6.9: tokens should stream executor→UI, and only terminal results become events. Today a turn is a single blocking Iris request and the UI only updates when it lands, so the chat feels laggy. Stream partial frames from the provider to the browser (via a side channel / SSE), keeping the event log terminal-only. Highest UX payoff.

### 2. Prompt-cache-stable prefixes
Invariant 9 / §6.4. Provider prompt caching only fires when the context *prefix* is byte-identical turn to turn. Right now the compaction summary and the skills catalog are injected as system messages that can shift the prefix. Make the prefix append-only and stable (supersede markers instead of in-place edits), and confirm OpenRouter is actually caching. Real cost win, and cheap.

### 3. Second provider / API kind (Anthropic Messages)
Lightspeed's `(providerId, apiKind, model)` model resolution. We hardcode the OpenAI chat-completions shape. Add an Anthropic Messages API kind — it brings native compaction and explicit prompt-cache breakpoints, and it proves the provider abstraction is real. Config already carries `url`/`model`; add an `api-kind` and branch the request/response codecs in `lib`.

### 4. A scry-namespace inspector
§6.5, Phase 1. A read-only view that renders the raw event log and tool uses straight from the scry namespace (Context-Lens style), separate from the chat UI. Small, and the legibility principle wants it. Good for debugging the loop.

## Client protocol & channels

### 5. ACP (Agent Client Protocol) surface — ✅ v1 done
`%acp` provides a generic durable duplex transport, and `%harness` implements the native ACP server baseline: initialize, new/load session, prompt, cancel, terminal message update, and stop response. The thin [`harness-acp.mjs`](../acp/harness-acp.mjs) adapter exposes any named native connection as ACP JSON-RPC over stdio for clients such as Zed; it contains no harness or protocol policy. See [`acp.md`](acp.md).

Follow-ups: (a) incremental model and tool-call updates once streaming (#1) lands; (b) surface ACP `session/request_permission` for tool grants; (c) richer prompt content; (d) map ACP `fs/*` and `terminal/*` client methods to `clay`/`run_js` where useful.

### 6. Tlon Messenger as a channel
§9 Phase 1. The "your agent shows up in Messenger and talks to your friends' agents" story: bridge Messenger channel messages to harness sessions (admit as input, deliver replies), reusing the A2A identity model over Ames. Larger, product-shaped; #5 (ACP) may be the cleaner path to the same place.

## Deeper / later

### 7. Rehearsal → desk files (self-authored Hoon/JS tools as files)
§6.7 Phase 2. We have the governed loop for **skills in state**. The next step is self-authored *tools* that live as files: the agent writes a tool (JS today, per the [threads spike](threads-substrate-notes.md); Hoon later), stages it, rehearses a copy of the session against it, and commits it to a staging desk. Clay builds on demand and Gall reloads on commit; the missing piece is running a *new* version of the loop against a *copy* of state, which needs the core to stay a pure library callable with either version.

### 8. References / CAS across the seam
§6.4, Phase 1. Content-address payloads (`(map hash atom)` in state; events carry hashes, not bodies) so the effect protocol is shaped for the vere64 blob store before it ossifies. **Deferred** — payloads are currently kilobytes and the blob-size threshold is still an open question upstream. Revisit when blobs land.

### 9. Real key hygiene
Keys currently live in agent state (better than per-session config, resolved at send time) but still sit in the pier plaintext. §6.8 wants keys on the Earth side only, never in Arvo state — which needs the external-executor seam (below). Also: the A2A webhook currently requires the ship's urbauth cookie; real external webhooks want a per-session token instead.

### 10. External executor over Lick / a dedicated driver
§9 Phase 2–3. Move the hands out of Iris to an external executor (streaming, real key isolation, sandboxes/MCP for tools) or eventually a dedicated Vere driver. The head shouldn't care which — "a hosted executor, a laptop, and a friend's GPU box look identical from inside the ship."

### 11. `tool_choice` / forced tool use
Small: let a session require a tool call (OpenAI `tool_choice`), for when you want a model to *always* verify with `run_js` rather than answering from its head. A per-session switch.

## Housekeeping

- **Rename `%harness`** to something better before this gets real.
- **Warmup**: do one `run_js("module.exports=()=>1")` at agent init to pay the ~60s QuickJS wasm warmup up front instead of on the first user call.
- **Upstream fixes to report**: the `gwbtc/urbit-mcp` fresh-install crash in `++merge-features`, and its scry tool 500-ing on session ids containing `_`.
- **Loom/perf**: everything runs on 32-bit vere; long-lived sessions will want vere64 + the blob store (#8). Measure before it bites.
