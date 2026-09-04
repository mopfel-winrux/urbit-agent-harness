import { useCallback, useEffect, useState } from 'react'
import { api } from './api.js'
import { PROVIDERS } from './providers.js'

const cache = new Map()

export function useProviderModels(provider, endpoint) {
  const details = PROVIDERS[provider]
  const modelsEndpoint = endpoint || details?.modelsEndpoint || ''
  const key = `${provider}:${modelsEndpoint}`
  const [models, setModels] = useState(() => cache.get(key) || [])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const refresh = useCallback(async () => {
    if (!modelsEndpoint) { setModels([]); setError(''); return }
    setLoading(true); setError('')
    try {
      const result = await api.models(provider, modelsEndpoint)
      const next = [...new Set(result?.models || [])].sort()
      cache.set(key, next); setModels(next)
    } catch (cause) { setError(cause.message) }
    finally { setLoading(false) }
  }, [key, modelsEndpoint, provider])

  useEffect(() => { setModels(cache.get(key) || []); void refresh() }, [key, refresh])
  return { models, loading, error, refresh }
}
