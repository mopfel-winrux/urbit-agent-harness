import assert from 'node:assert/strict'
import { test } from 'node:test'
import { generateProjectKey, projectReadEndpoint, projectRoles, roleDescriptions } from './projectAccess.js'

test('project keys require 32 CSPRNG bytes with no insecure fallback', () => {
  let requested = 0
  const key = generateProjectKey({ getRandomValues(bytes) { requested = bytes.length; bytes.forEach((_, index) => { bytes[index] = index }); return bytes } })
  assert.equal(requested, 32)
  assert.equal(key, `hpr_${Array.from({ length: 32 }, (_, i) => i.toString(16).padStart(2, '0')).join('')}`)
  assert.throws(() => generateProjectKey({}), /Secure key generation/)
  assert.notEqual(generateProjectKey(), generateProjectKey())
})

test('client URL has no key and maintainer authority is not owner authority', () => {
  assert.equal(projectReadEndpoint('https://ship.example/apps/harness'), 'https://ship.example/harness-project/read')
  assert.deepEqual(projectRoles, ['reader', 'contributor', 'maintainer'])
  assert.match(roleDescriptions.maintainer, /Cannot change access/)
  assert.match(roleDescriptions.maintainer, /accept proposals/)
})
