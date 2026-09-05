// ACP query/command facade. Resource keys are client lookup keys, not Grubbery
// roads or storage locations; changing the transport must not change ownership.
import { acp } from './acp.js'

async function action(value) {
  await acp.start()
  if (value.tlon) return acp.call('harness/tlon/configure', value.tlon)
  if (value.tlonProfile) return acp.call('harness/tlon/profile/set', value.tlonProfile)
  if (value.config) return acp.call('harness/session/configure', { sessionId: value.config.sid, config: value.config.config })
  if (value.defaults) return acp.call('harness/defaults/configure', { config: value.defaults })
  if (value.mcp) return acp.call('harness/mcp/configure', { servers: value.mcp })
  if (value['set-key']) return acp.call('harness/credential/set', { provider: value['set-key'].provider || 'openrouter', key: value['set-key'].key })
  throw new Error('Unsupported Harness action')
}

export const scryUrl = (path) => `/~/scry/harness/${path}.json`
async function read(path) {
  await acp.start()
  if (path === 'tlon') return acp.call('harness/tlon')
  if (path === 'tlon/contacts') return acp.call('harness/tlon/contacts')
  if (path === 'tlon/profile') return acp.call('harness/tlon/profile')
  if (path === 'sessions') return (await acp.call('session/list')).sessions?.map((session) => session.sessionId) || []
  if (path === 'status') return acp.call('harness/status')
  if (path.startsWith('status/')) return acp.call('harness/status', { provider: path.slice('status/'.length) })
  if (path === 'tools') return acp.call('harness/tools')
  if (path === 'defaults') return acp.call('harness/defaults')
  if (path === 'mcp') return acp.call('harness/mcp/servers')
  if (path.startsWith('session/')) return acp.call('harness/session/config', { sessionId: path.slice('session/'.length) })
  throw new Error(`Unsupported Harness read: ${path}`)
}

const models = async (provider, url) => {
  await acp.start()
  return acp.call('harness/provider/models', { provider, url }, 30_000)
}

export const api = { read, action, models }

export function resourcesFor(chat) {
  return {
    chat,
    session: `session/${chat}`,
    tools: 'tools',
    defaults: 'defaults',
    mcp: 'mcp',
  }
}
