import { useCallback, useEffect, useState } from 'react'
import { acp } from './acp'
import { resourcesFor } from './api'

export function useConversations(current, onSelect) {
  const [chats, setChats] = useState([])
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)
  const resources = resourcesFor(current)

  const refresh = useCallback(async () => {
    try {
      await acp.start()
      const result = await acp.call('session/list')
      setChats((result?.sessions || []).map((session) => session.sessionId))
      setError('')
    } catch (cause) { setError(cause.message) }
    finally { setLoading(false) }
  }, [])

  useEffect(() => {
    let live = true
    let timer
    const poll = async () => {
      if (!live) return
      await refresh()
      if (live) timer = setTimeout(poll, document.hidden ? 4000 : 1000)
    }
    poll()
    return () => { live = false; clearTimeout(timer) }
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
