import { useCallback, useEffect, useRef, useState } from 'react'
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
  const [result, setResult] = useState(() => ({ key, catalog: cache.get(key) || emptyCatalog() }))
  const active = useRef(key)
  active.current = key
  const generation = useRef(0)
  // Never show one provider's limits while the next provider is loading.
  const catalog = result.key === key ? result.catalog : cache.get(key) || emptyCatalog()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const refresh = useCallback(async () => {
    const request = ++generation.current
    const current = () => active.current === key && generation.current === request
    if (!modelsEndpoint) { setResult({ key, catalog: emptyCatalog() }); setError(''); setLoading(false); return }
    setLoading(true); setError('')
    try {
      const result = await api.models(provider, modelsEndpoint)
      const next = normalizeCatalog(result)
      if (current()) { cache.set(key, next); setResult({ key, catalog: next }) }
    } catch (cause) { if (current()) setError(cause.message) }
    finally { if (current()) setLoading(false) }
  }, [key, modelsEndpoint, provider])

  useEffect(() => {
    setResult({ key, catalog: cache.get(key) || emptyCatalog() })
    void refresh()
    return () => { ++generation.current }
  }, [key, refresh])
  return {
    models: catalog.models,
    contextFor: (model) => catalog.contexts[model] || null,
    loading,
    error,
    refresh,
  }
}
