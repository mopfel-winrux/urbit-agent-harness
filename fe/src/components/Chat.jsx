import { useEffect, useRef, useState } from 'react'
import { useSession } from '../useSession'
import Transcript from './Transcript'
import { MoonIcon, SendIcon, SettingsIcon, StopIcon } from './Icons'

export default function Chat({ chat, theme, onToggleTheme, onSettings, onFork, onSelect }) {
  const session = useSession(chat)
  const { snapshot, pending, busy, loading, error } = session
  const [draft, setDraft] = useState('')
  const bottom = useRef(null)
  const transcript = useRef(null)
  const follow = useRef(true)
  const phase = loading ? 'loading' : busy && snapshot.phase === 'idle' ? 'thinking' : snapshot.phase
  const entries = snapshot?.entries || []

  useEffect(() => {
    if (follow.current) bottom.current?.scrollIntoView({ block: 'end' })
  }, [entries, pending, busy, snapshot?.streaming])

  function send(event) {
    event.preventDefault()
    const text = draft.trim()
    if (!text || busy || loading) return
    follow.current = true
    setDraft('')
    void session.send(text)
  }

  return <main className="workspace chat-workspace">
    <header className="topbar">
      <div className="chat-heading"><div><strong>{chat}</strong>{snapshot?.model && <small>{snapshot.model}</small>}</div><div className={`run-status ${busy ? 'prompting' : phase}`}><span />{phase}</div></div>
      <div className="topbar-actions">
        <button className="icon-button" onClick={onSettings} title="Conversation settings"><SettingsIcon /></button>
        <button className="icon-button" onClick={onToggleTheme} title={`Use ${theme === 'dark' ? 'light' : 'dark'} theme`}><MoonIcon /></button>
      </div>
    </header>
    {error && <div className="error-banner">{error} <button className="text-button" onClick={session.refresh}>Refresh</button></div>}
    <section className="transcript" ref={transcript} onScroll={() => {
      const el = transcript.current
      follow.current = el.scrollHeight - el.scrollTop - el.clientHeight < 96
    }}><div className="transcript-inner">
      {snapshot?.origin && <p className="branch-origin">Branched from <button className="text-button" onClick={() => onSelect(snapshot.origin.sessionId)}>{snapshot.origin.sessionId}</button></p>}
      <Transcript items={entries} pending={pending} thinking={busy} streaming={snapshot?.streaming} phase={phase} onFork={onFork} />
      <div ref={bottom} />
    </div></section>
    <div className="composer-wrap"><form className="composer" onSubmit={send}>
      <textarea aria-label="Message" value={draft} onChange={(event) => setDraft(event.target.value)} onKeyDown={(event) => {
        if (event.key === 'Enter' && !event.shiftKey && !event.nativeEvent.isComposing) { event.preventDefault(); event.currentTarget.form.requestSubmit() }
      }} placeholder={loading ? 'Loading conversation…' : busy ? 'Prepare your next message…' : 'Message your harness…'} disabled={loading} rows={1} />
      {busy ? <button type="button" className="composer-button stop" onClick={session.stop} title="Interrupt"><StopIcon /></button> : <button className="composer-button" disabled={!draft.trim() || loading} title="Send"><SendIcon /></button>}
    </form><small>Enter to send · Shift+Enter for a new line{snapshot?.usage?.completion > 0 && ` · ${snapshot.usage.completion.toLocaleString()} output tokens`}{snapshot?.compactions > 0 && ` · ${snapshot.compactions} context summaries`}</small></div>
  </main>
}
