import assert from 'node:assert/strict'
import test from 'node:test'

import { normalizeCatalog } from './useProviderModels.js'

test('model catalogs preserve ids and index reported context windows', () => {
  assert.deepEqual(normalizeCatalog({
    models: ['plain-model', 'openrouter/model'],
    modelInfo: [
      { id: 'openrouter/model', contextWindow: 131_072 },
      { id: 'anthropic/model', contextWindow: 200_000 },
      { id: 'unknown/model', contextWindow: null },
    ],
  }), {
    models: ['anthropic/model', 'openrouter/model', 'plain-model', 'unknown/model'],
    contexts: { 'openrouter/model': 131_072, 'anthropic/model': 200_000 },
  })
})
