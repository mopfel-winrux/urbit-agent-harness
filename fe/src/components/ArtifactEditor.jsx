import { useEffect, useRef, useState } from 'react'
import { useWorkspace } from '../useWorkspace'
import { changedContent, documentDiff, draftKey, persistDraft, readDraft, workId } from '../workspace'
import Markdown from './Markdown'
import { ArtifactRows, ProjectSelect, WorkDialog, WorkFeedback, WorkPager, artifactHref, projectHref, useWorkMutation, workDate } from './WorkspaceCommon'

const blank = { title: '', body: '', sources: [] }
const contentDraft = (content) => content ? { base: content.revision, title: content.title, body: content.body, sources: content.sources || [] } : null
const publicURL = (path) => new URL(path, location.origin).href
const safeLink = (url) => { try { const parsed = new URL(url); return ['http:', 'https:'].includes(parsed.protocol) ? parsed.href : null } catch { return null } }

function Sources({ sources, onChange, disabled }) {
  const edit = (index, key, value) => onChange(sources.map((source, i) => i === index ? { ...source, [key]: value } : source))
  return <details className="work-sources"><summary>Source references ({sources.length})</summary>
    <p className="field-note">Private provenance for this revision. References are not included in the public page; links written in the document body are.</p>
    {sources.map((source, index) => <div className="work-source-row" key={index}>
      <label><span>Source {index + 1} label</span><input value={source.label} maxLength={256} disabled={disabled} onChange={(event) => edit(index, 'label', event.target.value)} /></label>
      <label><span>Source {index + 1} URL or address</span><input value={source.url} maxLength={2048} disabled={disabled} onChange={(event) => edit(index, 'url', event.target.value)} /></label>
      <button type="button" className="text-button danger-text" disabled={disabled} onClick={() => onChange(sources.filter((_, i) => i !== index))} aria-label={`Remove source ${index + 1}`}>Remove</button>
    </div>)}
    <button type="button" className="text-button" disabled={disabled || sources.length >= 16} onClick={() => onChange([...sources, { label: '', url: '' }])}>Add source reference</button>
  </details>
}

function ReadSources({ sources }) {
  return !!sources?.length && <details className="work-sources"><summary>Source references ({sources.length})</summary><ul>{sources.map((source, index) => <li key={index}>{safeLink(source.url) ? <a href={safeLink(source.url)} target="_blank" rel="noopener noreferrer">{source.label || source.url}</a> : <span>{source.label} {source.url}</span>}</li>)}</ul></details>
}

function Publication({ artifact, onClose }) {
  const [revision, setRevision] = useState(artifact.head)
  const [slug, setSlug] = useState(artifact.publication?.slug || artifact.title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 80))
  const [confirmed, setConfirmed] = useState(false)
  const [published, setPublished] = useState(null)
  const query = useWorkspace('preview', { id: artifact.id, revision })
  const mutation = useWorkMutation()
  const validSlug = /^[a-z0-9](?:[a-z0-9-]{0,78}[a-z0-9])?$/.test(slug)
  return <WorkDialog title={published ? 'Page published' : 'Publish a saved revision'} onClose={onClose} busy={mutation.busy} className="publication-dialog">
    {published ? <><p>Revision {published.revision} is public. Further edits stay private until you publish again.</p><a className="work-public-url" href={publicURL(published.path)} target="_blank" rel="noopener noreferrer">{publicURL(published.path)}</a><div className="form-actions"><button className="button primary" onClick={onClose}>Done</button></div></> : <>
      <p>Anyone with this URL can read and copy the page without signing in. Publish only content you intend to share.</p>
      <div className="field-grid"><label><span>Saved revision</span><select value={revision} disabled={mutation.busy} onChange={(event) => { setRevision(Number(event.target.value)); setConfirmed(false) }}>{Array.from({ length: artifact.head }, (_, index) => artifact.head - index).map((number) => <option key={number} value={number}>Revision {number}{number === artifact.head ? ' · latest' : ''}</option>)}</select></label><label><span>Public URL name</span><input value={slug} maxLength={80} disabled={mutation.busy} onChange={(event) => { setSlug(event.target.value); setConfirmed(false) }} autoComplete="off" spellCheck="false" /></label></div>
      <p className="field-note work-public-url">{publicURL(`/harness-pages/${slug || 'your-page'}`)}</p>
      {!validSlug && <p className="field-note">Use lowercase letters, digits, and interior hyphens, up to 80 characters.</p>}
      <WorkFeedback query={query} />
      {query.value && <iframe className="work-page-preview" title={`Public preview of revision ${revision}`} sandbox="" srcDoc={query.value.html} />}
      <p className="field-note">This is the exact public rendering. It includes only the saved title and body—not project access, source references, proposals, or history. Raw HTML and remote images are not embedded.</p>
      <label className="work-check"><input type="checkbox" checked={confirmed} disabled={mutation.busy || query.loading || !!query.error} onChange={(event) => setConfirmed(event.target.checked)} /><span>I reviewed revision {revision} and want its title, body, and body links publicly accessible.</span></label>
      <WorkFeedback query={mutation} />
      <div className="form-actions"><button className="button ghost" disabled={mutation.busy} onClick={onClose}>Cancel</button><button className="button primary" disabled={mutation.busy || !confirmed || !validSlug || !query.value || !!query.error} onClick={() => mutation.run('publish', { id: artifact.id, revision, head: query.value.head, exposure: artifact.exposure, slug, confirm: `${artifact.id}@${revision}` }, (result) => setPublished(result.artifact.publication))}>{mutation.busy ? 'Publishing…' : artifact.publication ? 'Update public page' : 'Publish page'}</button></div>
    </>}
  </WorkDialog>
}

