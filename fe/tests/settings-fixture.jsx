import { StrictMode, useState } from 'react'
import { createRoot } from 'react-dom/client'
import { api, resourcesFor } from '../src/api'
import { defaultConfig } from '../src/defaults'
import GlobalSettings from '../src/components/GlobalSettings'
import AgentSettings from '../src/components/AgentSettings'
import ProviderSettings from '../src/components/ProviderSettings'
import SearchSettings from '../src/components/SearchSettings'
import McpSettings from '../src/components/McpSettings'
import SkillSettings from '../src/components/SkillSettings'
import PeerSettings from '../src/components/PeerSettings'
import TlonSettings from '../src/components/TlonSettings'
import { emptyPeers, newPeerGrant } from '../src/peers'
import Settings from '../src/components/Settings'
import Sidebar from '../src/components/Sidebar'
import App from '../src/App'
import { acp } from '../src/acp'
import '../src/style.css'

const pending = new Map()
const params = new URLSearchParams(location.search)
let config = JSON.parse(sessionStorage.getItem('settings-fixture-config') || 'null') || defaultConfig()
let device = params.has('device') || sessionStorage.getItem('settings-fixture-device') === 'true'
let apiKey = false
let braveKey = sessionStorage.getItem('settings-fixture-brave') === 'true'
let search = JSON.parse(sessionStorage.getItem('settings-fixture-search') || 'null') || { provider: 'brave', 'instance-url': '' }
let skills = JSON.parse(sessionStorage.getItem('settings-fixture-skills') || '[]')
let peerSettings = JSON.parse(sessionStorage.getItem('settings-fixture-peers') || 'null') || { ...emptyPeers(), ship: '~zod', revision: '1', usage: [{ ship: '~nec', used: 1234, total: 1234 }] }
let tlonPolicy = JSON.parse(sessionStorage.getItem('settings-fixture-tlon') || 'null') || { enabled: false, owner: '~bud', mentions: true, trusted: [{ ship: '~nec', tools: ['web'] }] }
let siblingMoonOwners = sessionStorage.getItem('settings-fixture-siblings') === 'true'
let remoteShips = []
const tlonSnapshot = () => ({ policy: tlonPolicy, sessions: [], ship: '~zod', isMoon: params.has('moon'), sponsor: params.has('moon') ? '~bud' : null, siblingMoonOwners })
const peerSnapshot = () => ({ ...peerSettings, owners: [...(tlonPolicy.owner ? [newPeerGrant(tlonPolicy.owner, config.tools)] : []), ...(params.has('trusted-owner') ? [newPeerGrant('~nec', config.tools)] : [])], trusted: [...(tlonPolicy.owner ? [newPeerGrant(tlonPolicy.owner)] : []), ...tlonPolicy.trusted.map((entry) => newPeerGrant(entry.ship, entry.tools))] })
window.settingsFixture = { requests: [], reads: [], calls: [], saves: [], credentials: [], resolve: (id, value) => pending.get(id)(value) }
acp.start = async () => {}
acp.call = async (method) => {
  window.settingsFixture.calls.push(method)
  if (method === 'harness/onboarding/ensure') return { sessionId: null, ...(params.has('legacy-bootstrap') ? {} : { sessions: ['daily-notes', 'reading-list'].map((sessionId) => ({ sessionId })) }) }
  if (method === 'session/list') return { sessions: ['daily-notes', 'reading-list'].map((sessionId) => ({ sessionId })) }
  if (method === 'harness/session/snapshot') return { revision: 1, phase: 'idle', entries: [], model: config.model }
  throw new Error(`Unexpected fixture method: ${method}`)
}
api.read = async (path) => {
  window.settingsFixture.reads.push(path)
  if (path === 'peers') {
    if (window.settingsFixture.failPeerRead) throw new Error('Peer settings unavailable in fixture')
    return peerSnapshot()
  }
  if (path === 'tlon' || path === 'tlon/owner') return tlonSnapshot()
  if (path === 'peers/remote') return { ships: remoteShips }
  if (path === 'tlon/profile') return { nickname: '', avatar: '' }
  if (path === 'tlon/work') return { items: [], events: [], next: '' }
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
  if (action.owner) {
    if (action.owner.expectedOwner !== tlonPolicy.owner || action.owner.expectedSiblingMoonOwners !== siblingMoonOwners) throw new Error('Owner changed; reload before saving')
    siblingMoonOwners = action.owner.siblingMoonOwners
    tlonPolicy = { ...tlonPolicy, owner: action.owner.owner, enabled: action.owner.owner || siblingMoonOwners ? tlonPolicy.enabled : false }
    peerSettings.revision = String(Number(peerSettings.revision) + 1)
    sessionStorage.setItem('settings-fixture-tlon', JSON.stringify(tlonPolicy))
    sessionStorage.setItem('settings-fixture-siblings', String(siblingMoonOwners))
    window.settingsFixture.saves.push(action)
    return tlonSnapshot()
  }
  if (action.peerCheck) {
    remoteShips = [{ ship: action.peerCheck, allowed: true, checkedAt: '~2026.9.8', grant: newPeerGrant(action.peerCheck, ['web']) }]
    window.settingsFixture.saves.push(action)
    return { requested: true }
  }
  if (action.tlon) {
    tlonPolicy = action.tlon
    peerSettings.revision = String(Number(peerSettings.revision) + 1)
    sessionStorage.setItem('settings-fixture-tlon', JSON.stringify(tlonPolicy))
    window.settingsFixture.saves.push(action)
    return tlonSnapshot()
  }
  if (action.peerReset) {
    if (window.settingsFixture.failPeerReset) throw new Error('Reset failed in fixture')
    if (action.peerReset.revision !== peerSettings.revision) throw new Error('Peer settings or trust changed; reload before resetting')
    peerSettings = { ...peerSettings, usage: peerSettings.usage.map((entry) => entry.ship === action.peerReset.ship ? { ...entry, used: 0 } : entry) }
    sessionStorage.setItem('settings-fixture-peers', JSON.stringify(peerSettings))
    window.settingsFixture.saves.push(action)
    return peerSnapshot()
  }
  if (action.peers) {
    if (window.settingsFixture.failPeerSave) throw new Error('Peer save failed in fixture')
    if (action.peers.revision !== peerSettings.revision) throw new Error('Peer settings or trust changed; reload before saving')
    peerSettings = { ...peerSettings, ...action.peers, revision: String(Number(peerSettings.revision) + 1) }
    sessionStorage.setItem('settings-fixture-peers', JSON.stringify(peerSettings))
    window.settingsFixture.saves.push(action)
    return peerSnapshot()
  }
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
function SettingsFixture() {
  const [theme, setTheme] = useState('system')
  const changeTheme = (next) => { document.documentElement.dataset.theme = next; setTheme(next) }
  const component = params.get('page') === 'peers' ? <PeerSettings /> : params.get('page') === 'tlon' ? <TlonSettings onBack={() => {}} /> : params.get('page') === 'skills' ? <SkillSettings /> : params.get('page') === 'mcp' ? <McpSettings resources={resourcesFor('')} /> : params.get('page') === 'search' ? <SearchSettings /> : params.get('page') === 'provider'
  ? <ProviderSettings provider="openai" resources={resourcesFor('')} />
  : params.get('page') === 'conversation'
    ? <AgentSettings resources={resourcesFor('fixture')} theme={theme} onThemeChange={changeTheme} />
    : <GlobalSettings resources={resourcesFor('')} theme={theme} onThemeChange={changeTheme} />
  return params.get('page') === 'app' ? <App /> : params.get('page') === 'shell'
    ? <div className="app-shell"><Sidebar chats={['daily-notes']} settings onSelect={() => {}} onNew={() => {}} /><Settings resources={resourcesFor(params.has('global') ? '' : 'fixture')} theme={theme} onThemeChange={changeTheme} onBack={() => {}} /></div>
    : <main className="settings-content">{component}</main>
}
createRoot(document.getElementById('root')).render(<StrictMode><SettingsFixture /></StrictMode>)
