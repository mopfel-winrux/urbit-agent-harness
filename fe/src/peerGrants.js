export const peerTools = (available) => available.filter((name) => !['author', 'skill-write', 'corpus', 'admin'].includes(name))

export function allAvailableGrants(selected, available, servers) {
  // Snapshot named MCP servers; adding a server never extends this grant.
  // Broad Clay access is explicit and keeps any existing narrower grants.
  const grants = [
    ...selected,
    ...peerTools(available).filter((name) => !['clay', 'mcp', 'tlon-read', 'tlon-write', 'cron'].includes(name)),
    ...(available.includes('clay') ? [{ clay: '/' }] : []),
    ...(available.includes('mcp') ? servers.filter((server) => server.enabled).map((server) => ({ mcp: server.id })) : []),
  ]
  return [...new Map(grants.map((grant) => [JSON.stringify(grant), grant])).values()]
}
