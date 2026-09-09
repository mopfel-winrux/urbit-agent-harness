import { useEffect, useRef, useState } from 'react'
import { api } from '../api'
import { useResource } from '../useResource'
import { BackIcon } from './Icons'
import ShipPicker from './ShipPicker'
import ToolOptions, { toggleGrant } from './ToolOptions'
import TlonIcon from './TlonIcon'
import TlonProfile from './TlonProfile'
import TlonModels from './TlonModels'
import TlonCron from './TlonCron'
import TlonWork from './TlonWork'
import PeerTokenLimit from './PeerTokenLimit'
import { emptyPeers, effectivePeers, applyPeerLimits } from '../peers'

const initial = { enabled: false, owner: null, mentions: true, trusted: [] }
export default function TlonSettings({ onBack }) {
  const state = useResource('tlon', null, 5000)
  const contacts = useResource('tlon/contacts', [], 30_000)
  const tools = useResource('tools', [])
  const mcp = useResource('mcp', [])
  const peers = useResource('peers', emptyPeers())
  const [peerEdits, setPeerEdits] = useState({})
  const [policy, setPolicy] = useState(initial)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [saved, setSaved] = useState(false)
  const dirty = useRef(false)
  const unavailable = state.loading || !!state.error
  const peerGrants = new Map(effectivePeers(peers.value).map((grant) => [grant.ship, grant]))
  useEffect(() => { if (state.value?.policy && !dirty.current) setPolicy(state.value.policy) }, [state.value])
  const change = (patch) => { dirty.current = true; setSaved(false); setPolicy((old) => ({ ...old, ...patch })) }
  function toggleTool(ship, name) {
    change({ trusted: policy.trusted.map((entry) => entry.ship !== ship ? entry : { ...entry,
      tools: toggleGrant(entry.tools, name),
    }) })
  }
  async function save(event) {
    event.preventDefault()
    if (busy || unavailable) return
    setBusy(true); setError(''); setSaved(false)
    let trustSaved = false
    try {
      const edits = Object.fromEntries(Object.entries(peerEdits).filter(([ship]) => policy.trusted.some((entry) => entry.ship === ship)))
      if (Object.keys(edits).length) applyPeerLimits(peers.value, edits)
      const result = await api.action({ tlon: policy })
      state.setValue(result); setPolicy(result.policy); dirty.current = false; trustSaved = true
      if (Object.keys(edits).length) {
        const current = await api.read('peers')
        const applied = await api.action({ peers: applyPeerLimits(current, edits) })
        peers.setValue(applied)
      }
      setPeerEdits({}); setSaved(true)
    } catch (cause) { setError(`${trustSaved ? 'Tlon trust saved, but peer token limits were not saved. ' : ''}${cause.message}`) } finally { setBusy(false) }
  }
  return <main className="workspace settings-workspace">
    <header className="topbar"><button className="back-button" onClick={onBack}><BackIcon />Conversations</button></header>
    <div className="settings-content">
      <div className="page-header"><h1><TlonIcon /> Tlon</h1><p>Talk with the harness through DMs, groups, and threads.</p></div>
      <form className="settings-grid" onSubmit={save}>
        {(error || state.error || state.value?.error) && <div role="alert" className="inline-error">{error || state.error || state.value.error}</div>}
        {state.error && <button type="button" className="text-button" disabled={busy} onClick={() => { dirty.current = false; void state.refresh() }}>Retry loading Tlon settings</button>}
        <fieldset className="memory-model-fields" disabled={busy || unavailable}>
        <section className="panel settings-panel">
          <div className="section-title"><div><h2>Connection</h2><p>{state.value?.connected ? 'Listening to Tlon activity.' : policy.enabled ? 'Connecting to Tlon activity…' : 'Enable when your owner and permissions are ready.'}</p></div></div>
          <label className="tool-option"><input type="checkbox" checked={policy.enabled} onChange={(e) => change({ enabled: e.target.checked })} /><span><strong>Enable Tlon replies</strong><small>Reply only to your owner and trusted ships.</small></span></label>
          <label className="tool-option"><input type="checkbox" checked={policy.mentions} onChange={(e) => change({ mentions: e.target.checked })} /><span><strong>Require channel mentions</strong><small>DMs and replies to the bot’s posts do not need a mention.</small></span></label>
        </section>
        <section className="panel settings-panel">
          <div className="section-title"><div><h2>Owner</h2><p>{policy.owner || 'No explicit owner selected.'}{state.value?.siblingMoonOwners ? ' Sibling moons are also full admins.' : ''} Owners can administer Harness through direct requests and owner DMs. Group invitations from owners are accepted automatically.</p></div></div>
          <a href="#/settings?tab=peers">Manage full-admin ownership in Settings → Peers</a>
        </section>
        <section className="panel settings-panel">
          <div className="section-title"><div><h2>Trusted ships</h2><p>Can chat, start DMs, use Tlon actions, and call this ship’s agent with ask_peer. Peer requests have no token cap by default. Resource grants below also apply to inherited peer access. Channel replies are visible to other members.</p></div></div>
          <ShipPicker label="Add a trusted ship" contacts={contacts.value || []} exclude={[policy.owner, ...policy.trusted.map((entry) => entry.ship)]} onChange={(ship) => change({ trusted: [...policy.trusted, { ship, tools: [] }] })} />
          {policy.trusted.map((entry) => <details className="trusted-ship" key={entry.ship}>
            <summary>{contacts.value?.find((p) => p.ship === entry.ship)?.nickname || entry.ship} <small>{entry.ship} · {peerGrants.get(entry.ship)?.owner ? 'Owner · full admin' : `${entry.tools.filter((tool) => !['tlon-read', 'tlon-write', 'cron'].includes(tool)).length} resource grants`}</small></summary>
            {peerGrants.get(entry.ship)?.owner ? <p className="field-note">Owners have no peer token cap, use default resources, and can administer Harness through direct requests or owner DMs. These ordinary trusted grants do not restrict ownership. <a href="#/settings?tab=peers">Manage ownership in Peers</a>.</p> : <>
            <div className="peer-grant-fields">
              <PeerTokenLimit ship={entry.ship} value={peerEdits[entry.ship]?.budget ?? peerGrants.get(entry.ship)?.budget ?? 0} resource={peers} disabled={busy || unavailable || peers.loading || !!peers.error}
                onChange={(budget) => {
                  setSaved(false)
                  setPeerEdits((old) => ({ ...old, [entry.ship]: { budget,
                    original: old[entry.ship] ? old[entry.ship].original : peers.value.grants.find((grant) => grant.ship === entry.ship) || null,
                    originalLimit: old[entry.ship] ? old[entry.ship].originalLimit : (peers.value.limits || []).find((limit) => limit.ship === entry.ship) || null,
                  } }))
                }} />
              {peerGrants.get(entry.ship)?.overridden && <p className="field-note">This ship also has an explicit peer grant in Settings → Peers. Removing Tlon trust does not revoke that separate grant.</p>}
            </div>
            <ToolOptions servers={mcp.value || []} available={(tools.value || []).filter((name) => !['author', 'skill-write'].includes(name))} selected={entry.tools} onChange={(name) => toggleTool(entry.ship, name)} />
            </>}
            <button type="button" className="text-button" onClick={() => change({ trusted: policy.trusted.filter((p) => p.ship !== entry.ship) })}>Remove {entry.ship}</button>
          </details>)}
          {peers.loading && <p role="status">Loading peer token limits…</p>}
          {peers.error && <p className="inline-error" role="alert">Peer token limits unavailable: {peers.error}</p>}
          {(peers.error || Object.keys(peerEdits).length > 0) && <button type="button" className="text-button" disabled={busy} onClick={() => { setPeerEdits({}); setSaved(false); void peers.refresh() }}>Reload peer limits (discard limit edits)</button>}
        </section>
        </fieldset>
        <p className="field-note">These permissions belong to Harness. Conversation tools cannot publish private material into the shared skill library.</p>
        <div className="save-bar"><span role="status">{saved ? 'Saved.' : Object.keys(peerEdits).length ? 'Unsaved peer token limits. Applies to the next peer request.' : 'Changed permissions stop affected Tlon work. Conversations and notes remain; unrelated chats continue.'}</span><button className="button primary" disabled={busy || unavailable || (policy.enabled && !policy.owner && !state.value?.siblingMoonOwners) || (Object.keys(peerEdits).length > 0 && (peers.loading || !!peers.error))}>{busy ? 'Saving…' : 'Save Tlon settings'}</button></div>
      </form>
      <div className="settings-group"><TlonProfile /><TlonModels sessions={state.value?.sessions} /><TlonCron /><TlonWork /></div>
    </div>
  </main>
}
