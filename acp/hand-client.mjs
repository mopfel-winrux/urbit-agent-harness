// A hand uses the same ACP connection as any other client. It owns no model
// loop. Supply an initialized client with call(method, params).
export class DeliveryNotSent extends Error {}

export class HandClient {
  constructor(client, { hand, worker }) {
    if (!hand || !worker) throw new Error('A hand and stable worker identity are required')
    this.client = client
    this.hand = hand
    this.worker = worker
  }

  action(operation, params) { return this.client.call('harness/hand', { [operation]: params }) }
  bind(id, { address, sessionId, actors, enabled = true }) {
    return this.action('bind', { id, config: { hand: this.hand, address, sessionId, actors, enabled } })
  }
  enable(id, enabled) { return this.action('enable', { id, enabled }) }
  remove(id) { return this.action('remove', { id }) }
  observe(binding, { event, actor, text }) { return this.action('observe', { binding, event, actor, text }) }
  status(binding) { return this.action('status', { binding }) }
  outbox() { return this.action('outbox', { hand: this.hand }) }
  effect(effect) { return this.action('effect', { hand: this.hand, effect }) }
  claim(effect) { return this.action('claim', { hand: this.hand, effect, worker: this.worker }) }
  receipt(effect, status, external = '') {
    return this.action('receipt', { hand: this.hand, effect, worker: this.worker, status, external })
  }
  retry(effect) { return this.action('retry', { hand: this.hand, effect }) }

  async deliver(effect, publish) {
    const intent = await this.claim(effect)
    // A replayed claim might have published before its worker crashed. Only a
    // newly acquired claim is permission to start a fresh external operation.
    if (!intent.acquired) return { ...intent, needsReconciliation: true }
    let external
    try {
      external = await publish(intent)
      if (typeof external !== 'string') throw new Error('Publisher must return its external message id')
    } catch (error) {
      await this.receipt(effect, error instanceof DeliveryNotSent ? 'failed' : 'uncertain')
      throw error
    }
    // If receipt transport fails, leave the claim intact. Do not classify a
    // successful publication as failed or invoke publish again on reconnect.
    return this.receipt(effect, 'delivered', external)
  }
}
