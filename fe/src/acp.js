const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

export function webConnection() {
  const random = globalThis.crypto?.randomUUID?.().replaceAll('-', '').slice(0, 20)
    || `${Date.now()}${Math.floor(Math.random() * 1e9)}`
  return `harness-web-${random}`
}

class AcpClient extends EventTarget {
  constructor(connection = webConnection()) {
    super()
    this.connection = connection
    this.channel = `harness-ui-${Date.now()}-${Math.floor(Math.random() * 1e6)}`
    this.nextId = 0
    this.eventId = 0
    this.pending = new Map()
    this.running = false
    this.ready = null
    this.lastError = null
    this.recovering = null
  }

  ship() {
    return window.ship || (document.cookie.match(/urbauth-~([a-z-]+)/) || [])[1] || 'zod'
  }

  async poke(json) {
    const response = await fetch(`/~/channel/${this.channel}`, {
      method: 'PUT', credentials: 'same-origin',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify([{
        id: ++this.eventId, action: 'poke', ship: this.ship(), app: 'acp',
        mark: 'acp-action-1', json,
      }]),
    })
    if (!response.ok) throw new Error(`ACP transport returned HTTP ${response.status}`)
  }

  async start() {
    if (this.ready) return this.ready
    this.ready = (async () => {
      await this.poke({ open: { connection: this.connection } })
      this.running = true
      void this.poll()
      return this.call('initialize', { protocolVersion: 1, clientInfo: { name: 'harness-web', version: '0.2.0' } }, 15_000)
    })()
    this.ready.catch(() => {
      this.ready = null
      this.running = false
    })
    return this.ready
  }

  async call(method, params = {}, timeoutMs = method === 'session/prompt' ? 30 * 60_000 : 15_000) {
    const id = ++this.nextId
    const frame = { jsonrpc: '2.0', id, method, params }
    const result = new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id)
        reject(new Error(`${method} timed out; the ship did not answer.`))
      }, timeoutMs)
      this.pending.set(id, { resolve, reject, timer, frame })
    })
    try {
      await this.poke({ send: { connection: this.connection, target: 'agent', payload: JSON.stringify(frame) } })
    } catch (error) {
      const pending = this.pending.get(id)
      if (pending) clearTimeout(pending.timer)
      this.pending.delete(id)
      throw error
    }
    return result
  }

  notify(method, params = {}) {
    const frame = { jsonrpc: '2.0', method, params }
    return this.poke({ send: { connection: this.connection, target: 'agent', payload: JSON.stringify(frame) } })
  }

  async recover() {
    if (this.recovering) return this.recovering
    this.recovering = (async () => {
      await this.poke({ open: { connection: this.connection } })
      for (const { frame } of this.pending.values()) {
        await this.poke({ send: { connection: this.connection, target: 'agent', payload: JSON.stringify(frame) } })
      }
    })().finally(() => { this.recovering = null })
    return this.recovering
  }

  async poll() {
    while (this.running) {
      try {
        const response = await fetch(`/~/scry/acp/v1/${this.connection}/client.json?_=${Date.now()}`, {
          credentials: 'same-origin',
          cache: 'no-store',
        })
        if (response.status === 404) {
          await this.recover()
          await sleep(100)
          continue
        }
        if (!response.ok) throw new Error(`ACP poll returned HTTP ${response.status}`)
        if (response.ok) {
          const update = await response.json()
          const messages = Array.isArray(update?.messages) ? update.messages : []
          let through = 0
          for (const message of messages) {
            through = Math.max(through, Number(message.sequence) || 0)
            this.receive(JSON.parse(message.payload))
          }
          if (through) await this.poke({ ack: { connection: this.connection, target: 'client', through } })
        }
        if (this.lastError) {
          this.lastError = null
          this.dispatchEvent(new Event('transport-ready'))
        }
      } catch (error) {
        if (error.message !== this.lastError) {
          this.lastError = error.message
          this.dispatchEvent(new CustomEvent('transport-error', { detail: error }))
        }
      }
      await sleep(document.hidden ? 1500 : 180)
    }
  }

  close() {
    if (!this.running) return
    this.running = false
    void fetch(`/~/channel/${this.channel}`, {
      method: 'PUT', credentials: 'same-origin', keepalive: true,
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify([{
        id: ++this.eventId, action: 'poke', ship: this.ship(), app: 'acp',
        mark: 'acp-action-1', json: { close: { connection: this.connection, reason: 'browser closed' } },
      }]),
    })
  }

  receive(frame) {
    if (frame.id != null && ('result' in frame || 'error' in frame)) {
      const pending = this.pending.get(Number(frame.id))
      if (!pending) return
      this.pending.delete(Number(frame.id))
      clearTimeout(pending.timer)
      if (frame.error) pending.reject(new Error(frame.error.message || 'ACP request failed'))
      else pending.resolve(frame.result)
      return
    }
    if (frame.method) this.dispatchEvent(new CustomEvent(frame.method, { detail: frame.params }))
  }
}

export const acp = new AcpClient()
if (typeof window !== 'undefined') window.addEventListener('pagehide', (event) => {
  if (!event.persisted) acp.close()
})
