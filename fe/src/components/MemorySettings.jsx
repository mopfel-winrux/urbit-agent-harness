import { useEffect, useId, useRef, useState } from 'react'
import { api } from '../api'
import { defaultConfig } from '../defaults'
import { useResource } from '../useResource'
import { useProviderModels } from '../useProviderModels'
import { PROVIDERS, providerOf } from '../providers'
import { authMethod, withAuth, chooseProvider, catalogEndpoint } from '../providerConfig'
import ProviderRoute from './ProviderRoute'
import HeaderEditor from './HeaderEditor'

function ModelOverride({ name, title, description, value, defaults, onChange, disabled }) {
  const id = useId()
  const config = value || defaults
  const provider = providerOf(config.url)
  const catalog = useProviderModels(provider, catalogEndpoint(provider, config))
  const update = (next) => onChange(withAuth({ ...next, key: '', system: '', tools: [] }, providerOf(next.url), authMethod(providerOf(next.url), next)))
  return <section className="panel settings-panel">
    <div className="section-title"><div><h2>{title}</h2><p>{description}</p></div></div>
    <fieldset disabled={disabled} className="memory-model-fields">
      <label className="tool-option"><input type="checkbox" checked={!value} onChange={(event) => onChange(event.target.checked ? null : { ...defaults, key: '', system: '', tools: [] })} /><span><strong>Use global default</strong><small>Follows the current default: {defaults.model || 'no model selected'}.</small></span></label>
      {value && <>
        <div className="two-fields">
          <label><span>Provider</span><select value={provider} onChange={(event) => onChange(chooseProvider(config, event.target.value, 'api-key'))}>{Object.entries(PROVIDERS).map(([key, item]) => <option key={key} value={key}>{item.title}</option>)}</select></label>
          <label><span>Model</span><input required list={id} value={config.model || ''} onChange={(event) => update({ ...config, model: event.target.value, 'max-context': catalog.contextFor(event.target.value) || 80_000 })} /><datalist id={id}>{catalog.models.map((model) => <option key={model} value={model} />)}</datalist></label>
        </div>
        <ProviderRoute provider={provider} value={config} onChange={update} />
        {catalog.loading && <p className="field-note">Loading models…</p>}
        {catalog.error && <p className="field-note">Catalog unavailable. You can still enter a model name.</p>}
        <HeaderEditor value={config.headers || []} onChange={(headers) => update({ ...config, headers })} />
      </>}
    </fieldset>
  </section>
}

export default function MemorySettings() {
  const defaults = useResource('defaults', defaultConfig())
  const models = useResource('summary-models', { compaction: null, lcm: null })
  const [form, setForm] = useState({ compaction: null, lcm: null })
  const dirty = useRef(false)
  const [busy, setBusy] = useState(false)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState('')
  const unavailable = models.loading || defaults.loading || !!models.error || !!defaults.error
  useEffect(() => { if (!dirty.current && models.value) setForm(models.value) }, [models.value])
  const change = (name, value) => { dirty.current = true; setSaved(false); setForm((prior) => ({ ...prior, [name]: value })) }
  async function save(event) {
    event.preventDefault(); setBusy(true); setError(''); setSaved(false)
    if (unavailable) { setBusy(false); return }
    try {
      const clean = Object.fromEntries(Object.entries(form).map(([name, value]) => [name, value ? { ...value, model: value.model.trim(), url: value.url.trim(), key: '', system: '', tools: [], headers: (value.headers || []).filter((header) => header.name.trim()) } : null]))
      const applied = await api.action({ summaryModels: clean })
      models.setValue(applied); setForm(applied); dirty.current = false; setSaved(true)
    } catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }
  return <form className="settings-grid" onSubmit={save}>
    <p className="field-note">Original content stays searchable after summarization. These settings apply to the next summary request in any conversation; in-flight requests keep their selected model.</p>
    {(error || models.error || defaults.error) && <div className="inline-error" role="alert">{error || models.error || defaults.error}</div>}
    {(models.error || defaults.error) && <button type="button" className="button ghost" onClick={() => { models.refresh(); defaults.refresh() }}>Retry loading settings</button>}
    <ModelOverride title="Compaction model" description="Summarizes older complete exchanges into source-linked leaves." value={form.compaction} defaults={defaults.value} onChange={(value) => change('compaction', value)} disabled={busy || unavailable} />
    <ModelOverride title="LCM model" description="Condenses groups of summaries into a hierarchy, keeping links to their original evidence." value={form.lcm} defaults={defaults.value} onChange={(value) => change('lcm', value)} disabled={busy || unavailable} />
    <div className="save-bar"><span role="status">{saved ? 'Saved.' : dirty.current ? 'Unsaved changes.' : 'Unset overrides follow the global default.'}</span><button className="button primary" disabled={busy || unavailable}>{busy ? 'Saving…' : 'Save memory settings'}</button></div>
  </form>
}
