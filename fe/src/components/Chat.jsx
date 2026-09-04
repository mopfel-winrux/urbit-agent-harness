import { useEffect, useRef, useState } from 'react'
import { useSession } from '../useSession'
import Transcript from './Transcript'
import ChatComposer from './ChatComposer'
import { MoonIcon, SettingsIcon } from './Icons'

export default function Chat({ chat, theme, onToggleTheme, onSettings, onFork, onSelect }) {
  const session = useSession(chat)
  const { snapshot, pending, busy, loading, error } = session
  const [atBottom, setAtBottom] = useState(true)
  const transcript = useRef(null)
  const follow = useRef(true)
  const phase = loading ? 'loading' : busy && snapshot.phase === 'idle' ? 'thinking' : snapshot.phase
  const entries = snapshot?.entries || []

  useEffect(() => {
    if (follow.current) scrollToLatest()
  }, [entries, pending, busy, snapshot?.streaming])

  function scrollToLatest() {
    const element = transcript.current
    if (element) element.scrollTop = element.scrollHeight
    follow.current = true
    setAtBottom(true)
  }

  function send(text) {
    follow.current = true
    void session.send(text)
  }

  return <main className="workspace chat-workspace">
    <header className="topbar">
      <div className="chat-heading"><div><strong title={chat}>{chat}</strong>{snapshot?.model && <small title={snapshot.model}>{snapshot.model}</small>}</div><div className={`run-status ${busy ? 'prompting' : phase}`} aria-label={`Session ${phase}`}><span />{phase}</div></div>
      <div className="topbar-actions">
        <button className="icon-button" onClick={onSettings} title="Conversation settings" aria-label="Conversation settings"><SettingsIcon /></button>
        <button className="icon-button" onClick={onToggleTheme} title={`Theme: ${theme}. Change theme`} aria-label={`Theme: ${theme}. Change theme`}><MoonIcon /></button>
      </div>
    </header>
    {error && <div className="error-banner" role="alert">{error} <button className="text-button" onClick={session.refresh}>Refresh</button></div>}
    <div className="transcript-region"><section className="transcript" aria-label="Conversation messages" ref={transcript} onScroll={() => {
      const el = transcript.current
      follow.current = el.scrollHeight - el.scrollTop - el.clientHeight < 96
      setAtBottom(follow.current)
    }}><div className="transcript-inner">
      {snapshot?.origin && <p className="branch-origin">Branched from <button className="text-button" onClick={() => onSelect(snapshot.origin.sessionId)}>{snapshot.origin.sessionId}</button></p>}
      {loading ? <p className="transcript-loading" role="status">Loading conversation…</p> : <Transcript items={entries} pending={pending} thinking={busy} streaming={snapshot?.streaming} phase={phase} onFork={onFork} />}
    </div></section>
    {!atBottom && <button className="jump-to-latest" onClick={scrollToLatest}>↓ Latest messages</button>}
    </div>
    <ChatComposer busy={busy} loading={loading} usage={snapshot?.usage} compactions={snapshot?.compactions} onSend={send} onStop={session.stop} />
  </main>
}
