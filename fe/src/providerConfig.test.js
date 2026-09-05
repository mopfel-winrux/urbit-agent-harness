import assert from 'node:assert/strict'
import test from 'node:test'
import { PROVIDERS } from './providers.js'
import { authMethod, withAuth, chooseProvider, catalogEndpoint, credentialSlot } from './providerConfig.js'

test('OpenAI auth selects a fixed endpoint, catalog, and credential slot', () => {
  const api = withAuth({ url: 'https://wrong.example', headers: [] }, 'openai', 'api-key')
  const device = withAuth(api, 'openai', 'device')
  assert.equal(api.url, PROVIDERS.openai.endpoint)
  assert.equal(device.url, PROVIDERS.openai.deviceEndpoint)
  assert.equal(authMethod('openai', device), 'device')
  assert.equal(catalogEndpoint('openai', device), PROVIDERS.openai.deviceModelsEndpoint)
  assert.equal(credentialSlot('openai', 'device'), 'openai-device')
  assert.equal(credentialSlot('openai', 'api-key'), 'openai')
})

test('selecting OpenAI honors saved device preference and preserves an existing selection', () => {
  const previous = { url: PROVIDERS.openrouter.endpoint, headers: [{ name: 'x-private', value: 'fixture' }] }
  const selected = chooseProvider(previous, 'openai', 'device')
  assert.equal(selected.url, PROVIDERS.openai.deviceEndpoint)
  assert.deepEqual(selected.headers, [])
  assert.equal(chooseProvider(selected, 'openai', 'api-key'), selected)
})

test('OpenAI auth changes strip account/auth headers, not unrelated headers', () => {
  const config = { headers: [{ name: 'ChatGPT-Account-ID', value: 'fixture' }, { name: 'Authorization', value: 'Bearer fixture' }, { name: 'x-extra', value: 'kept' }] }
  assert.deepEqual(withAuth(config, 'openai', 'api-key').headers, [{ name: 'x-extra', value: 'kept' }])
})

test('only custom providers preserve an arbitrary endpoint and auth headers', () => {
  const custom = { url: 'https://inference.example/v1/chat/completions', headers: [{ name: 'Authorization', value: 'custom' }] }
  assert.equal(withAuth(custom, 'custom', 'api-key'), custom)
  assert.equal(withAuth(custom, 'openrouter', 'api-key').url, PROVIDERS.openrouter.endpoint)
})

test('Anthropic login selects its OAuth header on the same fixed route', () => {
  const config = withAuth({ headers: [] }, 'anthropic', 'device')
  assert.equal(config.url, PROVIDERS.anthropic.endpoint)
  assert.equal(authMethod('anthropic', config), 'device')
  assert.deepEqual(withAuth(config, 'anthropic', 'api-key').headers, [])
})
