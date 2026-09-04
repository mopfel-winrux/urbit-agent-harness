import { useEffect, useMemo, useRef, useState } from 'react'
import { api, waitFor } from '../api'
import { useGrub } from '../useGrub'
import { MoonIcon, SendIcon, StopIcon } from './Icons'

function ToolEntry({ entry }) {
  const use = entry.type === 'tool_use'
  const title = use ? entry.name || 'tool' : 'tool result'
  const body = use ? entry.input : entry.content ?? entry.text
  return <div className={`tool-entry ${use ? 'running' : 'complete'}`}>
    <div><span className="tool-dot" /><strong>{title}</strong><small>{use ? 'call' : 'result'}</small></div>
    <pre>{typeof body === 'string' ? body : JSON.stringify(body ?? {}, null, 2)}</pre>
  </div>
}

function Transcript({ entries }) {
  if (!entries.length) return <div className="empty-chat">
    <div className="empty-orbit"><span /></div>
    <span className="eyebrow">A durable conversation</span>
    <h2>What should we work on?</h2>
    <p>Start a conversation, inspect tool work as it happens, and return whenever you like.</p>
  </div>

  return entries.map((entry, index) => {
    if (entry?.type?.startsWith('tool_')) return <ToolEntry key={`${index}-${entry.id || entry.tool_use_id || ''}`} entry={entry} />
    const role = entry?.role || 'system'
    return <article className={`message ${role}`} key={`${index}-${role}`}>
      <div className="message-label">{role === 'assistant' ? 'harness' : role}</div>
      <div className="message-body">{String(entry?.content ?? '')}</div>
    </article>
  })
}

export default function Chat({ chat, roads, theme, onToggleTheme }) {
  const transcript = useGrub(roads.transcript, [])
  const status = useGrub(roads.status, { state: 'idle' })
  const [draft, setDraft] = useState('')
  const [sending, setSending] = useState(false)
  const [actionError, setActionError] = useState('')
  const bottom = useRef(null)
  const entries = Array.isArray(transcript.value) ? transcript.value : []
  const activity = status.value?.state || 'idle'
  const busy = sending || activity !== 'idle'
  const statusLabel = useMemo(() => {
    if (sending && activity === 'idle') return 'admitting message'
    if (activity === 'api') return 'thinking'
    if (activity === 'tool') return 'using a tool'
    return 'idle'
  }, [activity, sending])

  useEffect(() => { bottom.current?.scrollIntoView({ block: 'end' }) }, [entries.length, chat])
  useEffect(() => { setDraft(''); setActionError(''); setSending(false) }, [chat])

  async function send(event) {
    event.preventDefault()
    const content = draft.trim()
    if (!content || busy) return
    setSending(true); setActionError('')
    const baseline = entries.length
    try {
      await api.poke(roads.transcript, { action: 'message', content })
      setDraft('')
      const next = await waitFor(
        () => api.read(roads.transcript),
        (value) => Array.isArray(value) && value.slice(baseline).some((entry) => entry?.role === 'user' && entry.content === content),
      )
      transcript.setValue(next)
      await status.refresh()
    } catch (cause) {
      setActionError(cause.message)
    } finally {
      setSending(false)
    }
  }

  async function stop() {
    setActionError('')
    try {
      const value = activity === 'tool' && status.value?.id
        ? { action: 'interrupt', id: status.value.id }
        : { action: 'interrupt' }
      await api.poke(roads.transcript, value)
    } catch (cause) { setActionError(cause.message) }
  }

  return <main className="workspace chat-workspace">
    <header className="topbar">
      <div className="chat-heading"><div><strong>{chat}</strong></div><div className={`run-status ${activity}`}><span />{statusLabel}</div></div>
      <button className="icon-button" onClick={onToggleTheme} title={`Use ${theme === 'dark' ? 'light' : 'dark'} theme`}><MoonIcon /></button>
    </header>
    {(transcript.error || status.error || actionError) && <div className="error-banner">{actionError || transcript.error || status.error}</div>}
    <section className="transcript"><div className="transcript-inner"><Transcript entries={entries} /><div ref={bottom} /></div></section>
    <div className="composer-wrap">
      <form className="composer" onSubmit={send}>
        <textarea value={draft} onChange={(event) => setDraft(event.target.value)} onKeyDown={(event) => {
          if (event.key === 'Enter' && !event.shiftKey) { event.preventDefault(); event.currentTarget.form.requestSubmit() }
        }} placeholder={busy ? `${statusLabel}…` : 'Message your harness…'} disabled={busy} rows={1} />
        {busy
          ? <button type="button" className="composer-button stop" onClick={stop} title="Interrupt"><StopIcon /></button>
          : <button className="composer-button" disabled={!draft.trim()} title="Send"><SendIcon /></button>}
      </form>
      <small>Enter to send · Shift+Enter for a new line</small>
    </div>
  </main>
}
