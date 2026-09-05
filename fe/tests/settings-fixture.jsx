import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { api, resourcesFor } from '../src/api'
import { defaultConfig } from '../src/defaults'
import GlobalSettings from '../src/components/GlobalSettings'
import AgentSettings from '../src/components/AgentSettings'
import ProviderSettings from '../src/components/ProviderSettings'
import SearchSettings from '../src/components/SearchSettings'
import McpSettings from '../src/components/McpSettings'
import '../src/style.css'

const pending = new Map()
const params = new URLSearchParams(location.search)
let config = JSON.parse(sessionStorage.getItem('settings-fixture-config') || 'null') || defaultConfig()
let device = params.has('device') || sessionStorage.getItem('settings-fixture-device') === 'true'
let apiKey = false
let braveKey = sessionStorage.getItem('settings-fixture-brave') === 'true'
window.settingsFixture = { requests: [], saves: [], credentials: [], resolve: (id, value) => pending.get(id)(value) }
api.read = async (path) => {
  if (path === 'defaults' || path.startsWith('session/')) return config
  if (path === 'status/openai') return { 'has-key': device || apiKey, 'has-api-key': apiKey, 'has-device-login': device, 'auth-method': device ? 'device' : 'api-key' }
  if (path === 'status/brave') return { 'has-key': braveKey }
  return []
}
api.models = (provider, url) => new Promise((resolve) => {
  const id = window.settingsFixture.requests.length
  pending.set(id, resolve)
  window.settingsFixture.requests.push({ id, provider, url })
})
api.action = async (action) => {
  if (action['set-key']) {
    const { provider } = action['set-key']
    if (provider === 'openai-device') window.settingsFixture.deviceBundle = { hasRefresh: Boolean(action['set-key'].refreshToken), hasAccount: Boolean(action['set-key'].account) }
    window.settingsFixture.credentials.push(provider)
    if (provider === 'openai-device') { device = true; sessionStorage.setItem('settings-fixture-device', 'true') }
    if (provider === 'openai') apiKey = true
    if (provider === 'brave') {
      braveKey = Boolean(action['set-key'].key)
      sessionStorage.setItem('settings-fixture-brave', String(braveKey))
      return { 'has-key': braveKey }
    }
    return { 'has-key': true }
  }
  if (window.settingsFixture.failSave) throw new Error('Configuration save failed in fixture')
  if (action.mcp) {
    window.settingsFixture.saves.push(action.mcp)
    return action.mcp
  }
  config = action.defaults || action.config.config
  window.settingsFixture.saves.push(config)
  sessionStorage.setItem('settings-fixture-config', JSON.stringify(config))
  return config
}
const component = params.get('page') === 'mcp' ? <McpSettings resources={resourcesFor('')} /> : params.get('page') === 'search' ? <SearchSettings /> : params.get('page') === 'provider'
  ? <ProviderSettings provider="openai" resources={resourcesFor('')} />
  : params.get('page') === 'conversation'
    ? <AgentSettings resources={resourcesFor('fixture')} theme="system" onThemeChange={() => {}} />
    : <GlobalSettings resources={resourcesFor('')} theme="system" onThemeChange={() => {}} />
createRoot(document.getElementById('root')).render(<StrictMode>{component}</StrictMode>)
