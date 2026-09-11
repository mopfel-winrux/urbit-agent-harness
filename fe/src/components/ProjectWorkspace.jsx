import { useEffect, useState } from 'react'
import { useWorkspace } from '../useWorkspace'
import { workId } from '../workspace'
import { NewArtifact } from './Workspace'
import { ArtifactRows, WorkDialog, WorkFeedback, WorkPager, artifactHref, useWorkMutation, workDate } from './WorkspaceCommon'

function ProjectArtifacts({ project }) {
  const [offset, setOffset] = useState(0)
  const [create, setCreate] = useState(false)
  const query = useWorkspace('artifacts', { project: project.id, offset, limit: 24 })
  return <section><div className="section-title"><h2>Project documents</h2><button className="button primary" disabled={project.archived || create} onClick={() => setCreate(true)}>New artifact</button></div>
    {create && <NewArtifact project={project.id} onCancel={() => setCreate(false)} onCreated={(artifact) => { location.hash = artifactHref(artifact.id) }} />}
    <WorkFeedback query={query} />
    {!query.loading && !query.error && !query.value?.items?.length && <div className="work-empty"><h3>Put the shared work here</h3><p>Create a project document or copy a saved revision from a private artifact. Members can read the documents and their history; agent edits arrive as proposals.</p></div>}
    <ArtifactRows items={query.value?.items} /><WorkPager query={query} offset={offset} onOffset={setOffset} />
  </section>
}

function TaskEditor({ task, project, onClose }) {
  const [status, setStatus] = useState(task.status)
  const [outcome, setOutcome] = useState(task.outcome)
  const [artifact, setArtifact] = useState(task.artifact || '')
  const mutation = useWorkMutation()
  return <WorkDialog title="Update task" onClose={onClose} busy={mutation.busy}>
    <h3>{task.title}</h3><p>{task.description}</p><p className="field-note">{task.claimant ? `Claimed by ${task.claimant.label}` : 'Unclaimed'} · version {task.version}</p>
    <form onSubmit={(event) => { event.preventDefault(); void mutation.run('task-update', { id: task.id, version: task.version, status, outcome, artifact: artifact.trim() || null }, onClose) }}>
      <label><span>Status</span><select value={status} disabled={mutation.busy || project.archived} onChange={(event) => setStatus(event.target.value)}><option value="open">Open · release claim</option><option value="claimed">Claimed</option><option value="blocked">Blocked</option><option value="done">Done</option></select></label>
      <label><span>Outcome or next step</span><textarea rows={4} maxLength={4096} value={outcome} disabled={mutation.busy} onChange={(event) => setOutcome(event.target.value)} /></label>
      <label><span>Result artifact ID (optional)</span><input value={artifact} maxLength={96} disabled={mutation.busy} onChange={(event) => setArtifact(event.target.value)} placeholder="An artifact in this project" /></label>
      <p className="field-note">Reopening makes the task available to another agent. Marking it done records a result; it does not verify external actions.</p>
      <WorkFeedback query={mutation} />
      <div className="form-actions"><button type="button" className="button ghost" disabled={mutation.busy} onClick={onClose}>Cancel</button><button className="button primary" disabled={mutation.busy || project.archived}>{mutation.busy ? 'Saving…' : 'Save task'}</button></div>
    </form>
  </WorkDialog>
}

function NewTask({ project, onClose }) {
  const [id] = useState(workId)
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const mutation = useWorkMutation()
  return <form className="work-create" onSubmit={(event) => { event.preventDefault(); if (title.trim()) void mutation.run('task-create', { id, project: project.id, title: title.trim(), description }, onClose) }}>
    <h3>New task</h3><label><span>Task title</span><input autoFocus value={title} maxLength={256} required disabled={mutation.busy} onChange={(event) => setTitle(event.target.value)} placeholder="A bounded piece of work" /></label>
    <label><span>Brief and expected result</span><textarea rows={3} value={description} maxLength={4096} disabled={mutation.busy} onChange={(event) => setDescription(event.target.value)} /></label>
    <p className="field-note">Creating a task does not start an agent. Ask a participating conversation to inspect the project and claim the task.</p><WorkFeedback query={mutation} />
    <div className="form-actions"><button className="button ghost" type="button" disabled={mutation.busy} onClick={onClose}>Cancel</button><button className="button primary" disabled={mutation.busy || !title.trim()}>{mutation.busy ? 'Creating…' : 'Create task'}</button></div>
  </form>
}