function CopyArtifact({ artifact, content, onClose }) {
  const [id] = useState(workId)
  const [project, setProject] = useState(null)
  const [confirmed, setConfirmed] = useState(false)
  const mutation = useWorkMutation()
  return <WorkDialog title="Copy revision to a project" onClose={onClose} busy={mutation.busy}>
    <p>Copy revision {content.revision} of “{content.title}”. The original artifact and its earlier history stay where they are.</p>
    <ProjectSelect value={project} onChange={(value) => { setProject(value); setConfirmed(false) }} disabled={mutation.busy} />
    <label className="work-check"><input type="checkbox" checked={confirmed} onChange={(event) => setConfirmed(event.target.checked)} disabled={mutation.busy || !project} /><span>Share this revision's title, body, and source references with this project's members.</span></label>
    <WorkFeedback query={mutation} />
    <div className="form-actions"><button className="button ghost" disabled={mutation.busy} onClick={onClose}>Cancel</button><button className="button primary" disabled={mutation.busy || !project || !confirmed} onClick={() => mutation.run('artifact-create', { id, project, title: content.title, body: content.body, sources: content.sources }, (result) => { onClose(); location.hash = artifactHref(result.artifact.id) })}>{mutation.busy ? 'Copying…' : 'Copy and share revision'}</button></div>
  </WorkDialog>
}

