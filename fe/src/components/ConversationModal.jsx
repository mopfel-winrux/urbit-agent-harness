import { useLayoutEffect, useRef, useState } from 'react'

const clean = (value) => value.toLowerCase().replace(/[^a-z0-9-]/g, '-').replace(/^-+|-+$/g, '').slice(0, 64)

export default function ConversationModal({ mode, initialName, onClose, onSave }) {
  const [name, setName] = useState(initialName)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const dialog = useRef(null)
  const nameInput = useRef(null)
  useLayoutEffect(() => {
    const element = dialog.current
    const previous = document.activeElement
    element.showModal()
    nameInput.current.focus()
    return () => { element.close(); if (previous?.isConnected) previous.focus() }
  }, [])
  const normalized = clean(name)
  const rename = mode === 'rename'

  async function submit(event) {
    event.preventDefault()
    if (busy || !normalized || (rename && normalized === initialName)) return
    setBusy(true); setError('')
    try { await onSave(normalized); onClose() } catch (cause) { setError(cause.message); setBusy(false) }
  }

  return <dialog ref={dialog} className="conversation-dialog" aria-labelledby="conversation-dialog-title" onCancel={(event) => { event.preventDefault(); if (!busy) onClose() }} onMouseDown={(event) => { if (event.target === event.currentTarget && !busy) onClose() }}>
    <section className="modal-card">
      <header><div><span className="eyebrow">Conversation</span><h1 id="conversation-dialog-title">{mode === 'fork' ? 'Branch conversation' : rename ? 'Rename conversation' : 'New conversation'}</h1></div><button className="close-button" onClick={onClose} disabled={busy} aria-label="Close">×</button></header>
      <form onSubmit={submit}>
        <label><span>Name</span><input ref={nameInput} disabled={busy} value={name} onChange={(event) => setName(event.target.value)} placeholder="research-notes" /></label>
        {name && normalized !== name && <small className="field-note">Will be saved as <code>{normalized || '…'}</code></small>}
        {error && <div className="inline-error" role="alert">{error}</div>}
        <div className="form-actions"><button type="button" className="button ghost" disabled={busy} onClick={onClose}>Cancel</button><button className="button primary" disabled={busy || !normalized || (rename && normalized === initialName)}>{busy ? 'Saving…' : mode === 'fork' ? 'Branch' : rename ? 'Rename' : 'Create'}</button></div>
      </form>
    </section>
  </dialog>
}
