import { useState } from 'react'
import { api } from '../api'

export default function TlonLens({ resource }) {
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const lens = resource.value?.lens
  async function retry() {
    setBusy(true); setError('')
    try { resource.setValue(await api.action({ tlonLensRetry: true })) }
    catch (cause) { setError(cause.message) }
    finally { setBusy(false) }
  }
  return <section className="panel settings-panel tlon-lens">
    <div className="section-title"><div><h2>Steward Lens</h2><p>Run summaries attach to Tlon replies automatically. Private prompts, tool arguments, and result contents stay in Harness.</p></div></div>
    <p className="field-note">{lens?.owner ? `Owner-side storage: ${lens.owner}. ${lens.accepted} exports acknowledged, ${lens.pending} pending.` : 'Summaries use the configured Tlon owner’s native Steward storage.'}</p>
    {lens?.failed > 0 && <p role="status">{lens.failed} Lens exports were rejected or could not be sent. Check that the owner’s Steward trusts this bot. A self-owned bot needs a separate native storage path; Harness does not change Steward’s gateway configuration.</p>}
    <p className="field-note">Export failures do not block chat. Retrying exports only updates summaries—it never reruns tools or resends replies.</p>
    {error && <p role="alert" className="inline-error">{error}</p>}
    {lens?.failed > 0 && <button type="button" className="button" disabled={busy} onClick={retry}>{busy ? 'Retrying exports…' : 'Retry Lens exports'}</button>}
  </section>
}
