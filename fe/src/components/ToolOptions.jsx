const copy = {
  'ship-time': ['Ship time', 'Read the ship’s current time.'],
  clay: ['Desk files', 'Read and list files in Clay.'],
  web: ['Web requests', 'Fetch public HTTP resources.'],
  skills: ['Skills', 'Read instructions from the skill library.'],
  'skill-write': ['Write skills', 'Stage and update reusable instructions.'],
  author: ['Authoring', 'Create and revise ship-side resources.'],
  subagents: ['Subagents', 'Delegate independent work to another session.'],
  peers: ['Peer agents', 'Ask explicitly permitted agents on other ships.'],
  mcp: ['MCP servers', 'Discover and call tools on configured MCP servers.'],
}

export default function ToolOptions({ available = [], selected = [], onChange }) {
  const enabled = new Set(selected)
  return <div className="tool-options">{available.map((name) => {
    const [title, description] = copy[name] || [name, 'Allow this capability.']
    return <label className="tool-option" key={name}>
      <input type="checkbox" checked={enabled.has(name)} onChange={() => onChange(name, !enabled.has(name))} />
      <span><strong>{title}</strong><small>{description}</small></span>
    </label>
  })}</div>
}
