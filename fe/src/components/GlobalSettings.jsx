import { useEffect, useRef, useState } from 'react'
import { api } from '../api'
import { defaultConfig } from '../defaults'
import { PROVIDERS, providerOf } from '../providers'
import { useResource } from '../useResource'
import { useProviderModels } from '../useProviderModels'
import HeaderEditor from './HeaderEditor'
import ToolOptions from './ToolOptions'
import ProviderRoute from './ProviderRoute'
import { authMethod, withAuth, chooseProvider as providerConfig, catalogEndpoint } from '../providerConfig'

export default function GlobalSettings({ resources, theme, onThemeChange }) {
  const defaults = useResource(resources.defaults, defaultConfig())
  const tools = useResource(resources.tools, [])
  const openai = useResource('status/openai', {})
  const [form, setForm] = useState(defaultConfig())
  const [provider, setProvider] = useState('openrouter')
  const [busy, setBusy] = useState(false)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState('')
  const dirty = useRef(false)
  const details = PROVIDERS[provider]
  const catalogUrl = catalogEndpoint(provider, form)
  const catalog = useProviderModels(provider, catalogUrl)

  useEffect(() => {
    if (!defaults.value || dirty.current) return
    setForm(defaults.value)
    setProvider(providerOf(defaults.value.url))
  }, [defaults.value])

  const field = (name, value) => {
    dirty.current = true
    setSaved(false)
    setForm((current) => ({ ...current, [name]: value }))
  }
  const chooseProvider = (id) => {
    dirty.current = true
    setProvider(id)
    setForm((current) => providerConfig(current, id, id === 'openai' ? openai.value?.['auth-method'] : 'api-key'))
  }
  const chooseModel = (model) => {
    dirty.current = true; setSaved(false)
    setForm((current) => ({ ...current, model }))
  }
  const toggleTool = (name) => {
    const selected = new Set(form.tools || [])
    selected.has(name) ? selected.delete(name) : selected.add(name)
    field('tools', [...selected])
  }

  async function save(event) {
    event.preventDefault()
    setBusy(true); setError('')
    try {
      const clean = withAuth({
        ...form,
        url: form.url.trim(), model: form.model.trim(), key: '',
        headers: (form.headers || []).filter((header) => header.name.trim()),
        'max-context': catalog.contextFor(form.model.trim()) || 80_000,
      }, provider, authMethod(provider, form))
      const applied = await api.action({ defaults: clean })
      defaults.setValue(applied); setForm(applied); dirty.current = false; setSaved(true)
    } catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }

  return <form className="settings-grid" onSubmit={save}>
    {(error || defaults.error || tools.error) && <div className="inline-error">{error || defaults.error || tools.error}</div>}
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>New conversation defaults</h2><p>Every new thread takes a snapshot of this policy, then may diverge independently.</p></div></div>
      <div className="two-fields">
        <label><span>Provider</span><select value={provider} onChange={(event) => chooseProvider(event.target.value)}>{Object.entries(PROVIDERS).map(([id, value]) => <option key={id} value={id}>{value.title}</option>)}</select></label>
        <label><span>Model</span><input list={`global-models-${provider}`} value={form.model || ''} onChange={(event) => chooseModel(event.target.value)} placeholder={details.model || 'model-name'} /><datalist id={`global-models-${provider}`}>{catalog.models.map((model) => <option key={model} value={model} />)}</datalist></label>
      </div>
      <ProviderRoute provider={provider} value={form} onChange={(next) => { dirty.current = true; setSaved(false); setForm(next) }} />
      {catalog.loading && <p className="field-note">Loading the provider’s model catalog…</p>}
      {catalog.error && provider !== 'custom' && <p className="field-note">Catalog unavailable: {catalog.error}. You can still type a model name.</p>}
      {catalog.contextFor(form.model) && <p className="field-note">Provider reports {catalog.contextFor(form.model).toLocaleString()} tokens; applied automatically on save.</p>}
      <HeaderEditor value={form.headers || []} onChange={(value) => field('headers', value)} />
    </section>
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Instructions</h2><p>Initial operating policy for new threads.</p></div></div>
      <label><span>System instructions</span><textarea rows="9" value={form.system || ''} onChange={(event) => field('system', event.target.value)} /></label>
    </section>
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Default tools</h2><p>Capability grants inherited by new conversations.</p></div><button type="button" className="text-button" onClick={() => field('tools', [...(tools.value || [])])}>Enable all</button></div>
      <ToolOptions available={tools.value || []} selected={form.tools || []} onChange={toggleTool} />
    </section>
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Appearance</h2><p>Local display preference for this client.</p></div></div>
      <div className="segmented theme-options">{['system', 'light', 'dark'].map((option) => <button type="button" key={option} className={theme === option ? 'active' : ''} onClick={() => onThemeChange(option)}>{option}</button>)}</div>
    </section>
    <div className="save-bar"><span>{saved ? 'Saved.' : 'Applies when the next conversation is created.'}</span><button className="button primary" disabled={busy}>{busy ? 'Saving…' : 'Save defaults'}</button></div>
  </form>
}
