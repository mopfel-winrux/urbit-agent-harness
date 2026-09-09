// ACP query/command facade. Resource keys are client lookup keys, not Grubbery
// roads or storage locations; changing the transport must not change ownership.
import { acp } from './acp.js'

async function action(value) {
  await acp.start()
  if (value.owner) return acp.call('harness/tlon/owner/set', value.owner)
  if (value.tlon) return acp.call('harness/tlon/configure', { ...value.tlon, expectedOwner: value.tlon.owner })
  if (value.tlonProfile) return acp.call('harness/tlon/profile/set', value.tlonProfile)
  if (value.cancelCron) return acp.call('harness/cron/cancel', { id: value.cancelCron })
  if (value.clearCron) return acp.call('harness/cron/clear', { id: value.clearCron })
  if (value.hand) return acp.call('harness/hand', value.hand)
  if (value.retryAdmission) return acp.call('harness/tlon/admission/retry', { id: value.retryAdmission })
  if (value.config) return acp.call('harness/session/configure', { sessionId: value.config.sid, config: value.config.config })
  if (value.defaults) return acp.call('harness/defaults/configure', { config: value.defaults })
  if (value.summaryModels) return acp.call('harness/summary-models/configure', { models: value.summaryModels })
  if (value.peers) return acp.call('harness/peers/configure', value.peers)
  if (value.peerReset) return acp.call('harness/peers/reset', value.peerReset)
  if (value.peerCheck) return acp.call('harness/peers/check', { ship: value.peerCheck })
  if (value.mcp) return acp.call('harness/mcp/configure', { servers: value.mcp })
  if (value.search) return acp.call('harness/search/configure', { config: value.search })
  if (value.saveSkill) return acp.call('harness/skill/save', value.saveSkill)
  if (value.deleteSkill) return acp.call('harness/skill/delete', value.deleteSkill)
  if (value['set-key']) return acp.call('harness/credential/set', { ...value['set-key'], provider: value['set-key'].provider || 'openrouter' })
  throw new Error('Unsupported Harness action')
}

export const scryUrl = (path) => `/~/scry/harness/${path}.json`
async function read(path) {
  await acp.start()
  if (path === 'tlon') return acp.call('harness/tlon')
  if (path === 'tlon/owner') return acp.call('harness/tlon/owner')
  if (path === 'tlon/contacts') return acp.call('harness/tlon/contacts')
  if (path === 'tlon/profile') return acp.call('harness/tlon/profile')
  if (path === 'cron') return acp.call('harness/cron')
  if (path === 'tlon/work' || path.startsWith('tlon/work/')) return acp.call('harness/tlon/work', { before: path === 'tlon/work' ? '' : path.slice('tlon/work/'.length) })
  if (path === 'sessions') return (await acp.call('session/list')).sessions?.map((session) => session.sessionId) || []
  if (path === 'status') return acp.call('harness/status')
  if (path.startsWith('status/')) return acp.call('harness/status', { provider: path.slice('status/'.length) })
  if (path === 'tools') return acp.call('harness/tools')
  if (path === 'defaults') return acp.call('harness/defaults')
  if (path === 'summary-models') return acp.call('harness/summary-models')
  if (path === 'peers') return acp.call('harness/peers')
  if (path === 'peers/remote') return acp.call('harness/peers/remote')
  if (path === 'corpus/status') return acp.call('harness/corpus/status')
  if (path === 'mcp') return acp.call('harness/mcp/servers')
  if (path === 'search') return acp.call('harness/search')
  if (path === 'skills') return acp.call('harness/skills')
  if (path.startsWith('skill/')) return acp.call('harness/skill', { name: path.slice('skill/'.length) })
  if (path.startsWith('session/')) return acp.call('harness/session/config', { sessionId: path.slice('session/'.length) })
  throw new Error(`Unsupported Harness read: ${path}`)
}

const models = async (provider, url) => {
  await acp.start()
  // Device auth may spend up to 30 seconds renewing before catalog dispatch.
  return acp.call('harness/provider/models', { provider, url }, 60_000)
}

const corpus = async (operation, params = {}) => {
  if (!['search', 'read', 'expand', 'rebuild'].includes(operation)) throw new Error('Unsupported corpus operation')
  await acp.start()
  return acp.call(`harness/corpus/${operation}`, params)
}

export const api = { read, action, models, corpus }

export function resourcesFor(chat) {
  return {
    chat,
    session: `session/${chat}`,
    tools: 'tools',
    defaults: 'defaults',
    mcp: 'mcp',
  }
}
