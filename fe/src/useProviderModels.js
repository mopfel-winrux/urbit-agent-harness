import { useCallback, useEffect, useRef, useState } from 'react'
import { api } from './api.js'
import { PROVIDERS, providerOf } from './providers.js'
import { authMethod, catalogEndpoint, credentialSlot } from './providerConfig.js'
import { createModelCatalogs, resolveContextWindow } from './modelCatalogs.js'

const cache = createModelCatalogs(async (provider, endpoint) => normalizeCatalog(await api.models(provider, endpoint)))
export const invalidateModelCatalogs = () => cache.invalidate()
const emptyCatalog = () => ({ models: [], contexts: {} })

export async function resolveModelConfig(config, saved) {
  const provider = providerOf(config.url)
  const source = provider === 'anthropic' ? credentialSlot(provider, authMethod(provider, config)) : provider
  const window = await resolveContextWindow(config, saved,
    () => cache.load(source, catalogEndpoint(provider, config)))
  return { ...config, 'max-context': window }
}

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

export function useProviderModels(provider, endpoint, enabled = true) {
  const details = PROVIDERS[provider]
  const modelsEndpoint = endpoint || details?.modelsEndpoint || ''
  const key = `${provider}:${modelsEndpoint}`
  const [result, setResult] = useState(() => ({ key, catalog: cache.peek(key) || emptyCatalog() }))
  const active = useRef(key)
  active.current = enabled ? key : null
  const generation = useRef(0)
  // Never show one provider's limits while the next provider is loading.
  const catalog = !enabled ? emptyCatalog() : result.key === key ? result.catalog : cache.peek(key) || emptyCatalog()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const load = useCallback(async (force) => {
    const request = ++generation.current
    const current = () => active.current === key && generation.current === request
    if (!enabled || !modelsEndpoint) { setResult({ key, catalog: emptyCatalog() }); setError(''); setLoading(false); return }
    setLoading(true); setError('')
    try {
      const next = await cache.load(provider, modelsEndpoint, { force })
      if (current()) setResult({ key, catalog: next })
    } catch (cause) { if (current()) setError(cause.message) }
    finally { if (current()) setLoading(false) }
  }, [key, modelsEndpoint, provider, enabled])
  const refresh = useCallback(() => load(true), [load])

  useEffect(() => {
    setResult({ key, catalog: cache.peek(key) || emptyCatalog() })
    void load(false)
    return () => { ++generation.current }
  }, [key, load])
  return {
    models: catalog.models,
    contextFor: (model) => catalog.contexts[model] || null,
    loading,
    error,
    refresh,
  }
}
