import { useState } from 'react'

const clean = (value) => value.toLowerCase().replace(/[^a-z0-9-]/g, '-').replace(/^-+|-+$/g, '').slice(0, 64)

export default function ConversationModal({ mode, initialName, onClose, onSave }) {
  const [name, setName] = useState(initialName)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const normalized = clean(name)
  const rename = mode === 'rename'

  async function submit(event) {
    event.preventDefault()
    if (!normalized || (rename && normalized === initialName)) return
    setBusy(true); setError('')
    try { await onSave(normalized); onClose() } catch (cause) { setError(cause.message); setBusy(false) }
  }

  return <div className="modal-backdrop" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
    <section className="modal-card" role="dialog" aria-modal="true" aria-labelledby="conversation-dialog-title">
      <header><div><span className="eyebrow">Conversation</span><h1 id="conversation-dialog-title">{mode === 'fork' ? 'Branch conversation' : rename ? 'Rename conversation' : 'New conversation'}</h1></div><button className="close-button" onClick={onClose} aria-label="Close">×</button></header>
      <form onSubmit={submit}>
        <label><span>Name</span><input autoFocus value={name} onChange={(event) => setName(event.target.value)} placeholder="research-notes" /></label>
        {name && normalized !== name && <small className="field-note">Will be saved as <code>{normalized || '…'}</code></small>}
        {error && <div className="inline-error">{error}</div>}
        <div className="form-actions"><button type="button" className="button ghost" onClick={onClose}>Cancel</button><button className="button primary" disabled={busy || !normalized || (rename && normalized === initialName)}>{busy ? 'Saving…' : rename ? 'Rename' : 'Create'}</button></div>
      </form>
    </section>
  </div>
}
