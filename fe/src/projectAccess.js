export const projectRoles = ['reader', 'contributor', 'maintainer']
export const roleDescriptions = {
  reader: 'Read project documents, accepted history, proposals, and tasks.',
  contributor: 'Also propose document changes and create, claim, and update its own tasks.',
  maintainer: 'Also edit project details and update or release any project task claim. Cannot change access, archive the project, accept proposals, or publish through Workspace.',
}
export const clientStatusLabels = {
  active: 'Active · read-only', suspended: 'Suspended · project archived',
  expired: 'Expired', revoked: 'Revoked',
}

// Generate only on explicit owner confirmation. Never use Math.random,
// persist a key in browser storage, or put one in a URL or clipboard silently.
export function generateProjectKey(crypto = globalThis.crypto) {
  if (!crypto?.getRandomValues) throw new Error('Secure key generation is unavailable. Open Harness over HTTPS or localhost.')
  const bytes = crypto.getRandomValues(new Uint8Array(32))
  return `hpr_${Array.from(bytes, (byte) => byte.toString(16).padStart(2, '0')).join('')}`
}

export function projectReadEndpoint(origin) {
  return new URL('/harness-project/read', origin).href
}
