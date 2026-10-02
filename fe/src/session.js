// Event addresses and input identities come from the ship. Text matching is
// not an admission receipt; snapshots remain replaceable client state.
export function applySnapshot(previous, next) {
  if (previous && next.revision < previous.revision) return previous
  // A snapshot can be in flight when a newer stream frame arrives. Keep the
  // displayed prefix until that snapshot catches up; completion advances it.
  const streamed = previous?.streamRevision ?? previous?.revision
  if (previous && (streamed > next.revision || (streamed === next.revision &&
      (previous.streaming?.length || 0) > (next.streaming?.length || 0)))) {
    next = { ...next, streaming: previous.streaming, streamRevision: streamed, phase: 'thinking' }
  }
  if (next.entries == null) return { ...next, entries: previous?.entries ?? [], before: previous?.before ?? null }
  // Only join overlapping windows. After a long disconnect a gap must stay
  // discoverable through the ship's cursor, not look like complete history.
  const overlap = previous?.entries?.some((old) => next.entries.some((row) => row.id === old.id))
  if (!overlap) return next
  return { ...next, entries: mergeEntries(previous.entries, next.entries), before: previous.before ?? null }
}

// Stream offsets count UTF-8 bytes, as they do on the ship. A gap asks for an
// authoritative snapshot; stale or duplicate frames cannot revive a turn.
export function applyStream(snapshot, update) {
  if (!snapshot) return null
  const { revision, offset, content } = update
  if (!Number.isSafeInteger(revision) || !Number.isSafeInteger(offset) || offset < 0 ||
      content?.type !== 'text' || typeof content.text !== 'string') return null
  const currentRevision = snapshot.streamRevision ?? snapshot.revision
  if (revision < Math.max(currentRevision, snapshot.revision)) return snapshot
  const prefix = revision === currentRevision ? snapshot.streaming || '' : ''
  const bytes = new TextEncoder().encode(prefix).length
  if (offset < bytes && offset + new TextEncoder().encode(content.text).length <= bytes) return snapshot
  if (offset !== bytes) return null
  return { ...snapshot, streamRevision: revision, streaming: prefix + content.text, phase: 'thinking' }
}

function mergeEntries(older, newer) {
  const rows = new Map(older.map((row) => [row.id, row]))
  for (const row of newer) rows.set(row.id, row)
  return [...rows.values()].sort((a, b) => a.eventCount - b.eventCount)
}

export function applyHistory(previous, page, before) {
  if (!previous || previous.before !== before || page.revision > previous.revision) return previous
  return { ...previous, entries: mergeEntries(page.entries, previous.entries), before: page.before }
}

export function admitted(pending, entries) {
  return !!pending?.inputId && entries.some((entry) => entry.inputId === pending.inputId)
}

export function transcriptEntries(items) {
  const entries = []
  const tools = new Map()
  for (const item of items) {
    if (item.role === 'tool') {
      const call = tools.get(item.callId)
      const result = { status: item.cancelled ? 'cancelled' : 'completed', body: item.body }
      if (call) Object.assign(call, result)
      else entries.push({ ...item, ...result, type: 'tool', title: item.name })
      continue
    }
    if (item.body) entries.push(item)
    for (const call of item.calls || []) {
      const entry = { type: 'tool', id: `${item.id}:${call.id}`, title: call.name, status: 'in_progress', body: call.args }
      tools.set(call.id, entry)
      entries.push(entry)
    }
  }
  return entries
}
