export const DEFAULT_BALL = 'apps/harness.harness'

const encodePath = (path) => path.split('/').filter(Boolean).map(encodeURIComponent).join('/')
const blot = (name) => `?blot=${encodeURIComponent(`/${name}`)}`

async function responseData(response) {
  const text = await response.text()
  if (!text) return null
  try { return JSON.parse(text) } catch { return text }
}

async function request(url, options = {}) {
  const response = await fetch(url, { credentials: 'same-origin', ...options })
  const data = await responseData(response)
  if (!response.ok) {
    const detail = typeof data === 'string' ? data : data?.error || data?.message
    throw new Error(detail || `HTTP ${response.status}`)
  }
  return data
}

// Do not abort a slow write: cancelling its Eyre request also annuls the
// Grubbery Arrow. Keep the fetch alive, return after dispatch, and let callers
// confirm the resulting grub state.
async function writeRequest(url, options) {
  const response = request(url, options)
  const dispatched = new Promise((resolve) => setTimeout(() => resolve(null), 250))
  return Promise.race([response, dispatched])
}

export const fileUrl = (path, mark = 'json') =>
  `/grubbery/api/file/${encodePath(path)}${blot(mark)}`

export const keepUrl = (path, mark = 'json') =>
  `/grubbery/api/keep/${encodePath(path)}${blot(mark)}`

export const ballUrl = (path = '') => `/grubbery/ball/${encodePath(path)}`

export const api = {
  read: (path, mark = 'json') => request(fileUrl(path, mark)),
  get: (url) => request(url),
  post: (url, value) => writeRequest(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(value),
  }),
  poke: (path, value, mark = 'json') => writeRequest(
    `/grubbery/api/poke/${encodePath(path)}${blot(mark)}`,
    {
      method: 'POST',
      headers: { 'content-type': mark === 'json' ? 'application/json' : 'text/plain' },
      body: mark === 'json' ? JSON.stringify(value) : String(value),
    },
  ),
  over: (path, value, mark = 'json') => writeRequest(
    `/grubbery/api/over/${encodePath(path)}${blot(mark)}`,
    {
      method: 'POST',
      headers: { 'content-type': mark === 'json' ? 'application/json' : 'text/plain' },
      body: mark === 'json' ? JSON.stringify(value) : String(value),
    },
  ),
}

export async function waitFor(read, accepts, { attempts = 40, interval = 250 } = {}) {
  let value
  for (let attempt = 0; attempt < attempts; attempt += 1) {
    value = await read()
    if (accepts(value)) return value
    await new Promise((resolve) => setTimeout(resolve, interval))
  }
  throw new Error('The ship did not apply the change.')
}

export function paths(ball, agent, chat) {
  const agentRoot = `${ball}/agents/${agent}`
  const chatRoot = `${agentRoot}/chats/${chat}`
  return {
    agentRoot,
    chatRoot,
    chats: `${agentRoot}/ui/chats.json`,
    agentMain: `${agentRoot}/main.sig`,
    config: `${agentRoot}/config.json`,
    about: `${agentRoot}/about.txt`,
    anthropic: `${ball}/apis/anthropic`,
    transcript: `${chatRoot}/chat.json`,
    status: `${chatRoot}/status.json`,
  }
}
