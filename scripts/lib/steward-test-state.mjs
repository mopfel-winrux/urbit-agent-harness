// Test-only native trust inspection. Never expose the decoded private state.
import assert from 'node:assert/strict'
import ob from '../../fe/node_modules/urbit-ob/src/index.js'

export async function trusts(url, cookie, ship) {
  const res = await fetch(`${url}/~/scry/steward/dbug/state.noun`, { headers: { cookie }, signal: AbortSignal.timeout(15000) })
  assert.ok(res.ok)
  const bytes = new Uint8Array(await res.arrayBuffer()), refs = new Map(); let bit = 0
  function bits(n) { let out = 0n; for (let i = 0; i < n; i++) { assert.ok(bit < bytes.length * 8); out |= BigInt((bytes[bit >> 3] >> (bit++ & 7)) & 1) << BigInt(i) } return out }
  function rub() { let k = 0; while (bits(1) === 0n) k++; if (!k) return 0n; return bits(Number((1n << BigInt(k - 1)) + bits(k - 1))) }
  function cue() { const at = bit; let value; if (bits(1) === 0n) value = rub(); else if (bits(1) === 0n) value = [cue(), cue()]; else { value = refs.get(Number(rub())); assert.notEqual(value, undefined) } refs.set(at, value); return value }
  const state = cue()[1]; assert.equal(state[0], 0n)
  const who = BigInt(ob.patp2dec(ship))
  function has(tree) { return tree !== 0n && (tree[0] === who || has(tree[1][0]) || has(tree[1][1])) }
  return has(state[1][1][0])
}
