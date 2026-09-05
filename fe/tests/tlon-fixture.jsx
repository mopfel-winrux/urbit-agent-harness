import { createRoot } from 'react-dom/client'
import { api } from '../src/api'
import { acp } from '../src/acp'
import TlonSettings from '../src/components/TlonSettings'
import '../src/style.css'

let state = { policy: { enabled: false, owner: '~zod', mentions: true, trusted: [] }, connected: false, sessions: ['nec-dm-test'] }
window.tlonFixture = { saves: [], modelUpdates: [], profile: { nickname: 'Existing bot', avatar: 'https://example.com/bot.png' }, profileError: '' }
acp.call = async (method, params) => {
  if (method !== 'harness/session/use-default-model') throw new Error('Unexpected fixture method')
  window.tlonFixture.modelUpdates.push(params.sessionId)
  return {}
}
api.read = async (path) => path === 'defaults' ? { url: 'https://openrouter.ai/api/v1/chat/completions', model: 'test/model' } : path === 'tlon/profile' ? structuredClone(window.tlonFixture.profile) : path === 'tlon' ? structuredClone(state) : path === 'tools' ? ['clay', 'web'] : [
  { ship: '~zod', nickname: 'Owner', contact: true },
  { ship: '~nec', nickname: 'Alice', contact: true },
  { ship: '~bud', nickname: 'Alice peer', contact: false },
]
api.action = async ({ tlon, tlonProfile }) => {
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
