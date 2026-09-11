import { useLayoutEffect, useRef, useState } from 'react'
import { useWorkspace } from '../useWorkspace'
import { workspaceWrite } from '../workspace'
import { CloseIcon } from './Icons'

export const artifactHref = (id) => `#/artifacts/${encodeURIComponent(id)}`
export const projectHref = (id) => `#/projects/${encodeURIComponent(id)}`
export const workDate = (value) => value ? new Date(value).toLocaleString() : 'Date unavailable'

export function useWorkMutation() {
  const lock = useRef(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const run = async (action, args, done) => {
    if (lock.current) return
    lock.current = true; setBusy(true); setError('')
    try { const result = await workspaceWrite(action, args); await done?.(result); return result }
    catch (cause) { setError(cause.message); return null }
    finally { lock.current = false; setBusy(false) }
  }
  return { busy, error, setError, run }
}

export function WorkFeedback({ query }) {
  return <>
    {query.loading && <p className="field-note" role="status">Loading…</p>}
    {query.error && <div className="inline-error" role="alert">{query.error} {query.refresh && <button className="text-button" onClick={query.refresh}>Retry</button>}</div>}
  </>
}

export function WorkPager({ query, offset, onOffset }) {
  return <div className="work-pagination">
    {offset > 0 && <button className="button ghost" onClick={() => onOffset(Math.max(0, offset - 24))}>Previous</button>}
    {query.value?.nextOffset != null && <button className="button ghost" onClick={() => onOffset(query.value.nextOffset)}>Next</button>}
    {offset > 0 && <span className="field-note">Page {Math.floor(offset / 24) + 1}</span>}
  </div>
}

export function WorkDialog({ title, children, onClose, busy = false, className = '' }) {
  const ref = useRef(null)
  const heading = `dialog-${title.toLowerCase().replace(/[^a-z]+/g, '-')}`
  useLayoutEffect(() => {
    const element = ref.current, previous = document.activeElement
    element.showModal()
    return () => { element.close(); if (previous?.isConnected) previous.focus() }
  }, [])
  return <dialog ref={ref} className={`work-dialog ${className}`} aria-labelledby={heading} onCancel={(event) => { event.preventDefault(); if (!busy) onClose() }} onClick={(event) => { if (event.target === event.currentTarget && !busy) onClose() }}>
    <section className="work-dialog-content">
      <header><h2 id={heading}>{title}</h2><button className="icon-button" disabled={busy} onClick={onClose} aria-label="Close dialog"><CloseIcon /></button></header>
      {children}
    </section>
  </dialog>
}

export function ProjectSelect({ value, onChange, disabled }) {
  const [offset, setOffset] = useState(0)
  const query = useWorkspace('projects', { offset, limit: 24 })
  const [retained, setRetained] = useState([])
  const projects = [...new Map([...retained, ...(query.value?.items || [])].map((item) => [item.id, item])).values()].filter((item) => !item.archived)
  return <>
    <label><span>Project</span><select value={value || ''} disabled={disabled} onChange={(event) => onChange(event.target.value || null)}>
      <option value="">Private artifact · no project</option>
      {projects.map((project) => <option key={project.id} value={project.id}>{project.title}</option>)}
      {value && !projects.some((project) => project.id === value) && <option value={value}>{value}</option>}
    </select></label>
    <WorkFeedback query={query} />
    {query.value?.nextOffset != null && <button type="button" className="text-button" onClick={() => { setRetained(projects); setOffset(query.value.nextOffset) }}>Load more projects</button>}
  </>
}

export function ArtifactRows({ items = [] }) {
  return <div className="work-records">
    {items.map((artifact) => <a className="work-record" href={artifactHref(artifact.id)} key={artifact.id}>
      <div><strong>{artifact.title}</strong><span className="work-record-meta">{artifact.project ? 'Project artifact' : 'Private artifact'} · {artifact.head ? `Revision ${artifact.head}` : 'Awaiting review'}{artifact.archived ? ' · Archived' : ''}</span></div>
      <span className={`work-label${artifact.publication ? ' public' : ''}`}>{artifact.publication ? `Public · r${artifact.publication.revision}` : 'Not published'}</span>
    </a>)}
  </div>
}
