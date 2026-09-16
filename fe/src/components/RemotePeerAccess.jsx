import { useState } from 'react'
import { api } from '../api'
import { useResource } from '../useResource'
import ShipPicker from './ShipPicker'

export default function RemotePeerAccess() {
  const remote = useResource('peers/remote', { ships: [] }, 5000)
  const contacts = useResource('tlon/contacts', [], 30_000)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [requested, setRequested] = useState('')
  async function check(ship) {
    setBusy(true); setError(''); setRequested('')
    try { await api.action({ peerCheck: ship }); setRequested(ship); await remote.refresh() }
    catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }
  return <section className="panel settings-panel">
    <div className="section-title"><div><h2>Access on other ships</h2><p>Permissions reported by remote ships for this agent. This is not a complete directory, and reports can become stale. Each ship checks live access when called.</p></div></div>
    {(error || remote.error) && <div className="inline-error" role="alert">{error || remote.error}<button type="button" className="text-button" onClick={() => { setError(''); void remote.refresh() }}>Reload remote access</button></div>}
    <fieldset disabled={busy} className="memory-model-fields"><ShipPicker label="Check access on a ship" contacts={contacts.value || []} onChange={check} /></fieldset>
    <p className="field-note" role="status">{busy ? 'Requesting a permission report…' : requested ? `Report requested from ${requested}. No response means unknown, not denied; older peers may not support discovery.` : 'The agent can also use list_peer_access and check_peer.'}</p>
    {remote.loading && <p role="status">Loading known permissions…</p>}
    {!remote.loading && !remote.value?.ships?.length && <p>No remote permission reports yet. Check a ship above.</p>}
    {remote.value?.ships?.map((entry) => <details className="trusted-ship" key={entry.ship}>
      <summary>{entry.ship}<small>{entry.allowed ? 'Access reported' : 'No access reported'}</small></summary>
      <div className="peer-grant-fields"><p className="field-note">Last report: <code>{entry.checkedAt}</code></p>
        {entry.allowed && <p>{entry.grant?.tools?.length || 0} resource grants · {entry.grant?.budget ? `${Number(entry.grant.budget).toLocaleString()} token cap` : 'No token cap'}. Supports agent requests and direct granted-tool calls.</p>}
        <button type="button" className="text-button" disabled={busy} onClick={() => check(entry.ship)}>Refresh {entry.ship}</button>
      </div>
    </details>)}
  </section>
}
