import { useState } from 'react'
import { useWorkspace } from '../useWorkspace'
import { workId } from '../workspace'
import { BackIcon, PlusIcon } from './Icons'
import ArtifactEditor from './ArtifactEditor'
import ProjectWorkspace from './ProjectWorkspace'
import { ArtifactRows, ProjectSelect, WorkDialog, WorkFeedback, WorkPager, artifactHref, projectHref, useWorkMutation } from './WorkspaceCommon'
import './workspace.css'

export function NewArtifact({ project = null, onCancel, onCreated }) {
  const [id] = useState(workId)
  const [title, setTitle] = useState('')
  const [selected, setSelected] = useState(project)
  const mutation = useWorkMutation()
  return <form className="work-create" onSubmit={(event) => { event.preventDefault(); if (title.trim()) void mutation.run('artifact-create', { id, title: title.trim(), body: '', sources: [], project: selected }, (result) => onCreated(result.artifact)) }}>
    <h2>New artifact</h2>
    <label><span>Title</span><input autoFocus required maxLength={256} value={title} disabled={mutation.busy} onChange={(event) => setTitle(event.target.value)} placeholder="What are you working on?" /></label>
    {project == null && <ProjectSelect value={selected} onChange={setSelected} disabled={mutation.busy} />}
    <p className="field-note">{selected ? 'Project members can read this artifact and its history. Contributors can propose edits.' : 'Private in Harness. To share it with agents later, copy a selected revision into a project.'} The document is created in Notes. Nothing is published automatically.</p>
    <WorkFeedback query={mutation} />
    <div className="form-actions"><button type="button" className="button ghost" disabled={mutation.busy} onClick={onCancel}>Cancel</button><button className="button primary" disabled={mutation.busy || !title.trim()}>{mutation.busy ? 'Creating…' : 'Create artifact'}</button></div>
  </form>
}

function NewProject({ onCancel }) {
  const [id] = useState(workId)
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const mutation = useWorkMutation()
  return <form className="work-create" onSubmit={(event) => { event.preventDefault(); if (title.trim()) void mutation.run('project-create', { id, title: title.trim(), description }, (project) => { location.hash = projectHref(project.id) }) }}>
    <h2>New project</h2>
    <label><span>Project name</span><input autoFocus required maxLength={256} value={title} disabled={mutation.busy} onChange={(event) => setTitle(event.target.value)} /></label>
    <label><span>Purpose</span><textarea rows={3} maxLength={4096} value={description} disabled={mutation.busy} onChange={(event) => setDescription(event.target.value)} placeholder="The shared work and what a good outcome looks like" /></label>
    <p className="field-note">Projects start private. Add conversations explicitly to share documents and task records—not their transcripts or extra tools.</p>
    <WorkFeedback query={mutation} />
    <div className="form-actions"><button type="button" className="button ghost" disabled={mutation.busy} onClick={onCancel}>Cancel</button><button className="button primary" disabled={mutation.busy || !title.trim()}>{mutation.busy ? 'Creating…' : 'Create project'}</button></div>
  </form>
}

