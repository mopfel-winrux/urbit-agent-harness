import { useId, useState } from 'react'
import { api } from '../api'
import { useResource } from '../useResource'

const emptySkill = () => ({ name: '', desc: '', body: '', revision: '' })

export default function SkillSettings() {
  const instructionsLabel = useId()
  const library = useResource('skills', [], 4000)
  const [skill, setSkill] = useState(emptySkill)
  const [dirty, setDirty] = useState(false)
  const [busy, setBusy] = useState(false)
  const [saved, setSaved] = useState('')
  const [error, setError] = useState('')
  const [confirmDelete, setConfirmDelete] = useState(false)
  const change = (field, value) => { setSkill((old) => ({ ...old, [field]: value })); setDirty(true); setSaved(''); setConfirmDelete(false) }

  async function open(name) {
    if (dirty && !window.confirm('Discard unsaved skill changes?')) return
    setBusy(true); setError(''); setSaved(''); setConfirmDelete(false)
    try { setSkill(name == null ? emptySkill() : await api.read(`skill/${name}`)); setDirty(false) }
    catch (cause) { setError(cause.message) }
    finally { setBusy(false) }
  }

  async function save(event) {
    event.preventDefault()
    setBusy(true); setError(''); setSaved('')
    try {
      const applied = await api.action({ saveSkill: { ...skill, name: skill.revision ? skill.name : skill.name.trim() } })
      setSkill(applied); setDirty(false); setSaved('Skill saved.')
      library.setValue([...library.value.filter((item) => item.name !== applied.name), { name: applied.name, desc: applied.desc }])
    } catch (cause) { setError(cause.message) }
    finally { setBusy(false) }
  }

  async function remove() {
    setBusy(true); setError(''); setSaved('')
    try {
      library.setValue(await api.action({ deleteSkill: { name: skill.name, revision: skill.revision } }))
      setSkill(emptySkill()); setDirty(false); setConfirmDelete(false); setSaved('Skill deleted.')
    } catch (cause) { setError(cause.message) }
    finally { setBusy(false) }
  }

  return <div className="settings-grid">
    {(error || library.error) && <div className="inline-error" role="alert">{error || library.error}</div>}
    <section className="panel settings-panel">
      <div className="section-title"><div><h2>Skill library</h2><p>Reusable instructions shared across conversations. Keep private notes and credentials out of this library.</p></div><button type="button" className="button" disabled={busy} onClick={() => void open(null)}>New skill</button></div>
      {library.loading ? <p role="status">Loading skills…</p> : library.value.length ? <div className="skill-list" aria-label="Saved skills">
        {[...library.value].sort((a, b) => a.name.localeCompare(b.name)).map((item) => <button type="button" key={item.name} className={`skill-list-item ${skill.revision && skill.name === item.name ? 'active' : ''}`} disabled={busy} onClick={() => void open(item.name)}><strong>{item.name}</strong><span>{item.desc || 'No description'}</span></button>)}
      </div> : <p className="field-note">No saved skills yet. Add instructions below.</p>}
    </section>
    <form className="panel settings-panel" onSubmit={save}>
      <div className="section-title"><div><h2>{skill.revision ? 'Edit skill' : 'New skill'}</h2><p>Conversations with Skills access can read these instructions when relevant. Saving does not change tool permissions.</p></div></div>
      <label><span>Skill name</span><input required maxLength={128} disabled={busy || !!skill.revision} value={skill.name} onChange={(event) => change('name', event.target.value)} placeholder="e.g. weekly-summary" /></label>
      <label><span>Description</span><input maxLength={1024} disabled={busy} value={skill.desc} onChange={(event) => change('desc', event.target.value)} placeholder="When should Harness use this skill?" /></label>
      <label><span id={instructionsLabel}>Instructions</span><textarea aria-labelledby={instructionsLabel} className="skill-instructions" required maxLength={65536} rows={14} disabled={busy} spellCheck={false} value={skill.body} onChange={(event) => change('body', event.target.value)} placeholder="Write or paste the skill instructions here. Plain text or Markdown is welcome." /></label>
      <div className="skill-editor-actions"><span role="status">{saved || (dirty ? 'Unsaved changes' : '')}</span><button className="button primary" disabled={busy || !dirty || !skill.name.trim() || !skill.body.trim()}>{busy ? 'Working…' : 'Save skill'}</button></div>
      {skill.revision && <div className="skill-editor-actions">{confirmDelete ? <><span>Delete this shared skill?</span><button type="button" className="text-button" disabled={busy} onClick={() => setConfirmDelete(false)}>Keep skill</button><button type="button" className="text-button danger-text" disabled={busy} onClick={() => void remove()}>Confirm delete</button></> : <button type="button" className="text-button danger-text" disabled={busy} onClick={() => setConfirmDelete(true)}>Delete skill</button>}</div>}
    </form>
  </div>
}
