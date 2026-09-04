import { useEffect, useState } from 'react'
import { api } from '../api'
import { useGrub } from '../useGrub'
import { PROVIDERS, providerOf } from '../providers'
import { useProviderModels } from '../useProviderModels'

const themes = ['system', 'light', 'dark']

const toolCopy = {
  'ship-time': ['Ship time', 'Read the ship’s current time.'],
  clay: ['Desk files', 'Read and list files in Clay.'],
  web: ['Web requests', 'Fetch public HTTP resources.'],
  skills: ['Skills', 'Read instructions from the skill library.'],
  'skill-write': ['Write skills', 'Stage and update reusable instructions.'],
  author: ['Authoring', 'Create and revise ship-side resources.'],
  subagents: ['Subagents', 'Delegate independent work to another session.'],
  peers: ['Peer agents', 'Ask explicitly permitted agents on other ships.'],
}

function ToolOption({ name, checked, onChange }) {
  const [title, description] = toolCopy[name] || [name, 'Allow this capability in the conversation.']
  return <label className="tool-option">
    <input type="checkbox" checked={checked} onChange={onChange} />
    <span><strong>{title}</strong><small>{description}</small></span>
  </label>
}

export default function AgentSettings({ roads, theme, onThemeChange }) {
  const session = useGrub(roads.session, null)
  const tools = useGrub(roads.tools, [])
  const [form, setForm] = useState({})
  const [provider, setProvider] = useState('openrouter')
  const [busy, setBusy] = useState(false)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState('')
  const catalog = useProviderModels(provider)

  useEffect(() => {
    if (!session.value) return
    setForm(session.value)
    setProvider(providerOf(session.value.url))
  }, [session.value])
  useEffect(() => {
    if (!saved) return undefined
    const timeout = setTimeout(() => setSaved(false), 1800)
    return () => clearTimeout(timeout)
  }, [saved])
  const field = (name, value) => setForm((current) => ({ ...current, [name]: value }))

  function chooseProvider(next) {
    setProvider(next)
    const details = PROVIDERS[next]
    if (details.endpoint) setForm((current) => ({ ...current, url: details.endpoint, model: details.model }))
  }

  async function save(event) {
    event.preventDefault()
    setBusy(true); setError(''); setSaved(false)
    const config = {
      url: form.url?.trim() || PROVIDERS.openrouter.endpoint,
      model: form.model?.trim() || 'openai/gpt-4o-mini',
      key: '',
      headers: Array.isArray(form.headers) ? form.headers : [],
      system: form.system || '',
      'max-context': Number(form['max-context']) || 80_000,
      tools: Array.isArray(form.tools) ? form.tools : [],
    }
    try {
      const applied = await api.action({ config: { sid: roads.chat, config } })
      session.setValue(applied); setForm(applied); setSaved(true)
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
      <div className="section-title"><div><h2>Model</h2><p>Choose a provider or point the conversation at any OpenAI-compatible endpoint.</p></div></div>
      <div className="two-fields">
        <label><span>Provider</span><select value={provider} onChange={(event) => chooseProvider(event.target.value)}>{Object.entries(PROVIDERS).map(([id, details]) => <option key={id} value={id}>{details.title}{id === 'custom' ? ' endpoint' : ''}</option>)}</select></label>
        <label><span>Model</span><input list={`models-${provider}`} value={form.model || ''} onChange={(event) => field('model', event.target.value)} placeholder={PROVIDERS[provider].model || 'model-name'} /><datalist id={`models-${provider}`}>{catalog.models.map((model) => <option key={model} value={model} />)}</datalist></label>
      </div>
      <label><span>Endpoint</span><input type="url" value={form.url || ''} onChange={(event) => { setProvider(providerOf(event.target.value)); field('url', event.target.value) }} /></label>
      {catalog.loading && <p className="field-note">Loading the provider’s model catalog…</p>}
      {catalog.error && provider !== 'custom' && <p className="field-note">Catalog unavailable: {catalog.error}. You can still type a model name.</p>}
    </section>
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Instructions & context</h2><p>These become part of this conversation’s event log.</p></div></div>
      <label><span>System instructions</span><textarea rows="5" value={form.system || ''} onChange={(event) => field('system', event.target.value)} /></label>
      <label><span>Context window</span><input type="number" min="1000" step="1000" value={form['max-context'] || ''} onChange={(event) => field('max-context', event.target.value)} /></label>
    </section>
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Tools</h2><p>Capabilities are explicit per conversation.</p></div></div>
      <div className="tool-options">{(tools.value || []).map((name) => <ToolOption key={name} name={name} checked={(form.tools || []).includes(name)} onChange={() => toggleTool(name)} />)}</div>
    </section>
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Appearance</h2><p>Use the system color scheme or choose a fixed theme.</p></div></div>
      <div className="segmented theme-options">{themes.map((option) => <button type="button" key={option} className={theme === option ? 'active' : ''} onClick={() => onThemeChange(option)}>{option}</button>)}</div>
    </section>
    <div className="save-bar"><span>{saved ? 'Saved.' : 'Changes apply to the next turn.'}</span><button className="button primary" disabled={busy}>{busy ? 'Saving…' : 'Save conversation'}</button></div>
  </form>
}