function Tasks({ project }) {
  const [offset, setOffset] = useState(0)
  const [create, setCreate] = useState(false)
  const [selected, setSelected] = useState(null)
  const query = useWorkspace('tasks', { project: project.id, offset, limit: 24 })
  const mutation = useWorkMutation()
  return <section><div className="section-title"><h2>Shared tasks</h2><button className="button primary" disabled={project.archived || create} onClick={() => setCreate(true)}>New task</button></div>
    <p className="field-note">Agents claim work before acting. A claim belongs to one worker; only that worker or you can update it. Live delegated agents can participate through their parent's project access.</p>
    {create && <NewTask project={project} onClose={() => setCreate(false)} />}
    <WorkFeedback query={query} /><WorkFeedback query={mutation} />
    {!query.loading && !query.error && !query.value?.items?.length && <div className="work-empty"><h3>Give each agent a clear piece of work</h3><p>Add a brief and the expected output. A task can link to a project artifact when the work is ready.</p></div>}
    <div className="work-task-list">{query.value?.items?.map((task) => <article className="work-task" key={task.id}>
      <div className="section-title"><h3>{task.title}</h3><span className={`work-label ${task.status === 'done' ? 'public' : ''}`}>{task.status}</span></div>
      {task.description && <p>{task.description}</p>}<p className="field-note">{task.claimant ? `Claimed by ${task.claimant.label}` : 'Available to claim'} · {workDate(task.updated)}</p>
      {task.outcome && <p className="work-task-outcome">{task.outcome}</p>}{task.artifact && <a href={artifactHref(task.artifact)}>Open result artifact</a>}
      <div className="work-task-actions"><code>{task.id}</code><div className="work-actions">{task.status === 'open' && <button className="button ghost" disabled={project.archived || mutation.busy} onClick={() => mutation.run('task-claim', { id: task.id, version: task.version })}>Claim for myself</button>}<button className="button ghost" disabled={project.archived || mutation.busy} onClick={() => setSelected(task)}>Update task</button></div></div>
    </article>)}</div>
    <WorkPager query={query} offset={offset} onOffset={setOffset} />
    {selected && <TaskEditor key={`${selected.id}:${selected.version}`} task={selected} project={project} onClose={() => setSelected(null)} />}
  </section>
}

