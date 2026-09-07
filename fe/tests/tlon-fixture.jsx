import { createRoot } from 'react-dom/client'
import { api } from '../src/api'
import { acp } from '../src/acp'
import TlonSettings from '../src/components/TlonSettings'
import '../src/style.css'

let state = { policy: { enabled: false, owner: '~zod', mentions: true, trusted: [] }, connected: false, sessions: ['nec-dm-test'] }
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
  if (path.startsWith('tlon/work')) { window.tlonFixture.workReads.push(path); return structuredClone(window.tlonFixture.work) }
  return read(path)
}
api.action = async ({ tlon, tlonProfile, cancelCron, clearCron, hand, retryAdmission }) => {
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
createRoot(document.getElementById('root')).render(<div className="app-shell"><TlonSettings onBack={() => {}} /></div>)
