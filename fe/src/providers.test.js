import assert from 'node:assert/strict'
import test from 'node:test'

import { PROVIDERS } from './providers.js'

test('provider presets use the intended lightweight defaults', () => {
  assert.equal(PROVIDERS.openrouter.model, 'z-ai/glm-5.3-flash')
  assert.equal(PROVIDERS.openai.model, 'gpt-5.6-luna')
  assert.equal(PROVIDERS.openai.deviceModel, 'gpt-5.6-luna')
  assert.equal(PROVIDERS.anthropic.model, 'claude-haiku-4-5')
})
