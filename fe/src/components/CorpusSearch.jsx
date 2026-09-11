import { useEffect, useRef, useState } from 'react'
import { api } from '../api'
import { useResource } from '../useResource'
import { BackIcon } from './Icons'
import WorkspaceSearchSource from './WorkspaceSearchSource'

const isWorkspace = (record) => ['artifact', 'project', 'task'].includes(record.kind)
const address = (record) => isWorkspace(record) ? `${record.kind}:${record.id}` : `conversation:${record.scope}:${record.eventCount}`
const provenance = (record) => [record.hand, record.author, record.kind, ...(record.kind === 'artifact' ? [`${record.matchCount} matching ${record.matchCount === 1 ? 'revision' : 'revisions'}`, record.currentMatches ? 'Current revision matches' : 'Historical matches only'] : []), record.archived ? 'Archived' : '', record.sent ? new Date(record.sent).toLocaleString() : 'Date unavailable'].filter(Boolean).join(' · ')

function Source({ record, onSelect, onOpen }) {
  const [content, setContent] = useState(null)
  const [edges, setEdges] = useState(null)
  const [busy, setBusy] = useState(true)
  const [error, setError] = useState('')
  const generation = useRef(0)
  const [retry, setRetry] = useState(0)
  useEffect(() => {
    const epoch = ++generation.current
    setBusy(true); setError('')
    Promise.all([
      api.corpus('read', record),
      record.kind === 'summary' ? api.corpus('expand', record) : Promise.resolve(null),
    ]).then(([body, sources]) => {
      if (generation.current === epoch) { setContent(body); setEdges(sources) }
    }).catch((cause) => { if (generation.current === epoch) setError(cause.message) })
      .finally(() => { if (generation.current === epoch) setBusy(false) })
    return () => { generation.current++ }
  }, [record, retry])
  async function more(operation) {
    const epoch = generation.current
    setBusy(true); setError('')
    try {
      const next = await api.corpus(operation, { scope: record.scope, eventCount: record.eventCount, offset: operation === 'read' ? content.nextOffset : edges.nextOffset })
      if (epoch !== generation.current) return
      if (operation === 'read') setContent((prior) => ({ ...next, body: prior.body + next.body }))
      else setEdges((prior) => ({ ...next, sources: [...prior.sources, ...next.sources] }))
    } catch (cause) { if (epoch === generation.current) setError(cause.message) }
    finally { if (epoch === generation.current) setBusy(false) }
  }
  return <>
    <div className="section-title"><div><h2>Source · {record.eventCount}</h2><p>{provenance(record)}</p></div><button className="text-button" onClick={() => onOpen(record.sessionId)}>Open conversation</button></div>
    <p className="corpus-source-name">{record.sessionId}</p>
    {error && <div className="inline-error" role="alert">{error} <button className="text-button" onClick={() => setRetry((value) => value + 1)}>Retry source</button></div>}
    {busy && <p className="field-note" role="status">Loading source…</p>}
    {content && <>
      <p className="field-note">Retained reference material. Original wording is shown below.</p>
      <div className="corpus-source-body">{content.body}</div>
      {content.nextOffset != null && <button className="button ghost" disabled={busy} onClick={() => more('read')}>Read more</button>}
    </>}
    {edges && <section className="corpus-evidence" aria-label="Summary evidence">
      <h3>Evidence · depth {edges.depth}</h3>
      {!edges.sources.length && <p className="field-note">This legacy summary has no recorded source links.</p>}
      {edges.sources.filter(Boolean).map((source) => <button className="corpus-evidence-link" key={address(source)} onClick={() => onSelect(source)}><strong>{source.kind === 'summary' ? 'Summary' : 'Original source'} · {source.eventCount}</strong><span>{source.snippet}</span></button>)}
      {edges.nextOffset != null && <button className="text-button" disabled={busy} onClick={() => more('expand')}>More evidence</button>}
    </section>}
  </>
}

