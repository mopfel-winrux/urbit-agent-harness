import assert from 'node:assert/strict'
import test from 'node:test'

import { resourcesFor, scryUrl } from './api.js'
import { DEFAULT_SYSTEM_PROMPT, defaultConfig } from './defaults.js'

test('native Harness scries encode the typed Gall namespace', () => {
  assert.equal(scryUrl('session/research-notes'), '/~/scry/harness/session/research-notes.json')
  assert.equal(scryUrl('sessions'), '/~/scry/harness/sessions.json')
})

test('settings resource keys address the shared Harness session surface', () => {
  assert.deepEqual(resourcesFor('notes'), {
    chat: 'notes',
    session: 'session/notes',
    tools: 'tools',
    defaults: 'defaults',
    mcp: 'mcp',
  })
})

test('new conversations default to an OpenAI-compatible endpoint', () => {
  const config = defaultConfig()
  assert.match(config.url, /openrouter\.ai/)
  assert.equal(config.model, 'z-ai/glm-5.3-flash')
  assert.equal(config['max-context'], 1_310_720)
  assert.ok(config.tools.includes('mcp'))
  assert.deepEqual(config.headers, [])
})

test('the default context presents Harness as a durable, bounded agent', () => {
  const config = defaultConfig()
  assert.equal(config.system, DEFAULT_SYSTEM_PROMPT)
  assert.match(config.system, /transcript as working memory/)
  assert.match(config.system, /no ambient shell, filesystem, network, or authority/)
  assert.match(config.system, /When a task matches a skill catalog entry, read the skill/)
  assert.match(config.system, /list_mcp_tools before call_mcp_tool/)
  assert.match(config.system, /never retry blindly/)
  assert.match(config.system, /survive compaction verbatim/)
  assert.match(config.system, /Do not use shared skills to store private conversation facts/)
})
