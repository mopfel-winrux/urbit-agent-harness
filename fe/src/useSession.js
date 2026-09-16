import { useCallback, useEffect, useRef, useState } from 'react'
import { acp } from './acp'
import { admitted, applySnapshot, applyHistory } from './session'
import { clientId } from './clientId.js'
import { createSessionPolling } from './sessionPolling.js'

const running = (snapshot) => ['thinking', 'tools', 'compacting'].includes(snapshot?.phase)

export function useSession(chat) {
  const [snapshot, setSnapshot] = useState(null)
  const [pending, setPending] = useState(null)
  const [sending, setSending] = useState(false)
  const [error, setError] = useState('')
  const [actionError, setActionError] = useState('')
  const [loadingHistory, setLoadingHistory] = useState(false)
  const current = useRef(null)
  const live = useRef(false)
  const fetching = useRef(null)
  const latestSend = useRef(null)
  const polling = useRef(null)

  const read = useCallback(() => {
    if (fetching.current) return fetching.current
    fetching.current = (async () => {
      try {
        await acp.start()
        const next = await acp.call('harness/session/snapshot', {
          sessionId: chat, ...(current.current ? { since: current.current.revision } : {}),
        })
        if (!live.current) return
        current.current = applySnapshot(current.current, next)
        setSnapshot(current.current)
        setPending((value) => admitted(value, current.current.entries) ? null : value)
        setError('')
      } catch (cause) { if (live.current) setError(cause.message) }
      finally { fetching.current = null }
    })()
    return fetching.current
  }, [chat])
  const refresh = useCallback(() => polling.current?.refresh() ?? read(), [read])

  useEffect(() => {
    live.current = true
    const loop = createSessionPolling({ read,
      active: () => !current.current || !!latestSend.current || running(current.current),
      hidden: () => document.hidden,
    })
    polling.current = loop
    const update = ({ detail }) => {
      if (detail?.sessionId !== chat) return
      const value = detail.update
      if (value?.sessionUpdate === 'harness_prompt_admitted') {
        setPending((item) => {
          if (item?.id !== value.clientMessageId) return item
          const next = { ...item, inputId: value.inputId }
          return admitted(next, current.current?.entries || []) ? null : next
        })
      }
      if (value?.sessionUpdate === 'harness_agent_stream_chunk') loop.stream()
      else void loop.refresh()
    }
    const focus = () => { if (!document.hidden) void loop.refresh() }
    const ready = () => { void loop.refresh() }
    acp.addEventListener('session/update', update)
    acp.addEventListener('transport-ready', ready)
    window.addEventListener('focus', focus)
    document.addEventListener('visibilitychange', focus)
    void loop.refresh()
    return () => {
      live.current = false; loop.close()
      if (polling.current === loop) polling.current = null
      acp.removeEventListener('session/update', update)
      acp.removeEventListener('transport-ready', ready)
      window.removeEventListener('focus', focus)
      document.removeEventListener('visibilitychange', focus)
    }
  }, [chat, read])

  async function send(text) {
    const attempt = {}
    latestSend.current = attempt
    try {
      const id = clientId()
      setPending({ id, text }); setSending(true); setActionError('')
      const result = acp.call('session/prompt', { sessionId: chat, clientMessageId: id, prompt: [{ type: 'text', text }] })
      void refresh()
      await result
    } catch (cause) { if (live.current && latestSend.current === attempt) setActionError(cause.message) }
    finally {
      // A /stop prompt may supersede an in-flight prompt. Its predecessor's
      // completion must not clear the new command's ghost or sending state.
      if (live.current && latestSend.current === attempt) { latestSend.current = null; setPending(null); setSending(false); void refresh() }
    }
  }

  async function stop() {
    try { await acp.call('session/cancel', { sessionId: chat }); await refresh() }
    catch (cause) { if (live.current) setActionError(cause.message) }
  }

  async function loadHistory() {
    const before = current.current?.before
    if (before == null || loadingHistory) return
    setLoadingHistory(true)
    try {
      const page = await acp.call('harness/session/history', { sessionId: chat, before })
      if (!live.current) return
      // Refresh live state before joining a page captured after our snapshot.
      if (page.revision > current.current.revision) await refresh()
      current.current = applyHistory(current.current, page, before)
      setSnapshot(current.current)
    } catch (cause) { if (live.current) setActionError(cause.message) }
    finally { if (live.current) setLoadingHistory(false) }
  }

  const active = running(snapshot)
  return { snapshot, pending, error: error || actionError || snapshot?.error || '', loading: !snapshot,
    busy: sending || active, send, stop, refresh, loadHistory, loadingHistory }
}