export default function CorpusSearch({ onBack, onOpen }) {
  const status = useResource('search/status', null, 2500)
  const [query, setQuery] = useState('')
  const [submitted, setSubmitted] = useState('')
  const [result, setResult] = useState(null)
  const [trail, setTrail] = useState([])
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const request = useRef(0)
  const [failed, setFailed] = useState(null)
  const resultButtons = useRef(new Map())
  const detail = useRef(null)
  useEffect(() => () => { request.current++ }, [])
  const selected = trail.at(-1)
  async function search(event, more = false, retryRequest = null) {
    event?.preventDefault()
    const text = retryRequest?.text ?? (more ? submitted : query.trim())
    const cursor = retryRequest?.cursor ?? (more ? result.cursor : null)
    if (!text) return
    const epoch = ++request.current
    setBusy(true); setError(''); setFailed(null)
    if (!more) { setSubmitted(text); setResult(null); setTrail([]) }
    try {
      const next = await api.search('query', { query: text, limit: 20, ...(more ? { cursor } : {}) })
      if (epoch !== request.current) return
      setResult((prior) => ({ ...next, hits: more ? [...(prior?.hits || []), ...next.hits] : next.hits }))
    } catch (cause) { if (epoch === request.current) { setError(cause.message); setFailed({ text, more, cursor }) } }
    finally { if (epoch === request.current) setBusy(false) }
  }
  function select(record, child = false) {
    setTrail((prior) => child ? [...prior, record] : [record])
    requestAnimationFrame(() => detail.current?.focus())
  }
  function closeSource() {
    const origin = trail[0]
    setTrail((prior) => prior.slice(0, -1))
    if (trail.length === 1) requestAnimationFrame(() => resultButtons.current.get(address(origin))?.focus())
  }
  return <main className="workspace corpus-workspace">
    <header className="topbar"><button className="back-button" onClick={onBack}><BackIcon />Conversations</button></header>
    <div className="corpus-content">
      <div className="page-header"><h1>Search content</h1><p>Find retained conversations, saved artifacts, projects, and tasks in one place.</p></div>
      <form className="corpus-search-form" role="search" onSubmit={search}>
        <label><span>Search Harness</span><input type="search" autoFocus value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Words from a message, document, or task" required /></label>
        <button className="button primary" disabled={busy || !query.trim()}>{busy ? 'Searching…' : 'Search'}</button>
      </form>
      <p className="field-note corpus-status" role="status">{status.value ? `${status.value.indexed.toLocaleString()} conversation records · ${(status.value.workspaceRecords || 0).toLocaleString()} saved work entries${status.value.indexing || status.value.workspaceIndexing ? ' · Indexing; results may be incomplete. Search again for new matches.' : ' · Index up to date.'}` : status.loading ? 'Loading index status…' : 'Index status unavailable.'}</p>
      {(result?.status?.workspaceAvailable === false || status.value?.workspaceAvailable === false) && <p className="inline-error" role="status">Notes is unavailable. Only conversation results are shown; search again when Notes reconnects.</p>}
      {error && <div className="inline-error" role="alert">{error} {failed && <button className="text-button" disabled={busy} onClick={() => search(null, failed.more, failed)}>Retry search</button>}</div>}
      {status.error && <div className="inline-error" role="alert">{status.error} <button className="text-button" onClick={status.refresh}>Retry index status</button></div>}
      <div className={`corpus-layout${selected ? ' has-source' : ''}`}>
        <section className="corpus-results" aria-label="Search results" aria-busy={busy}>
          {!submitted && <div className="corpus-empty"><h2>Find the work behind a conversation</h2><p>Search retained messages and summary evidence alongside saved Notes-backed artifacts, project descriptions, and tasks. An artifact appears once, with its matching revisions inside. Unsaved drafts and unaccepted proposals are not indexed.</p></div>}
          {result && <p className="corpus-result-count" role="status">{result.hits.length ? `${result.hits.length} results${result.cursor ? ' loaded' : ''} for “${submitted}”` : `No results for “${submitted}”. Try fewer words or a different spelling.`}</p>}
          {result?.hits.filter(Boolean).map((record) => <div key={address(record)}>
            <button ref={(element) => { if (element) resultButtons.current.set(address(record), element); else resultButtons.current.delete(address(record)) }} className={`corpus-hit${trail[0] && address(record) === address(trail[0]) ? ' active' : ''}`} onClick={() => select(record)} aria-pressed={!!trail[0] && address(record) === address(trail[0])}>
              <strong>{isWorkspace(record) ? record.title : record.sessionId}</strong><span className="corpus-hit-meta">{provenance(record)}</span><span className="corpus-hit-snippet">{record.snippet}</span>
            </button>
          </div>)}
          {result?.cursor && <button className="button ghost corpus-more" disabled={busy} onClick={(event) => search(event, true)}>Load more results</button>}
        </section>
        {selected && <section className="corpus-detail panel" ref={detail} tabIndex={-1} aria-label="Selected source">
          <div className="corpus-detail-nav"><button className="back-button" onClick={closeSource}><BackIcon />{trail.length > 1 ? 'Parent summary' : 'Close source'}</button><span>{trail.length > 1 ? `${trail.length - 1} evidence links followed` : 'Source detail'}</span></div>
          {isWorkspace(selected) ? <WorkspaceSearchSource key={`${address(selected)}:${selected.searchToken}`} record={selected} query={submitted} /> : <Source key={address(selected)} record={selected} onSelect={(record) => select(record, true)} onOpen={onOpen} />}
        </section>}
      </div>
    </div>
  </main>
}
