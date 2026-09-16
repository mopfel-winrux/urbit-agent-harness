import assert from 'node:assert/strict'
import test from 'node:test'
import { emptyPeers, newPeerGrant, effectivePeers, editPeer, peerPayload, applyPeerLimits } from './peers.js'

test('new peer grants default to zero/unlimited without resource access', () => {
  assert.deepEqual(newPeerGrant('~nec'), { ship: '~nec', tools: [], budget: 0, model: null, inflows: [] })
})
test('owners take precedence over explicit and inherited resource limits', () => {
  const stored = { ...emptyPeers(), grants: [{ ...newPeerGrant('~nec'), budget: 10 }],
    limits: [{ ship: '~nec', budget: 5 }], trusted: [newPeerGrant('~nec')], owners: [newPeerGrant('~nec', ['web'])] }
  const owner = effectivePeers(stored)[0]
  assert.equal(owner.owner, true)
  assert.equal(owner.budget, 0)
  assert.deepEqual(owner.tools, ['web'])
  assert.throws(() => editPeer(stored, '~nec', { budget: 1 }), /full administrative/)
  assert.throws(() => applyPeerLimits(stored, { '~nec': { budget: 1 } }), /now an owner/)
  assert.equal(effectivePeers({ ...stored, owners: [] })[0].budget, 10)
  assert.equal(peerPayload(stored).grants[0].budget, 10)
})
test('trusted ships inherit grants without duplicating them into explicit policy', () => {
  const stored = { ...emptyPeers(), trusted: [newPeerGrant('~nec', ['web'])] }
  assert.equal(effectivePeers(stored)[0].inherited, true)
  assert.equal(effectivePeers(stored)[0].budget, 0)
  assert.deepEqual(peerPayload(stored).grants, [])
  assert.deepEqual(effectivePeers({ ...stored, trusted: [] }), [])
})
test('trusted limits retain inherited access and resetting restores unlimited', () => {
  const inherited = { ...emptyPeers(), trusted: [newPeerGrant('~nec', ['web'])] }
  const changed = editPeer(inherited, '~nec', { budget: '20000' })
  assert.equal(peerPayload(changed).limits[0].budget, 20000)
  assert.deepEqual(changed.grants, [])
  assert.equal(effectivePeers(changed)[0].overridden, false)
  assert.deepEqual(effectivePeers(changed)[0].tools, ['web'])
  assert.equal(effectivePeers({ ...changed, limits: [] })[0].budget, 0)
  assert.deepEqual(effectivePeers({ ...changed, trusted: [] }), [])
  assert.deepEqual(effectivePeers({ ...changed, trusted: [newPeerGrant('~nec', ['skills'])] })[0].tools, ['skills'])
})
test('peer limits reject blanks, fractions, negatives and unsafe numbers', () => {
  for (const budget of ['', -1, 0.5, 'abc', Number.MAX_SAFE_INTEGER + 1]) {
    assert.throws(() => peerPayload(editPeer(emptyPeers(), '~nec', { budget })), /whole token limit/)
  }
  assert.equal(peerPayload(editPeer(emptyPeers(), '~nec', { budget: '0' })).grants[0].budget, 0)
})
test('peer policy validates canonical identities and never copies credentials', () => {
  const data = { ...emptyPeers(), grants: [newPeerGrant('nec')], config: { model: ' test ', url: ' https://example.com ', headers: [], key: 'do-not-save', tools: ['code'] } }
  const out = peerPayload(data)
  assert.equal(out.grants[0].ship, '~nec')
  assert.equal(out.config.key, '')
  assert.deepEqual(out.config.tools, [])
  assert.throws(() => peerPayload({ ...data, grants: [newPeerGrant('not-a-ship')] }), /valid ship/)
  assert.throws(() => peerPayload({ ...data, grants: [newPeerGrant('nec'), newPeerGrant('~nec')] }), /valid ship/)
})
test('Tlon token edits preserve peer model, tools, skills and unrelated grants', () => {
  const grant = { ...newPeerGrant('~nec', ['web']), model: 'custom', inflows: ['reading'] }
  const stored = { ...emptyPeers(), revision: 'latest', grants: [grant, newPeerGrant('~bud')] }
  const out = applyPeerLimits(stored, { '~nec': { budget: '12345', original: grant } })
  assert.deepEqual(out.grants.find((entry) => entry.ship === '~nec'), { ...grant, budget: 12345 })
  assert.ok(out.grants.some((entry) => entry.ship === '~bud'))
  assert.equal(out.revision, 'latest')
})
test('Tlon token edits reject concurrent peer changes and use newly saved trust', () => {
  const grant = newPeerGrant('~nec')
  assert.throws(() => applyPeerLimits({ ...emptyPeers(), grants: [{ ...grant, model: 'changed' }] }, { '~nec': { budget: '100', original: grant } }), /changed/)
  const out = applyPeerLimits({ ...emptyPeers(), trusted: [newPeerGrant('~nec', ['web'])] }, { '~nec': { budget: '100', original: null } })
  assert.deepEqual(out.grants, [])
  assert.equal(out.limits[0].budget, 100)
})

test('a captured absence of a grant or limit remains a conflict baseline', () => {
  const edit = { '~nec': { budget: '100', original: null, originalLimit: null } }
  assert.throws(() => applyPeerLimits({ ...emptyPeers(), grants: [newPeerGrant('~nec')] }, edit), /changed/)
  assert.throws(() => applyPeerLimits({ ...emptyPeers(), limits: [{ ship: '~nec', budget: 500 }] }, edit), /changed/)
  const withoutTrust = applyPeerLimits(emptyPeers(), edit)
  assert.deepEqual(withoutTrust.grants, [])
  assert.deepEqual(withoutTrust.limits, [{ ship: '~nec', budget: 100 }])
  assert.deepEqual(effectivePeers(withoutTrust), [])
})
