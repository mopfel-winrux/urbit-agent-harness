// Auth selection owns built-in routes. The persisted URL is the selection;
// there is no second auth flag that can disagree with it after a reload.
import { PROVIDERS, providerOf } from './providers.js'

export function authMethod(provider, config = {}) {
  if (provider === 'openai') return config.url === PROVIDERS.openai.deviceEndpoint ? 'device' : 'api-key'
  if (provider === 'anthropic') return (config.headers || []).some((h) => h.name.toLowerCase() === 'anthropic-beta' && h.value.includes('oauth-')) ? 'device' : 'api-key'
  return 'api-key'
}

export function withAuth(config, provider, method) {
  if (provider === 'custom') return config
  const details = PROVIDERS[provider]
  const headers = (config.headers || []).filter((h) => !['authorization', 'x-api-key', 'chatgpt-account-id'].includes(h.name.toLowerCase())
    && !(h.name.toLowerCase() === 'anthropic-beta' && h.value.includes('oauth-')))
  if (provider === 'anthropic' && method === 'device') headers.push({ name: 'anthropic-beta', value: 'oauth-2025-04-20' })
  return { ...config, url: method === 'device' && details.deviceEndpoint ? details.deviceEndpoint : details.endpoint, headers }
}

export function chooseProvider(config, provider, preferredAuth = 'api-key') {
  if (providerOf(config.url) === provider) return config
  const details = PROVIDERS[provider]
  // Do not carry another provider's headers/credentials across a provider switch.
  return withAuth({ ...config, url: details.endpoint || '', model: details.model || '', headers: [], key: '' }, provider, preferredAuth)
}

export function catalogEndpoint(provider, config) {
  const details = PROVIDERS[provider]
  return authMethod(provider, config) === 'device' && details.deviceModelsEndpoint ? details.deviceModelsEndpoint : details.modelsEndpoint
}

export function credentialSlot(provider, method) {
  return provider === 'openai' && method === 'device' ? 'openai-device' : provider
}
