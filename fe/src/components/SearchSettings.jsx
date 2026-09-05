import { useState } from 'react'
import { api } from '../api'
import { useResource } from '../useResource'

export default function SearchSettings() {
  const status = useResource('status/brave', { 'has-key': false })
  const [key, setKey] = useState('')
  const [busy, setBusy] = useState(false)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState('')

  async function save(value) {
    setBusy(true); setError(''); setSaved(false)
    try {
      const applied = await api.action({ 'set-key': { provider: 'brave', key: value.trim() } })
      status.setValue(applied); setKey(''); setSaved(true)
    } catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }

  return <form className="settings-grid" onSubmit={(event) => { event.preventDefault(); void save(key) }}>
    {(error || status.error) && <div className="inline-error">{error || status.error}</div>}
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Web search</h2><p>Brave Search for conversations with the Web capability, through any client.</p></div><span className={`status ${status.value?.['has-key'] ? 'good' : ''}`}>{status.value?.['has-key'] ? 'key configured' : 'key needed'}</span></div>
      <label><span>Brave Search API key</span><input type="password" autoComplete="off" value={key} onChange={(event) => { setKey(event.target.value); setSaved(false) }} placeholder={status.value?.['has-key'] ? 'Enter a replacement key' : 'Enter your Brave Search API key'} /></label>
      <p className="field-note">Search returns up to five results with titles, links and excerpts. The bot can fetch a result to read more. Your key is never included in model context.</p>
      <p className="field-note"><a href="https://api-dashboard.search.brave.com/" target="_blank" rel="noreferrer">Get a Brave Search API key</a></p>
      {status.value?.['has-key'] && <button type="button" className="text-button danger-text" disabled={busy} onClick={() => void save('')}>Remove search key</button>}
    </section>
    <div className="save-bar"><span>{saved ? 'Saved.' : 'Shared search credential; each conversation controls its Web permission.'}</span><button className="button primary" disabled={busy || !key.trim()}>{busy ? 'Saving…' : 'Save search key'}</button></div>
  </form>
}
