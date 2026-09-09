# Sessions, context and memory

Harness implements source-linked hierarchical compaction, bounded explicit
notes, and a hand-independent lexical corpus index. One event log remains the
authority; summaries and the searchable projection are derived from it. No
memory daemon, embedding service, or fact-extraction loop is required.

## Hierarchy and model settings

`harness-lcm` stores immutable nodes with either original event addresses or
ordered child-node addresses. Active roots form a chronological forest. Leaf
compaction summarizes complete older exchanges without re-summarizing prior
roots. Four contiguous roots of equal depth become one parent before eligible
inference; an oversized group may shrink to two. Edges must point backward and
replace exactly the selected contiguous roots. Descendant lists are never
copied into every ancestor.

Settings → Memory has independent optional **Compaction model** (leaves) and
**LCM model** (parents) routes. Unset overrides follow the current global
default, not the conversation's snapshotted answer configuration. Provider
credentials resolve through the shared credential boundary. Each request freezes its selected endpoint,
model, source coverage and budget before dispatch; editing settings does not
change an outstanding request's decoder. Neither setting changes the answer
model, instructions or grants of a conversation.

## Indexed corpus and explicit recall

Search content in the sidebar searches retained input, context, assistant text,
tool arguments/results, notes and summaries from every encountered hand. It
does not fetch unencountered Tlon history or another app's database. Provider
errors, configuration and credential state are excluded. Retrieved tool content
can itself contain sensitive data; it inherits its conversation's authority.

`harness-corpus-index` uses standard Hoon maps/sets, 4,096-document segments,
a term-to-segment directory, ordered `mop` postings and native `in`/`on`
operations. Matching requires all query terms (AND). Exact terms do not expand;
missing terms may use bounded two-byte prefix buckets and edit-distance-one candidates. Query
merging retains only one page, and fuzzy lookup does not materialize its entire
vocabulary bucket.

The head captures append deltas at its existing commit boundary. Backfill and
rebuild advance on paced Behn wakes, at most 32 events and a 65,536-byte target
per batch. A single oversized event is indexed alone rather than silently
truncated; this is not a hard maximum event latency. Queries never replay source
logs. Source records use immutable corpus scope IDs and one-based event
addresses, independent of mutable session names. Rename preserves coordinates;
deletion drops canonical records/authority immediately and recreation gets a
new scope. Inaccessible derived terms/snippets remain until an explicit rebuild
reclaims them. Rebuild exposes lag
and partial coverage while it runs, rather than pretending results are complete.

The GUI has owner-wide search and source inspection. The model tools
`lcm_search`, `lcm_read` and `lcm_expand` default to the current conversation.
The explicit `corpus` grant enables cross-conversation recall only for owner
conversations; social and delegated provenance keeps recall local even if that
grant is present. Forks index their retained prefix under their own scope.
Authorization filters matches before pagination and is rechecked for reads.
Cursors bind query, permitted scopes and index epoch; IDs/cursors grant no
authority. Read chunks preserve UTF-8 boundaries at 12,000 bytes; expansion
returns at most 16 immediate edges, not an unbounded recursive traversal.

Limits are explicit: query text ≤512 bytes, pages 1–64 results, bounded fuzzy
candidate work. Common queries can still visit every candidate segment, and
global status/synchronization visit the scope/session directory. These are not
constant-time whole-corpus guarantees. No claim is made about physical erasure
from backups, bounded primary-log growth, or constant-cost full replay.

## Compaction planning and acceptance

`lib/harness-context.hoon` owns pure budgeting, source selection and validation;
`harness-lcm-context` composes it with the hierarchy and source addresses.
Provider codecs supply estimates of the encoding actually dispatched; the head
records an `lcm-planned` event before emitting the request. The plan names
the source log boundary, active-prefix count/digest, original context length,
model/endpoint, estimated input, output reserve and optional command identity.
Replay recovers the exact source prefix or selected child summaries.

The current policy reserves `min(4096, window / 4)` output tokens plus a 10%
estimation margin. These are explicit conservative policy constants, not
provider metadata or benchmark-derived optimal values. Chat Completions requests
send the matching output cap; the Codex subscription route uses provider-managed
output behavior. All size estimates are rounded bytes/4,
not exact tokenization. `/context` labels that uncertainty and the configured
window as catalog-or-fallback; this label does not distinguish a specific
catalog source from fallback configuration.

Compaction responds to the active model's capacity, not an absolute working-set
cap. Before eligible inference, compare the encoded-request estimate with
`window - output-budget - floor(window / 10)`. Below that threshold, proceed
without summarizing; above it, plan compaction before dispatch. A larger model
can use its larger window. Switching to a smaller model immediately changes the
next decision; there is no cached threshold to invalidate. The window comes
from the session's catalog-derived configuration or its declared fallback.

Source selection aims to leave one third of that input budget as raw recent
exchanges, plus the checkpoint and other prompt material. This proportional
target provides room to grow; it is not an exact final-context bound. The next
request is measured again. Neither the trigger nor the tail has a separate
fixed token cap, and there is no UI context-size knob. The percentage margin,
tail ratio and output reservation are explicit policy, not provider metadata.

