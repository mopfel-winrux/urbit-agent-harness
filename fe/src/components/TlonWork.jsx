import { useState } from 'react'
import { api } from '../api'
import { useResource } from '../useResource'

const labels = { received: 'Received', working: 'Working', completed: 'Completed · waiting to send', sending: 'Sending', uncertain: 'Send uncertain', delivered: 'Delivered', 'send-failed': 'Send failed', failed: 'Work failed', cancelled: 'Cancelled', abandoned: 'Abandoned' }

function Recovery({ record, mode, onClose, onSaved }) {
  const [outcome, setOutcome] = useState('abandoned')
  const [reason, setReason] = useState('')
  const [external, setExternal] = useState(record.externalId || '')
  const [checked, setChecked] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  async function submit(event) {
    event.preventDefault()
    if (busy || !checked || (mode === 'resolve' && !reason.trim())) return
    setBusy(true); setError('')
    try {
      await api.action({ hand: mode === 'retry'
        ? { retry: { hand: 'tlon', effect: record.id } }
        : { resolve: { hand: 'tlon', effect: record.id, attempt: record.attempt, status: outcome, external, reason: reason.trim() } } })
      await onSaved(); onClose()
    } catch (cause) { setError(cause.message) }
    finally { setBusy(false) }
  }
  return <form aria-label="Delivery recovery" onSubmit={submit}>
    <p className="field-note">Check the native conversation before changing its delivery record. A timeout is not proof that a message was not sent. Recovery never reruns the model.</p>
    {mode === 'resolve' ? <>
      <label><span>Recorded outcome</span><select value={outcome} disabled={busy} onChange={(event) => setOutcome(event.target.value)}>
        <option value="abandoned">Abandon without resending</option>
        <option value="delivered">Confirmed delivered</option>
        <option value="failed">Confirmed not delivered</option>
        <option value="uncertain">Still uncertain</option>
      </select></label>
      <label><span>Evidence or reason</span><textarea required maxLength={1024} disabled={busy} value={reason} onChange={(event) => setReason(event.target.value)} /></label>
      <label><span>Native message reference (optional)</span><input maxLength={2048} disabled={busy} value={external} onChange={(event) => setExternal(event.target.value)} /></label>
      <p className="field-note">This records your decision and fences the previous worker attempt. Marking a send failed does not resend it. Abandonment is terminal; history and receipts remain.</p>
    </> : <p className="field-note">Retry publishes the same recorded result, not a new model answer. Do this only when the previous attempt is known not to have been delivered.</p>}
    <label className="tool-option"><input type="checkbox" checked={checked} disabled={busy} onChange={(event) => setChecked(event.target.checked)} /><span>I checked the delivery evidence and understand this action.</span></label>
    {error && <p className="inline-error" role="alert">{error}</p>}
    <div className="form-actions"><button type="button" className="button ghost" disabled={busy} onClick={onClose}>Cancel recovery</button><button className="button primary" disabled={busy || !checked || (mode === 'resolve' && !reason.trim())}>{busy ? 'Saving…' : mode === 'retry' ? 'Retry recorded send' : 'Record outcome'}</button></div>
  </form>
}

function WorkList() {
  const [cursors, setCursors] = useState([''])
  const before = cursors.at(-1)
  const work = useResource(before ? `tlon/work/${before}` : 'tlon/work', null, 5000)
  const [recovery, setRecovery] = useState(null)
  const [busy, setBusy] = useState(null)
  const [error, setError] = useState('')
  const refresh = async () => { work.setValue(work.value); await work.refresh() }
  async function retryAdmission(id) {
    setBusy(id); setError('')
    try { await api.action({ retryAdmission: id }); await refresh() }
    catch (cause) { setError(cause.message) }
    finally { setBusy(null) }
  }
  return <>
    <p className="field-note">Received and completed work are not delivery receipts. Uncertain sends require evidence, not another automatic attempt. This owner-only view includes retired bindings.</p>
    {(error || work.error) && <p className="inline-error" role="alert">{error || work.error}</p>}
    <button type="button" className="text-button" onClick={refresh}>Refresh work</button>
    {work.value?.headConnected === false && <p className="field-note">The head is unavailable. Delivery evidence is not currently readable; it has not been discarded.</p>}
    {!work.loading && work.value?.headConnected !== false && !work.value?.records?.length && <p className="field-note">No retained work on this page.</p>}
    {work.value?.records?.map((record) => <article key={`${record.kind}:${record.id}`} className="trusted-ship">
      <p><strong>{labels[record.status] || record.status}</strong> · {record.actor} · <code>{record.destination}</code></p>
      <p>{record.text}</p>
      {record.reply && <p className="field-note">Reply: {record.reply}</p>}
      <p className="field-note">{record.kind === 'admission' ? `Admission: ${record.stage}` : `Attempt ${record.attempt} · ${record.current ? 'current authorization' : 'retired or disabled authorization'}`}</p>
      {record.error && <p className="inline-error">{record.error}</p>}
      {record.externalId && <p className="field-note">Native reference: <code>{record.externalId}</code></p>}
      <a href={`#/settings/${encodeURIComponent(record.sessionId)}`}>Conversation settings</a>
      {record.kind === 'admission' && record.canRetry && <button type="button" className="text-button" disabled={busy !== null} onClick={() => retryAdmission(record.id)}>Resume admission</button>}
      {record.kind === 'input' && record.canRetry && <button type="button" className="text-button" onClick={() => setRecovery({ record, mode: 'retry' })}>Retry failed send</button>}
      {record.canResolve && <button type="button" className="text-button" onClick={() => setRecovery({ record, mode: 'resolve' })}>Resolve delivery</button>}
      {recovery?.record.id === record.id && <Recovery key={`${record.id}:${recovery.mode}`} {...recovery} onClose={() => setRecovery(null)} onSaved={refresh} />}
    </article>)}
    <div className="form-actions">
      {cursors.length > 1 && <button type="button" className="button ghost" onClick={() => { setRecovery(null); setCursors(['']) }}>Latest work</button>}
      {work.value?.next && <button type="button" className="button ghost" onClick={() => { setRecovery(null); setCursors([...cursors, work.value.next]) }}>Older work</button>}
    </div>
  </>
}

export default function TlonWork() {
  const [open, setOpen] = useState(false)
  return <section className="panel settings-panel"><details onToggle={(event) => setOpen(event.currentTarget.open)}>
    <summary>Work and delivery</summary>
    {open && <WorkList />}
  </details></section>
}
