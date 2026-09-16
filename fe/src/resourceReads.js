// Shared in-flight reads only: never a persistent authority/configuration cache.
// A saved value invalidates older reads for every mounted consumer of the key.
export function createResourceReads(read) {
  const entries = new Map()
  const entryFor = (path) => {
    if (!entries.has(path)) entries.set(path, { listeners: new Set(), pending: null, generation: 0 })
    return entries.get(path)
  }
  const release = (path, entry) => {
    if (!entry.listeners.size && !entry.pending && entries.get(path) === entry) entries.delete(path)
  }
  const publish = (entry, value) => { for (const listener of entry.listeners) listener(value) }
  return {
    subscribe(path, listener) {
      const entry = entryFor(path)
      entry.listeners.add(listener)
      return () => {
        entry.listeners.delete(listener)
        // StrictMode can immediately resubscribe. Once a view is genuinely
        // gone, a later mount must not inherit its unfinished read.
        queueMicrotask(() => {
          if (entry.listeners.size) return
          entry.generation++
          entry.pending = null
          release(path, entry)
        })
      }
    },
    replace(path, value) {
      const entry = entryFor(path)
      entry.generation++
      entry.pending = null
      publish(entry, { value, error: '' })
      release(path, entry)
    },
    refresh(path) {
      const entry = entryFor(path)
      if (entry.pending) return entry.pending
      const generation = entry.generation
      const pending = Promise.resolve().then(() => read(path)).then(
        (value) => { if (generation === entry.generation) publish(entry, { value, error: '' }) },
        (cause) => { if (generation === entry.generation) publish(entry, { error: cause.message }) },
      ).finally(() => {
        if (entry.pending === pending) entry.pending = null
        release(path, entry)
      })
      entry.pending = pending
      return pending
    },
  }
}
