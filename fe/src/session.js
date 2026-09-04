// Event addresses and input identities come from the ship. Text matching is
// not an admission receipt; snapshots remain replaceable client state.
export function applySnapshot(previous, next) {
  if (previous && next.revision < previous.revision) return previous
  return { ...next, entries: next.entries ?? previous?.entries ?? [] }
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
      const result = { status: 'completed', body: item.body }
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
