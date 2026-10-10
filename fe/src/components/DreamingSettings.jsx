import { useState } from 'react'
import { api } from '../api'
import { useResource } from '../useResource'

export default function DreamingSettings() {
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
      setNotice('Saved.')
    } catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }
  const lastRun = dreaming.value?.lastRun
  return <section className="memory-dreaming" aria-label="Dreaming settings" aria-busy={busy || dreaming.loading}>
    <label className="tool-option">
      <input type="checkbox" aria-label="Scheduled dreaming" aria-describedby="dreaming-help" checked={dreaming.value?.enabled === true} disabled={busy || unavailable} onChange={(event) => change(event.target.checked)} />
      <span><strong>Scheduled dreaming</strong><small id="dreaming-help">Reviews new activity daily. Uses model tokens.</small></span>
    </label>
    <div className="memory-dreaming-result" role="status">
      {dreaming.loading ? 'Loading dreaming settings…' : busy ? 'Saving…' : notice}
      {!unavailable && (dreaming.value.running || lastRun) && <p>{dreaming.value.running ? 'Reviewing evidence…' : `${dreaming.value.status || 'Review complete.'} ${Number(dreaming.value.changes).toLocaleString()} ${Number(dreaming.value.changes) === 1 ? 'memory change' : 'memory changes'}.`}{lastRun ? <> Last run: <time dateTime={new Date(lastRun).toISOString()}>{new Date(lastRun).toLocaleString()}</time>.</> : ''}</p>}
    </div>
    {(error || dreaming.error) && <div className="inline-error" role="alert">{error || dreaming.error}{dreaming.error && <button type="button" className="text-button" onClick={() => { setError(''); dreaming.refresh() }}>Retry loading dreaming</button>}</div>}
  </section>
}
