import { allAvailableGrants } from '../peerGrants'

export default function GrantAllAvailable({ ship, selected, tools, mcp, skills, inflows = [], onChange }) {
  const catalogs = [tools, mcp, ...(skills ? [skills] : [])]
  const loading = catalogs.some((catalog) => catalog.loading)
  const failed = catalogs.some((catalog) => catalog.error)
  const grants = allAvailableGrants(selected, tools.value || [], mcp.value || [])
  const shared = [...new Set([...inflows, ...(skills?.value || []).map((skill) => skill.name)])]
  const complete = grants.length === selected.length && shared.length === inflows.length
  return <div className="grant-all-available">
    <button type="button" className="button ghost" aria-label={`Grant all available to ${ship}`} disabled={loading || failed || complete}
      onClick={() => onChange({ tools: grants, ...(skills ? { inflows: shared } : {}) })}>{loading ? 'Loading permissions…' : complete && !failed ? 'All available selected' : 'Grant all available'}</button>
    <span className="field-note">All eligible tools, all Clay files, enabled MCP servers{skills ? ', and saved skills' : ''}. Save to apply.</span>
    {failed && <p className="inline-error" role="alert">Permission catalog unavailable. <button type="button" className="text-button" onClick={() => { for (const catalog of catalogs) if (catalog.error) void catalog.refresh() }}>Retry loading permissions</button></p>}
  </div>
}
