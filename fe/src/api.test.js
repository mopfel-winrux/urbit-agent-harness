import assert from 'node:assert/strict'
import test from 'node:test'

import { defaultConfig, paths, scryUrl } from './api.js'

test('native Harness scries encode the typed Gall namespace', () => {
  assert.equal(scryUrl('session/research-notes'), '/~/scry/harness/session/research-notes.json')
  assert.equal(scryUrl('sessions'), '/~/scry/harness/sessions.json')
})

test('conversation paths share the Harness session surface', () => {
  assert.deepEqual(paths('notes'), {
    chat: 'notes',
    chats: 'sessions',
    session: 'session/notes',
    config: 'session/notes',
    transcript: 'session/notes',
    status: 'session/notes',
    tools: 'tools',
  })
})

test('new conversations default to an OpenAI-compatible endpoint', () => {
  const config = defaultConfig()
  assert.match(config.url, /openrouter\.ai/)
  assert.deepEqual(config.headers, [])
})
