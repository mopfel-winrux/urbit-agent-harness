import { useCallback, useEffect, useState } from 'react'
import { api } from './api.js'
import { PROVIDERS } from './providers.js'

const cache = new Map()
const emptyCatalog = () => ({ models: [], contexts: {} })

export function normalizeCatalog(result = {}) {
  const contexts = {}
  const ids = []
  for (const entry of result.modelInfo || []) {
    if (!entry || typeof entry.id !== 'string') continue
    ids.push(entry.id)
    const context = Number(entry.contextWindow)
    if (Number.isSafeInteger(context) && context > 0) contexts[entry.id] = context
  }
  for (const entry of result.models || []) {
    const id = typeof entry === 'string' ? entry : entry?.id
    if (typeof id === 'string') ids.push(id)
  }
  return { models: [...new Set(ids)].sort(), contexts }
}

export function useProviderModels(provider, endpoint) {
  const details = PROVIDERS[provider]
  const modelsEndpoint = endpoint || details?.modelsEndpoint || ''
  const key = `${provider}:${modelsEndpoint}`
  const [catalog, setCatalog] = useState(() => cache.get(key) || emptyCatalog())
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const refresh = useCallback(async () => {
    if (!modelsEndpoint) { setCatalog(emptyCatalog()); setError(''); return }
    setLoading(true); setError('')
    try {
      const result = await api.models(provider, modelsEndpoint)
      const next = normalizeCatalog(result)
      cache.set(key, next); setCatalog(next)
    } catch (cause) { setError(cause.message) }
    finally { setLoading(false) }
  }, [key, modelsEndpoint, provider])

  useEffect(() => { setCatalog(cache.get(key) || emptyCatalog()); void refresh() }, [key, refresh])
  return {
    models: catalog.models,
    contextFor: (model) => catalog.contexts[model] || null,
    loading,
    error,
    refresh,
  }
}
