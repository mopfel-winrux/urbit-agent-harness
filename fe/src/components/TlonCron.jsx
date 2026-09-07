import { useState } from 'react'
import { api } from '../api'
import { useResource } from '../useResource'

export default function TlonCron() {
  const schedules = useResource('tlon/cron', [], 5000)
  const [busy, setBusy] = useState(null)
  const [error, setError] = useState('')
  const update = async (id, clear = false) => {
    setBusy(id); setError('')
    try { schedules.setValue(await api.action(clear ? { clearCron: id } : { cancelCron: id })) }
    catch (cause) { setError(cause.message) }
    finally { setBusy(null) }
  }
  return <section className="panel settings-panel">
    <div className="section-title"><div><h2>Scheduled work</h2><p>Ask in an authorized Tlon conversation for a task or a literal reminder. Recurring tasks use UTC; one-shot reminders require an explicit timezone offset and do not run a model at delivery time.</p></div></div>
    {(error || schedules.error) && <p role="alert" className="inline-error">{error || schedules.error}</p>}
    {!schedules.value?.length && <p className="field-note">No schedules. A fired task is not a delivered reply; execution and delivery are tracked separately.</p>}
    {schedules.value?.map((job) => <article key={job.id} className="trusted-ship">
      <p><strong>{job.prompt}</strong></p>
      <p><code>{job.schedule}</code> {job.timezone || 'UTC'} · {job.kind === 'reminder' ? 'literal reminder' : 'model task'} · {job.state} · {job.remaining} runs remaining</p>
      {job.destination && <p className="field-note">Destination: {job.destination}</p>}
      <p className="field-note">Next: {job.next} · Execution: {job.execution || 'not admitted'} · Delivery: {job.delivery || 'not published'}</p>
      {job.evidenceAvailable === false && <p className="field-note">The head is unavailable; execution and delivery evidence cannot currently be read.</p>}
      {job.reason && <p className="field-note">{job.reason}</p>}
      <a href={`#/settings/${encodeURIComponent(job.runSessionId)}`}>Scheduled conversation</a>
      {job.clearable ? <button type="button" className="text-button" disabled={busy !== null} onClick={() => update(job.id, true)}>{busy === job.id ? 'Clearing…' : 'Clear finished schedule'}</button>
        : job.state !== 'cancelled' && <button type="button" className="text-button" disabled={busy !== null} onClick={() => update(job.id)}>{busy === job.id ? 'Cancelling…' : 'Cancel schedule'}</button>}
    </article>)}
    <p className="field-note">Cancellation cannot retract dispatched effects. Clear removes completed or cancelled schedules only after their work is settled; conversation history and delivery receipts remain.</p>
  </section>
}
