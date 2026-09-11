import { useEffect, useRef, useState } from 'react'
import { api } from '../api'

export default function WorkspaceSearchSource({ record, query }) {
  const artifact = record.kind === 'artifact'
  const [revision, setRevision] = useState(record.revision)
  const [content, setContent] = useState(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [retry, setRetry] = useState(0)
  const [expanded, setExpanded] = useState(false)
  const [versions, setVersions] = useState(null)
  const [versionsBusy, setVersionsBusy] = useState(false)
  const [versionsError, setVersionsError] = useState('')
  const generation = useRef(0)
  const versionGeneration = useRef(0)
  const params = { query, kind: record.kind, id: record.id, searchToken: record.searchToken }

  useEffect(() => {
    const epoch = ++generation.current
    setContent(null); setError(''); setBusy(true)
    api.search('read', { query, kind: record.kind, id: record.id, searchToken: record.searchToken, revision })
      .then((value) => { if (generation.current === epoch) setContent(value) })
      .catch((cause) => { if (generation.current === epoch) setError(cause.message) })
      .finally(() => { if (generation.current === epoch) setBusy(false) })
    return () => { generation.current++ }
  }, [record, query, revision, retry])
  useEffect(() => () => { versionGeneration.current++ }, [])

  async function loadVersions(more = false) {
    const epoch = ++versionGeneration.current
    setVersionsBusy(true); setVersionsError('')
    try {
      const next = await api.search('versions', { ...params, offset: more ? versions.nextOffset : 0, limit: 16 })
      if (epoch === versionGeneration.current) setVersions((prior) => ({ ...next, items: more ? [...prior.items, ...next.items] : next.items }))
    } catch (cause) { if (epoch === versionGeneration.current) setVersionsError(cause.message) }
    finally { if (epoch === versionGeneration.current) setVersionsBusy(false) }
  }
  async function moreBody() {
    const epoch = generation.current
    setBusy(true); setError('')
    try {
      const next = await api.search('read', { ...params, revision, offset: content.content.nextOffset })
      if (epoch === generation.current) setContent((prior) => ({ ...next, content: { ...next.content, body: prior.content.body + next.content.body } }))
    } catch (cause) { if (epoch === generation.current) setError(cause.message) }
    finally { if (epoch === generation.current) setBusy(false) }
  }
  function toggleVersions() {
    setExpanded((value) => !value)
    if (!expanded && !versions && !versionsBusy) void loadVersions()
  }
  const path = artifact ? `#/artifacts/${encodeURIComponent(record.id)}` : `#/projects/${encodeURIComponent(record.project || record.id)}`
  return <>
    <div className="section-title"><div><h2>{record.title}</h2><p>{artifact ? `Matching revision ${revision} · Current revision ${record.head}` : record.kind === 'task' ? 'Project task' : 'Project'}</p></div><a className="text-button" href={path}>{artifact ? 'Open current artifact' : 'Open project'}</a></div>
    {artifact && <>
      <p className="field-note">{revision === record.head ? 'This revision is the current document.' : 'This is a historical match, not the current document.'} Read-only saved text from Notes; unsaved drafts are not included.</p>
      <button className="text-button corpus-version-toggle" aria-expanded={expanded} aria-controls="matching-revisions" onClick={toggleVersions}>{expanded ? 'Hide' : 'Show'} {record.matchCount} matching {record.matchCount === 1 ? 'revision' : 'revisions'}</button>
      {expanded && <section id="matching-revisions" className="corpus-versions" aria-label="Matching revisions">
        {versionsBusy && <p className="field-note" role="status">Loading matching revisions…</p>}
        {versionsError && <div className="inline-error" role="alert">{versionsError} <button className="text-button" disabled={versionsBusy} onClick={() => loadVersions(Boolean(versions?.nextOffset))}>Retry revisions</button></div>}
        {versions?.items.map((item) => <button key={item.revision} className={`corpus-version${revision === item.revision ? ' active' : ''}`} aria-pressed={revision === item.revision} onClick={() => setRevision(item.revision)}><strong>Revision {item.revision}{item.revision === record.head ? ' · Current' : ''}</strong><span>{item.title} · {item.at ? new Date(item.at).toLocaleString() : 'Date unavailable'}</span></button>)}
        {versions?.nextOffset != null && <button className="text-button" disabled={versionsBusy} onClick={() => loadVersions(true)}>More matching revisions</button>}
      </section>}
    </>}
    {busy && <p className="field-note" role="status">Loading {artifact ? 'revision' : record.kind}…</p>}
    {error && <div className="inline-error" role="alert">{error} <button className="text-button" disabled={busy} onClick={() => setRetry((value) => value + 1)}>Retry source</button></div>}
    {content && <>
      {artifact && content.content.title !== record.title && <h3>{content.content.title}</h3>}
      <div className="corpus-source-body">{artifact ? content.content.body : content.description || 'No description.'}</div>
      {artifact && content.content.sources?.length > 0 && <section className="corpus-evidence" aria-label="Source references"><h3>Source references</h3>{content.content.sources.map((source, index) => <p className="corpus-source-name" key={index}>{source.label}<br /><span className="field-note">{source.url}</span></p>)}</section>}
      {!artifact && content.outcome && <><h3>Outcome</h3><div className="corpus-source-body">{content.outcome}</div></>}
      {artifact && content.content.nextOffset != null && <button className="button ghost" disabled={busy} onClick={moreBody}>Read more</button>}
    </>}
  </>
}
