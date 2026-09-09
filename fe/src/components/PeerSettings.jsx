import { useEffect, useId, useRef, useState } from 'react'
import { api } from '../api'
import { defaultConfig } from '../defaults'
import { useResource } from '../useResource'
import { useProviderModels } from '../useProviderModels'
import { PROVIDERS, providerOf } from '../providers'
import { authMethod, withAuth, chooseProvider, catalogEndpoint } from '../providerConfig'
import { emptyPeers, effectivePeers, editPeer, peerPayload } from '../peers'
import ShipPicker from './ShipPicker'
import ToolOptions, { toggleGrant } from './ToolOptions'
import PeerTokenLimit from './PeerTokenLimit'
import ProviderRoute from './ProviderRoute'
import HeaderEditor from './HeaderEditor'
import OwnerSettings from './OwnerSettings'
import RemotePeerAccess from './RemotePeerAccess'

export default function PeerSettings() {
  const stored = useResource('peers', emptyPeers())
  const defaults = useResource('defaults', defaultConfig())
  const contacts = useResource('tlon/contacts', [], 30_000)
  const tools = useResource('tools', [])
  const mcp = useResource('mcp', [])
  const skills = useResource('skills', [])
  const openai = useResource('status/openai', {})
  const [form, setForm] = useState(emptyPeers)
  const [busy, setBusy] = useState(false)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState('')
  const dirty = useRef(false)
  const modelId = useId()
  const config = form.config || defaults.value
  const provider = providerOf(config.url)
  const catalog = useProviderModels(provider, catalogEndpoint(provider, config))
  const unavailable = stored.loading || defaults.loading || !!stored.error || !!defaults.error
  useEffect(() => { if (!dirty.current && stored.value) setForm(stored.value) }, [stored.value])
  const liveForm = { ...form, owners: stored.value?.owners || [], trusted: stored.value?.trusted || [] }
  const change = (next) => { dirty.current = true; setSaved(false); setForm(next) }
  const edit = (ship, patch) => change(editPeer(liveForm, ship, patch))
  const modelChange = (next) => change({ ...form, config: withAuth({ ...next, key: '', tools: [] }, providerOf(next.url), authMethod(providerOf(next.url), next)) })
  const peers = effectivePeers(liveForm)
  async function reload() {
    dirty.current = false; setError(''); setSaved(false)
    await Promise.all([stored.refresh(), defaults.refresh()])
  }
  async function save(event) {
    event.preventDefault()
    if (busy || unavailable) return
    setBusy(true); setError(''); setSaved(false)
    try {
      const applied = await api.action({ peers: peerPayload(form) })
      stored.setValue(applied); setForm(applied); dirty.current = false; setSaved(true)
    } catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }
  return <div className="settings-grid">
    <OwnerSettings contacts={contacts} onSaved={() => void stored.refresh()} />
    <RemotePeerAccess />
    <form className="settings-grid" onSubmit={save}>
    {(error || stored.error || defaults.error) && <div className="inline-error" role="alert">{error || stored.error || defaults.error}<button type="button" className="text-button" disabled={busy} onClick={reload}>Reload saved peer settings (discard edits)</button></div>}
    {stored.loading && <p role="status">Loading peer access…</p>}
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Incoming peer access</h2><p>These ships can ask the agent or call granted tools directly on {form.ship || 'this ship'}. Direct tool calls do not add a serving-model turn. Owners and Tlon trusted ships are included automatically.</p></div></div>
      <p className="field-note">To ask another ship, its owner must grant your ship access there. Adding it here only allows incoming requests.</p>
      <fieldset disabled={busy || unavailable} className="memory-model-fields">
        <ShipPicker label="Add a peer ship" contacts={contacts.value || []} exclude={[form.ship, ...peers.map((entry) => entry.ship)]} onChange={(ship) => edit(ship, {})} />
        {contacts.error && <p className="field-note">Contacts unavailable; enter the ship’s full @p.</p>}
        {!peers.length && !stored.loading && <p>No peer ships allowed yet. Add one here or in <a href="#/tlon">Tlon → Trusted ships</a>.</p>}
        {peers.map((entry) => <details className="trusted-ship" key={entry.ship}>
          <summary>{entry.ship}<small>{entry.owner ? 'Owner · full admin' : entry.inherited ? entry.overridden ? 'Tlon trust · custom peer grant' : 'Tlon trust' : 'Explicit peer grant'} · {Number(entry.budget) === 0 ? 'No token limit' : `${Number(entry.budget).toLocaleString()} tokens`}</small></summary>
          <div className="peer-grant-fields">
            {entry.owner ? <p className="field-note">Full administrative access, all shared skills, and default resources. Change ownership above to remove admin access; ordinary peer grants cannot restrict an owner.</p> : <>
            {entry.inherited && <p className="field-note">{entry.overridden ? 'This custom grant overrides inherited Tlon resource access. Removing Tlon trust will not remove this explicit grant.' : 'Resource access follows this ship’s Tlon grants. Removing Tlon trust removes this inherited access.'}</p>}
            <div className="two-fields">
              <PeerTokenLimit ship={entry.ship} value={entry.budget} resource={stored} disabled={busy || unavailable} onChange={(budget) => edit(entry.ship, { budget })} />
              <label><span>Model override</span><input value={entry.model || ''} placeholder="Use serving model" aria-label={`Model override for ${entry.ship}`} onChange={(event) => edit(entry.ship, { model: event.target.value || null })} /><small className="field-note">Optional model ID on the serving provider.</small></label>
            </div>
            <ToolOptions available={(tools.value || []).filter((name) => !['author', 'skill-write', 'corpus'].includes(name))} selected={entry.tools} servers={mcp.value || []} onChange={(grant) => edit(entry.ship, { tools: toggleGrant(entry.tools, grant) })} />
            {tools.error && <p className="field-note">Tool catalog unavailable. Existing grants are preserved.</p>}
            <fieldset className="peer-skills"><legend>Shared skills</legend>
              {[...new Set([...(skills.value || []).map((skill) => skill.name), ...entry.inflows])].map((name) => <label className="tool-option" key={name}><input type="checkbox" checked={entry.inflows.includes(name)} onChange={() => edit(entry.ship, { inflows: entry.inflows.includes(name) ? entry.inflows.filter((item) => item !== name) : [...entry.inflows, name] })} /><span>{name}</span></label>)}
              {!skills.value?.length && !entry.inflows.length && <p className="field-note">No saved skills to share. Peer conversations do not see the rest of your skill library.</p>}
            </fieldset>
            {entry.overridden || entry.limited ? <button type="button" className="text-button danger-text" onClick={() => change({ ...form, grants: form.grants.filter((grant) => grant.ship !== entry.ship), limits: (form.limits || []).filter((limit) => limit.ship !== entry.ship) })}>{entry.inherited ? `Reset ${entry.ship} to trusted defaults` : `Revoke ${entry.ship}`}</button>
              : <p className="field-note">Remove this ship in <a href="#/tlon">Tlon settings</a> to revoke inherited access.</p>}
            </>}
          </div>
        </details>)}
      </fieldset>
    </section>
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Serving model</h2><p>Answers incoming peer requests in a separate conversation for each ship. Provider credentials come from Providers settings; tools come from that peer’s grant.</p></div></div>
      <fieldset disabled={busy || unavailable} className="memory-model-fields">
        <label className="tool-option"><input type="checkbox" checked={!form.config} onChange={(event) => change({ ...form, config: event.target.checked ? null : { ...defaults.value, key: '', tools: [] } })} /><span><strong>Use global defaults</strong><small>{defaults.value.model || 'No default model selected'}. Follows future default model changes.</small></span></label>
        {form.config && <>
          <div className="two-fields">
            <label><span>Provider</span><select value={provider} onChange={(event) => modelChange(chooseProvider(config, event.target.value, event.target.value === 'openai' ? openai.value?.['auth-method'] : 'api-key'))}>{Object.entries(PROVIDERS).map(([id, item]) => <option key={id} value={id}>{item.title}</option>)}</select></label>
            <label><span>Serving model</span><input required list={modelId} value={config.model} onChange={(event) => modelChange({ ...config, model: event.target.value, 'max-context': catalog.contextFor(event.target.value) || 80_000 })} /><datalist id={modelId}>{catalog.models.map((model) => <option key={model} value={model} />)}</datalist></label>
          </div>
          <ProviderRoute provider={provider} value={config} onChange={modelChange} />
          {catalog.error && <p className="field-note">Model catalog unavailable; you can enter a model ID.</p>}
          <HeaderEditor value={config.headers || []} onChange={(headers) => modelChange({ ...config, headers })} />
          <label><span>Peer system instructions</span><textarea rows="5" value={config.system || ''} onChange={(event) => modelChange({ ...config, system: event.target.value })} /></label>
        </>}
      </fieldset>
    </section>
    <div className="save-bar"><span role="status">{saved ? 'Peer settings saved.' : dirty.current ? 'Unsaved peer changes.' : 'Changes apply to the next peer request. Token limits do not reset past usage.'}</span><button className="button primary" disabled={busy || unavailable}>{busy ? 'Saving…' : 'Save peer settings'}</button></div>
    </form>
  </div>
}
