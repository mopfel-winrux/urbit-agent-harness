// Catalogs supply model capacity, never credentials or capability grants.
export async function resolveContextWindow(config, saved, read) {
  try {
    const catalog = await read()
    const capacity = catalog.contexts?.[config.model]
    if (Number.isSafeInteger(capacity) && capacity > 0) return capacity
  } catch { /* A catalog outage must not lower an unchanged model's capacity. */ }
  const unchanged = config.model === saved?.model && config.url === saved?.url
    && JSON.stringify(config.headers || []) === JSON.stringify(saved?.headers || [])
  const previous = saved?.['max-context']
  return unchanged && Number.isSafeInteger(previous) && previous > 0 ? previous : 80_000
}

export function createModelCatalogs(read, { ttl = 300_000, now = Date.now, limit = 32 } = {}) {
  const cache = new Map()
  const pending = new Map()
  let generation = 0
  const keyFor = (provider, endpoint) => `${provider}:${endpoint}`
  return {
    peek(key) { return cache.get(key)?.value },
    load(provider, endpoint, { force = false } = {}) {
      const key = keyFor(provider, endpoint)
      if (!endpoint) return Promise.resolve({ models: [], contexts: {} })
      if (pending.has(key)) return pending.get(key)
      const cached = cache.get(key)
      if (!force && cached && now() - cached.at < ttl) return Promise.resolve(cached.value)
      const started = generation
      const request = Promise.resolve().then(() => read(provider, endpoint)).then((value) => {
        if (started !== generation) return value
        cache.delete(key)
        cache.set(key, { value, at: now() })
        while (cache.size > limit) cache.delete(cache.keys().next().value)
        return value
      }).finally(() => { if (pending.get(key) === request) pending.delete(key) })
      pending.set(key, request)
      return request
    },
    invalidate() { generation++; cache.clear(); pending.clear() },
  }
}
