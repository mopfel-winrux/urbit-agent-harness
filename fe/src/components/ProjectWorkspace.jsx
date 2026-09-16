import { useEffect, useState } from 'react'
import { useWorkspace } from '../useWorkspace'
import { workId } from '../workspace'
import { NewArtifact } from './Workspace'
import ProjectAccess from './ProjectAccess'
import { ArtifactRows, ProjectSelect, WorkDialog, WorkFeedback, WorkPager, artifactHref, useWorkMutation, workDate } from './WorkspaceCommon'

function ProjectArtifacts({ project }) {
  const [offset, setOffset] = useState(0)
  const [create, setCreate] = useState(false)
  const query = useWorkspace('artifacts', { project: project?.id || null, offset, limit: 24 })
  return <section><div className="section-title"><h2>Project documents</h2><button className="button primary" disabled={project?.archived || create} onClick={() => setCreate(true)}>New artifact</button></div>
    {create && <NewArtifact project={project.id} onCancel={() => setCreate(false)} onCreated={(artifact) => { location.hash = artifactHref(artifact.id) }} />}
    <WorkFeedback query={query} />
    {!query.loading && !query.error && !query.value?.items?.length && <div className="work-empty"><h3>Put the shared work here</h3><p>Create a project document or copy a saved revision from a private artifact. Members can read the documents and their history; agent edits arrive as proposals.</p></div>}
    <ArtifactRows items={query.value?.items} /><WorkPager query={query} offset={offset} onOffset={setOffset} />
  </section>
}

function TaskEditor({ task, onClose, onDeleted }) {
  const [title, setTitle] = useState(task.title)
  const [description, setDescription] = useState(task.description)
  const [project, setProject] = useState(task.project || null)
  const [deleting, setDeleting] = useState(false)
  const [status, setStatus] = useState(task.status)
  const [outcome, setOutcome] = useState(task.outcome)
  const [artifact, setArtifact] = useState(task.artifact || '')
  const mutation = useWorkMutation()
  if (deleting) return <WorkDialog title="Delete this task?" onClose={() => setDeleting(false)} busy={mutation.busy}>
    <p>Delete “{task.title}”? This permanently removes the task record. It does not stop an agent or delete linked documents.</p>
    <WorkFeedback query={mutation} />
    <div className="form-actions"><button className="button ghost" disabled={mutation.busy} onClick={() => setDeleting(false)}>Keep task</button><button className="button danger-text" disabled={mutation.busy} onClick={() => mutation.run('task-delete', { id: task.id, version: task.version }, onDeleted)}>{mutation.busy ? 'Deleting…' : 'Delete task'}</button></div>
  </WorkDialog>
  return <WorkDialog title="Update task" onClose={onClose} busy={mutation.busy}>
    <form onSubmit={(event) => { event.preventDefault(); void mutation.run('task-update', { id: task.id, version: task.version, title: title.trim(), description, project, status, outcome, artifact: artifact.trim() || null }, () => { onClose(); if (project !== (task.project || null)) location.hash = `#/tasks/${encodeURIComponent(task.id)}` }) }}>
      <label><span>Task title</span><input autoFocus required maxLength={256} value={title} disabled={mutation.busy} onChange={(event) => setTitle(event.target.value)} /></label>
      <label><span>Brief and expected result</span><textarea rows={3} maxLength={4096} value={description} disabled={mutation.busy} onChange={(event) => setDescription(event.target.value)} /></label>
      <ProjectSelect value={project} onChange={setProject} disabled={mutation.busy} emptyLabel="No project" />
      <label><span>Status</span><select value={status} disabled={mutation.busy} onChange={(event) => setStatus(event.target.value)}><option value="open">Open</option><option value="claimed">Assigned</option><option value="blocked">Needs attention</option><option value="done">Complete</option></select></label>
      <label><span>Outcome or next step</span><textarea rows={4} maxLength={4096} value={outcome} disabled={mutation.busy} onChange={(event) => setOutcome(event.target.value)} /></label>
      <label><span>Result artifact ID (optional)</span><input value={artifact} maxLength={96} disabled={mutation.busy} onChange={(event) => setArtifact(event.target.value)} placeholder="An accessible result document" /></label>
      <p className="field-note">Reopening makes the task available to another agent. Marking it done records a result; it does not verify external actions.</p>
      <WorkFeedback query={mutation} />
      <div className="form-actions"><button type="button" className="text-button" disabled={mutation.busy} onClick={() => setDeleting(true)}>Delete task…</button><button type="button" className="button ghost" disabled={mutation.busy} onClick={onClose}>Cancel</button><button className="button primary" disabled={mutation.busy || !title.trim()}>{mutation.busy ? 'Saving…' : 'Save task'}</button></div>
    </form>
  </WorkDialog>
}

