import { useEffect, useRef, useState } from 'react'
import { api } from '../api'
import { useResource } from '../useResource'
import { BackIcon } from './Icons'
import ShipPicker from './ShipPicker'
import ToolOptions from './ToolOptions'
import TlonIcon from './TlonIcon'
import TlonProfile from './TlonProfile'

const initial = { enabled: false, owner: null, mentions: true, trusted: [] }
export default function TlonSettings({ onBack }) {
  const state = useResource('tlon', null)
  const contacts = useResource('tlon/contacts', [], 30_000)
  const tools = useResource('tools', [])
  const [policy, setPolicy] = useState(initial)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [saved, setSaved] = useState(false)
  const dirty = useRef(false)
  useEffect(() => { if (state.value?.policy && !dirty.current) setPolicy(state.value.policy) }, [state.value])
  const change = (patch) => { dirty.current = true; setSaved(false); setPolicy((old) => ({ ...old, ...patch })) }
  function toggleTool(ship, name) {
    change({ trusted: policy.trusted.map((entry) => entry.ship !== ship ? entry : { ...entry,
      tools: entry.tools.includes(name) ? entry.tools.filter((tool) => tool !== name) : [...entry.tools, name],
    }) })
  }
  async function save(event) {
    event.preventDefault(); setBusy(true); setError('')
    try {
      const result = await api.action({ tlon: policy })
      state.setValue(result); setPolicy(result.policy); dirty.current = false; setSaved(true)
    } catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }
  return <main className="workspace settings-workspace">
    <header className="topbar"><button className="back-button" onClick={onBack}><BackIcon />Conversations</button></header>
    <div className="settings-content">
      <div className="page-header"><span className="eyebrow">Conversation hand</span><h1><TlonIcon /> Tlon</h1><p>Talk with the harness through DMs, groups, and threads.</p></div>
      <TlonProfile />
      <form className="settings-grid" onSubmit={save}>
        {(error || state.error || state.value?.error) && <div role="alert" className="inline-error">{error || state.error || state.value.error}</div>}
        <section className="panel settings-panel">
          <div className="section-title"><div><h2>Connection</h2><p>{state.value?.connected ? 'Listening to Tlon activity.' : policy.enabled ? 'Connecting to Tlon activity…' : 'Enable when your owner and permissions are ready.'}</p></div></div>
          <label className="tool-option"><input type="checkbox" checked={policy.enabled} onChange={(e) => change({ enabled: e.target.checked })} /><span><strong>Enable Tlon hand</strong><small>Reply only to your owner and trusted ships.</small></span></label>
          <label className="tool-option"><input type="checkbox" checked={policy.mentions} onChange={(e) => change({ mentions: e.target.checked })} /><span><strong>Require channel mentions</strong><small>DMs and replies to the bot’s posts do not need a mention.</small></span></label>
        </section>
        <section className="panel settings-panel">
          <div className="section-title"><div><h2>Owner</h2><p>Full tool access. Group invitations from this ship are accepted automatically.</p></div></div>
          <ShipPicker label="Owner ship" value={policy.owner || ''} contacts={contacts.value || []} onChange={(owner) => change({ owner, trusted: policy.trusted.filter((entry) => entry.ship !== owner) })} />
          {contacts.error && <p className="field-note">Contacts unavailable; you can still select a valid @p.</p>}
        </section>
        <section className="panel settings-panel">
          <div className="section-title"><div><h2>Trusted ships</h2><p>Can chat and start DMs. Tools start off; grant only what each person needs. Channel replies are visible to other members.</p></div></div>
          <ShipPicker label="Add a trusted ship" contacts={contacts.value || []} exclude={[policy.owner, ...policy.trusted.map((entry) => entry.ship)]} onChange={(ship) => change({ trusted: [...policy.trusted, { ship, tools: [] }] })} />
          {policy.trusted.map((entry) => <details className="trusted-ship" key={entry.ship}>
            <summary>{contacts.value?.find((p) => p.ship === entry.ship)?.nickname || entry.ship} <small>{entry.ship} · {entry.tools.length} tools</small></summary>
            <ToolOptions available={tools.value || []} selected={entry.tools} onChange={(name) => toggleTool(entry.ship, name)} />
            <button type="button" className="text-button" onClick={() => change({ trusted: policy.trusted.filter((p) => p.ship !== entry.ship) })}>Remove {entry.ship}</button>
          </details>)}
        </section>
        <div className="save-bar"><span>{saved ? 'Saved.' : 'Permission changes stop active Tlon work and start fresh sessions.'}</span><button className="button primary" disabled={busy || state.loading || (policy.enabled && !policy.owner)}>{busy ? 'Saving…' : 'Save Tlon settings'}</button></div>
      </form>
    </div>
  </main>
}
