import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { api, resourcesFor } from '../src/api'
import { defaultConfig } from '../src/defaults'
import GlobalSettings from '../src/components/GlobalSettings'
import AgentSettings from '../src/components/AgentSettings'
import ProviderSettings from '../src/components/ProviderSettings'
import SearchSettings from '../src/components/SearchSettings'
import McpSettings from '../src/components/McpSettings'
import SkillSettings from '../src/components/SkillSettings'
import '../src/style.css'

const pending = new Map()
const params = new URLSearchParams(location.search)
let config = JSON.parse(sessionStorage.getItem('settings-fixture-config') || 'null') || defaultConfig()
let device = params.has('device') || sessionStorage.getItem('settings-fixture-device') === 'true'
let apiKey = false
let braveKey = sessionStorage.getItem('settings-fixture-brave') === 'true'
let search = JSON.parse(sessionStorage.getItem('settings-fixture-search') || 'null') || { provider: 'brave', 'instance-url': '' }
let skills = JSON.parse(sessionStorage.getItem('settings-fixture-skills') || '[]')
window.settingsFixture = { requests: [], saves: [], credentials: [], resolve: (id, value) => pending.get(id)(value) }
api.read = async (path) => {
  if (path === 'skills') return skills.map(({ name, desc }) => ({ name, desc }))
  if (path.startsWith('skill/')) return skills.find((skill) => skill.name === path.slice(6))
  if (path === 'defaults' || path.startsWith('session/')) return config
  if (path === 'status/openai') return { 'has-key': device || apiKey, 'has-api-key': apiKey, 'has-device-login': device, 'auth-method': device ? 'device' : 'api-key' }
  if (path === 'status/brave') return { 'has-key': braveKey }
  if (path === 'search') return search
  if (path === 'tools') return ['clay', 'web', 'skills', 'skill-write', 'author', 'subagents', 'peers', 'mcp']
  if (path === 'mcp' && params.get('page') !== 'mcp') return [
    { id: 'calendar', name: 'Calendar', enabled: true },
    { id: 'notes', name: 'Notes', enabled: true },
  ]
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
  if (action.saveSkill || action.deleteSkill) {
    const input = action.saveSkill || action.deleteSkill
    const old = skills.find((skill) => skill.name === input.name)
    if (input.revision !== (old?.revision || '')) throw new Error('Skill changed; reload it before saving or deleting')
    const next = { ...input, revision: crypto.randomUUID() }
    skills = skills.filter((skill) => skill.name !== input.name)
    if (action.saveSkill) skills.push(next)
    sessionStorage.setItem('settings-fixture-skills', JSON.stringify(skills))
    window.settingsFixture.saves.push(action)
    return action.saveSkill ? next : skills.map(({ name, desc }) => ({ name, desc }))
  }
  if (action.search) {
    search = action.search
    sessionStorage.setItem('settings-fixture-search', JSON.stringify(search))
    window.settingsFixture.saves.push(search)
    return search
  }
  if (action.mcp) {
    window.settingsFixture.saves.push(action.mcp)
    return action.mcp
  }
  config = action.defaults || action.config.config
  window.settingsFixture.saves.push(config)
  sessionStorage.setItem('settings-fixture-config', JSON.stringify(config))
  return config
}
const component = params.get('page') === 'skills' ? <SkillSettings /> : params.get('page') === 'mcp' ? <McpSettings resources={resourcesFor('')} /> : params.get('page') === 'search' ? <SearchSettings /> : params.get('page') === 'provider'
  ? <ProviderSettings provider="openai" resources={resourcesFor('')} />
  : params.get('page') === 'conversation'
    ? <AgentSettings resources={resourcesFor('fixture')} theme="system" onThemeChange={() => {}} />
    : <GlobalSettings resources={resourcesFor('')} theme="system" onThemeChange={() => {}} />
createRoot(document.getElementById('root')).render(<StrictMode>{component}</StrictMode>)
