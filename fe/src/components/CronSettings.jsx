import { useState } from 'react'
import { api } from '../api'
import { useResource } from '../useResource'

export default function CronSettings() {
  const schedules = useResource('cron', [], 5000)
  const [busy, setBusy] = useState(null)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')
  const update = async (id, clear = false) => {
    setBusy({ id, action: clear ? 'clear' : 'cancel' }); setError(''); setNotice('')
    try { schedules.setValue(await api.action(clear ? { clearCron: id } : { cancelCron: id })) }
    catch (cause) { setError(cause.message) }
    finally { setBusy(null) }
  }
  const retry = async (job) => {
    setBusy({ id: job.id, action: 'retry' }); setError(''); setNotice('')
    try {
      schedules.setValue(await api.action({ retryCron: { id: job.id, input: job.lastInput } }))
      setNotice(`Retry requested for “${job.prompt}”.`)
    } catch (cause) { setError(cause.message); void schedules.refresh() }
    finally { setBusy(null) }
  }
  return <section className="panel settings-panel cron-settings" aria-busy={schedules.loading || busy !== null}>
    <div className="section-title"><div><h2>Scheduled work</h2><p>Schedules belong to Harness. Ask through any authorized conversation hand for a recurring task or a literal reminder, delivered back through that hand.</p></div></div>
    <p className="field-note">Recurring tasks use UTC. One-shot reminders require an explicit timezone offset and do not run a model at delivery time.</p>
    {(error || schedules.error) && <p role="alert" className="inline-error">{error || schedules.error}</p>}
    {notice && <p role="status" className="field-note">{notice}</p>}
    {schedules.error && <button type="button" className="text-button" disabled={busy !== null} onClick={() => void schedules.refresh()}>Retry loading schedules</button>}
    {schedules.loading && <p role="status">Loading schedules…</p>}
    {!schedules.loading && !schedules.error && !schedules.value?.length && <p className="field-note">No schedules yet. Execution and delivery will be tracked separately here.</p>}
    {schedules.value?.map((job) => <article key={job.id} className="trusted-ship">
      <p><strong>{job.prompt}</strong></p>
      <p><code>{job.schedule}</code> {job.timezone || 'UTC'} · {job.kind === 'reminder' ? 'literal reminder' : 'model task'} · {job.state} · {job.remaining} runs remaining</p>
      <p className="field-note">Hand: {job.hand || 'unknown'}{job.destination && <> · Destination: {job.destination}</>}</p>
      <p className="field-note">{job.state === 'active' ? `Next: ${job.next} · ` : ''}Execution: {job.execution || 'not admitted'} · Delivery: {job.delivery || 'not published'}</p>
      {job.evidenceAvailable === false && <p className="field-note">The head is unavailable; execution and delivery evidence cannot currently be read.</p>}
      {job.reason && <p className="field-note">{job.reason}</p>}
      <div className="settings-actions"><a href={`#/${encodeURIComponent(job.runSessionId)}`}>Run conversation</a><a href={`#/${encodeURIComponent(job.sessionId)}`}>Source conversation</a>
      {job.retryable && <button type="button" className="text-button" disabled={busy !== null || !!schedules.error} onClick={() => retry(job)}>{busy?.id === job.id && busy.action === 'retry' ? 'Retrying…' : 'Retry failed run'}</button>}
      {job.clearable ? <button type="button" className="text-button" disabled={busy !== null || !!schedules.error} onClick={() => update(job.id, true)}>{busy?.id === job.id && busy.action === 'clear' ? 'Clearing…' : 'Clear finished schedule'}</button>
        : job.state !== 'cancelled' && <button type="button" className="text-button" disabled={busy !== null || !!schedules.error} onClick={() => update(job.id)}>{busy?.id === job.id && busy.action === 'cancel' ? 'Cancelling…' : 'Cancel schedule'}</button>}</div>
    </article>)}
    <p className="field-note">Cancellation cannot retract dispatched effects. Clear removes completed or cancelled schedules only after their work is settled; conversation history and delivery receipts remain.</p>
  </section>
}
