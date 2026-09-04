import { useEffect, useState } from 'react'
import { api, ballUrl, waitFor } from '../api'
import { useGrub } from '../useGrub'

const themes = ['system', 'light', 'dark']

export default function AgentSettings({ roads, theme, onThemeChange }) {
  const config = useGrub(roads.config, {})
  const about = useGrub(roads.about, '', 'txt')
  const [form, setForm] = useState({})
  const [description, setDescription] = useState('')
  const [busy, setBusy] = useState(false)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => { if (config.value && typeof config.value === 'object') setForm(config.value) }, [config.value])
  useEffect(() => { if (typeof about.value === 'string') setDescription(about.value) }, [about.value])
  useEffect(() => {
    if (!saved) return undefined
    const timeout = setTimeout(() => setSaved(false), 1800)
    return () => clearTimeout(timeout)
  }, [saved])
  const field = (name, value) => setForm((current) => ({ ...current, [name]: value }))

  async function save(event) {
    event.preventDefault()
    setBusy(true); setError(''); setSaved(false)
    const next = {
      ...form,
      context_window: Number(form.context_window) || 80_000,
      message_cap: Number(form.message_cap) || 20_000,
    }
    try {
      await api.over(roads.config, next)
      const appliedConfig = await waitFor(
        () => api.read(roads.config),
        (value) => value?.model === next.model
          && value?.['api-proxy'] === next['api-proxy']
          && value?.context_window === next.context_window
          && value?.message_cap === next.message_cap
          && value?.channel === next.channel,
      )
      await api.over(roads.about, description, 'txt')
      const appliedAbout = await waitFor(
        () => api.read(roads.about, 'txt'),
        (value) => typeof value === 'string' && value.trim() === description.trim(),
      )
      setForm(appliedConfig); setDescription(appliedAbout); setSaved(true)
    } catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }

  return <form className="settings-grid" onSubmit={save}>
    {(error || config.error || about.error) && <div className="inline-error">{error || config.error || about.error}</div>}
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Model</h2><p>Choose the provider and model used for new turns.</p></div></div>
      <div className="two-fields">
        <label><span>Provider</span><select value={form['api-proxy'] || ''} onChange={(event) => field('api-proxy', event.target.value)}><option value="anthropic">Anthropic</option><option value="openrouter">OpenRouter</option></select></label>
        <label><span>Model</span><input value={form.model || ''} onChange={(event) => field('model', event.target.value)} placeholder="claude-sonnet-4-6" /></label>
      </div>
    </section>
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Context</h2><p>Bound each request while retaining the full conversation.</p></div></div>
      <div className="two-fields equal">
        <label><span>Context window</span><input type="number" min="1000" step="1000" value={form.context_window || ''} onChange={(event) => field('context_window', event.target.value)} /></label>
        <label><span>Message cap</span><input type="number" min="1000" step="1000" value={form.message_cap || ''} onChange={(event) => field('message_cap', event.target.value)} /></label>
      </div>
    </section>
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Identity & channel</h2><p>Describe this agent and optionally connect its main conversation to a channel.</p></div></div>
      <label><span>Public description</span><textarea rows="4" value={description} onChange={(event) => setDescription(event.target.value)} /></label>
      <label><span>Channel path</span><input value={form.channel || ''} onChange={(event) => field('channel', event.target.value)} placeholder="telegram/main-bot" /></label>
    </section>
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Appearance</h2><p>Use the system color scheme or choose a fixed theme.</p></div></div>
      <div className="segmented theme-options">{themes.map((option) => <button type="button" key={option} className={theme === option ? 'active' : ''} onClick={() => onThemeChange(option)}>{option}</button>)}</div>
    </section>
    <section className="panel architecture-panel">
      <div className="section-title"><div><h2>Processes</h2><p>Inspect the live agent tree.</p></div></div>
      <a className="process-link" href={ballUrl(roads.agentRoot)} target="_blank" rel="noreferrer">Open process inspector ↗</a>
    </section>
    <div className="save-bar"><span>{saved ? 'Saved.' : 'Changes apply to the next turn.'}</span><button className="button primary" disabled={busy}>{busy ? 'Saving…' : 'Save agent'}</button></div>
  </form>
}