function ProposalReview({ id, artifact, onClose }) {
  const query = useWorkspace('proposal', { id })
  const proposal = query.value?.proposal, content = query.value?.content
  const base = useWorkspace(proposal?.base ? 'revision' : null, { id: artifact.id, revision: proposal?.base })
  const mutation = useWorkMutation()
  const [reason, setReason] = useState('')
  const [decided, setDecided] = useState('')
  const old = base.value?.content || blank
  const diff = content ? documentDiff(old.body, content.body) : null
  const ready = content && (!proposal.base || base.value?.content)
  const stale = proposal && proposal.base !== artifact.head
  return <section className="work-review" aria-label="Proposal review">
    <div className="section-title"><h2>Review proposed changes</h2><button className="button ghost" disabled={mutation.busy} onClick={onClose}>Back to proposals</button></div>
    <WorkFeedback query={query} /><WorkFeedback query={base} />
    {proposal && <>
      <p className="field-note">{proposal.by.label} · {workDate(proposal.at)} · Based on {proposal.base ? `revision ${proposal.base}` : 'a new document'}</p>
      <p>{proposal.reason || 'No explanation supplied.'}</p>
      {stale && proposal.status === 'pending' && <div className="work-notice" role="status">This proposal is based on revision {proposal.base}; the artifact is now revision {artifact.head}. It cannot be accepted over newer work. Ask the agent to read the current revision and submit a new proposal.</div>}
      {ready && <>
        <div className="work-diff-columns"><section><h3>Base title</h3><p>{old.title || 'New document'}</p></section><section><h3>Proposed title</h3><p>{content.title}</p></section></div>
        <details className="work-diff-context"><summary>Read the complete proposed document</summary><Markdown text={content.body} /><ReadSources sources={content.sources} /></details>
        <h3>Body changes</h3>
        {diff.same ? <p className="field-note">The body is unchanged.</p> : <div className="work-diff" aria-label="Document replacement diff">
          {!!diff.prefix.length && <pre className="diff-context">{diff.prefix.join('\n')}</pre>}
          <div className="work-diff-columns"><section><h4>Removed</h4><pre className="diff-removed">{diff.removed.join('\n') || '(No removed lines)'}</pre></section><section><h4>Added</h4><pre className="diff-added">{diff.added.join('\n') || '(No added lines)'}</pre></section></div>
          {!!diff.suffix.length && <pre className="diff-context">{diff.suffix.join('\n')}</pre>}
        </div>}
        {JSON.stringify(old.sources) !== JSON.stringify(content.sources) && <div className="work-diff-columns"><section><h3>Base references</h3><pre className="work-reference-text">{JSON.stringify(old.sources || [], null, 2)}</pre></section><section><h3>Proposed references</h3><pre className="work-reference-text">{JSON.stringify(content.sources || [], null, 2)}</pre></section></div>}
      </>}
      {decided ? <p className="work-notice" role="status">{decided}</p> : proposal.status !== 'pending' ? <p className="work-notice">Proposal {proposal.status}. {proposal.decision}</p> : <>
        <label><span>Review note (optional)</span><textarea rows={2} value={reason} maxLength={4096} disabled={mutation.busy} onChange={(event) => setReason(event.target.value)} /></label>
        <p className="field-note">Accepting creates an exact saved revision. It does not publish anything.</p>
        <WorkFeedback query={mutation} />
        <div className="form-actions"><button className="button ghost" disabled={mutation.busy} onClick={() => mutation.run('review', { id, accept: false, reason }, () => setDecided('Proposal rejected. The document is unchanged.'))}>Reject proposal</button><button className="button primary" disabled={mutation.busy || stale || !ready} onClick={() => mutation.run('review', { id, accept: true, reason }, (result) => setDecided(`Accepted as revision ${result.revision}. It has not been published.`))}>{mutation.busy ? 'Recording review…' : 'Accept exact changes'}</button></div>
      </>}
    </>}
  </section>
}

function Proposals({ artifact }) {
  const [offset, setOffset] = useState(0)
  const [selected, setSelected] = useState(null)
  const query = useWorkspace('proposals', { artifact: artifact.id, offset, limit: 24 })
  if (selected) return <ProposalReview key={selected} id={selected} artifact={artifact} onClose={() => setSelected(null)} />
  return <section><WorkFeedback query={query} />
    {!query.loading && !query.error && !query.value?.items?.length && <div className="work-empty"><h2>No proposals yet</h2><p>Ask an agent with Workspace tools to read this artifact and propose an edit. Its changes will appear here for your review.</p><code>{artifact.id}</code></div>}
    <div className="work-records">{query.value?.items?.map((proposal) => <button className="work-record" key={proposal.id} onClick={() => setSelected(proposal.id)}><div><strong>{proposal.title}</strong><span className="work-record-meta">{proposal.by.label} · {proposal.base ? `Base r${proposal.base}` : 'New document'} · {workDate(proposal.at)}</span><span>{proposal.reason}</span></div><span className="work-label">{proposal.status}</span></button>)}</div>
    <WorkPager query={query} offset={offset} onOffset={setOffset} />
  </section>
}

function History({ artifact }) {
  const [offset, setOffset] = useState(0)
  const [selected, setSelected] = useState(null)
  const query = useWorkspace('revisions', { id: artifact.id, offset, limit: 24 })
  const revision = useWorkspace(selected ? 'revision' : null, { id: artifact.id, revision: selected })
  const [copy, setCopy] = useState(false)
  return <section><WorkFeedback query={query} />
    <div className="work-records">{query.value?.items?.map((item) => <button className="work-record" key={item.revision} onClick={() => setSelected(item.revision)} aria-pressed={selected === item.revision}><div><strong>Revision {item.revision} · {item.title}</strong><span className="work-record-meta">{item.by.label} · {workDate(item.at)}</span></div>{artifact.publication?.revision === item.revision && <span className="work-label public">Public</span>}</button>)}</div>
    <WorkPager query={query} offset={offset} onOffset={setOffset} />
    <WorkFeedback query={revision} />
    {revision.value?.content && <div className="work-history-document"><div className="section-title"><h2>{revision.value.content.title}</h2><button className="button ghost" onClick={() => setCopy(true)}>Copy this revision</button></div><p className="field-note">Saved revision {selected} · read-only</p><Markdown text={revision.value.content.body} /><ReadSources sources={revision.value.content.sources} /></div>}
    {copy && <CopyArtifact artifact={artifact} content={revision.value.content} onClose={() => setCopy(false)} />}
  </section>
}

