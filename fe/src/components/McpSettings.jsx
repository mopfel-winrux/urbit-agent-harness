import { useEffect, useRef, useState } from 'react'
import { api } from '../api'
import { useGrub } from '../useGrub'
import HeaderEditor from './HeaderEditor'

const blankServer = () => ({ id: '', name: '', url: '', headers: [], enabled: true })

export default function McpSettings({ roads }) {
  const stored = useGrub(roads.mcp, [])
  const [servers, setServers] = useState([])
  const [busy, setBusy] = useState(false)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState('')
  const dirty = useRef(false)

  useEffect(() => {
    if (!dirty.current && Array.isArray(stored.value)) setServers(stored.value)
  }, [stored.value])

  const update = (index, patch) => {
    dirty.current = true; setSaved(false)
    setServers((current) => current.map((server, at) => at === index ? { ...server, ...patch } : server))
  }
  const add = () => { dirty.current = true; setServers((current) => [...current, blankServer()]) }
  const remove = (index) => { dirty.current = true; setServers((current) => current.filter((_, at) => at !== index)) }

  async function save(event) {
    event.preventDefault()
    const clean = servers.map((server) => ({
      ...server,
      id: server.id.trim(), name: server.name.trim() || server.id.trim(), url: server.url.trim(),
      headers: (server.headers || []).filter((header) => header.name.trim()).map((header) => ({ name: header.name.trim(), value: header.value })),
      enabled: Boolean(server.enabled),
    }))
    if (clean.some((server) => !server.id || !server.url)) return setError('Every server needs an id and URL.')
    if (new Set(clean.map((server) => server.id)).size !== clean.length) return setError('Server ids must be unique.')
    setBusy(true); setError('')
    try {
      const applied = await api.action({ mcp: clean })
      stored.setValue(applied); setServers(applied); dirty.current = false; setSaved(true)
    } catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }

  return <form className="settings-grid" onSubmit={save}>
    {(error || stored.error) && <div className="inline-error">{error || stored.error}</div>}
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>MCP servers</h2><p>Remote stateless Streamable HTTP endpoints available to conversations granted the MCP capability.</p></div><button type="button" className="text-button" onClick={add}>Add server</button></div>
      {!servers.length && <div className="empty-setting"><strong>No MCP servers configured</strong><span>Add an endpoint to make its tools discoverable from any permitted conversation.</span></div>}
      <div className="mcp-servers">{servers.map((server, index) => <section className="mcp-server" key={`${server.id}-${index}`}>
        <div className="mcp-server-title">
          <label className="compact-check"><input type="checkbox" checked={server.enabled} onChange={(event) => update(index, { enabled: event.target.checked })} /><span>Enabled</span></label>
          <button type="button" className="text-button danger-text" onClick={() => remove(index)}>Remove</button>
        </div>
        <div className="two-fields equal">
          <label><span>Server id</span><input required value={server.id} onChange={(event) => update(index, { id: event.target.value })} placeholder="search" /></label>
          <label><span>Display name</span><input value={server.name} onChange={(event) => update(index, { name: event.target.value })} placeholder="Search tools" /></label>
        </div>
        <label><span>Streamable HTTP URL</span><input type="url" required value={server.url} onChange={(event) => update(index, { url: event.target.value })} placeholder="https://mcp.example.com/mcp" /></label>
        <HeaderEditor value={server.headers || []} onChange={(headers) => update(index, { headers })} note="Add bearer tokens or server-specific authorization. Headers are only sent to this endpoint." />
      </section>)}</div>
    </section>
    <div className="save-bar"><span>{saved ? 'Saved.' : 'MCP configuration is shared across conversations; each conversation still controls its MCP grant.'}</span><button className="button primary" disabled={busy}>{busy ? 'Saving…' : 'Save MCP servers'}</button></div>
  </form>
}
