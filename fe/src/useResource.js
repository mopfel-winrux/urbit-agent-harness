import { useCallback, useEffect, useState } from 'react'
import { api } from './api'
import { createResourceReads } from './resourceReads.js'

const reads = createResourceReads((path) => api.read(path))

// Stable settings refresh on entry, focus, saves, and a modest safety poll.
// Live views opt into shorter intervals; overlapping requests share one read.
export function useResource(path, fallback, interval = 30_000) {
  const [value, replaceValue] = useState(fallback)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const setValue = useCallback((next) => {
    if (path) reads.replace(path, next)
  }, [path])
  const refresh = useCallback(() => path ? reads.refresh(path) : Promise.resolve(), [path])

  useEffect(() => {
    replaceValue(fallback)
    setLoading(Boolean(path))
    setError('')
    if (!path) return undefined

    const unsubscribe = reads.subscribe(path, (next) => {
      if ('value' in next) replaceValue(next.value)
      setError(next.error)
      setLoading(false)
    })
    let live = true
    let timer
    const poll = async () => {
      if (!live) return
      clearTimeout(timer)
      await refresh()
      if (live) {
        clearTimeout(timer)
        timer = setTimeout(poll, document.hidden ? Math.max(4000, interval) : interval)
      }
    }
    const focus = () => { if (!document.hidden) void poll() }
    window.addEventListener('focus', focus)
    document.addEventListener('visibilitychange', focus)
    void poll()
    return () => {
      live = false
      unsubscribe()
      clearTimeout(timer)
      window.removeEventListener('focus', focus)
      document.removeEventListener('visibilitychange', focus)
    }
  }, [path, refresh, interval])

  return { value, setValue, loading, error, refresh }
}
