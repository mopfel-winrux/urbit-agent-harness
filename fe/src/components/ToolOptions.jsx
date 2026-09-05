const copy = {
  clay: ['Desk files', 'Read and list files in Clay.'],
  web: ['Web search & requests', 'Search with the configured provider and fetch HTTP resources.'],
  skills: ['Skills', 'Read instructions from the skill library.'],
  'skill-write': ['Write shared skills', 'Create, overwrite or delete instructions used by other conversations.'],
  author: ['Skill experiments', 'Stage instructions, try read-only rehearsals, and publish to the shared library. Publishing is not protected by a review gate.'],
  subagents: ['Subagents', 'Delegate independent work to another session.'],
  peers: ['Peer agents', 'Ask explicitly permitted agents on other ships.'],
}

export const grantKey = (grant) => typeof grant === 'string' ? `family:${grant}` : `mcp:${grant.mcp}`
export function toggleGrant(selected, grant) {
  const key = grantKey(grant)
  return selected.some((item) => grantKey(item) === key)
    ? selected.filter((item) => grantKey(item) !== key) : [...selected, grant]
}

export default function ToolOptions({ available = [], selected = [], servers = [], onChange }) {
  const enabled = new Set(selected.map(grantKey))
  const registry = new Map(servers.map((server) => [server.id, server]))
  for (const grant of selected) {
    if (typeof grant !== 'string' && !registry.has(grant.mcp)) registry.set(grant.mcp, { id: grant.mcp, missing: true })
  }
  return <div className="tool-options">{available.filter((name) => name !== 'mcp').map((name) => {
    const [title, description] = copy[name] || [name, 'Allow this capability.']
    return <label className="tool-option" key={name}>
      <input type="checkbox" checked={enabled.has(grantKey(name))} onChange={() => onChange(name)} />
      <span><strong>{title}</strong><small>{description}</small></span>
    </label>
  })}
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
