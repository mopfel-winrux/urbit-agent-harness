export const CONVERSATION_POLL_MS = 15_000
export const CONVERSATION_HIDDEN_POLL_MS = 60_000

// Pushes cover this client's changes and other same-origin tabs. The slower
// fallback covers native hands/older servers that don't emit list changes.
export function watchConversationUpdates({ refresh, acp, window, document, channel,
  setTimer = setTimeout, clearTimer = clearTimeout }) {
  let live = true, timer, changedTimer, pending = false, again = false
  const poll = async () => {
    if (!live) return
    if (pending) { again = true; return }
    pending = true
    clearTimer(timer)
    try { await refresh() } finally {
      pending = false
      if (live) {
        if (again) { again = false; void poll() }
        else timer = setTimer(poll, document.hidden ? CONVERSATION_HIDDEN_POLL_MS : CONVERSATION_POLL_MS)
      }
    }
  }
  const changed = () => {
    if (!live || changedTimer != null) return
    changedTimer = setTimer(() => { changedTimer = null; void poll() }, 250)
  }
  const local = () => { channel?.postMessage('changed'); changed() }
  const updated = (event) => {
    // Token chunks are not new list entries; completion invalidates via RPC.
    if (event.detail?.update?.sessionUpdate === 'user_message_chunk') local()
  }
  const focus = () => { if (!document.hidden) void poll() }
  acp.addEventListener('harness/sessions/changed', local)
  acp.addEventListener('session/update', updated)
  acp.addEventListener('transport-ready', changed)
  window.addEventListener('focus', focus)
  document.addEventListener('visibilitychange', focus)
  channel?.addEventListener('message', changed)
  void poll()
  return () => {
    live = false
    clearTimer(timer); clearTimer(changedTimer)
    acp.removeEventListener('harness/sessions/changed', local)
    acp.removeEventListener('session/update', updated)
    acp.removeEventListener('transport-ready', changed)
    window.removeEventListener('focus', focus)
    document.removeEventListener('visibilitychange', focus)
    channel?.removeEventListener('message', changed)
    channel?.close()
  }
}
