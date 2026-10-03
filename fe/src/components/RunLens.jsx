import { useEffect, useRef, useState } from 'react'
import { api } from '../api'
import { Select } from './Picker'
import { BackIcon } from './Icons'
import './run-lens.css'

const statusLabel = (status) => ({ assembling: 'Preparing', queued: 'Queued', dispatching: 'Thinking', tool_running: 'Using tools', delivering: 'Delivering', completed: 'Completed', no_reply: 'No reply', aborted: 'Interrupted', error: 'Failed', timed_out: 'Timed out' }[status] || status)
const dateLabel = (value) => value == null ? 'Not recorded' : new Date(value).toLocaleString()

export default function RunLens({ chat, revision, onClose }) {
  const [runs, setRuns] = useState([])
  const [selected, setSelected] = useState('')
  const [before, setBefore] = useState(null)
  const [report, setReport] = useState(null)
  const [loading, setLoading] = useState(true)
  const [loadingMore, setLoadingMore] = useState(false)
  const [error, setError] = useState('')
  const [attempt, setAttempt] = useState(0)
  const expanded = useRef(false)
  const heading = useRef(null)
  const lensId = selected || runs[0]?.lensId

  useEffect(() => { heading.current?.focus() }, [])
  useEffect(() => {
    let current = true
    setError('')
    api.runs(chat).then((page) => {
      if (!current) return
      setRuns((previous) => [...new Map([...page.runs, ...previous].map((run) => [run.lensId, run])).values()])
      if (!expanded.current) setBefore(page.before)
      setLoading(false)
    }).catch((cause) => { if (current) { setError(cause.message); setLoading(false) } })
    return () => { current = false }
  }, [chat, revision, attempt])

  useEffect(() => {
    if (!lensId) return
    let current = true
    api.runs(chat, { lensId }).then((value) => {
      if (current) { setReport(value); setError('') }
    }).catch((cause) => { if (current) setError(cause.message) })
    return () => { current = false }
  }, [chat, lensId, revision, attempt])

  async function loadEarlier() {
    setLoadingMore(true); setError('')
    try {
      const page = await api.runs(chat, { before })
      setRuns((previous) => [...new Map([...previous, ...page.runs].map((run) => [run.lensId, run])).values()])
      expanded.current = true
      setBefore(page.before)
    } catch (cause) { setError(cause.message) } finally { setLoadingMore(false) }
  }

  const current = report?.lensId === lensId ? report : null
  return <section className="run-lens" aria-labelledby="run-lens-title">
    <div className="run-lens-heading">
      <h1 id="run-lens-title" ref={heading} tabIndex={-1}>Context Lens</h1>
      <button className="back-button" onClick={onClose}><BackIcon />Conversation</button>
    </div>
    <p className="run-lens-help">Inspect the recorded context, tool calls, and reply for an input. Previews are bounded; timings not recorded by the journal stay unknown.</p>
    {error && <div className="inline-error" role="alert">{error} <button className="text-button" onClick={() => setAttempt((value) => value + 1)}>Retry loading runs</button></div>}
    {loading ? <p role="status">Loading runs…</p> : !runs.length ? !error && <p>No recorded runs in this conversation. Send a message to start one.</p> : <>
      <div className="run-lens-picker">
        <Select label="Run" value={lensId} onValueChange={setSelected}>
          {runs.map((run) => <Select.Option key={run.lensId} value={run.lensId}>{run.preview || 'Input without text'} · {dateLabel(run.createdAt)}</Select.Option>)}
        </Select>
        {selected && <button className="text-button" onClick={() => setSelected('')}>Follow latest run</button>}
        {before != null && <button className="text-button" disabled={loadingMore} onClick={loadEarlier}>{loadingMore ? 'Loading…' : 'Load earlier runs'}</button>}
      </div>
      {!current ? !error && <p role="status">Loading run details…</p> : <>
        <dl className="run-lens-summary">
          <div><dt>Status</dt><dd>{statusLabel(current.status)}</dd></div>
          <div><dt>Model</dt><dd>{[current.provider, current.model].filter(Boolean).join(' / ') || 'Not recorded'}</dd></div>
          <div><dt>Received</dt><dd>{dateLabel(current.createdAt)}</dd></div>
          <div><dt>Tool calls</dt><dd>{current.tools?.callCount ?? 0}</dd></div>
          {current.delivery && <div><dt>Delivery</dt><dd>{current.delivery.status}</dd></div>}
        </dl>
        {current.error && <p className="inline-error">{current.error}</p>}
        {current.truncated && <p className="run-lens-help">This run has more evidence than the inspection limit. The full journal remains on the ship.</p>}
        <section className="run-lens-section"><h2>Context</h2>
          <p className="run-lens-help">{current.context?.description}</p>
          {(current.context?.sources || []).map((source, index) => <details key={index} className="run-lens-evidence">
            <summary><strong>{source.label}</strong><span>{source.included ? 'Included' : 'Excluded'}</span></summary>
            {source.reason && <p>{source.reason}</p>}
            <pre className="run-lens-source">{source.preview || 'No text preview recorded.'}</pre>
          </details>)}
        </section>
        <section className="run-lens-section"><h2>Tools</h2>
          {!current.tools?.runs?.length && <p className="run-lens-help">No tool calls recorded for this run.</p>}
          {(current.tools?.runs || []).map((tool, index) => <details key={`${tool.id}-${index}`} className="run-lens-evidence">
            <summary><strong>{tool.name}</strong><span>{statusLabel(tool.status)}</span></summary>
            <h3>Arguments</h3><pre>{tool.argumentDetail || tool.argumentSummary || 'Not recorded'}</pre>
            <h3>Result</h3><pre>{tool.resultSummary ?? tool.error ?? 'No result recorded.'}</pre>
          </details>)}
        </section>
        <section className="run-lens-section"><h2>Reply</h2><pre className="run-lens-reply">{current.reply ?? 'No final reply recorded.'}</pre></section>
        <details className="run-lens-evidence"><summary>Raw run record</summary><pre>{JSON.stringify(current, null, 2)}</pre></details>
      </>}
    </>}
  </section>
}