export default function ArtifactEditor({ id }) {
  const query = useWorkspace('artifact', { id })
  const artifact = query.value?.artifact, content = query.value?.content
  const [draft, setDraft] = useState(() => readDraft(sessionStorage, id))
  const [baseline, setBaseline] = useState(null)
  const [tab, setTab] = useState('edit')
  const [dialog, setDialog] = useState(null)
  const [storageOK, setStorageOK] = useState(true)
  const [notice, setNotice] = useState('')
  const mutation = useWorkMutation()
  const currentDraft = useRef(draft)
  currentDraft.current = draft
  useEffect(() => {
    if (!content) return
    if (!baseline) setBaseline(contentDraft(content))
    if (!draft) setDraft(contentDraft(content))
  }, [content, draft, baseline])
  const dirty = !!draft && (!baseline || changedContent(draft, baseline))
  const conflict = !!artifact && !!draft && artifact.head > draft.base
  useEffect(() => {
    if (!dirty) return
    const guard = (event) => { event.preventDefault(); event.returnValue = '' }
    window.addEventListener('beforeunload', guard)
    return () => window.removeEventListener('beforeunload', guard)
  }, [dirty])
  const change = (patch) => {
    const next = { ...draft, ...patch }
    setDraft(next); setNotice('')
    setStorageOK(persistDraft(sessionStorage, id, next))
  }
  const reload = () => {
    if (dirty && !confirm('Discard your unsaved draft and load the latest saved revision?')) return
    const next = contentDraft(content)
    setDraft(next); setBaseline(next); setNotice('Loaded the latest saved revision.')
    try { sessionStorage.removeItem(draftKey(id)) } catch { /* The in-memory draft remains usable. */ }
  }
  const save = () => {
    const submitted = { ...draft, sources: draft.sources.map((source) => ({ ...source })) }
    return mutation.run('artifact-save', { id, project: artifact.project, ...submitted }, (result) => {
      const saved = { ...submitted, base: result.artifact.head }
      setBaseline(saved)
      const next = changedContent(currentDraft.current, submitted) ? { ...currentDraft.current, base: result.artifact.head } : saved
      setDraft(next); setStorageOK(persistDraft(sessionStorage, id, next)); setNotice(`Saved revision ${result.artifact.head}. The public page is unchanged.`)
    })
  }
  return <div className="work-content artifact-content">
    <a className="work-breadcrumb" href="#/artifacts">All artifacts</a>
    <WorkFeedback query={query} />
    {artifact && <>
      <div className="work-heading"><div><h1>{artifact.title}</h1><p className="field-note">{artifact.project ? <a href={projectHref(artifact.project)}>Project access</a> : 'Private artifact'} · {artifact.head ? `Saved revision ${artifact.head}` : 'Agent draft · awaiting review'}{artifact.archived ? ' · Archived' : ''}</p></div><div className="work-actions"><button className="button ghost" disabled={!artifact.head || artifact.archived || mutation.busy} onClick={() => setDialog('publish')}>Publish…</button>{draft && <button className="button primary" disabled={mutation.busy || !dirty || conflict || artifact.archived || !draft.title.trim()} onClick={save}>{mutation.busy ? 'Saving…' : 'Save revision'}</button>}</div></div>
      {artifact.publication && <div className="work-publication"><div><strong>Public revision {artifact.publication.revision}</strong><a href={publicURL(artifact.publication.path)} target="_blank" rel="noopener noreferrer">{publicURL(artifact.publication.path)}</a>{artifact.head !== artifact.publication.revision && <span className="field-note">The latest saved revision is not the published revision.</span>}</div><button className="text-button" disabled={mutation.busy} onClick={() => setDialog('unpublish')}>Unpublish…</button></div>}
      {conflict && <div className="work-notice" role="status">Revision {artifact.head} is newer than your draft's base ({draft.base}). Your draft is preserved. Copy any changes you need before loading the latest revision. <button className="text-button" disabled={mutation.busy} onClick={reload}>Load latest revision</button></div>}
      {!storageOK && <div className="inline-error" role="alert">This browser could not retain your draft. Keep this page open and save or copy your work before navigating away.</div>}
      {!!notice && <p className="work-save-status" role="status">{notice}</p>}
      {dirty && !notice && <p className="field-note" role="status">Unsaved draft{storageOK ? ' · retained in this browser tab' : ''}. Publishing uses a saved revision, not this draft.</p>}
      <WorkFeedback query={mutation} />
      <nav className="work-tabs" aria-label="Artifact sections">{[['edit', 'Edit'], ['preview', 'Draft preview'], ['proposals', 'Proposals'], ['history', 'History']].map(([key, label]) => <button key={key} aria-pressed={tab === key} onClick={() => setTab(key)}>{label}</button>)}</nav>
      {tab === 'edit' && (draft ? <div className="work-editor"><label><span>Document title</span><input value={draft.title} maxLength={256} disabled={artifact.archived || mutation.busy} onChange={(event) => change({ title: event.target.value })} /></label><label><span>Document body · Markdown</span><textarea className="work-markdown-input" value={draft.body} disabled={artifact.archived || mutation.busy} onChange={(event) => change({ body: event.target.value })} placeholder="Start the document here…" spellCheck="true" /></label><p className="field-note">Headings, lists, links, tables, and code blocks are supported. Public formatting is intentionally limited; inspect the exact page before publishing.</p><Sources sources={draft.sources} onChange={(sources) => change({ sources })} disabled={artifact.archived || mutation.busy} /></div> : <div className="work-empty"><h2>Review the first draft</h2><p>This agent-created artifact has no accepted revision yet. Review its proposal to start the document.</p><button className="button primary" onClick={() => setTab('proposals')}>Review proposals</button></div>)}
      {tab === 'preview' && (draft ? <div className="work-draft-preview"><p className="field-note">Draft preview · not the public page</p><h2>{draft.title}</h2><Markdown text={draft.body} /></div> : <p>No accepted content yet. Review the first proposal.</p>)}
      {tab === 'proposals' && <Proposals artifact={artifact} />}
      {tab === 'history' && <History artifact={artifact} />}
      <div className="work-footer"><code title="Stable artifact ID">{id}</code><div className="work-actions">{content && <button className="text-button" onClick={() => setDialog('copy')}>Copy saved revision to project…</button>}<button className="text-button" disabled={mutation.busy || !!artifact.publication} onClick={() => setDialog('archive')}>{artifact.archived ? 'Restore artifact…' : 'Archive artifact…'}</button></div></div>
      {dialog === 'publish' && <Publication artifact={artifact} onClose={() => setDialog(null)} />}
      {dialog === 'copy' && <CopyArtifact artifact={artifact} content={content} onClose={() => setDialog(null)} />}
      {dialog === 'unpublish' && <WorkDialog title="Unpublish this page?" busy={mutation.busy} onClose={() => setDialog(null)}><p>The public URL will stop serving this page. Copies already downloaded or shared cannot be recalled. Your document and history stay private on the ship.</p><WorkFeedback query={mutation} /><div className="form-actions"><button className="button ghost" disabled={mutation.busy} onClick={() => setDialog(null)}>Cancel</button><button className="button primary" disabled={mutation.busy} onClick={() => mutation.run('unpublish', { id, exposure: artifact.exposure }, () => { setDialog(null); setNotice('Page unpublished.') })}>Unpublish page</button></div></WorkDialog>}
      {dialog === 'archive' && <WorkDialog title={artifact.archived ? 'Restore this artifact?' : 'Archive this artifact?'} busy={mutation.busy} onClose={() => setDialog(null)}><p>{artifact.archived ? 'Project members will be able to read it again under current access settings.' : 'Agents will no longer be able to read or propose changes. Accepted history and proposals remain available to you.'}</p><WorkFeedback query={mutation} /><div className="form-actions"><button className="button ghost" disabled={mutation.busy} onClick={() => setDialog(null)}>Cancel</button><button className="button primary" disabled={mutation.busy} onClick={() => mutation.run('artifact-archive', { id, base: artifact.head, archived: !artifact.archived }, () => setDialog(null))}>{artifact.archived ? 'Restore artifact' : 'Archive artifact'}</button></div></WorkDialog>}
    </>}
  </div>
}
