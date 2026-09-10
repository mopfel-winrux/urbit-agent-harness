import { useCallback, useEffect, useRef, useState } from 'react'
import { acp } from './acp'
import { resourcesFor } from './api'
import { sortConversations } from './conversations'
import { watchConversationUpdates } from './conversationUpdates.js'

export function useConversations(current, onSelect) {
  const [chats, setChats] = useState([])
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)
  const welcomed = useRef(false)
  const pending = useRef(null)
  const live = useRef(false)
  const resources = resourcesFor(current)

  const refresh = useCallback(() => {
    if (pending.current) return pending.current
    pending.current = (async () => {
      try {
        await acp.start()
        let result
        if (!welcomed.current) {
          result = await acp.call('harness/onboarding/ensure')
          welcomed.current = true
        }
        // Older ships return only sessionId from ensure; keep that compatible.
        if (!Array.isArray(result?.sessions)) result = await acp.call('session/list')
        const next = sortConversations(result?.sessions || [])
        if (live.current) { setChats(next); setError('') }
        return next
      } catch (cause) { if (live.current) setError(cause.message) }
      finally { if (live.current) setLoading(false); pending.current = null }
    })()
    return pending.current
  }, [])

  useEffect(() => {
    live.current = true
    const channel = typeof BroadcastChannel === 'undefined' ? null : new BroadcastChannel('harness-conversations')
    const stop = watchConversationUpdates({ refresh, acp, window, document, channel })
    return () => { live.current = false; stop() }
  }, [refresh])

  async function create(name) {
    await acp.start()
    const result = await acp.call('session/new', { cwd: '/', mcpServers: [], name })
    await refresh()
    onSelect(result.sessionId)
  }

  async function remove(name) {
    await acp.call('session/delete', { sessionId: name })
    await refresh()
    if (name === current) onSelect(chats.find((item) => item !== name) || '')
  }

  async function rename(from, name) {
    if (!from || from === name) return
    if (chats.includes(name)) throw new Error('A conversation with that name already exists.')
    await acp.call('harness/session/rename', { sessionId: from, name })
    await refresh()
    if (current === from) onSelect(name)
  }

  return { chats, error, loading, resources, create, remove, rename, refresh }
}
