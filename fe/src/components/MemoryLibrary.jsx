import { useEffect, useId, useRef, useState } from 'react'
import { api } from '../api'
import { ChevronDownIcon, PlusIcon, SearchIcon } from './Icons'

const bytes = (text) => new TextEncoder().encode(text).length
const date = (at) => at ? new Intl.DateTimeFormat(undefined, { dateStyle: 'medium' }).format(new Date(at)) : ''

function Source({ memory }) {
  const source = memory.source || {}
  return <span className="memory-source">
    <span>{memory.explicit ? 'Saved' : 'Captured'}{source.actor ? ` by ${source.actor}` : ''}{memory.updatedAt ? ` · ${date(memory.updatedAt)}` : ''}</span>
    {source.sessionId ? <a href={`#${encodeURIComponent(source.sessionId)}`}>Open conversation<span className="memory-source-name"> · {source.sessionId}</span></a> : <span>Memory settings</span>}
  </span>
}

function MemoryEditor({ item, onClose, onSaved, closeRequest }) {
  const isNew = !item
  const [record, setRecord] = useState(item)
  const [name, setName] = useState(item?.name || '')
  const [text, setText] = useState(item?.text || '')
  const [general, setGeneral] = useState(item?.general || false)
  const [loading, setLoading] = useState(!isNew)
  const [ready, setReady] = useState(isNew)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [dirty, setDirty] = useState(false)
  const [confirmForget, setConfirmForget] = useState(false)
  const field = useRef(null)
  const alive = useRef(true)
  const helpId = useId()
  const nameId = useId()
  const nameHelpId = useId()
  const readRequest = useRef(0)
  const limit = general ? 256 : 1024
  const length = bytes(text)
  const valid = /^[a-z0-9_-]{1,64}$/.test(name) && text.trim() && length <= limit

  async function load() {
    const id = ++readRequest.current
    setLoading(true); setError(''); setReady(false)
    try {
      const current = await api.memory('read', { name: item.name })
      if (!alive.current || id !== readRequest.current) return
      setRecord(current); setText(current.text || ''); setGeneral(current.general); setDirty(false); setReady(true)
    } catch (cause) { if (alive.current && id === readRequest.current) setError(cause.message) }
    finally { if (alive.current && id === readRequest.current) setLoading(false) }
  }
  useEffect(() => {
    alive.current = true
    if (item) void load()
    else field.current?.focus()
    return () => { alive.current = false; readRequest.current++ }
  }, [])
  const change = (setter, value) => { setter(value); setDirty(true); setConfirmForget(false) }
  const close = () => { if (!busy) onClose(dirty) }
  useEffect(() => {
    if (closeRequest) closeRequest.current = close
    return () => { if (closeRequest) closeRequest.current = null }
  })
  async function mutate(operation) {
    setBusy(true); setError('')
    try {
      const saved = await api.memory(operation, { name, revision: record?.revision || '0', ...(operation === 'save' ? { text: text.trim(), general } : {}) })
      if (alive.current) onSaved(saved, operation)
    } catch (cause) { if (alive.current) setError(cause.message) }
    finally { if (alive.current) setBusy(false) }
  }
  return <form className="memory-editor settings-panel" aria-label={isNew ? 'Add memory' : `Edit ${name}`} onSubmit={(event) => { event.preventDefault(); if (valid && ready && !busy) void mutate('save') }}>
    <div className="memory-editor-heading"><h3>{isNew ? 'Add a memory' : name}</h3><button type="button" className="text-button" disabled={busy} onClick={close}>Close</button></div>
    {loading && <p role="status">Loading current memory…</p>}
    {error && <div className="inline-error" role="alert"><p>{error}</p>{!isNew && <><p>Your draft stays here. Reloading replaces it with the current memory.</p><button className="text-button" type="button" disabled={busy || loading} onClick={() => void load()}>Reload current memory</button></>}</div>}
    {!loading && record?.text === null && <p className="field-note">This memory is forgotten. Saving restores it as an explicit correction.</p>}
    <fieldset disabled={busy || loading || !ready}>
      {isNew && <label><span id={nameId}>Name</span><input aria-labelledby={nameId} aria-describedby={nameHelpId} ref={field} required pattern="[a-z0-9_-]{1,64}" maxLength={64} value={name} onChange={(event) => change(setName, event.target.value)} placeholder="e.g. writing-preferences" /><small id={nameHelpId} className="field-note">Lowercase letters, numbers, hyphens or underscores.</small></label>}
      <label><span>Memory</span><textarea ref={isNew ? undefined : field} required rows={4} value={text} aria-describedby={helpId} aria-invalid={length > limit || undefined} onChange={(event) => change(setText, event.target.value)} placeholder="A useful fact to remember across conversations." /></label>
      <p id={helpId} className={`memory-text-limit ${length > limit ? 'danger-text' : ''}`}>{length.toLocaleString()} / {limit.toLocaleString()} bytes</p>
      <label className="memory-preference"><input type="checkbox" checked={general} onChange={(event) => change(setGeneral, event.target.checked)} /><span>Use across topics<small>For your communication preferences, such as “Keep replies brief.” Up to two are included without a topic match. Other memories are recalled when relevant. Limit: 256 bytes.</small></span></label>
      <p className="field-note">Saved corrections are protected from automatic capture.</p>
      <div className="memory-actions"><button className="button primary" disabled={!valid || !dirty}>{busy ? 'Saving…' : 'Save memory'}</button>{dirty && <button type="button" className="text-button" onClick={() => onClose(false)}>Discard changes</button>}{!isNew && <button type="button" className="text-button danger-text" onClick={() => setConfirmForget(true)}>Forget memory</button>}</div>
      {confirmForget && <div className="memory-confirm" role="group" aria-label="Confirm forgetting"><p>Forget this shared memory? It stops appearing in recall. Source conversations and revision history stay available.</p><div className="memory-actions"><button type="button" className="button danger-text" onClick={() => void mutate('forget')}>Confirm forget</button><button type="button" className="text-button" onClick={() => setConfirmForget(false)}>Keep memory</button></div></div>}
    </fieldset>
    {record && <div className="memory-provenance"><h4>Source</h4><Source memory={record} />{record.history?.length > 0 && <details><summary>Recent revisions</summary><ol className="memory-history">{record.history.map((prior) => <li key={prior.revision}><p>{prior.text || 'Forgotten memory'}</p><Source memory={prior} /></li>)}</ol></details>}</div>}
  </form>
}

