import { canonicalShip } from './people.js'
import { clientId } from './clientId.js'

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

export function webConnection() {
  return `harness-web-${clientId()}`
}

export class AcpClient extends EventTarget {
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
    this.receivedThrough = 0
    this.host = null
    this.identity = null
    // A slow ship is not a failed request. Abort only when this client closes.
    this.transport = new AbortController()
  }

  ship() {
    if (!this.host) throw new Error('The current ship has not been identified.')
    return this.host
  }

  async identify() {
    this.assertOpen()
    if (this.identity) return this.identity
    this.identity = (async () => {
      // Cookies are shared across ports. Eyre knows both this server's ship
      // and the authenticated identity; browser globals/cookie order do not.
      const read = async (path) => {
        const response = await fetch(path, { credentials: 'same-origin', cache: 'no-store', signal: this.transport.signal })
        if (!response.ok) throw new Error(`Could not identify this ship (HTTP ${response.status}).`)
        const ship = canonicalShip(await response.text())
        if (!ship) throw new Error('The server did not return a valid ship identity.')
        return ship
      }
      const [host, identity] = await Promise.all([read('/~/host'), read('/~/name')])
      if (host !== identity) throw new Error('Sign in to this ship, then reload Harness.')
      this.host = host.slice(1)
      return this.host
    })().catch((error) => { this.identity = null; this.host = null; throw error })
    return this.identity
  }

  async poke(json) {
    const ship = await this.identify()
    const response = await fetch(`/~/channel/${this.channel}`, {
      method: 'PUT', credentials: 'same-origin',
      signal: this.transport.signal,
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify([{
        id: ++this.eventId, action: 'poke', ship, app: 'acp',
        mark: 'acp-action-1', json,
      }]),
    })
    if (!response.ok) throw new Error(`ACP transport returned HTTP ${response.status}`)
  }

  async start() {
    if (this.ready) return this.ready
    this.ready = (async () => {
      await this.poke({ open: { connection: this.connection } })
      this.assertOpen()
      this.running = true
      void this.poll()
      return this.call('initialize', { protocolVersion: 1, clientInfo: { name: 'harness-web', version: '0.2.0' } })
    })()
    this.ready.catch(() => {
      this.ready = null
      this.running = false
    })
    return this.ready
  }

  assertOpen() {
    if (this.transport.signal.aborted) throw new Error('Connection closed. Reload Harness to reconnect.')
  }

  async call(method, params = {}) {
    this.assertOpen()
    const id = ++this.nextId
    const frame = { jsonrpc: '2.0', id, method, params }
    const result = new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject, frame })
    })
    // A reply or connection closure can arrive before the HTTP poke finishes.
    result.catch(() => {})
    try {
      await this.poke({ send: { connection: this.connection, target: 'agent', payload: JSON.stringify(frame) } })
    } catch (error) {
      const pending = this.pending.get(id)
      this.pending.delete(id)
      pending?.reject(error)
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
      this.receivedThrough = 0
      // A missing queue is not proof that a mutation was never admitted.
      for (const [id, pending] of this.pending) {
        pending.reject(new Error('Connection restored. Check the conversation before repeating your action.'))
        this.pending.delete(id)
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
          signal: this.transport.signal,
        })
        if (!this.running) return
        if (response.status === 404) {
          await this.recover()
          await sleep(100)
          continue
        }
        if (!response.ok) throw new Error(`ACP poll returned HTTP ${response.status}`)
        if (response.ok) {
          const update = await response.json()
          const messages = Array.isArray(update?.messages) ? update.messages : []
          const through = this.receiveBatch(messages)
          if (through) await this.poke({ ack: { connection: this.connection, target: 'client', through } })
        }
        if (this.lastError) {
          this.lastError = null
          this.dispatchEvent(new Event('transport-ready'))
        }
      } catch (error) {
        if (!this.running) return
        if (error.message !== this.lastError) {
          this.lastError = error.message
          this.dispatchEvent(new CustomEvent('transport-error', { detail: error }))
        }
      }
      if (this.running) await sleep(document.hidden ? 1500 : 180)
    }
  }

  close() {
    if (this.transport.signal.aborted) return
    const wasRunning = this.running
    this.running = false
    this.ready = null
    this.transport.abort()
    for (const pending of this.pending.values()) {
      pending.reject(new Error('Connection closed. Check the conversation before repeating your action.'))
    }
    this.pending.clear()
    if (!wasRunning || !this.host) return
    void fetch(`/~/channel/${this.channel}`, {
      method: 'PUT', credentials: 'same-origin', keepalive: true,
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify([{
        id: ++this.eventId, action: 'poke', ship: this.ship(), app: 'acp',
        mark: 'acp-action-1', json: { close: { connection: this.connection, reason: 'browser closed' } },
      }]),
    }).catch(() => {})
  }

  receiveBatch(messages) {
    for (const message of messages) {
      const sequence = Number(message.sequence) || 0
      if (sequence <= this.receivedThrough) continue
      this.receive(JSON.parse(message.payload))
      this.receivedThrough = sequence
    }
    return this.receivedThrough
  }

  receive(frame) {
    if (frame.id != null && ('result' in frame || 'error' in frame)) {
      const pending = this.pending.get(Number(frame.id))
      if (!pending) return
      this.pending.delete(Number(frame.id))
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
