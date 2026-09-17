import { PROVIDERS } from '../providers'

export default function ModelFallbacks({ value = [], zdr = false, onChange }) {
  const providers = zdr ? ['openrouter'] : ['openrouter', 'openai', 'anthropic', 'xai']
  const change = (index, field, next) => onChange(value.map((entry, at) => at === index ? { ...entry, [field]: next } : entry))
  return <section className="settings-grid" aria-label="Fallback models">
    <div className="section-title"><div><h3>Fallback models</h3><p>Try these in order if the model cannot respond. Uses saved API keys; does not retry after response text is delivered.</p></div></div>
    {value.map((entry, index) => <div className="model-fallback-row" key={index}>
      <label><span>Fallback {index + 1} provider</span><select value={entry.provider} onChange={(event) => change(index, 'provider', event.target.value)}>{[...new Set([...providers, entry.provider])].map((id) => <option key={id} value={id}>{PROVIDERS[id]?.title || id}{zdr && id !== 'openrouter' ? ' (not eligible for ZDR)' : ''}</option>)}</select></label>
      <label><span>Fallback {index + 1} model</span><input required value={entry.model} maxLength={256} onChange={(event) => change(index, 'model', event.target.value)} placeholder="provider/model-name" /></label>
      <button className="button" type="button" aria-label={`Remove fallback ${index + 1}`} onClick={() => onChange(value.filter((_, at) => at !== index))}>Remove</button>
    </div>)}
    {zdr && <p className="field-note">Fallbacks also require OpenRouter zero data retention endpoints.</p>}
    <button className="button" type="button" disabled={value.length >= 4} onClick={() => onChange([...value, { provider: 'openrouter', model: '' }])}>Add fallback model</button>
  </section>
}
