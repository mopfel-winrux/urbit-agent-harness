import { useCallback, useEffect, useState } from 'react'
import { api, keepUrl } from './api'

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
    refresh()
    const stream = new EventSource(keepUrl(path, mark))
    const name = path.split('/').pop()
    const receive = (event) => {
      if (!live || !event.data) return
      try {
        setValue(mark === 'json' ? JSON.parse(event.data) : event.data)
        setError('')
        setLoading(false)
      } catch {
        // A reconnecting stream can end on a partial frame; the next event or
        // explicit refresh supplies a complete value.
      }
    }
    for (const kind of ['old', 'new', 'upd']) stream.addEventListener(`${kind} /${name}`, receive)
    stream.onerror = () => { if (live) setError('Live updates are reconnecting…') }
    return () => { live = false; stream.close() }
  }, [path, mark, refresh])

  return { value, setValue, loading, error, refresh }
}