function NewTask({ project, onClose }) {
  const [id] = useState(workId)
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [group, setGroup] = useState(project?.id || null)
  const mutation = useWorkMutation()
  return <form className="work-create" onSubmit={(event) => { event.preventDefault(); if (title.trim()) void mutation.run('task-create', { id, project: group, title: title.trim(), description }, () => { onClose(); if (group !== (project?.id || null)) location.hash = `#/tasks/${encodeURIComponent(id)}` }) }}>
    <h3>New task</h3><label><span>Task title</span><input autoFocus value={title} maxLength={256} required disabled={mutation.busy} onChange={(event) => setTitle(event.target.value)} placeholder="A bounded piece of work" /></label>
    <label><span>Brief and expected result</span><textarea rows={3} value={description} maxLength={4096} disabled={mutation.busy} onChange={(event) => setDescription(event.target.value)} /></label>
    <ProjectSelect value={group} onChange={setGroup} disabled={mutation.busy} emptyLabel="No project" />
    <p className="field-note">A piece of work to keep track of. Your agent handles the bookkeeping.</p><WorkFeedback query={mutation} />
    <div className="form-actions"><button className="button ghost" type="button" disabled={mutation.busy} onClick={onClose}>Cancel</button><button className="button primary" disabled={mutation.busy || !title.trim()}>{mutation.busy ? 'Creating…' : 'Create task'}</button></div>
  </form>
}

export function Tasks({ project, initialTask }) {
  const [offset, setOffset] = useState(0)
  const [create, setCreate] = useState(false)
  const [selected, setSelected] = useState(null)
  const [focused, setFocused] = useState(initialTask || null)
  useEffect(() => { if (initialTask) { setFocused(initialTask); setSelected(null) } }, [initialTask])
  const query = useWorkspace(focused ? 'task' : 'tasks', focused ? { id: focused } : { project: project?.id || null, includeArchived: !!project?.archived, offset, limit: 24 })
  const mismatch = focused && query.value && project && query.value.project !== project.id
  const items = focused ? (query.value && !mismatch ? [query.value] : []) : query.value?.items || []
  return <section><div className="section-title"><h2>Tasks</h2><button className="button primary" disabled={project?.archived || create} onClick={() => setCreate(true)}>New task</button></div>
    <p className="field-note">Ask for work or updates in your conversation. Tasks keep track of what needs doing and who is handling it.</p>
    {create && <NewTask project={project} onClose={() => setCreate(false)} />}
    <WorkFeedback query={query} />
    {focused && <button className="text-button" onClick={() => setFocused(null)}>Show all tasks</button>}
    {mismatch && <p className="inline-error" role="alert">This task belongs to another project. Open it from the work inbox.</p>}
    {!focused && !query.loading && !query.error && !items.length && <div className="work-empty"><h3>No tasks yet</h3><p>You can ask your agent for help without creating a task here.</p></div>}
    <div className="work-task-list">{items.map((task) => <article className="work-task" key={task.id}>
      <div className="section-title"><h3>{task.title}</h3><span className={`work-label ${task.status === 'done' ? 'public' : ''}`}>{{ open: 'Open', claimed: 'Assigned', blocked: 'Needs attention', done: 'Complete' }[task.status]}</span></div>
      {task.description && <p>{task.description}</p>}<p className="field-note">{workDate(task.updated)}</p>
      {task.outcome && <p className="work-task-outcome">{task.outcome}</p>}{task.artifact && <a href={artifactHref(task.artifact)}>Open result artifact</a>}
      <div className="work-task-actions"><button className="button ghost" onClick={() => setSelected(task)}>Update task</button></div>
    </article>)}</div>
    {!focused && <WorkPager query={query} offset={offset} onOffset={setOffset} />}
    {selected && <TaskEditor key={`${selected.id}:${selected.version}`} task={selected} onClose={() => setSelected(null)} onDeleted={() => { setSelected(null); setFocused(null); if (initialTask && !project) location.hash = '#/tasks' }} />}
  </section>
}

