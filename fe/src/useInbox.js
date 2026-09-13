import { useCallback, useEffect, useRef, useState } from 'react'
import { api } from './api'
import { createResourceReads } from './resourceReads'
import { createInboxPolling } from './inbox'

const reads = createResourceReads((key) => api.inbox(JSON.parse(key)))

export function useInbox(params) {
  const key = JSON.stringify(params)
  const [state, setState] = useState({ key, loading: true, refreshing: false, value: null, error: '' })
  const polling = useRef(null)
  useEffect(() => {
    let live = true
    setState({ key, loading: true, refreshing: false, value: null, error: '' })
    const unsubscribe = reads.subscribe(key, (result) => setState((previous) => ({ ...previous, ...result, key, loading: false })))
    const poller = createInboxPolling(async () => {
      if (!live) return
      setState((previous) => ({ ...previous, refreshing: true }))
      await reads.refresh(key)
      if (live) setState((previous) => ({ ...previous, refreshing: false }))
    }, { isHidden: () => document.hidden })
    polling.current = poller
    window.addEventListener('focus', poller.refresh)
    document.addEventListener('visibilitychange', poller.visibilityChanged)
    void poller.refresh()
    return () => {
      live = false
      poller.stop()
      unsubscribe()
      window.removeEventListener('focus', poller.refresh)
      document.removeEventListener('visibilitychange', poller.visibilityChanged)
      if (polling.current === poller) polling.current = null
    }
  }, [key])
  const refresh = useCallback(() => polling.current?.refresh(), [])
  return { ...(state.key === key ? state : { loading: true, refreshing: false, value: null, error: '' }), refresh }
}
