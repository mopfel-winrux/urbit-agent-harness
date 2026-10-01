import { Select } from './Picker'
import { useEffect, useRef, useState } from 'react'
import { api } from '../api'
import { useResource } from '../useResource'
import { withAuth } from '../providerConfig'
import { RunnerSelect } from './ProviderRoute'
import './connected-runners.css'

const randomHex = bytes => Array.from(crypto.getRandomValues(new Uint8Array(bytes)), n => n.toString(16).padStart(2, '0')).join('')
const shellQuote = text => `'${text.replaceAll("'", "'\\''")}'`

export default function ConnectedRunners({ resources }) {
  const runners = useResource('runners', [], 15_000)
  const config = useResource(resources.chat ? resources.session : resources.defaults, null)
  const [form, setForm] = useState({ url: 'connected://' })
  const [label, setLabel] = useState('')
  const [pairing, setPairing] = useState(null)
  const [runtime, setRuntime] = useState('acp')
  const [busy, setBusy] = useState('')
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [confirm, setConfirm] = useState('')
  const draft = useRef(null), dirty = useRef(false)
  useEffect(() => {
    if (!dirty.current && config.value) setForm({ ...config.value, url: config.value.url?.startsWith('connected://') ? config.value.url : 'connected://' })
  }, [config.value])

  async function create(event) {
    event.preventDefault(); setBusy('create'); setError(''); setMessage('')
    try {
      if (!draft.current || draft.current.label !== label.trim()) draft.current = { id: `runner-${randomHex(8)}`, label: label.trim(), key: `hrr_${randomHex(32)}` }
      await api.runners('create', draft.current)
      setPairing(draft.current); draft.current = null; setLabel('')
      await runners.refresh()
    } catch (cause) { setError(cause.message) } finally { setBusy('') }
  }

  async function save(event) {
    event.preventDefault(); setBusy('save'); setError(''); setMessage('')
    try {
      const selected = form.url.slice(12)
      if (!runners.value?.some(row => row.id === selected && row.status !== 'revoked')) throw new Error('Choose an available runner before saving.')
      const next = withAuth({ ...config.value, url: form.url }, 'connected')
      const applied = await api.action(resources.chat ? { config: { sid: resources.chat, config: next } } : { defaults: next })
      config.setValue(applied); dirty.current = false
      setMessage(resources.chat ? 'Connected agent selected for the next turn.' : 'Connected agent selected for new conversations.')
    } catch (cause) { setError(cause.message) } finally { setBusy('') }
  }

  async function revoke(row) {
    setBusy(row.id); setError(''); setMessage('')
    try {
      await api.runners('revoke', { id: row.id })
      setConfirm(''); setMessage(`Access revoked for ${row.label}. Local effects already started cannot be undone.`)
      if (pairing?.id === row.id) setPairing(null)
      await runners.refresh()
    } catch (cause) { setError(cause.message) } finally { setBusy('') }
  }

  function download() {
    const url = URL.createObjectURL(new Blob([`${pairing.key}\n`], { type: 'text/plain' }))
    const link = document.createElement('a')
    link.href = url; link.download = `harness-${pairing.id}.key`; link.click()
    setTimeout(() => URL.revokeObjectURL(url), 1000)
  }

  const filename = pairing ? `harness-${pairing.id}.key` : ''
  const command = pairing ? `chmod 600 ${filename}\nnode acp/connected-runner.mjs \\\n  --ship ${shellQuote(window.location.origin)} \\\n  --runner ${pairing.id} \\\n  --key-file /absolute/path/${filename} \\\n  --repo /absolute/path/to/repo \\\n  --state /private/path/${pairing.id}.json \\\n  --agent ${runtime} \\\n  --harness-tool current_time` : ''

  return <div className="settings-grid">
    {(error || runners.error || config.error) && <div className="inline-error" role="alert">{error || runners.error || config.error}</div>}
    <form className="panel settings-panel" onSubmit={save}>
      <div className="section-title"><div><h2>Connected agent</h2><p>Use Claude Code, Codex, or an ACP agent on your computer. The computer connects out to your ship.</p></div></div>
      <RunnerSelect value={form} onChange={(next) => { dirty.current = true; setForm(next); setMessage('') }} />
      <p className="field-note">{resources.chat ? 'Saving changes this conversation’s provider.' : 'Saving applies to new conversations. Existing conversations keep their provider.'}</p>
      <button className="button primary" disabled={!!busy || config.loading || !config.value || form.url === 'connected://'}>Use connected agent</button>
    </form>
    {message && <p role="status">{message}</p>}
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Agent connections</h2><p>Pair Claude Code and Codex separately, even on the same computer. Each connection has its own key and can serve different conversations.</p></div><button type="button" className="button" disabled={!!busy} onClick={() => runners.refresh()}>Refresh status</button></div>
      {runners.loading ? <p role="status">Loading runners…</p> : !runners.value?.length ? <p>No agents connected. Add a connection below to get started.</p> : <ul className="runner-list">
        {runners.value.map(row => <li key={row.id}>
          <div className="runner-row"><strong>{row.label}</strong><span className={`status ${row.status === 'online' ? 'good' : ''}`}>{row.status}</span>{row.status !== 'revoked' && <button type="button" className="button ghost" disabled={!!busy} onClick={() => setConfirm(row.id)} aria-label={`Revoke ${row.label}`}>Revoke</button>}</div>
          {confirm === row.id && <div className="runner-confirm"><p>Disconnect {row.label} and stop accepting its replies? This cannot undo local work already started.</p><div className="runner-actions"><button type="button" className="button" disabled={!!busy} onClick={() => revoke(row)}>Revoke access</button><button type="button" className="button ghost" disabled={!!busy} onClick={() => setConfirm('')}>Keep access</button></div></div>}
        </li>)}
      </ul>}
    </section>
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>{pairing ? 'Start your runner' : 'Add an agent connection'}</h2><p>No ship login code, browser cookie, or inbound port is needed.</p></div></div>
      {pairing ? <div className="settings-grid">
        <p role="status">{pairing.label} is paired. Download its key now; it cannot be retrieved after you leave this page.</p>
        <button type="button" className="button" onClick={download}>Download runner key</button>
        <Select label="Local agent" value={runtime} onValueChange={nextValue => setRuntime(nextValue)}><Select.Option value="acp">Claude Code / ACP</Select.Option><Select.Option value="codex">Codex</Select.Option></Select>
        <p>Use the ACP runner script. Replace the paths and run:</p>
        <pre className="runner-command"><code>{command}</code></pre>
        <p className="field-note">Sign in locally first. Claude Code needs <code>claude-agent-acp</code>; Codex uses <code>codex app-server</code>. For another ACP agent, append <code>-- your-agent-command</code>.</p>
        <p className="field-note">This command allows only the ship’s clock tool. Add explicit <code>--harness-tool</code> grants as needed. Local permission requests are denied by default; Codex starts read-only.</p>
        <button type="button" className="button ghost" onClick={() => setPairing(null)}>Done with setup</button>
      </div> : <form onSubmit={create} className="settings-grid">
        <label><span>Connection name</span><input required maxLength={128} value={label} onChange={event => setLabel(event.target.value)} placeholder="Claude Code · laptop" /></label>
        <button className="button" disabled={!!busy || !label.trim()}>{busy === 'create' ? 'Pairing…' : 'Create runner key'}</button>
      </form>}
    </section>
  </div>
}
