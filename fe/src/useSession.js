import { useCallback, useEffect, useRef, useState } from 'react'
import { acp } from './acp'
import { admitted, applySnapshot } from './session'

export function useSession(chat) {
  const [snapshot, setSnapshot] = useState(null)
  const [pending, setPending] = useState(null)
  const [sending, setSending] = useState(false)
  const [error, setError] = useState('')
  const [actionError, setActionError] = useState('')
  const current = useRef(null)
  const live = useRef(false)
  const fetching = useRef(null)

  const refresh = useCallback(() => {
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

  useEffect(() => {
    live.current = true
    let cancelled = false
    let timer
    const poll = async () => {
      await refresh()
      if (!cancelled) timer = setTimeout(poll, document.hidden ? 2500 : 600)
    }
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
      if (value?.sessionUpdate !== 'harness_agent_stream_chunk') void refresh()
    }
    acp.addEventListener('session/update', update)
    void poll()
    return () => { cancelled = true; live.current = false; clearTimeout(timer); acp.removeEventListener('session/update', update) }
  }, [chat, refresh])

  async function send(text) {
    const id = crypto.randomUUID()
    setPending({ id, text }); setSending(true); setActionError('')
    try {
      await acp.call('session/prompt', { sessionId: chat, clientMessageId: id, prompt: [{ type: 'text', text }] })
      if (live.current) await refresh()
    } catch (cause) { if (live.current) setActionError(cause.message) }
    finally {
      if (live.current) { setPending(null); setSending(false); void refresh() }
    }
  }

  async function stop() {
    try { await acp.notify('session/cancel', { sessionId: chat }); await refresh() }
    catch (cause) { if (live.current) setActionError(cause.message) }
  }

  const active = ['thinking', 'tools', 'compacting'].includes(snapshot?.phase)
  return { snapshot, pending, error: error || actionError || snapshot?.error || '', loading: !snapshot,
    busy: sending || active, send, stop, refresh }
}
