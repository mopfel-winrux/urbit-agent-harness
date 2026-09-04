import { useEffect, useMemo, useRef, useState } from 'react'
import { acp } from '../acp'
import { MoonIcon, SendIcon, SettingsIcon, StopIcon } from './Icons'

function ToolEntry({ entry }) {
  return <div className={`tool-entry ${entry.status === 'in_progress' ? 'running' : 'complete'}`}>
    <div><span className="tool-dot" /><strong>{entry.title || 'tool'}</strong><small>{entry.status === 'in_progress' ? 'call' : 'result'}</small></div>
    <pre>{typeof entry.body === 'string' ? entry.body : JSON.stringify(entry.body ?? {}, null, 2)}</pre>
  </div>
}

function ThinkingMessage({ streaming }) {
  return <article className={`message assistant thinking-message ${streaming ? 'streaming' : ''}`} aria-live="polite">
    <div className="message-label">harness</div>
    <div className="message-body">{streaming || <span className="thinking-dots" aria-label="Thinking"><i /><i /><i /></span>}</div>
  </article>
}

function Transcript({ entries, pending, thinking, streaming }) {
  if (!entries.length && !pending && !thinking) return <div className="empty-chat">
    <div className="empty-orbit"><span /></div>
    <span className="eyebrow">New conversation</span>
    <h2>What should we work on?</h2>
    <p>Start a conversation, inspect tool work as it happens, and return whenever you like.</p>
  </div>
  return <>{entries.map((entry, index) => entry.type === 'tool'
    ? <ToolEntry key={entry.id || index} entry={entry} />
    : <article className={`message ${entry.role}`} key={entry.id || index}>
      <div className="message-label">{entry.role === 'assistant' ? 'harness' : entry.role}</div>
      <div className="message-body">{entry.body}</div>
    </article>)}{pending && <article className="message user pending">
      <div className="message-label">user</div><div className="message-body">{pending.text}</div>
    </article>}{thinking && <ThinkingMessage streaming={streaming} />}</>
}

function textContent(content) {
  if (content?.type === 'text') return content.text || ''
  return typeof content === 'string' ? content : JSON.stringify(content ?? '')
}

export default function Chat({ chat, theme, onToggleTheme, onSettings }) {
  const [entries, setEntries] = useState([])
  const [draft, setDraft] = useState('')
  const [pending, setPending] = useState(null)
  const [streaming, setStreaming] = useState('')
  const [state, setState] = useState('loading')
  const [error, setError] = useState('')
  const bottom = useRef(null)
  const busy = state === 'loading' || state === 'prompting'
  const statusLabel = useMemo(() => state === 'loading' ? 'loading' : state === 'prompting' ? 'thinking' : 'idle', [state])

  useEffect(() => {
    let live = true
    setEntries([]); setDraft(''); setPending(null); setStreaming(''); setError(''); setState('loading')
    const update = (event) => {
      const params = event.detail
      if (!live || params?.sessionId !== chat) return
      const value = params.update || {}
      if (value.sessionUpdate === 'user_message_chunk') {
        const body = textContent(value.content).replace(/\n$/, '')
        setEntries((old) => [...old, { role: 'user', body }])
        setPending((current) => current && current.text.trimEnd() === body.trimEnd() ? null : current)
      } else if (value.sessionUpdate === 'agent_message_chunk') {
        setStreaming('')
        setEntries((old) => [...old, { role: 'assistant', body: textContent(value.content) }])
      } else if (value.sessionUpdate === 'harness_agent_stream_chunk') {
        setStreaming((old) => old + textContent(value.content))
      } else if (value.sessionUpdate === 'tool_call') {
        setEntries((old) => [...old, { type: 'tool', id: value.toolCallId, title: value.title, status: value.status, body: value.rawInput }])
      } else if (value.sessionUpdate === 'tool_call_update') {
        const body = value.content?.map((part) => textContent(part.content)).join('\n') || ''
        setEntries((old) => {
          const found = old.some((entry) => entry.id === value.toolCallId)
          return found ? old.map((entry) => entry.id === value.toolCallId ? { ...entry, status: value.status, body } : entry) : [...old, { type: 'tool', id: value.toolCallId, status: value.status, body }]
        })
      }
    }
    const transportError = (event) => live && setError(event.detail?.message || 'ACP transport error')
    const transportReady = () => live && setError('')
    acp.addEventListener('session/update', update)
    acp.addEventListener('transport-error', transportError)
    acp.addEventListener('transport-ready', transportReady)
    void acp.start().then(() => acp.call('session/load', { sessionId: chat, cwd: '/', mcpServers: [] })).then(() => {
      if (live) setState('idle')
    }).catch((cause) => { if (live) { setError(cause.message); setState('idle') } })
    return () => {
      live = false
      acp.removeEventListener('session/update', update)
      acp.removeEventListener('transport-error', transportError)
      acp.removeEventListener('transport-ready', transportReady)
    }
  }, [chat])

  useEffect(() => { bottom.current?.scrollIntoView({ block: 'end' }) }, [entries.length, pending, state, streaming])

  async function send(event) {
    event.preventDefault()
    const text = draft.trim()
    if (!text || busy) return
    const pendingId = crypto.randomUUID()
    setDraft(''); setPending({ id: pendingId, text }); setStreaming(''); setError(''); setState('prompting')
    try {
      await acp.call('session/prompt', { sessionId: chat, prompt: [{ type: 'text', text }] })
    } catch (cause) {
      setDraft(text); setPending(null); setError(cause.message)
    } finally {
      setPending((current) => current?.id === pendingId ? null : current)
      setStreaming('')
      setState('idle')
    }
  }

  async function stop() {
    setError('')
    try { await acp.notify('session/cancel', { sessionId: chat }) }
    catch (cause) { setError(cause.message) }
  }

  return <main className="workspace chat-workspace">
    <header className="topbar">
      <div className="chat-heading"><div><strong>{chat}</strong></div><div className={`run-status ${state}`}><span />{statusLabel}</div></div>
      <div className="topbar-actions">
        <button className="icon-button" onClick={onSettings} title="Conversation settings"><SettingsIcon /></button>
        <button className="icon-button" onClick={onToggleTheme} title={`Use ${theme === 'dark' ? 'light' : 'dark'} theme`}><MoonIcon /></button>
      </div>
    </header>
    {error && <div className="error-banner">{error}</div>}
    <section className="transcript"><div className="transcript-inner"><Transcript entries={entries} pending={pending} thinking={state === 'prompting'} streaming={streaming} /><div ref={bottom} /></div></section>
    <div className="composer-wrap"><form className="composer" onSubmit={send}>
      <textarea value={draft} onChange={(event) => setDraft(event.target.value)} onKeyDown={(event) => {
        if (event.key === 'Enter' && !event.shiftKey) { event.preventDefault(); event.currentTarget.form.requestSubmit() }
      }} placeholder={state === 'loading' ? 'Loading conversation…' : state === 'prompting' ? 'Prepare your next message…' : 'Message your harness…'} disabled={state === 'loading'} rows={1} />
      {state === 'prompting' ? <button type="button" className="composer-button stop" onClick={stop} title="Interrupt"><StopIcon /></button> : <button className="composer-button" disabled={!draft.trim() || busy} title="Send"><SendIcon /></button>}
    </form><small>Enter to send · Shift+Enter for a new line</small></div>
  </main>
}
