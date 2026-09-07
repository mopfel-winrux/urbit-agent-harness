import { useEffect, useRef, useState } from 'react'
import { api } from '../api'
import { useResource } from '../useResource'

export default function SearchSettings() {
  const status = useResource('status/brave', { 'has-key': false })
  const stored = useResource('search', { provider: 'brave', 'instance-url': '' })
  const [config, setConfig] = useState({ provider: 'brave', 'instance-url': '' })
  const dirty = useRef(false)
  const [key, setKey] = useState('')
  const [busy, setBusy] = useState(false)
  const [saved, setSaved] = useState(false)
  const [credentialSaved, setCredentialSaved] = useState('')
  const [error, setError] = useState('')
  useEffect(() => { if (stored.value && !dirty.current) setConfig(stored.value) }, [stored.value])
  const field = (name, value) => { dirty.current = true; setSaved(false); setConfig((old) => ({ ...old, [name]: value })) }
  async function saveProvider(event) {
    event.preventDefault()
    const clean = { ...config, 'instance-url': config['instance-url'].trim().replace(/\/+$/, '') }
    if (clean.provider === 'searxng' || clean['instance-url']) {
      try {
        const url = new URL(clean['instance-url'])
        if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password || url.search || url.hash) throw new Error()
      } catch { setError('Enter an HTTP(S) instance URL without query, fragment or credentials.'); return }
    }
    setBusy(true); setError(''); setSaved(false)
    try {
      const applied = await api.action({ search: clean })
      stored.setValue(applied); setConfig(applied); dirty.current = false; setSaved(true)
    } catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }

  async function save(value) {
    setBusy(true); setError(''); setCredentialSaved('')
    try {
      const applied = await api.action({ 'set-key': { provider: 'brave', key: value.trim() } })
      status.setValue(applied); setKey(''); setCredentialSaved(value.trim() ? 'Search key saved.' : 'Search key removed.')
    } catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }

  return <form className="settings-grid" onSubmit={saveProvider}>
    {(error || status.error || stored.error) && <div className="inline-error" role="alert">{error || status.error || stored.error}</div>}
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Web search provider</h2><p>Shared by conversations with the Web capability, through any client.</p></div></div>
      <label><span>Search provider</span><select value={config.provider} onChange={(event) => field('provider', event.target.value)}><option value="brave">Brave Search</option><option value="searxng">SearXNG</option></select></label>
      {config.provider === 'searxng' && <>
        <label><span>SearXNG instance URL</span><input type="url" required value={config['instance-url']} onChange={(event) => field('instance-url', event.target.value)} placeholder="https://search.example.org" /></label>
        <p className="field-note">Use the instance base URL, including any hosting path prefix. The harness appends /search. The instance must allow JSON output in search.formats; many public instances do not. <a href="https://docs.searxng.org/dev/search_api.html" target="_blank" rel="noreferrer">SearXNG API setup</a></p>
      </>}
      <p className="field-note">Search returns up to five results with titles, links and excerpts. Switching providers preserves the Brave key.</p>
    </section>
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Brave Search credential</h2><p>Used only when Brave is selected.</p></div><span className={`status ${status.value?.['has-key'] ? 'good' : ''}`}>{status.value?.['has-key'] ? 'key configured' : 'key needed'}</span></div>
      <label><span>Brave Search API key</span><input type="password" autoComplete="off" value={key} onChange={(event) => { setKey(event.target.value); setCredentialSaved('') }} placeholder={status.value?.['has-key'] ? 'Enter a replacement key' : 'Enter your Brave Search API key'} /></label>
      <p className="field-note">Search returns up to five results with titles, links and excerpts. The bot can fetch a result to read more. Your key is never included in model context.</p>
      <p className="field-note"><a href="https://api-dashboard.search.brave.com/" target="_blank" rel="noreferrer">Get a Brave Search API key</a></p>
      <div className="settings-actions">
        <button type="button" className="button" disabled={busy || !key.trim()} onClick={() => void save(key)}>Save search key</button>
        {status.value?.['has-key'] && <button type="button" className="text-button danger-text" disabled={busy} onClick={() => void save('')}>Remove search key</button>}
      </div>
      <p className="field-note" role="status">{credentialSaved}</p>
    </section>
    <div className="save-bar"><span role="status">{saved ? 'Search provider saved.' : dirty.current ? 'Unsaved search provider changes.' : 'Each conversation controls its Web permission.'}</span><button className="button primary" disabled={busy || stored.loading}>{busy ? 'Saving…' : 'Save search provider'}</button></div>
  </form>
}
