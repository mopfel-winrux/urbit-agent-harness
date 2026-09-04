import { acp } from './acp.js'

async function action(value) {
  await acp.start()
  if (value.config) return acp.call('harness/session/configure', { sessionId: value.config.sid, config: value.config.config })
  if (value['set-key']) return acp.call('harness/credential/set', { provider: value['set-key'].provider || 'openrouter', key: value['set-key'].key })
  throw new Error('Unsupported Harness action')
}

export const scryUrl = (path) => `/~/scry/harness/${path}.json`
async function read(path) {
  await acp.start()
  if (path === 'sessions') return (await acp.call('session/list')).sessions?.map((session) => session.sessionId) || []
  if (path === 'status') return acp.call('harness/status')
  if (path.startsWith('status/')) return acp.call('harness/status', { provider: path.slice('status/'.length) })
  if (path === 'tools') return acp.call('harness/tools')
  if (path.startsWith('session/')) return acp.call('harness/session/config', { sessionId: path.slice('session/'.length) })
  throw new Error(`Unsupported Harness read: ${path}`)
}

const models = async (provider, url) => {
  await acp.start()
  return acp.call('harness/provider/models', { provider, url }, 30_000)
}

export const api = { read, action, models }

export function paths(chat) {
  return {
    chat,
    chats: 'sessions',
    session: `session/${chat}`,
    config: `session/${chat}`,
    transcript: `session/${chat}`,
    status: `session/${chat}`,
    tools: 'tools',
  }
}

export const defaultConfig = (overrides = {}) => ({
  url: 'https://openrouter.ai/api/v1/chat/completions',
  model: 'openai/gpt-4o-mini',
  key: '',
  headers: [],
  system: 'You are a capable personal agent living on an Urbit ship. Be direct, careful, and useful.',
  'max-context': 80_000,
  tools: ['ship-time', 'clay', 'web', 'skills', 'skill-write', 'author', 'subagents', 'peers'],
  ...overrides,
})
