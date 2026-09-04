import assert from 'node:assert/strict'
import test from 'node:test'

import { webConnection } from './acp.js'

test('each browser instance gets a fresh valid ACP connection', () => {
  const first = webConnection()
  const second = webConnection()
  assert.notEqual(first, second)
  assert.match(first, /^harness-web-[a-z0-9-]+$/)
  assert.ok(first.length <= 128)
})
