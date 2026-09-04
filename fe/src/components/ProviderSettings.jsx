import { useEffect, useState } from 'react'
import { api, waitFor } from '../api'
import { useGrub } from '../useGrub'

const OPENROUTER = 'apps/openrouter.openrouter'

function Stat({ label, value }) {
  return <div><span>{label}</span><strong>{Number(value || 0).toLocaleString()}</strong></div>
}

export default function ProviderSettings({ provider, roads }) {
  const root = provider === 'anthropic' ? roads.anthropic : OPENROUTER
  const config = useGrub(`${root}/config.json`, {})
  const usage = useGrub(`${root}/usage.json`, {})
  const models = useGrub(provider === 'openrouter' ? `${root}/models.json` : '', {})
  const [form, setForm] = useState({})
  const [busy, setBusy] = useState(false)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    if (config.value && typeof config.value === 'object') setForm(config.value)
  }, [config.value])
  useEffect(() => {
    if (!saved) return undefined
    const timeout = setTimeout(() => setSaved(false), 1800)
    return () => clearTimeout(timeout)
  }, [saved])

  async function save(event) {
    event.preventDefault()
    setBusy(true); setSaved(false); setError('')
    const next = provider === 'anthropic'
      ? { ...form, url: form.url?.trim() || 'https://api.anthropic.com/v1/messages' }
      : { ...config.value, 'api-key': form['api-key'] || '' }
    try {
      await api.over(`${root}/config.json`, next)
      const applied = await waitFor(
        () => api.read(`${root}/config.json`),
        (value) => value?.['api-key'] === next['api-key'] && (provider !== 'anthropic' || value.url === next.url),
      )
      config.setValue(applied); setForm(applied); setSaved(true)
    } catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }

  const problem = error || config.error || usage.error || models.error
  const calls = Array.isArray(usage.value?.calls) ? usage.value.calls : []
  const modelCount = provider === 'openrouter' && models.value && typeof models.value === 'object'
    ? Object.keys(models.value).length
    : null

  return <form className="settings-grid" onSubmit={save}>
    {problem && <div className="inline-error">{problem}</div>}
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>{provider === 'anthropic' ? 'Anthropic' : 'OpenRouter'}</h2><p>Credentials remain in this provider process and are used only for its requests.</p></div><span className={`status ${form['api-key'] ? 'good' : ''}`}>{form['api-key'] ? 'configured' : 'key needed'}</span></div>
      <label><span>API key</span><input type="password" autoComplete="off" value={form['api-key'] || ''} onChange={(event) => setForm((value) => ({ ...value, 'api-key': event.target.value }))} placeholder={provider === 'anthropic' ? 'sk-ant-…' : 'sk-or-…'} /></label>
      {provider === 'anthropic' && <label><span>Endpoint</span><input value={form.url || ''} onChange={(event) => setForm((value) => ({ ...value, url: event.target.value }))} /></label>}
    </section>
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Usage</h2><p>Accounting reported by the provider proxy.</p></div>{modelCount != null && <span className="status">{modelCount} models</span>}</div>
      <div className="usage-stats">
        <Stat label="Requests" value={usage.value?.requests} />
        <Stat label="Input tokens" value={usage.value?.['input-tokens']} />
        <Stat label="Output tokens" value={usage.value?.['output-tokens']} />
        <Stat label="Recent calls" value={calls.length} />
      </div>
    </section>
    <div className="save-bar"><span>{saved ? 'Saved.' : 'Changes apply to the next request.'}</span><button className="button primary" disabled={busy}>{busy ? 'Saving…' : `Save ${provider === 'anthropic' ? 'Anthropic' : 'OpenRouter'}`}</button></div>
  </form>
}
