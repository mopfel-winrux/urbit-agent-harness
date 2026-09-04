import assert from 'node:assert/strict'
import test from 'node:test'

import { ballUrl, fileUrl, keepUrl, paths } from './api.js'

test('Grubbery URLs preserve ball hierarchy and encode names', () => {
  assert.equal(
    fileUrl('apps/harness.harness/agents/main/chats/research notes/chat.json'),
    '/grubbery/api/file/apps/harness.harness/agents/main/chats/research%20notes/chat.json?blot=%2Fjson',
  )
  assert.equal(
    keepUrl('apps/harness.harness/agents/main/about.txt', 'txt'),
    '/grubbery/api/keep/apps/harness.harness/agents/main/about.txt?blot=%2Ftxt',
  )
  assert.equal(ballUrl('apps/harness.harness'), '/grubbery/ball/apps/harness.harness')
})

test('agent roads share one durable namespace', () => {
  assert.deepEqual(paths('apps/harness.harness', 'main', 'notes'), {
    agentRoot: 'apps/harness.harness/agents/main',
    chatRoot: 'apps/harness.harness/agents/main/chats/notes',
    chats: 'apps/harness.harness/agents/main/ui/chats.json',
    agentMain: 'apps/harness.harness/agents/main/main.sig',
    config: 'apps/harness.harness/agents/main/config.json',
    about: 'apps/harness.harness/agents/main/about.txt',
    anthropic: 'apps/harness.harness/apis/anthropic',
    transcript: 'apps/harness.harness/agents/main/chats/notes/chat.json',
    status: 'apps/harness.harness/agents/main/chats/notes/status.json',
  })
})
