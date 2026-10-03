import { useState } from 'react'
import { api } from '../api'

export default function TlonLens({ state, unavailable, onUpdate }) {
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const owner = state?.policy?.owner
  const lens = state?.lens
  async function change(action) {
    setBusy(true); setError('')
    try { onUpdate(await api.action(action)) } catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }
  return <section className="panel settings-panel" aria-labelledby="tlon-lens-title">
    <div className="section-title"><div><h2 id="tlon-lens-title">Context Lens</h2><p>Inspect runs in a conversation’s Context Lens. Optionally sync new Tlon runs to your owner ship.</p></div></div>
    <p className="field-help">Owner sync sends bounded context, tool arguments, results, and replies privately to {owner || 'your configured owner'}. Posts carry only a run ID. It also configures this ship’s Steward owner for run retries.</p>
    {owner ? <p className="field-help">On {owner}, trust this bot in Steward before enabling sync{state?.ship ? <>: <code>:steward &amp;steward-action-1 [%trust-bot {state.ship}]</code></> : '.'}</p> : <p className="field-help">Set an explicit owner in Settings before enabling sync.</p>}
    <p className="field-help">Disabling sync does not delete records already stored on the owner ship. Changing owners disables sync. The retry cache holds the latest 64 runs.</p>
    {(error || lens?.error) && <p className="inline-error" role="alert">{error || lens.error}</p>}
    <div className="section-actions">
      <button type="button" className="button ghost" disabled={busy || unavailable || (!owner && !lens?.enabled)} onClick={() => change({ tlonLens: { enabled: !lens?.enabled, expectedOwner: owner } })}>{busy ? 'Saving…' : lens?.enabled ? 'Disable owner sync' : 'Enable owner sync'}</button>
      {lens?.enabled && <button type="button" className="text-button" disabled={busy || unavailable} onClick={() => change({ retryLens: true })}>Retry sync</button>}
    </div>
    <p className="field-help" role="status">{lens?.enabled ? `${lens.pending || 0} run records awaiting sync. Tlon replies must be enabled for live updates.` : 'Owner sync is off. Local run inspection stays available.'}</p>
  </section>
}
