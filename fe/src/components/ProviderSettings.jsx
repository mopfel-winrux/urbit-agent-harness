import { useEffect, useRef, useState } from 'react'
import { api } from '../api'
import { useGrub } from '../useGrub'
import { PROVIDERS, providerOf } from '../providers'
import { useProviderModels } from '../useProviderModels'
import { AnthropicDeviceLogin, OpenAIDeviceLogin } from './ProviderLogin'

function HeaderEditor({ value, onChange }) {
  const replace = (index, next) => onChange(value.map((entry, at) => at === index ? next : entry))
  return <div className="header-editor">
    <div className="field-heading"><span>Request headers</span><button type="button" className="text-button" onClick={() => onChange([...value, { name: '', value: '' }])}>Add header</button></div>
    {!value.length && <p className="field-note">Content-Type is automatic. Add organization IDs, versions, or a provider-specific authorization header.</p>}
    {value.map((header, index) => <div className="header-row" key={index}>
      <input aria-label="Header name" value={header.name || ''} onChange={(event) => replace(index, { ...header, name: event.target.value })} placeholder="x-provider-header" />
      <input aria-label="Header value" type={/authorization|token|key/i.test(header.name) ? 'password' : 'text'} value={header.value || ''} onChange={(event) => replace(index, { ...header, value: event.target.value })} placeholder="value" />
      <button type="button" className="remove-header" onClick={() => onChange(value.filter((_, at) => at !== index))} aria-label="Remove header">×</button>
    </div>)}
  </div>
}

export default function ProviderSettings({ provider, roads }) {
  const details = PROVIDERS[provider]
  const session = useGrub(roads.session, null)
  const status = useGrub(`status/${provider}`, { 'has-key': false })
  const [key, setKey] = useState('')
  const [endpoint, setEndpoint] = useState(details.endpoint)
  const [model, setModel] = useState(details.model)
  const [headers, setHeaders] = useState([])
  const [busy, setBusy] = useState(false)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState('')
  const [dirty, setDirty] = useState(false)
  const loadedProvider = useRef('')
  const catalogUrl = provider === 'openai' && endpoint.includes('chatgpt.com/') ? details.deviceModelsEndpoint : details.modelsEndpoint
  const catalog = useProviderModels(provider, catalogUrl)

  useEffect(() => {
    if (dirty && loadedProvider.current === provider) return
    loadedProvider.current = provider
    const ownsSession = Boolean(session.value) && providerOf(session.value.url) === provider
    setEndpoint(ownsSession ? session.value.url : details.endpoint || session.value?.url || '')
    setModel(ownsSession ? session.value?.model || details.model : details.model || session.value?.model || '')
    setHeaders(Array.isArray(session.value?.headers) ? session.value.headers : [])
    setKey('')
    setDirty(false)
  }, [details.endpoint, dirty, provider, session.value])

  const edit = (setter) => (value) => { setDirty(true); setter(value) }

  async function save(event) {
    event.preventDefault()
    setBusy(true); setSaved(false); setError('')
    const cleanHeaders = headers.filter((header) => header.name.trim()).map((header) => ({ name: header.name.trim(), value: header.value }))
    const config = {
      url: endpoint.trim() || details.endpoint,
      model: model.trim() || details.model || 'openai/gpt-4o-mini',
      key: '',
      headers: cleanHeaders,
      system: session.value?.system || '',
      'max-context': session.value?.['max-context'] || 80_000,
      tools: session.value?.tools || [],
    }
    try {
      if (key) await api.action({ 'set-key': { provider, key } })
      const applied = await api.action({ config: { sid: roads.chat, config } })
      session.setValue(applied); setKey(''); setDirty(false); setSaved(true)
      await status.refresh()
    } catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }

  async function acceptCredential({ token, refreshToken = '', account = '' }) {
    await api.action({ 'set-key': { provider, key: token } })
    if (refreshToken) await api.action({ 'set-key': { provider: `${provider}-refresh`, key: refreshToken } })
    if (account) await api.action({ 'set-key': { provider: 'openai-account', key: account } })
    if (provider === 'openai') {
      setEndpoint(details.deviceEndpoint); setModel(details.deviceModel)
      setHeaders(account ? [{ name: 'chatgpt-account-id', value: account }] : [])
    } else {
      setHeaders([{ name: 'anthropic-beta', value: 'oauth-2025-04-20' }])
    }
    setDirty(true)
    await status.refresh()
  }

  return <form className="settings-grid" onSubmit={save}>
    {(error || session.error || status.error) && <div className="inline-error">{error || session.error || status.error}</div>}
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>{details.title}</h2><p>{details.copy}</p></div><span className={`status ${status.value?.['has-key'] ? 'good' : ''}`}>{status.value?.['has-key'] ? 'credential configured' : 'credential needed'}</span></div>
      {provider === 'openai' && <OpenAIDeviceLogin onCredential={acceptCredential} />}
      {provider === 'anthropic' && <AnthropicDeviceLogin onCredential={acceptCredential} />}
      <label><span>{provider === 'custom' ? 'Bearer token (optional)' : 'API key'}</span><input type="password" autoComplete="off" value={key} onChange={(event) => edit(setKey)(event.target.value)} placeholder={details.placeholder} /></label>
      <label><span>Model</span><input list={`provider-models-${provider}`} value={model} onChange={(event) => edit(setModel)(event.target.value)} placeholder={details.model || 'model-name'} /><datalist id={`provider-models-${provider}`}>{catalog.models.map((name) => <option key={name} value={name} />)}</datalist></label>
      {catalog.loading && <p className="field-note">Loading the provider’s model catalog…</p>}
      {catalog.error && provider !== 'custom' && <p className="field-note">Catalog unavailable: {catalog.error}. You can still type a model name.</p>}
      <label><span>Endpoint</span><input type="url" required value={endpoint} onChange={(event) => edit(setEndpoint)(event.target.value)} placeholder="https://inference.example/v1/chat/completions" /></label>
      <HeaderEditor value={headers} onChange={edit(setHeaders)} />
    </section>
    <div className="save-bar"><span>{saved ? 'Saved.' : 'Saving also selects this endpoint for the current conversation.'}</span><button className="button primary" disabled={busy}>{busy ? 'Saving…' : `Save ${details.title}`}</button></div>
  </form>
}