function ProjectSettings({ project }) {
  const [title, setTitle] = useState(project.title)
  const [description, setDescription] = useState(project.description)
  const [base, setBase] = useState(project.version)
  const [confirmArchive, setConfirmArchive] = useState(false)
  const [saved, setSaved] = useState('')
  const mutation = useWorkMutation()
  const dirty = title !== project.title || description !== project.description
  const stale = base !== project.version
  useEffect(() => { if (!dirty) setBase(project.version) }, [project.version, dirty])
  return <section><h2>Project settings</h2><form onSubmit={(event) => { event.preventDefault(); void mutation.run('project-edit', { id: project.id, version: base, title, description, archived: project?.archived }, (result) => { setBase(result.version); setSaved('Project saved.') }) }}>
    <label><span>Project name</span><input required maxLength={256} value={title} disabled={mutation.busy} onChange={(event) => { setTitle(event.target.value); setSaved('') }} /></label><label><span>Purpose</span><textarea rows={4} maxLength={4096} value={description} disabled={mutation.busy} onChange={(event) => { setDescription(event.target.value); setSaved('') }} /></label>
    {stale && <p className="work-notice">Project settings or access changed. Your edits are preserved. <button type="button" className="text-button" onClick={() => { if (!dirty || confirm('Discard these unsaved project settings and load the current version?')) { setTitle(project.title); setDescription(project.description); setBase(project.version) } }}>Load current settings</button></p>}
    {saved && <p role="status">{saved}</p>}<WorkFeedback query={mutation} /><div className="form-actions"><button className="button primary" disabled={mutation.busy || stale || !dirty || !title.trim()}>{mutation.busy ? 'Saving…' : 'Save project'}</button></div>
  </form><div className="work-footer"><p className="field-note">{project?.archived ? 'Archived projects are hidden from active project lists.' : 'Archiving suspends project document access. It does not unpublish public pages.'}</p><button className="button ghost" disabled={mutation.busy} onClick={() => setConfirmArchive(true)}>{project?.archived ? 'Restore project…' : 'Archive project…'}</button></div>
    {confirmArchive && <WorkDialog title={project?.archived ? 'Restore this project?' : 'Archive this project?'} busy={mutation.busy} onClose={() => setConfirmArchive(false)}><p>{project?.archived ? 'Existing members will regain their saved access levels.' : 'Agents will lose access to project documents. Tasks and history remain. Public pages stay online until you unpublish them individually.'}</p><WorkFeedback query={mutation} /><div className="form-actions"><button className="button ghost" disabled={mutation.busy} onClick={() => setConfirmArchive(false)}>Cancel</button><button className="button primary" disabled={mutation.busy} onClick={() => mutation.run('project-edit', { id: project.id, version: project.version, title: project.title, description: project.description, archived: !project?.archived }, () => setConfirmArchive(false))}>{project?.archived ? 'Restore project' : 'Archive project'}</button></div></WorkDialog>}
  </section>
}

export default function ProjectWorkspace({ id, initialTask }) {
  const query = useWorkspace('project', { id })
  const [tab, setTab] = useState(initialTask ? 'tasks' : 'documents')
  useEffect(() => { if (initialTask) setTab('tasks') }, [initialTask])
  const project = query.value
  return <div className="work-content"><a className="work-breadcrumb" href="#/projects">All projects</a><WorkFeedback query={query} />{project && <>
    <div className="work-heading"><div><h1>{project.title}</h1><p className="work-description">{project.description || 'A collection of related tasks.'}</p></div></div>
    {project?.archived && <p className="work-notice">This project is archived. Document access is suspended; tasks and public pages are unchanged.</p>}
    <nav className="work-tabs" aria-label="Project sections">{[['documents', 'Documents'], ['tasks', 'Tasks'], ['access', 'Sharing'], ['settings', 'Settings']].map(([key, label]) => <button key={key} aria-pressed={tab === key} onClick={() => setTab(key)}>{label}</button>)}</nav>
    {tab === 'documents' && <ProjectArtifacts project={project} />}{tab === 'tasks' && <Tasks project={project} initialTask={initialTask} />}{tab === 'access' && <ProjectAccess key={project.id} project={project} />}{tab === 'settings' && <ProjectSettings project={project} />}
  </>}</div>
}
