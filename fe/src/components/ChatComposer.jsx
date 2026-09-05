import { useLayoutEffect, useRef, useState } from 'react'
import { SendIcon, StopIcon } from './Icons'

export default function ChatComposer({ busy, loading, usage, compactions, onSend, onStop }) {
  const [draft, setDraft] = useState('')
  const isStop = draft.trim() === '/stop'
  const input = useRef(null)
  useLayoutEffect(() => {
    const element = input.current
    element.style.height = 'auto'
    element.style.height = `${Math.min(element.scrollHeight, 180)}px`
  }, [draft])

  function send(event) {
    event.preventDefault()
    const text = draft.trim()
    if (!text || (busy && !isStop) || loading) return
    setDraft('')
    onSend(text)
    input.current.focus()
  }

  return <div className="composer-wrap"><form className="composer" onSubmit={send}>
    <textarea ref={input} aria-label="Message" value={draft} onChange={(event) => setDraft(event.target.value)} onKeyDown={(event) => {
      if (event.key === 'Enter' && !event.shiftKey && !event.nativeEvent.isComposing) { event.preventDefault(); event.currentTarget.form.requestSubmit() }
    }} placeholder={loading ? 'Loading conversation…' : busy ? 'Prepare your next message…' : 'Message your harness…'} disabled={loading} rows={1} />
    {busy && !isStop ? <button type="button" className="composer-button stop" onClick={onStop} title="Interrupt" aria-label="Interrupt"><StopIcon /></button>
      : <button className="composer-button" disabled={!draft.trim() || loading} title="Send" aria-label="Send"><SendIcon /></button>}
  </form><small>Enter to send · Shift+Enter for a new line · /help for commands{usage?.completion > 0 && ` · ${usage.completion.toLocaleString()} output tokens`}{compactions > 0 && ` · ${compactions} context summaries`}</small></div>
}
