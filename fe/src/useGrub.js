import { useCallback, useEffect, useState } from 'react'
import { api } from './api'

export function useGrub(path, fallback, mark = 'json') {
  const [value, setValue] = useState(fallback)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  const refresh = useCallback(async () => {
    if (!path) return
    try {
      const next = await api.read(path, mark)
      setValue(next)
      setError('')
    } catch (cause) {
      setError(cause.message)
    } finally {
      setLoading(false)
    }
  }, [path, mark])

  useEffect(() => {
    setValue(fallback)
    setLoading(true)
    setError('')
    if (!path) return undefined

    let live = true
    let timer
    const poll = async () => {
      if (!live) return
      await refresh()
      if (live) timer = setTimeout(poll, document.hidden ? 4000 : 900)
    }
    poll()
    return () => { live = false; clearTimeout(timer) }
  }, [path, mark, refresh])

  return { value, setValue, loading, error, refresh }
}
