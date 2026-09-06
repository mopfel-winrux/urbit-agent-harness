import { useState } from 'react'
import { api } from '../api'
import { useResource } from '../useResource'

export default function TlonCron() {
  const schedules = useResource('tlon/cron', [], 5000)
  const [busy, setBusy] = useState(null)
  const [error, setError] = useState('')
  const cancel = async (id) => {
    setBusy(id); setError('')
    try { schedules.setValue(await api.action({ cancelCron: id })) }
    catch (cause) { setError(cause.message) }
    finally { setBusy(null) }
  }
  return <section className="panel settings-panel">
    <div className="section-title"><div><h2>Scheduled work</h2><p>Grant Scheduled Tlon work to an owner conversation, then ask there to schedule a task. Schedules use UTC and a bounded run count.</p></div></div>
    {(error || schedules.error) && <p role="alert" className="inline-error">{error || schedules.error}</p>}
    {!schedules.value?.length && <p className="field-note">No schedules. A fired task is not a delivered reply; execution and delivery are tracked separately.</p>}
    {schedules.value?.map((job) => <article key={job.id} className="trusted-ship">
      <p><strong>{job.prompt}</strong></p>
      <p><code>{job.schedule}</code> UTC · {job.state} · {job.remaining} runs remaining</p>
      <p className="field-note">Next: {job.next} · Execution: {job.execution || 'not admitted'} · Delivery: {job.delivery || 'not published'}</p>
      {job.reason && <p className="field-note">{job.reason}</p>}
      <a href={`#/settings/${encodeURIComponent(job.runSessionId)}`}>Scheduled conversation</a>
      {job.state !== 'cancelled' && <button type="button" className="text-button" disabled={busy === job.id} onClick={() => cancel(job.id)}>{busy === job.id ? 'Cancelling…' : 'Cancel schedule'}</button>}
    </article>)}
    <p className="field-note">Cancellation stops pending work but cannot retract effects already dispatched. Permission changes require explicit rescheduling; uncertain sends are never automatically repeated.</p>
  </section>
}
