import { useState } from 'react'
import { acp } from '../acp'
import { useResource } from '../useResource'
import { PROVIDERS, providerOf } from '../providers'

// The hand owns routing, not a second provider configuration. New lanes take
// Harness defaults; existing sessions change only by an explicit owner action.
export default function TlonModels({ sessions = [] }) {
  const defaults = useResource('defaults', null)
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState('')
  const [error, setError] = useState('')
  async function apply() {
    setBusy(true); setMessage(''); setError('')
    let applied = 0
    try {
      for (const sessionId of sessions) {
        await acp.call('harness/session/use-default-model', { sessionId })
        applied++
      }
      setMessage(`Updated ${applied} conversations. Send a new message to try the selected model.`)
    } catch (cause) { setError(`Updated ${applied} of ${sessions.length}: ${cause.message}`) }
    finally { setBusy(false) }
  }
  const config = defaults.value
  return <section className="panel settings-panel tlon-models">
    <div className="section-title"><div><h2>Model</h2><p>New Tlon conversations use Harness defaults. Existing conversations keep their own model until you change it.</p></div></div>
    {config && <p><strong>{PROVIDERS[providerOf(config.url)].title}</strong> · {config.model}</p>}
    <p><a href="#/settings">Edit default provider and model</a></p>
    {(error || defaults.error) && <p className="inline-error" role="alert">{error || defaults.error}</p>}
    {sessions.length > 0 && <>
      <button className="button" disabled={busy || !config} onClick={apply}>{busy ? 'Applying…' : `Apply defaults to ${sessions.length} Tlon conversations`}</button>
      <p className="field-note">Changes the endpoint, model and provider headers for the next turn. Instructions, history and tool permissions stay unchanged.</p>
      <details><summary>Conversation models</summary><ul>{sessions.map((sid) => <li key={sid}><a href={`#/settings/${encodeURIComponent(sid)}`}>{sid}</a></li>)}</ul></details>
    </>}
    {message && <p role="status">{message}</p>}
  </section>
}
