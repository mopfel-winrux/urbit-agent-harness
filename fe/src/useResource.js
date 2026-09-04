import { useCallback, useEffect, useRef, useState } from 'react'
import { api } from './api'

// A replaceable client view of an ACP resource, not a second source of truth.
// Generations fence responses from a closed view or a read predating a save.
export function useResource(path, fallback) {
  const [value, replaceValue] = useState(fallback)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const generation = useRef(0)
  const setValue = useCallback((next) => {
    generation.current++; replaceValue(next); setLoading(false); setError('')
  }, [])

  const refresh = useCallback(async () => {
    if (!path) return
    const epoch = generation.current
    try {
      const next = await api.read(path)
      if (epoch !== generation.current) return
      replaceValue(next)
      setError('')
    } catch (cause) {
      if (epoch === generation.current) setError(cause.message)
    } finally {
      if (epoch === generation.current) setLoading(false)
    }
  }, [path])

  useEffect(() => {
    setValue(fallback)
    setLoading(true)
    setError('')
    if (!path) { setLoading(false); return undefined }

    let live = true
    let timer
    const poll = async () => {
      if (!live) return
      await refresh()
      if (live) timer = setTimeout(poll, document.hidden ? 4000 : 900)
    }
    poll()
    return () => { live = false; generation.current++; clearTimeout(timer) }
  }, [path, refresh, setValue])

  return { value, setValue, loading, error, refresh }
}