export default function MemoryLibrary({ captureModel }) {
  const [draft, setDraft] = useState('')
  const [query, setQuery] = useState('')
  const [items, setItems] = useState([])
  const [total, setTotal] = useState(null)
  const [cursor, setCursor] = useState(null)
  const [pages, setPages] = useState([''])
  const [page, setPage] = useState(0)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [failedPage, setFailedPage] = useState(null)
  const [active, setActive] = useState(null)
  const [expanded, setExpanded] = useState(true)
  const [notice, setNotice] = useState('')
  const request = useRef(0)
  const addButton = useRef(null)
  const rowButtons = useRef(new Map())
  const closeRequest = useRef(null)
  const listHeading = useRef(null)

  async function load(search = query, target = 0, starts = [''], focus = false) {
    const id = ++request.current
    setLoading(true); setError(''); setFailedPage({ search, target, starts, focus })
    try {
      const result = await api.memory('list', { query: search, cursor: starts[target] || '' })
      if (id !== request.current) return
      setItems(result.items); setCursor(result.nextCursor); setTotal(result.total)
      setPage(target); setPages(starts); setQuery(search)
      if (focus) requestAnimationFrame(() => { listHeading.current?.focus(); listHeading.current?.scrollIntoView({ block: 'nearest' }) })
    } catch (cause) { if (id === request.current) setError(cause.message) }
    finally { if (id === request.current) setLoading(false) }
  }
  useEffect(() => { void load(''); return () => { request.current++ } }, [])
  function close(keepDraft = false) {
    const previous = active
    if (keepDraft) setExpanded(false)
    else setActive(null)
    requestAnimationFrame(() => (previous === '' ? addButton.current : rowButtons.current.get(previous))?.focus())
  }
  function open(name) { setActive(name); setExpanded(true); setNotice('') }
  function saved(item, operation) {
    setActive(null); setNotice(operation === 'forget' ? 'Memory forgotten. Source history is retained.' : 'Memory saved and shared.')
    setDraft(''); void load('')
    requestAnimationFrame(() => addButton.current?.focus())
  }
  return <section className="memory-library" aria-labelledby="memory-library-title">
    <div className="section-title"><div><h2 id="memory-library-title">Shared memory</h2><p>Facts shared across conversations. Open a memory to read its source or make a correction.</p></div><button ref={addButton} className="button primary" disabled={active !== null && !(active === '' && !expanded)} onClick={() => open('')}><PlusIcon />{active === '' && !expanded ? 'Resume draft' : 'Add memory'}</button></div>
    <p className="memory-capture-note">Automatic capture uses the LCM model{captureModel ? <>: <strong>{captureModel}</strong></> : ''}.</p>
    <details className="memory-sharing"><summary>How sharing works</summary><p>Memories are shared across admitted conversations and local subagents, including conversations with the owner. They are not private to their source channel. Each reply receives a small selection of relevant memories.</p><p>Use <code>/memory off</code> in a conversation to disable recall and capture there and in its subagents. “Use across topics” gives a communication preference recall priority; it does not change who can access it.</p></details>
    <div role="status" className="memory-notice">{notice}</div>
    {active === '' && <div className="panel memory-new"><div hidden={!expanded}><MemoryEditor onClose={close} onSaved={saved} /></div>{!expanded && <div className="memory-draft"><span>New memory · Unsaved changes</span><button className="text-button" onClick={() => close(false)}>Discard changes</button></div>}</div>}
    <form className="memory-search" role="search" onSubmit={(event) => { event.preventDefault(); setNotice(''); void load(draft.trim()) }}>
      <label><span>Search memories</span><span className="memory-search-input"><SearchIcon /><input type="search" value={draft} maxLength={512} disabled={active !== null} placeholder="Search words or prefixes" onChange={(event) => setDraft(event.target.value)} /></span></label>
      <button className="button" disabled={active !== null}>Search</button>
    </form>
    <div className="memory-list-heading" ref={listHeading} tabIndex={-1}><span>{query ? `Results for “${query}”` : total === null ? 'Saved memories' : `${total.toLocaleString()} saved ${total === 1 ? 'memory' : 'memories'}`}</span><button className="text-button" disabled={loading || active !== null} onClick={() => { setDraft(''); void load('') }}>{query ? 'Clear search' : 'Refresh'}</button></div>
    {error && <div className="inline-error" role="alert"><p>{error}</p><button className="text-button" disabled={loading || active !== null} onClick={() => { const { search, target, starts, focus } = failedPage; void load(search, target, starts, focus) }}>Retry loading memories</button></div>}
    <div className="panel memory-list" aria-busy={loading}>
      {items.map((item) => <div className="memory-row" key={item.name}>
        <button type="button" ref={(node) => { if (node) rowButtons.current.set(item.name, node); else rowButtons.current.delete(item.name) }} className="memory-row-button" aria-expanded={active === item.name && expanded} aria-controls={`memory-editor-${item.name}`} aria-label={`Inspect ${item.name}`} disabled={loading || (active !== null && active !== item.name)} onClick={() => { if (active === item.name && expanded) closeRequest.current?.(); else open(item.name) }}>
          <span><span className="memory-row-text">{item.text}</span><span className="memory-row-meta"><span>{item.name}</span><span>{active === item.name && !expanded ? 'Unsaved changes' : item.general ? 'Across topics' : item.explicit ? 'Explicit' : 'Captured'}</span></span></span><ChevronDownIcon />
        </button>
        {active === item.name && <><div id={`memory-editor-${item.name}`} hidden={!expanded}><MemoryEditor key={item.name} item={item} onClose={close} onSaved={saved} closeRequest={closeRequest} /></div>{!expanded && <div className="memory-draft"><span>Expand to save, or discard this draft to continue browsing.</span><button className="text-button" onClick={() => close(false)}>Discard changes</button></div>}</>}
      </div>)}
      {!items.length && !loading && !error && <div className="memory-empty"><h3>{cursor ? 'No matches in this page' : query ? 'No matching memories' : 'Nothing remembered yet'}</h3><p>{cursor ? 'Continue to the next page to search more memories.' : query ? 'Try fewer words or a shorter word prefix.' : 'Facts appear here as conversations reveal lasting context. You can also add a memory yourself.'}</p></div>}
      {loading && <p className="memory-loading" role="status">Loading memories…</p>}
    </div>
    {(page > 0 || cursor) && <nav className="memory-pagination" aria-label="Memory pages"><button className="button" disabled={loading || active !== null || page === 0} onClick={() => void load(query, page - 1, pages, true)}>Previous</button><span>Page {page + 1} · {items.length} shown</span><button className="button" disabled={loading || active !== null || !cursor} onClick={() => void load(query, page + 1, [...pages.slice(0, page + 1), cursor], true)}>Next</button></nav>}
  </section>
}