function Access({ project }) {
  const [offset, setOffset] = useState(0)
  const query = useWorkspace('sessions', { offset, limit: 24 })
  const [retained, setRetained] = useState([])
  const sessions = [...new Map([...retained, ...(query.value?.items || [])].map((session) => [session.scope, session])).values()]
  const [scope, setScope] = useState('')
  const [role, setRole] = useState('reader')
  const [pending, setPending] = useState(null)
  const mutation = useWorkMutation()
  const byScope = new Map(sessions.map((session) => [session.scope, session]))
  const members = project.members || []
  return <section><h2>Conversation access</h2><p>Members can read all documents, accepted history, proposals, and tasks in this project. Contributors can also propose changes and claim tasks.</p><p className="field-note">Private conversation transcripts are not shared. Workspace tools must be enabled separately in each conversation's settings. Removing access cannot erase material already read or copied.</p>
    <WorkFeedback query={query} /><WorkFeedback query={mutation} />
    <div className="work-members">{members.map((member) => {
      const session = byScope.get(member.scope)
      return <div className="work-member" key={member.scope}><div><strong>{session?.sessionId || member.scope}</strong><span className="work-record-meta">{member.role} · {session ? session.workspaceTools ? 'Workspace tools enabled' : 'Workspace tools not enabled' : 'Conversation name unavailable on this page'}</span></div><div className="work-actions">{session && <a className="text-button" href={`#/settings/${encodeURIComponent(session.sessionId)}`}>Conversation settings</a>}<button className="text-button" disabled={mutation.busy} onClick={() => setPending({ scope: member.scope, role: member.role === 'reader' ? 'contributor' : 'reader', label: session?.sessionId || member.scope })}>{member.role === 'reader' ? 'Make contributor…' : 'Make reader…'}</button><button className="text-button danger-text" disabled={mutation.busy} onClick={() => setPending({ scope: member.scope, role: null, label: session?.sessionId || member.scope })}>Remove…</button></div></div>
    })}</div>
    {!members.length && <p className="work-empty">Only you have access. Add a conversation to start sharing project work.</p>}
    <form className="work-access-form" onSubmit={(event) => { event.preventDefault(); const session = byScope.get(scope); if (session) setPending({ scope, role, label: session.sessionId }) }}>
      <h3>Add a conversation</h3><div className="field-grid"><label><span>Conversation</span><select value={scope} disabled={mutation.busy || project.archived} onChange={(event) => setScope(event.target.value)}><option value="">Choose a conversation</option>{sessions.filter((session) => !members.some((member) => member.scope === session.scope)).map((session) => <option value={session.scope} key={session.scope}>{session.sessionId}{!session.workspaceTools ? ' · enable Workspace tools separately' : ''}</option>)}</select></label><label><span>Access level</span><select value={role} disabled={mutation.busy || project.archived} onChange={(event) => setRole(event.target.value)}><option value="reader">Reader</option><option value="contributor">Contributor</option></select></label></div>
      {query.value?.nextOffset != null && <button className="text-button" type="button" onClick={() => { setRetained(sessions); setOffset(query.value.nextOffset) }}>Load more conversations</button>}
      <div className="form-actions"><button className="button primary" disabled={!scope || mutation.busy || project.archived}>Review access…</button></div>
    </form>
    {pending && <WorkDialog title={pending.role ? 'Share project access?' : 'Remove project access?'} busy={mutation.busy} onClose={() => setPending(null)}><p>{pending.role ? `“${pending.label}” will have ${pending.role} access to all current and future documents, history, proposals, and task records in “${project.title}”.` : `“${pending.label}” will lose project access. Existing proposals from this source cannot be accepted without current contributor access. Previously copied material cannot be recalled.`}</p><p className="field-note">Conversation identity is stable through renames. A deleted and recreated conversation does not inherit this membership. Its private transcript and resource tool grants are unchanged.</p><WorkFeedback query={mutation} /><div className="form-actions"><button className="button ghost" disabled={mutation.busy} onClick={() => setPending(null)}>Cancel</button><button className="button primary" disabled={mutation.busy} onClick={() => mutation.run('member', { id: project.id, version: project.version, scope: pending.scope, role: pending.role }, () => { setPending(null); setScope('') })}>{mutation.busy ? 'Saving access…' : pending.role ? 'Confirm access' : 'Remove access'}</button></div></WorkDialog>}
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
  return <section><h2>Project settings</h2><form onSubmit={(event) => { event.preventDefault(); void mutation.run('project-edit', { id: project.id, version: base, title, description, archived: project.archived }, (result) => { setBase(result.version); setSaved('Project saved.') }) }}>
    <label><span>Project name</span><input required maxLength={256} value={title} disabled={mutation.busy} onChange={(event) => { setTitle(event.target.value); setSaved('') }} /></label><label><span>Purpose</span><textarea rows={4} maxLength={4096} value={description} disabled={mutation.busy} onChange={(event) => { setDescription(event.target.value); setSaved('') }} /></label>
    {stale && <p className="work-notice">Project settings or access changed. Your edits are preserved. <button type="button" className="text-button" onClick={() => { if (!dirty || confirm('Discard these unsaved project settings and load the current version?')) { setTitle(project.title); setDescription(project.description); setBase(project.version) } }}>Load current settings</button></p>}
    {saved && <p role="status">{saved}</p>}<WorkFeedback query={mutation} /><div className="form-actions"><button className="button primary" disabled={mutation.busy || stale || !dirty || !title.trim()}>{mutation.busy ? 'Saving…' : 'Save project'}</button></div>
  </form><div className="work-footer"><p className="field-note">{project.archived ? 'Archived projects are unavailable to agents.' : 'Archiving suspends project access. It does not unpublish public pages.'}</p><button className="button ghost" disabled={mutation.busy} onClick={() => setConfirmArchive(true)}>{project.archived ? 'Restore project…' : 'Archive project…'}</button></div>
    {confirmArchive && <WorkDialog title={project.archived ? 'Restore this project?' : 'Archive this project?'} busy={mutation.busy} onClose={() => setConfirmArchive(false)}><p>{project.archived ? 'Existing members will regain their saved access levels.' : 'Agents will lose access to the project. Documents, task claims, and history remain. Public pages stay online until you unpublish them individually.'}</p><WorkFeedback query={mutation} /><div className="form-actions"><button className="button ghost" disabled={mutation.busy} onClick={() => setConfirmArchive(false)}>Cancel</button><button className="button primary" disabled={mutation.busy} onClick={() => mutation.run('project-edit', { id: project.id, version: project.version, title: project.title, description: project.description, archived: !project.archived }, () => setConfirmArchive(false))}>{project.archived ? 'Restore project' : 'Archive project'}</button></div></WorkDialog>}
  </section>
}

export default function ProjectWorkspace({ id }) {
  const query = useWorkspace('project', { id })
  const [tab, setTab] = useState('documents')
  const project = query.value
  return <div className="work-content"><a className="work-breadcrumb" href="#/projects">All projects</a><WorkFeedback query={query} />{project && <>
    <div className="work-heading"><div><h1>{project.title}</h1><p className="work-description">{project.description || 'A shared place for documents and tasks.'}</p></div><span className="work-label">{project.archived ? 'Archived' : 'Private project'}</span></div>
    {project.archived && <p className="work-notice">This project is archived. Agent access is suspended; public pages are unchanged.</p>}
    <nav className="work-tabs" aria-label="Project sections">{[['documents', 'Documents'], ['tasks', 'Tasks'], ['access', 'Access'], ['settings', 'Settings']].map(([key, label]) => <button key={key} aria-pressed={tab === key} onClick={() => setTab(key)}>{label}</button>)}</nav>
    {tab === 'documents' && <ProjectArtifacts project={project} />}{tab === 'tasks' && <Tasks project={project} />}{tab === 'access' && <Access project={project} />}{tab === 'settings' && <ProjectSettings project={project} />}
    <p className="work-id field-note">Project ID: <code>{id}</code></p>
  </>}</div>
}
