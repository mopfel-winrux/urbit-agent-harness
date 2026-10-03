import assert from 'node:assert/strict'
import test from 'node:test'
import { PROVIDERS } from './providers.js'
import { authMethod, withAuth, chooseProvider, catalogEndpoint, credentialSlot } from './providerConfig.js'
import { defaultConfig } from './defaults.js'

test('OpenAI leads provider choices and defaults to device login without rewriting saved routes', () => {
  assert.equal(Object.keys(PROVIDERS)[0], 'openai')
  assert.equal(defaultConfig().url, PROVIDERS.openai.deviceEndpoint)
  assert.equal(chooseProvider({ url: PROVIDERS.openrouter.endpoint }, 'openai').url, PROVIDERS.openai.deviceEndpoint)
  const saved = { url: PROVIDERS.openai.endpoint, model: 'saved-model' }
  assert.equal(chooseProvider(saved, 'openai'), saved)
  assert.equal(chooseProvider({ url: '' }, 'openai', 'api-key').url, PROVIDERS.openai.endpoint)
})

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
  assert.equal(credentialSlot('anthropic', 'device'), 'anthropic-device')
  assert.equal(credentialSlot('anthropic', 'api-key'), 'anthropic')
  assert.deepEqual(withAuth(config, 'anthropic', 'api-key').headers, [])
})

test('xAI device login selects the subscription route without borrowing API credentials', () => {
  const device = withAuth({ headers: [{ name: 'ChatGPT-Account-ID', value: 'private' }] }, 'xai', 'device')
  assert.equal(device.url, PROVIDERS.xai.deviceEndpoint)
  assert.equal(authMethod('xai', device), 'device')
  assert.equal(catalogEndpoint('xai', device), PROVIDERS.xai.deviceModelsEndpoint)
  assert.equal(credentialSlot('xai', 'device'), 'xai-device')
  assert.equal(credentialSlot('xai', 'api-key'), 'xai')
  assert.deepEqual(device.headers, [])
  assert.equal(withAuth(device, 'xai', 'api-key').url, PROVIDERS.xai.endpoint)
  assert.equal(chooseProvider({ url: PROVIDERS.openai.endpoint }, 'xai', 'device').url, device.url)
})
