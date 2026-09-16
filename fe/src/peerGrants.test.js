import assert from 'node:assert/strict'
import test from 'node:test'
import { allAvailableGrants, peerTools } from './peerGrants.js'

test('grant all selects eligible tools and explicit resource grants without granting ownership', () => {
  const available = ['web', 'curl', 'clay', 'mcp', 'skills', 'code', 'workspace', 'admin', 'author', 'skill-write', 'corpus', 'cron', 'tlon-read']
  const servers = [{ id: 'local', enabled: true }, { id: 'disabled', enabled: false }]
  const selected = ['web', { clay: '/notes' }, { mcp: 'missing' }]
  const result = allAvailableGrants(selected, available, servers)
  assert.deepEqual(result, ['web', { clay: '/notes' }, { mcp: 'missing' }, 'curl', 'skills', 'code', 'workspace', { clay: '/' }, { mcp: 'local' }])
  assert.deepEqual(allAvailableGrants(result, available, servers), result)
  assert.deepEqual(selected, ['web', { clay: '/notes' }, { mcp: 'missing' }])
  servers.push({ id: 'future', enabled: true })
  assert.ok(!result.some((grant) => grant.mcp === 'future'))
  assert.deepEqual(peerTools(['web', 'corpus', 'admin', 'author', 'skill-write']), ['web'])
})

test('grant all does not invent unavailable resource families', () => {
  assert.deepEqual(allAvailableGrants([], ['web'], [{ id: 'local', enabled: true }]), ['web'])
  assert.deepEqual(allAvailableGrants([{ clay: '/notes' }], [], []), [{ clay: '/notes' }])
})
