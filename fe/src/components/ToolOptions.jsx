import { useState } from 'react'

const copy = {
  web: ['Web search & GET', 'Search with the configured provider and read HTTP resources using GET.'],
  curl: ['Curl / general HTTP', 'Make HTTP requests with custom methods, headers and bodies. Can write to external services and reach private addresses.'],
  skills: ['Skills', 'Read instructions from the skill library.'],
  'skill-write': ['Write shared skills', 'Create, overwrite or delete instructions used by other conversations.'],
  author: ['Skill experiments', 'Stage instructions, try read-only rehearsals, and publish to the shared library. Publishing is not protected by a review gate.'],
  subagents: ['Subagents', 'Delegate independent work to another session.'],
  peers: ['Peer agents', 'Ask explicitly permitted agents on other ships.'],
}

export const grantKey = (grant) => typeof grant === 'string' ? `family:${grant}` : 'clay' in grant ? `clay:${grant.clay}` : `mcp:${grant.mcp}`
export function toggleGrant(selected, grant) {
  const key = grantKey(grant)
  return selected.some((item) => grantKey(item) === key)
    ? selected.filter((item) => grantKey(item) !== key) : [...selected, grant]
}

export default function ToolOptions({ available = [], selected = [], servers = [], onChange }) {
  const [clayPath, setClayPath] = useState('')
  const [pathError, setPathError] = useState('')
  const enabled = new Set(selected.map(grantKey))
  const registry = new Map(servers.map((server) => [server.id, server]))
  for (const grant of selected) {
    if (typeof grant !== 'string' && 'mcp' in grant && !registry.has(grant.mcp)) registry.set(grant.mcp, { id: grant.mcp, missing: true })
  }
  const addClay = () => {
    const path = clayPath.trim().replace(/\/+$/, '')
    const parts = path.slice(1).split('/')
    if (!path.startsWith('/') || !parts[0] || parts.some((part) => !part || part === '.' || part === '..' || /\s/.test(part))) {
      setPathError('Enter a desk/path prefix, such as /harness/lib.'); return
    }
    const grant = { clay: path }
    if (!enabled.has(grantKey(grant))) onChange(grant)
    setClayPath(''); setPathError('')
  }
  return <div className="tool-options">{available.filter((name) => !['mcp', 'clay', 'tlon-read', 'tlon-write', 'cron'].includes(name)).map((name) => {
    const [title, description] = copy[name] || [name, 'Allow this capability.']
    return <label className="tool-option" key={name}>
      <input type="checkbox" checked={enabled.has(grantKey(name))} onChange={() => onChange(name)} />
      <span><strong>{title}</strong><small>{description}</small></span>
    </label>
  })}
    {selected.filter((grant) => typeof grant !== 'string' && 'clay' in grant).map((grant) => <label className="tool-option" key={grantKey(grant)}>
      <input type="checkbox" checked onChange={() => onChange(grant)} />
      <span><strong>{grant.clay === '/' ? 'All Clay files (broad access)' : `Clay: ${grant.clay}`}</strong><small>{grant.clay === '/' ? 'Preserved legacy grant. This can read every desk, including future files. Remove it and grant narrower paths.' : 'Read and list this path and its descendants, including future files under it.'}</small></span>
    </label>)}
    {available.includes('clay') && <div>
      <label><span>Clay read path</span><input value={clayPath} onChange={(event) => { setClayPath(event.target.value); setPathError('') }} placeholder="/harness/lib" /></label>
      <button type="button" className="text-button" onClick={addClay}>Grant Clay path</button>
      {pathError && <p className="inline-error">{pathError}</p>}
    </div>}
    {selected.includes('clay') && <label className="tool-option"><input type="checkbox" checked onChange={() => onChange('clay')} /><span><strong>Legacy Clay grant (inactive)</strong><small>Remove this historical grant and select a path.</small></span></label>}
    {[...registry.values()].map((server) => {
      const grant = { mcp: server.id }
      return <label className="tool-option" key={grantKey(grant)}>
        <input type="checkbox" checked={enabled.has(grantKey(grant))} onChange={() => onChange(grant)} />
        <span><strong>MCP: {server.name || server.id}</strong><small>{server.id} — {server.missing ? 'Not registered; cannot be called.' : !server.enabled ? 'Disabled; cannot be called.' : 'Allow all tools on this server.'}</small></span>
      </label>
    })}
    {selected.includes('mcp') && <label className="tool-option"><input type="checkbox" checked onChange={() => onChange('mcp')} /><span><strong>Legacy MCP grant (inactive)</strong><small>Remove this legacy grant and choose individual servers.</small></span></label>}
    {!registry.size && <p className="field-note">No MCP servers registered. Register a server in MCP settings, then grant it here.</p>}
  </div>
}