Selection keeps the latest completed exchange and unanswered input. It chooses
complete historical exchanges using a recent-tail budget target and chunks the
eligible prefix to fit the summary request's own budget. Tool calls/results are
never split. On already-short history, explicit compaction selects the older
exchanges together instead of summarizing only a potentially trivial first pair.
An indivisible oversized exchange fails locally; there is no automatic
large-artifact projection to make it fit.

`checkpoint-completed` records the replacement and reported usage. The reducer
checks outstanding identity and the frozen source digest before replacing the
prefix, preserving any new tail input. A manual command acknowledgement is
placed at its admission boundary in model context so later input still needs an
answer; the human transcript records completion in event order. Historical text
is labelled reference material, not system/developer instructions.

Empty, truncated, tool-producing or non-reducing summaries fail without replacing
context or retrying automatically. Summary usage is included in cumulative usage
and separately reported as `compactionUsage`, including rejected summaries when
the provider reports usage. Missing usage remains zero, not an estimated charge.
Four attempts per admitted input bound automatic chunking; each summary has a
three-minute watchdog. Cancellation fences late results. An in-flight summary
without a source plan cannot be accepted as a checkpoint after reload.

`/context` and `/compact` share native, ACP and hand ingress. Only `/compact`
invokes inference. It requires no tools and publishes success only after the
checkpoint is accepted. Full source transcripts remain available. Full-log
replay, history reads and request construction are not constant-cost.

## Pinned conversation notes

`lib/harness-memory.hoon` is a pure bounded-note policy. Notes are a map derived
from the same session event log, not a second database. Human ingress provides:

- `/remember project Keep the deployment read-only.` saves or replaces a note.
- `/memory` lists the current notes without inference.
- `/forget project` unpins a note without erasing earlier messages or summaries.

Names have 1–32 lowercase ASCII letters, digits, hyphens or underscores. Each
body is at most 1,024 UTF-8 bytes; each session allows at most 16 notes and
8,192 total name/body bytes. Replacements count against the resulting map.
Overflow is rejected explicitly; there is no silent eviction. These limits
bound current note content, not noun/map overhead, audit history, or backups.

Notes enter ordinary model requests verbatim as user-level reference material
and count toward request estimates. They are not passed as a separate block to
the summarizer, which cannot edit them; earlier note commands may still appear
in the history it summarizes. Removing a pin is therefore not an erasure or a
guarantee that a model cannot recall its old text. Notes are never promoted to
system instructions. Both Chat Completions and Responses use the same policy.

Notes inherit the session's access scope. A new independent conversation starts
empty; a fork carries notes at the selected history boundary and later changes
are independent. An admitted participant can edit that session's notes, not
another conversation's. Tlon actor isolation and hand authorization remain the
boundary; pinned notes require no global memory grant. Clients inspect notes in session
snapshots/views as `memory: [{name, body}]`. A `memory-set` event records each
edit alongside the identified command input and acknowledgement.

There are no model-side note-writing tools or automatic fact extraction.
Printing a memory command does not execute it. Shared skills are a separate
instruction library, not private memory. Notes complement lossy hierarchical
summaries rather than replacing source history.

Compaction bounds neither the primary transcript nor replay time. Every note
edit is another audit event and searchable evidence. There is no embedding
store or per-turn extraction request, automatic primary-history retention policy
or large-artifact projection.

## Verification

Native tests exercise production hierarchy, index, corpus, JSON and persistence
helpers. `scripts/lcm-conformance.mjs` uses a local model server through real
ACP/Iris to create leaves and parents, expand evidence, paginate search, check
model recall grants, and test rename/delete/recreation.
`scripts/compaction-conformance.mjs` covers frozen spans, cancellation, failures,
model-window changes, concurrent input and independent Grubbery replay.
Both temporarily select local summary overrides and restore the saved values;
run them alone on a development ship, never concurrently with each other.
Neither requires a paid provider request.

`desk/tests-integration/harness-corpus-benchmark.hoon` builds 32,768 fixture documents and
times production rare-AND, common, scoped and prefix queries independently of
construction using native `%bout` hints. Its synthetic results are not a
production latency guarantee.

Run conformance on a disposable development ship:

```sh
SHIP_URL=http://test-ship.example SHIP_COOKIE=/path/to/auth-cookie.txt \
  node scripts/compaction-conformance.mjs
```

Set `COMPACTION_WATCHDOG_TEST=1` to include the three-minute hung-summary
deadline. The fixture removes unbound test sessions; disabled hand-bound
fixtures retain audit records.

`scripts/compaction-provider-smoke.mjs` uses saved provider credentials in a
temporary, tools-disabled session and makes four real requests, including a
summary. Optional `SMOKE_URL` and `SMOKE_MODEL` select that session's provider.
It does not change global defaults or credentials.

Measure index construction separately from queries, and record workload,
hardware and runtime with results. Synthetic corpus timings do not establish
production latency, rich-message ingestion cost or maximum event-loop stalls.
See [development](development.md) for test safety.
