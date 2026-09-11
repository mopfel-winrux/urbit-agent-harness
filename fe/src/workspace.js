import { acp } from './acp.js'
import { EyreSubscription } from './eyreSubscription.js'
import { clientId } from './clientId.js'

export async function workspaceCall(action, args = {}) {
  await acp.start()
  return acp.call('harness/workspace', { action, args })
}

// One mounted workspace watch, shared by all visible queries. Invalidation
// during a read owes a trailing read, never a replay of a mutation.
export function createWorkspaceReads(call, watch) {
  const entries = new Map()
  let stop
  const publish = (entry, result) => { for (const listener of entry.listeners) listener(result) }
  async function refresh(key) {
    const entry = entries.get(key)
    if (!entry) return
    if (entry.pending) { entry.again = true; return entry.pending }
    entry.pending = (async () => {
      do {
        entry.again = false
        try {
          const [action, args] = JSON.parse(key)
          const value = await call(action, args)
          if (entries.get(key) === entry) publish(entry, { value, error: '' })
        } catch (cause) {
          if (entries.get(key) === entry) publish(entry, { error: cause.message })
        }
      } while (entry.again && entries.get(key) === entry)
    })().finally(() => { entry.pending = null })
    return entry.pending
  }
  const invalidate = () => { for (const key of entries.keys()) void refresh(key) }
  return {
    subscribe(key, listener) {
      let entry = entries.get(key)
      if (!entry) { entry = { listeners: new Set(), pending: null, again: false }; entries.set(key, entry) }
      entry.listeners.add(listener)
      if (!stop) stop = watch(invalidate)
      if (!entry.pending) void refresh(key)
      return () => {
        entry.listeners.delete(listener)
        if (!entry.listeners.size) entries.delete(key)
        if (!entries.size) { stop?.(); stop = null }
      }
    },
    refresh,
    invalidate,
  }
}

function watchWorkspace(invalidate) {
  let live = true
  let subscription
  let retry
  let revision
  const connect = async () => {
    try {
      await acp.start()
      if (!live) return
      subscription = new EyreSubscription({
        ship: acp.ship(), app: 'harness', path: '/workspace-events',
        isReady: (value) => Number.isSafeInteger(value?.revision),
        onUpdate: (value) => {
          if (!Number.isSafeInteger(value?.revision)) return
          if (revision !== undefined && revision !== value.revision) invalidate()
          revision = value.revision
        },
        onDisconnect: () => { if (live) retry = setTimeout(connect, 10_000) },
      })
      void subscription.run()
    } catch { if (live) retry = setTimeout(connect, 10_000) }
  }
  const focus = () => { if (!document.hidden) invalidate() }
  const safety = setInterval(() => { if (!document.hidden) invalidate() }, 30_000)
  window.addEventListener('focus', focus)
  document.addEventListener('visibilitychange', focus)
  void connect()
  return () => {
    live = false
    clearTimeout(retry)
    clearInterval(safety)
    subscription?.close()
    window.removeEventListener('focus', focus)
    document.removeEventListener('visibilitychange', focus)
  }
}

export const workspaceReads = createWorkspaceReads(workspaceCall, watchWorkspace)
export async function workspaceWrite(action, args) {
  const result = await workspaceCall(action, args)
  workspaceReads.invalidate()
  return result
}

export const workId = () => `w-${clientId()}`
export const draftKey = (id) => `harness-artifact-draft:${id}`
export function readDraft(storage, id) {
  try {
    const value = JSON.parse(storage.getItem(draftKey(id)))
    return value && Number.isSafeInteger(value.base) && typeof value.title === 'string' && typeof value.body === 'string' && Array.isArray(value.sources) ? value : null
  } catch { return null }
}
export function persistDraft(storage, id, value) {
  try { storage.setItem(draftKey(id), JSON.stringify(value)); return true } catch { return false }
}
export function changedContent(a, b) {
  return a?.title !== b?.title || a?.body !== b?.body || JSON.stringify(a?.sources || []) !== JSON.stringify(b?.sources || [])
}

// Linear-time, bounded replacement diff: shared prefix/suffix remain context;
// the middle is explicitly replaced. Never a quadratic LCS on a 256 KiB page.
export function documentDiff(before, after) {
  const left = before.split('\n'), right = after.split('\n')
  let start = 0, end = 0
  while (start < left.length && start < right.length && left[start] === right[start]) start++
  while (end < left.length - start && end < right.length - start && left[left.length - 1 - end] === right[right.length - 1 - end]) end++
  return { same: before === after, prefix: left.slice(Math.max(0, start - 3), start), removed: left.slice(start, left.length - end), added: right.slice(start, right.length - end), suffix: end ? right.slice(right.length - end, right.length - end + 3) : [] }
}
