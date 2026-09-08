import { useEffect, useRef, useState } from 'react'
import { api } from '../api'
import { useResource } from '../useResource'
import ShipPicker from './ShipPicker'

export default function OwnerSettings({ onSaved }) {
  const state = useResource('tlon', null)
  const contacts = useResource('tlon/contacts', [], 30_000)
  const [owner, setOwner] = useState(null)
  const [siblings, setSiblings] = useState(false)
  const [baseline, setBaseline] = useState(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [saved, setSaved] = useState(false)
  const dirty = useRef(false)
  useEffect(() => {
    if (!state.value?.policy || dirty.current) return
    setOwner(state.value.policy.owner)
    setSiblings(Boolean(state.value.siblingMoonOwners))
    setBaseline(state.value)
  }, [state.value])
  function change(fn) { dirty.current = true; setSaved(false); fn() }
  async function save(event) {
    event.preventDefault()
    if (busy || !baseline || state.error) return
    setBusy(true); setError(''); setSaved(false)
    try {
      const result = await api.action({ owner: { owner, expectedOwner: baseline.policy.owner,
        siblingMoonOwners: siblings, expectedSiblingMoonOwners: Boolean(baseline.siblingMoonOwners) } })
      dirty.current = false; state.setValue(result); setBaseline(result); setSaved(true)
      onSaved?.()
    } catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }
  return <form className="panel settings-panel" onSubmit={save}>
    <div className="section-title"><div><h2>Owner · full admin</h2><p>Can manage Harness settings, credentials, skills, conversations, and permissions through a direct peer request or owner DM. Group messages do not gain admin access. Ownership applies even when Tlon replies are off.</p></div></div>
    {state.loading && <p role="status">Loading ownership…</p>}
    {(error || state.error) && <div className="inline-error" role="alert">{error || state.error}<button type="button" className="text-button" disabled={busy} onClick={() => { dirty.current = false; setError(''); setSaved(false); void state.refresh() }}>Reload ownership (discard edits)</button></div>}
    <fieldset className="memory-model-fields" disabled={busy || state.loading || !!state.error || !baseline}>
      <ShipPicker label="Owner ship" value={owner || ''} contacts={contacts.value || []} exclude={[state.value?.ship]} onChange={(ship) => change(() => setOwner(ship))} />
      {contacts.error && <p className="field-note">Contacts unavailable; enter the full ship name.</p>}
      {owner && <button type="button" className="text-button danger-text" onClick={() => change(() => setOwner(null))}>Clear owner</button>}
      {state.value?.isMoon && <>
        <p className="field-note">This moon’s current sponsor is {state.value.sponsor}. The sponsor is selected as owner once by default. A replacement or cleared owner is preserved.</p>
        <label className="tool-option"><input type="checkbox" checked={siblings} onChange={(event) => change(() => setSiblings(event.target.checked))} /><span><strong>Make sibling moons full admins</strong><small>Off by default. Every other moon with the same current sponsor gains full administrative authority. This follows live sponsorship, including future changes.</small></span></label>
      </>}
      <p className="field-note">Owners have no peer token cap. Removing ownership does not remove a separately saved peer grant. Clearing all owners also disables Tlon replies.</p>
      <div className="save-bar"><span role="status">{saved ? 'Ownership saved.' : dirty.current ? 'Unsaved ownership changes.' : 'Only grant ownership to a ship you trust to administer Harness.'}</span><button className="button primary" disabled={busy || !dirty.current}>{busy ? 'Saving…' : 'Save ownership'}</button></div>
    </fieldset>
  </form>
}
