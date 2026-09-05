import { useEffect, useRef, useState } from 'react'
import { api } from '../api'
import { useResource } from '../useResource'
import { PROVIDERS, providerOf } from '../providers'
import { useProviderModels } from '../useProviderModels'
import ToolOptions from './ToolOptions'

const themes = ['system', 'light', 'dark']

export default function AgentSettings({ resources, theme, onThemeChange }) {
  const session = useResource(resources.session, null)
  const tools = useResource(resources.tools, [])
  const [form, setForm] = useState({})
  const [provider, setProvider] = useState('openrouter')
  const [busy, setBusy] = useState(false)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState('')
  const [dirty, setDirty] = useState(false)
  const loadedChat = useRef('')
  const details = PROVIDERS[provider]
  const catalogUrl = provider === 'openai' && form.url === details.deviceEndpoint ? details.deviceModelsEndpoint : details.modelsEndpoint
  const catalog = useProviderModels(provider, catalogUrl)

  useEffect(() => {
    if (!session.value) return
    if (dirty && loadedChat.current === resources.chat) return
    loadedChat.current = resources.chat
    setForm(session.value)
    setProvider(providerOf(session.value.url))
    setDirty(false)
  }, [dirty, resources.chat, session.value])
  useEffect(() => {
    if (!saved) return undefined
    const timeout = setTimeout(() => setSaved(false), 1800)
    return () => clearTimeout(timeout)
  }, [saved])
  const field = (name, value) => {
    setDirty(true)
    setForm((current) => ({ ...current, [name]: value }))
  }

  function chooseProvider(next) {
    setDirty(true)
    setProvider(next)
    const details = PROVIDERS[next]
    if (details.endpoint) setForm((current) => ({ ...current, url: details.endpoint, model: details.model }))
  }

  function chooseModel(model) {
    setDirty(true)
    setForm((current) => ({ ...current, model }))
  }

  async function save(event) {
    event.preventDefault()
    setBusy(true); setError(''); setSaved(false)
    const config = {
      url: form.url?.trim() || PROVIDERS.openrouter.endpoint,
      model: form.model?.trim() || PROVIDERS.openrouter.model,
      key: '',
      headers: Array.isArray(form.headers) ? form.headers : [],
      system: form.system || '',
      'max-context': catalog.contextFor(form.model?.trim() || PROVIDERS.openrouter.model) || 80_000,
      tools: Array.isArray(form.tools) ? form.tools : [],
    }
    try {
      const applied = await api.action({ config: { sid: resources.chat, config } })
      session.setValue(applied); setForm(applied); setDirty(false); setSaved(true)
    } catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }

  function toggleTool(name) {
    const selected = new Set(form.tools || [])
    selected.has(name) ? selected.delete(name) : selected.add(name)
    field('tools', [...selected])
  }

  return <form className="settings-grid" onSubmit={save}>
    {(error || session.error || tools.error) && <div className="inline-error">{error || session.error || tools.error}</div>}
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Model</h2><p>Provider and model for <strong>{resources.chat}</strong>. Changes affect its next turn.</p></div></div>
      <div className="two-fields">
        <label><span>Provider</span><select value={provider} onChange={(event) => chooseProvider(event.target.value)}>{Object.entries(PROVIDERS).map(([id, details]) => <option key={id} value={id}>{details.title}{id === 'custom' ? ' endpoint' : ''}</option>)}</select></label>
        <label><span>Model</span><input list={`models-${provider}`} value={form.model || ''} onChange={(event) => chooseModel(event.target.value)} placeholder={PROVIDERS[provider].model || 'model-name'} /><datalist id={`models-${provider}`}>{catalog.models.map((model) => <option key={model} value={model} />)}</datalist></label>
      </div>
      <label><span>Endpoint</span><input type="url" value={form.url || ''} onChange={(event) => { setProvider(providerOf(event.target.value)); field('url', event.target.value) }} /></label>
      {catalog.loading && <p className="field-note">Loading the provider’s model catalog…</p>}
      {catalog.error && provider !== 'custom' && <p className="field-note">Catalog unavailable: {catalog.error}. You can still type a model name.</p>}
      {catalog.contextFor(form.model) && <p className="field-note">Provider reports a {catalog.contextFor(form.model).toLocaleString()} token context window; applied automatically on save.</p>}
    </section>
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Instructions</h2><p>These become part of this conversation’s event log.</p></div></div>
      <label><span>System instructions</span><textarea rows="5" value={form.system || ''} onChange={(event) => field('system', event.target.value)} /></label>
    </section>
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Tools</h2><p>Capabilities for <strong>{resources.chat}</strong>. New conversations begin with all of them enabled.</p></div><button type="button" className="text-button" onClick={() => field('tools', [...(tools.value || [])])}>Enable all</button></div>
      <ToolOptions available={tools.value || []} selected={form.tools || []} onChange={toggleTool} />
    </section>
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Appearance</h2><p>Use the system color scheme or choose a fixed theme.</p></div></div>
      <div className="segmented theme-options">{themes.map((option) => <button type="button" key={option} className={theme === option ? 'active' : ''} onClick={() => onThemeChange(option)}>{option}</button>)}</div>
    </section>
    <div className="save-bar"><span>{saved ? 'Saved.' : 'Changes apply to the next turn.'}</span><button className="button primary" disabled={busy}>{busy ? 'Saving…' : 'Save conversation'}</button></div>
  </form>
}
