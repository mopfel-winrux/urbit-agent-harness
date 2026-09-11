import { useCallback, useEffect, useState } from 'react'
import { workspaceReads } from './workspace.js'

export function useWorkspace(action, args = {}) {
  const key = action ? JSON.stringify([action, args]) : ''
  const [state, setState] = useState({ key, loading: Boolean(key), error: '', value: null })
  useEffect(() => {
    setState({ key, loading: Boolean(key), error: '', value: null })
    if (!key) return
    return workspaceReads.subscribe(key, (result) => setState((previous) => ({ ...previous, ...result, key, loading: false })))
  }, [key])
  const refresh = useCallback(() => key ? workspaceReads.refresh(key) : Promise.resolve(), [key])
  return { ...(state.key === key ? state : { loading: Boolean(key), error: '', value: null }), refresh }
}
