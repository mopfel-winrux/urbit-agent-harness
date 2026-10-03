import { createRoot } from 'react-dom/client'
import { api, resourcesFor } from '../src/api'
import { acp } from '../src/acp'
import TlonSettings from '../src/components/TlonSettings'
import Settings from '../src/components/Settings'
import Sidebar from '../src/components/Sidebar'
import '../src/style.css'

const schedulesPage = new URLSearchParams(location.search).has('schedules')
let state = { revision: 'revision-1', ship: '~nec', lens: { enabled: false, pending: 0, error: '' }, policy: { enabled: false, owner: '~zod', response: 'mentions', allowed: [], channels: [], trusted: [] }, connected: false, sessions: ['nec-dm-test'] }
window.tlonFixture = { saves: [], modelUpdates: [], cron: [], cancelled: [], work: { records: [], next: null, headConnected: true }, workReads: [], recoveries: [], recoveryError: '', profile: { nickname: 'Existing bot', avatar: 'https://example.com/bot.png' }, profileError: '' }
acp.call = async (method, params) => {
  if (method !== 'harness/session/use-default-model') throw new Error('Unexpected fixture method')
  window.tlonFixture.modelUpdates.push(params.sessionId)
  return {}
}
api.read = async (path) => path === 'tlon/cron' ? structuredClone(window.tlonFixture.cron) : path === 'mcp' ? [{ id: 'calendar', name: 'Calendar', enabled: true }, { id: 'notes', name: 'Notes', enabled: true }] : path === 'defaults' ? { url: 'https://openrouter.ai/api/v1/chat/completions', model: 'test/model' } : path === 'tlon/profile' ? structuredClone(window.tlonFixture.profile) : path === 'tlon' ? structuredClone(state) : path === 'tools' ? ['clay', 'web', 'mcp', 'tlon-read', 'tlon-write', 'cron'] : [
  { ship: '~zod', nickname: 'Owner', contact: true },
  { ship: '~nec', nickname: 'Alice', contact: true },
  { ship: '~bud', nickname: 'Alice peer', contact: false },
]
const read = api.read
api.read = async (path) => {
  if (path === 'tlon/channels') return [{ channel: 'chat/~zod/general', title: 'General', group: 'Test group' }]
  if (path === 'cron') {
    if (window.tlonFixture.cronError) throw new Error(window.tlonFixture.cronError)
    if (window.tlonFixture.holdCron) await new Promise((resolve) => { window.tlonFixture.releaseCron = resolve })
    return structuredClone(window.tlonFixture.cron)
  }
  if (path.startsWith('tlon/work')) { window.tlonFixture.workReads.push(path); return structuredClone(window.tlonFixture.work) }
  return read(path)
}
api.action = async ({ tlon, tlonProfile, tlonLens, retryLens, cancelCron, clearCron, retryCron, hand, retryAdmission }) => {
  if (tlonLens) {
    window.tlonFixture.lensConfig = tlonLens
    state = { ...state, lens: { ...state.lens, enabled: tlonLens.enabled, owner: tlonLens.expectedOwner } }
    return structuredClone(state)
  }
  if (retryLens) { window.tlonFixture.lensRetry = true; return structuredClone(state) }
  if (retryCron) {
    if (window.tlonFixture.retryError) throw new Error(window.tlonFixture.retryError)
    window.tlonFixture.recoveries.push({ retryCron })
    if (window.tlonFixture.holdRetry) await new Promise(resolve => { window.tlonFixture.releaseRetry = resolve })
    window.tlonFixture.cron = window.tlonFixture.cron.map(job => job.id === retryCron.id ? { ...job, retryable: false, execution: 'running', delivery: null } : job)
    return structuredClone(window.tlonFixture.cron)
  }
  if (hand || retryAdmission) {
    if (window.tlonFixture.recoveryError) throw new Error(window.tlonFixture.recoveryError)
    window.tlonFixture.recoveries.push(hand || { retryAdmission })
    window.tlonFixture.work.records = window.tlonFixture.work.records.map((record) => {
      if (record.id !== (hand?.resolve?.effect || hand?.retry?.effect || retryAdmission)) return record
      return { ...record, status: hand?.resolve?.status || 'completed', canResolve: false, canRetry: false }
    })
    return {}
  }
  if (clearCron) {
    if (window.tlonFixture.clearError) throw new Error(window.tlonFixture.clearError)
    window.tlonFixture.cron = window.tlonFixture.cron.filter((job) => job.id !== clearCron)
    return structuredClone(window.tlonFixture.cron)
  }
  if (cancelCron) {
    window.tlonFixture.cancelled.push(cancelCron)
    window.tlonFixture.cron = window.tlonFixture.cron.map((job) => job.id === cancelCron ? { ...job, state: 'cancelled', reason: 'Cancelled in owner settings' } : job)
    return structuredClone(window.tlonFixture.cron)
  }
  if (tlonProfile) {
    if (window.tlonFixture.profileError) throw new Error(window.tlonFixture.profileError)
    window.tlonFixture.profile = structuredClone(tlonProfile)
    return structuredClone(tlonProfile)
  }
  window.tlonFixture.saves.push(tlon)
  state = { ...state, policy: tlon }
  return state
}
createRoot(document.getElementById('root')).render(<div className="app-shell"><Sidebar chats={['daily-notes']} tlon={!schedulesPage} settings={schedulesPage} onSelect={() => {}} onNew={() => {}} />{schedulesPage ? <Settings resources={resourcesFor('')} initialTab="schedules" onBack={() => {}} /> : <TlonSettings onBack={() => {}} />}</div>)
