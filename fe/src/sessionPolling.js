export function sessionPollDelay(active, hidden) {
  return active ? (hidden ? 2500 : 600) : (hidden ? 30_000 : 10_000)
}

// One read at a time, with one trailing read when a notification arrives after
// that read began. Repeated notifications cannot postpone an already due read.
export function createSessionPolling({ read, active, hidden,
  setTimer = setTimeout, clearTimer = clearTimeout }) {
  let live = true, timer, pending = null, again = false
  const refresh = () => {
    if (!live) return Promise.resolve()
    clearTimer(timer)
    if (pending) { again = true; return pending }
    pending = (async () => {
      do {
        again = false
        await read()
      } while (live && again)
    })().finally(() => {
      pending = null
      if (live) timer = setTimer(refresh, sessionPollDelay(active(), hidden()))
    })
    return pending
  }
  return {
    refresh,
    // Streams already have a fast safety poll during local turns. The first
    // chunk of a newly observed turn must also wake an otherwise idle view.
    stream() { if (!active()) void refresh() },
    close() { live = false; again = false; clearTimer(timer) },
  }
}
