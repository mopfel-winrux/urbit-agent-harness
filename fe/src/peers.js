import { canonicalShip } from './people.js'

export const emptyPeers = () => ({ revision: '', ship: '', config: null, grants: [], trusted: [], owners: [], limits: [], usage: [] })
export const newPeerGrant = (ship, tools = []) => ({ ship, tools, model: null, budget: 0, inflows: [] })
export function effectivePeers(settings) {
  const limits = new Map((settings.limits || []).map((limit) => [limit.ship, limit.budget]))
  const entries = new Map((settings.trusted || []).map((grant) => [grant.ship, { ...grant, budget: limits.get(grant.ship) ?? grant.budget, inherited: true, overridden: false, limited: limits.has(grant.ship) }]))
  for (const grant of settings.grants || []) entries.set(grant.ship, { ...grant, inherited: entries.has(grant.ship), overridden: true })
  for (const grant of settings.owners || []) entries.set(grant.ship, { ...grant, owner: true, inherited: true, overridden: false })
  return [...entries.values()].sort((a, b) => a.ship.localeCompare(b.ship))
}
export function editPeer(settings, ship, patch) {
  const prior = effectivePeers(settings).find((entry) => entry.ship === ship) || newPeerGrant(ship)
  if (prior.owner) throw new Error('Owners have full administrative access. Change ownership before editing peer grants.')
  const { inherited, overridden, limited, ...grant } = prior
  if (inherited && !overridden && Object.keys(patch).length === 1 && 'budget' in patch) {
    return { ...settings, limits: [...(settings.limits || []).filter((entry) => entry.ship !== ship), { ship, budget: patch.budget }] }
  }
  return { ...settings, grants: [...settings.grants.filter((entry) => entry.ship !== ship), { ...grant, ...patch }] }
}
export function peerPayload(settings) {
  const parseBudget = (ship, value) => {
    const budget = Number(value)
    if (String(value).trim() === '' || !Number.isSafeInteger(budget) || budget < 0) throw new Error(`Enter a whole token limit of 0 or more for ${ship}. 0 = unlimited.`)
    return budget
  }
  const seen = new Set()
  const grants = settings.grants.map((entry) => {
    const ship = canonicalShip(entry.ship)
    if (!ship || seen.has(ship)) throw new Error('Choose a valid ship that is not already in the list.')
    seen.add(ship)
    const budget = parseBudget(ship, entry.budget)
    return { ship, budget, model: entry.model?.trim() || null, tools: entry.tools || [], inflows: entry.inflows || [] }
  })
  const limits = (settings.limits || []).map((entry) => ({ ship: entry.ship, budget: parseBudget(entry.ship, entry.budget) }))
  return { revision: settings.revision, grants, limits, config: settings.config ? {
    ...settings.config, key: '', tools: [], model: settings.config.model.trim(), url: settings.config.url.trim(),
    headers: (settings.config.headers || []).filter((header) => header.name.trim()),
  } : null }
}

// Tlon trust and explicit peer policy have separate owners. Rebase only the
// edited limits after saving trust; never overwrite a concurrently edited grant.
export function applyPeerLimits(settings, edits) {
  let next = settings
  for (const [ship, { budget, original, originalLimit = null }] of Object.entries(edits)) {
    if ((settings.owners || []).some((entry) => entry.ship === ship)) throw new Error(`${ship} is now an owner. Reload peer limits; owners have no token cap.`)
    const current = settings.grants.find((entry) => entry.ship === ship) || null
    const limit = (settings.limits || []).find((entry) => entry.ship === ship) || null
    if (JSON.stringify(current) !== JSON.stringify(original) || JSON.stringify(limit) !== JSON.stringify(originalLimit)) throw new Error(`Peer grant for ${ship} changed. Reload peer limits before saving.`)
    next = current ? editPeer(next, ship, { budget }) : { ...next,
      limits: [...(next.limits || []).filter((entry) => entry.ship !== ship), { ship, budget }],
    }
  }
  return peerPayload(next)
}
