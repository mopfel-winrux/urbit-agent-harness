import { useEffect, useRef, useState } from 'react'
import { api } from '../api'
import { useResource } from '../useResource'

// A view of Contacts, not another identity store. Refresh external edits while
// idle, but never replace a draft (including deliberately cleared fields).
export default function TlonProfile() {
  const profile = useResource('tlon/profile', null, 5000)
  const [draft, setDraft] = useState({ nickname: '', avatar: '' })
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [saved, setSaved] = useState(false)
  const dirty = useRef(false)
  useEffect(() => {
    if (profile.value && !dirty.current) setDraft(profile.value)
  }, [profile.value])
  function change(field, value) {
    dirty.current = true; setSaved(false)
    setDraft((old) => ({ ...old, [field]: value }))
  }
  async function save(event) {
    event.preventDefault(); setBusy(true); setError(''); setSaved(false)
    try {
      const result = await api.action({ tlonProfile: draft })
      profile.setValue(result); setDraft(result); dirty.current = false; setSaved(true)
    } catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }
  return <form className="panel settings-panel tlon-profile" onSubmit={save}>
    <div className="section-title"><div><h2>Bot profile</h2><p>This ship’s public profile, shared with Contacts and Tlon.</p></div></div>
    {(error || profile.error) && <p role="alert" className="inline-error">{error || profile.error}</p>}
    <fieldset disabled={busy || profile.loading || !profile.value}>
      <label>Nickname<input value={draft.nickname} maxLength={64} onChange={(event) => change('nickname', event.target.value)} autoComplete="off" /></label>
      <label>Avatar URL<input type="url" value={draft.avatar} maxLength={2048} placeholder="https://…" onChange={(event) => change('avatar', event.target.value)} /></label>
    </fieldset>
    <div className="save-bar"><span>{saved ? 'Profile saved.' : 'Leave a field empty to clear it.'}</span><button className="button primary" disabled={busy || profile.loading || !profile.value}>{busy ? 'Saving…' : 'Save profile'}</button></div>
  </form>
}
