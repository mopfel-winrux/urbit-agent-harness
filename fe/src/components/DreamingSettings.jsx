import { useState } from 'react'
import { api } from '../api'
import { useResource } from '../useResource'

export default function DreamingSettings({ model }) {
  const dreaming = useResource('memory/dreaming', null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')
  const unavailable = dreaming.loading || !!dreaming.error || !dreaming.value
  async function change(enabled) {
    setBusy(true); setError(''); setNotice('')
    try {
      const applied = await api.action({ dreaming: { enabled } })
      dreaming.setValue(applied)
      setNotice(applied.enabled ? 'Dreaming enabled. The first review runs in about a day.' : 'Dreaming is off.')
    } catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }
  const lastRun = dreaming.value?.lastRun
  return <section className="memory-dreaming" aria-label="Dreaming settings" aria-busy={busy || dreaming.loading}>
    <label className="tool-option">
      <input type="checkbox" aria-label="Scheduled dreaming" aria-describedby="dreaming-help" checked={dreaming.value?.enabled === true} disabled={busy || unavailable} onChange={(event) => change(event.target.checked)} />
      <span><strong>Scheduled dreaming</strong><small>Once a day, review fresh evidence from up to eight conversations for durable facts. Uses additional model tokens.</small></span>
    </label>
    <p id="dreaming-help" className="field-note">Applies across conversations, except those with <code>/memory off</code>. Turning dreaming off leaves recall, manual saves and capture during compaction available.</p>
    <p className="field-note">Dreaming uses the LCM model{model ? <>: <strong>{model}</strong></> : ''}.</p>
    <div className="memory-dreaming-result" role="status">
      {dreaming.loading ? 'Loading dreaming settings…' : busy ? 'Saving…' : notice}
      {!unavailable && <p>{dreaming.value.running ? 'Reviewing evidence…' : lastRun ? `${dreaming.value.status || 'Review complete.'} ${Number(dreaming.value.changes).toLocaleString()} ${Number(dreaming.value.changes) === 1 ? 'memory change' : 'memory changes'}.` : 'No dreaming runs yet.'}{lastRun ? <> Last run: <time dateTime={new Date(lastRun).toISOString()}>{new Date(lastRun).toLocaleString()}</time>.</> : ''}</p>}
    </div>
    {(error || dreaming.error) && <div className="inline-error" role="alert">{error || dreaming.error}{dreaming.error && <button type="button" className="text-button" onClick={() => { setError(''); dreaming.refresh() }}>Retry loading dreaming</button>}</div>}
  </section>
}