function Directory({ kind }) {
  const [offset, setOffset] = useState(0)
  const [create, setCreate] = useState(false)
  const query = useWorkspace(kind, { offset, limit: 24 })
  const artifacts = kind === 'artifacts'
  return <div className="work-content">
    <div className="work-heading"><div className="page-header"><h1>{artifacts ? 'Artifacts' : 'Projects'}</h1><p>{artifacts ? 'Documents that outlive the conversation. Edit, review, and publish a saved revision.' : 'Shared documents and tasks, with explicit access for each conversation.'}</p></div><button className="button primary" onClick={() => setCreate(true)} disabled={create}><PlusIcon />{artifacts ? 'New artifact' : 'New project'}</button></div>
    {create && (artifacts ? <NewArtifact onCancel={() => setCreate(false)} onCreated={(artifact) => { location.hash = artifactHref(artifact.id) }} /> : <NewProject onCancel={() => setCreate(false)} />)}
    <WorkFeedback query={query} />
    {!query.loading && !query.error && !query.value?.items?.length && <div className="work-empty"><h2>{artifacts ? 'A place for the work itself' : 'Bring a few conversations together'}</h2><p>{artifacts ? 'Start a document here, or ask an agent with Workspace tools to prepare a draft. Agent drafts wait for your review before becoming accepted revisions.' : 'Create a project, add the conversations that should participate, and give each one a clear task. Their private transcripts stay separate.'}</p></div>}
    {artifacts ? <ArtifactRows items={query.value?.items} /> : <div className="work-records">{query.value?.items?.map((project) => <a className="work-record" key={project.id} href={projectHref(project.id)}><div><strong>{project.title}</strong><span className="work-record-meta">{project.description || 'No purpose added yet'}</span></div><span className="work-label">{project.archived ? 'Archived' : `${project.members?.length || 0} conversations`}</span></a>)}</div>}
    <WorkPager query={query} offset={offset} onOffset={setOffset} />
  </div>
}

function NotesOperation() {
  const query = useWorkspace('notes-status')
  const pending = query.value?.pending
  const mutation = useWorkMutation()
  const [release, setRelease] = useState(false)
  const [confirmed, setConfirmed] = useState(false)
  if (!pending) return null
  return <div className="work-content work-operation">
    <div className="work-notice" role="status"><strong>{pending.uncertain ? 'Notes result is uncertain' : 'Waiting for Notes'}</strong><p>{pending.action} · {pending.artifact}. Other document changes wait until this operation is resolved.</p><div className="work-actions"><a href="/notes/" target="_blank" rel="noopener noreferrer">Inspect Notes</a><button className="text-button" disabled={mutation.busy} onClick={() => mutation.run('notes-resume', { id: pending.id })}>Check result again</button><button className="text-button" disabled={mutation.busy} onClick={() => { setConfirmed(false); setRelease(true) }}>Stop waiting…</button></div><WorkFeedback query={mutation} /></div>
    {release && <WorkDialog title="Stop waiting for this Notes result?" onClose={() => setRelease(false)} busy={mutation.busy}>
      <p>This only releases Harness’s pending operation. It cannot cancel or undo a change already sent to Notes. A new Note or public page may already exist, or may still appear.</p>
      <p>Inspect Notes first. Do not repeat a create or publish just because its result was lost. Your Note, draft, and proposal are not deleted by this action.</p>
      <label className="work-check"><input type="checkbox" checked={confirmed} disabled={mutation.busy} onChange={(event) => setConfirmed(event.target.checked)} /><span>I inspected Notes and understand that this does not undo the operation.</span></label>
      <WorkFeedback query={mutation} />
      <div className="form-actions"><button className="button ghost" disabled={mutation.busy} onClick={() => setRelease(false)}>Keep waiting</button><button className="button primary" disabled={mutation.busy || !confirmed} onClick={() => mutation.run('notes-release', { id: pending.id, confirm: `release ${pending.id}` }, () => setRelease(false))}>Stop waiting</button></div>
    </WorkDialog>}
  </div>
}

export default function Workspace({ kind, id, onBack }) {
  return <main className="workspace work-workspace">
    <header className="topbar"><button className="back-button" onClick={onBack}><BackIcon />Conversations</button><nav className="work-topnav" aria-label="Workspace"><a href="#/artifacts" aria-current={kind === 'artifacts' ? 'page' : undefined}>Artifacts</a><a href="#/projects" aria-current={kind === 'projects' ? 'page' : undefined}>Projects</a></nav></header>
    <NotesOperation />
    {id ? kind === 'artifacts' ? <ArtifactEditor key={id} id={id} /> : <ProjectWorkspace key={id} id={id} /> : <Directory key={kind} kind={kind} />}
  </main>
}
