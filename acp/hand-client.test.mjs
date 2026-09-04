import test from 'node:test'
import assert from 'node:assert/strict'
import { HandClient, DeliveryNotSent } from './hand-client.mjs'

function fixture({ acquired = true, receiptFails = false } = {}) {
  const calls = []
  const client = { call: async (method, params) => {
    calls.push({ method, params })
    if (params.claim) return { effectId: '0v1', acquired, text: 'answer', address: 'opaque' }
    if (params.receipt && receiptFails) throw new Error('Connection lost')
    return params.receipt || {}
  } }
  return { calls, hand: new HandClient(client, { hand: 'example', worker: 'one' }) }
}

test('binding and observations use the ordinary ACP extension', async () => {
  const { hand, calls } = fixture()
  await hand.bind('b', { address: 'opaque', sessionId: 's', actors: ['alice'] })
  await hand.observe('b', { event: 'external-1', actor: 'alice', text: 'Hello' })
  assert.equal(calls[0].method, 'harness/hand')
  assert.equal(calls[0].params.bind.config.hand, 'example')
  assert.equal(calls[1].params.observe.event, 'external-1')
})
test('publication receives its stable effect identity and returns a receipt', async () => {
  const { hand, calls } = fixture()
  await hand.deliver('0v1', async (intent) => { assert.equal(intent.effectId, '0v1'); return 'message-9' })
  assert.equal(calls[1].params.receipt.status, 'delivered')
  assert.equal(calls[1].params.receipt.external, 'message-9')
})
test('a repeated claim never publishes again automatically', async () => {
  const { hand } = fixture({ acquired: false })
  const result = await hand.deliver('0v1', () => assert.fail('must not publish'))
  assert.equal(result.needsReconciliation, true)
})
test('unknown publication failure requires reconciliation', async () => {
  const { hand, calls } = fixture()
  await assert.rejects(hand.deliver('0v1', async () => { throw new Error('timeout') }))
  assert.equal(calls[1].params.receipt.status, 'uncertain')
})
test('only a positively unsent effect is marked retryable', async () => {
  const { hand, calls } = fixture()
  await assert.rejects(hand.deliver('0v1', async () => { throw new DeliveryNotSent('rejected before send') }))
  assert.equal(calls[1].params.receipt.status, 'failed')
})
test('lost receipt does not classify successful publication as failed', async () => {
  const { hand, calls } = fixture({ receiptFails: true })
  await assert.rejects(hand.deliver('0v1', async () => 'message-9'))
  assert.equal(calls.length, 2)
  assert.equal(calls[1].params.receipt.status, 'delivered')
})
