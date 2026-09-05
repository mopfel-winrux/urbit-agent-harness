import { useEffect, useRef, useState } from 'react'
import { api } from '../api'
import { useResource } from '../useResource'
import { PROVIDERS } from '../providers'
import { authMethod, withAuth, chooseProvider, catalogEndpoint, credentialSlot } from '../providerConfig'
import { useProviderModels } from '../useProviderModels'
import { AnthropicDeviceLogin, OpenAIDeviceLogin } from './ProviderLogin'
import ProviderRoute from './ProviderRoute'
import HeaderEditor from './HeaderEditor'

export default function ProviderSettings({ provider, resources }) {
  const details = PROVIDERS[provider]
  const session = useResource(resources.chat ? resources.session : resources.defaults, null)
  const status = useResource(`status/${provider}`, { 'has-key': false })
  const [key, setKey] = useState('')
  const [form, setForm] = useState({ url: details.endpoint, model: details.model, headers: [] })
  const [busy, setBusy] = useState(false)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState('')
  const dirty = useRef(false)
  const loaded = useRef('')
  const method = authMethod(provider, form)
  const catalog = useProviderModels(provider, catalogEndpoint(provider, form))
  const configured = provider === 'openai'
    ? status.value?.[method === 'device' ? 'has-device-login' : 'has-api-key']
    : status.value?.['has-key']

  useEffect(() => {
    const identity = `${provider}:${resources.chat || 'defaults'}`
    if (dirty.current && loaded.current === identity) return
    if (!session.value) return
    loaded.current = identity
    const preferred = status.value?.['auth-method'] || 'api-key'
    let next = chooseProvider(session.value, provider, preferred)
    // Repair the displayed selection when the only saved OpenAI credential is
    // a device login. Persisting it still goes through the ordinary Save path.
    if (provider === 'openai' && !status.value?.['has-api-key'] && status.value?.['has-device-login']) next = withAuth(next, provider, 'device')
    setForm(next); setKey(''); dirty.current = false
  }, [provider, resources.chat, session.value, status.value])

  function edit(next) { dirty.current = true; setSaved(false); setForm(next) }

  async function persist(next) {
    const selectedModel = next.model.trim() || details.model
    const config = withAuth({
      ...next, url: next.url.trim(), model: selectedModel, key: '',
      headers: (next.headers || []).filter((h) => h.name.trim()).map((h) => ({ ...h, name: h.name.trim() })),
      system: session.value?.system || '', tools: session.value?.tools || [],
      'max-context': catalog.contextFor(selectedModel) || 80_000,
    }, provider, authMethod(provider, next))
    const applied = resources.chat
      ? await api.action({ config: { sid: resources.chat, config } })
      : await api.action({ defaults: config })
    session.setValue(applied); setForm(applied); setKey(''); dirty.current = false; setSaved(true)
  }

  async function save(event) {
    event.preventDefault()
    setBusy(true); setSaved(false); setError('')
    try {
      if (provider === 'openai' && !configured && !key) throw new Error(method === 'device' ? 'Complete device login first.' : 'Enter an API key for API-key authentication.')
      if (key) await api.action({ 'set-key': { provider: credentialSlot(provider, method), key } })
      await persist(form)
      await status.refresh(); void catalog.refresh()
    } catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }

  async function acceptCredential({ token, refreshToken = '', account = '' }) {
    setBusy(true); setError(''); dirty.current = true
    try {
      await api.action({ 'set-key': { provider: credentialSlot(provider, 'device'), key: token } })
      if (refreshToken) await api.action({ 'set-key': { provider: `${provider}-refresh`, key: refreshToken } })
      if (provider === 'openai') await api.action({ 'set-key': { provider: 'openai-account', key: account } })
      // A completed login commits its matching route, not just its credential.
      // Account identity stays in credential storage, out of conversation logs.
      await persist(withAuth(form, provider, 'device'))
      await status.refresh(); void catalog.refresh()
    } finally { setBusy(false) }
  }

  return <form className="settings-grid" onSubmit={save}>
    {(error || session.error || status.error) && <div className="inline-error">{error || session.error || status.error}</div>}
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>{details.title}</h2><p>{details.copy}</p></div><span className={`status ${configured ? 'good' : ''}`}>{configured ? 'credential configured' : 'credential needed'}</span></div>
      <ProviderRoute provider={provider} value={form} onChange={edit} />
      {provider === 'openai' && method === 'device' && <OpenAIDeviceLogin onCredential={acceptCredential} />}
      {provider === 'anthropic' && method === 'device' && <AnthropicDeviceLogin onCredential={acceptCredential} />}
      {method === 'api-key' && <label><span>{provider === 'custom' ? 'Bearer token (optional)' : 'API key'}</span><input type="password" autoComplete="off" value={key} onChange={(event) => { dirty.current = true; setKey(event.target.value) }} placeholder={details.placeholder} /></label>}
      <label><span>Model</span><input list={`provider-models-${provider}`} value={form.model || ''} onChange={(event) => edit({ ...form, model: event.target.value })} placeholder={details.model || 'model-name'} /><datalist id={`provider-models-${provider}`}>{catalog.models.map((name) => <option key={name} value={name} />)}</datalist></label>
      {catalog.loading && <p className="field-note">Loading the provider’s model catalog…</p>}
      {catalog.error && provider !== 'custom' && <p className="field-note">Catalog unavailable: {catalog.error}. You can still type a model name.</p>}
      {catalog.contextFor(form.model) && <p className="field-note">Provider reports a {catalog.contextFor(form.model).toLocaleString()} token context window. It will be applied when you save.</p>}
      <HeaderEditor value={form.headers || []} onChange={(headers) => edit({ ...form, headers })} />
    </section>
    <div className="save-bar"><span>{saved ? 'Saved.' : resources.chat ? 'Saving selects this provider and authentication for the conversation.' : 'Saving selects this provider and authentication for new conversations.'}</span><button className="button primary" disabled={busy || session.loading}>{busy ? 'Saving…' : `Save ${details.title}`}</button></div>
  </form>
}
