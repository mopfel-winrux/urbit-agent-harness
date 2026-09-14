import { useState } from 'react'
import { useWorkspace } from '../useWorkspace'
import { projectRoles, roleDescriptions } from '../projectAccess'
import { WorkDialog, WorkFeedback, useWorkMutation } from './WorkspaceCommon'
import ProjectClients from './ProjectClients'

export default function ProjectAccess({ project }) {
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
  const changed = pending && pending.version !== project.version
  const review = (choice) => setPending({ ...choice, version: project.version })
  return <>
    <section aria-labelledby="conversation-access-heading"><h2 id="conversation-access-heading">Conversation access</h2><p>Members can read all documents, accepted history, proposals, and tasks in this project. Contributors can also propose changes and claim tasks. Maintainers can coordinate any project task and edit the project’s details.</p><p className="field-note">Only you can change access, archive the project, accept proposals, or publish through Workspace. Native Notes permissions are separate. Private transcripts are not shared, and Workspace tools must be enabled separately in each conversation.</p>
      <WorkFeedback query={query} /><WorkFeedback query={mutation} />
      <div className="work-members">{members.map((member) => {
        const session = byScope.get(member.scope)
        return <div className="work-member" key={member.scope}><div><strong>{session?.sessionId || member.scope}</strong><span className="work-record-meta">{member.role} · {session ? session.workspaceTools ? 'Workspace tools enabled' : 'Workspace tools not enabled' : 'Conversation name unavailable on this page'}</span></div><div className="work-actions">{session && <a className="text-button" href={`#/settings/${encodeURIComponent(session.sessionId)}`}>Conversation settings</a>}<button className="text-button" disabled={mutation.busy || project.archived} onClick={() => review({ scope: member.scope, role: member.role, label: session?.sessionId || member.scope, existing: true })}>Change role…</button><button className="text-button danger-text" disabled={mutation.busy} onClick={() => review({ scope: member.scope, role: null, label: session?.sessionId || member.scope })}>Remove…</button></div></div>
      })}</div>
      {!members.length && <p className="work-empty">Only you have access. Add a conversation to start sharing project work.</p>}
      <form className="work-access-form" onSubmit={(event) => { event.preventDefault(); const session = byScope.get(scope); if (session) review({ scope, role, label: session.sessionId }) }}>
        <h3>Add a conversation</h3><div className="field-grid"><label><span>Conversation</span><select value={scope} disabled={mutation.busy || project.archived} onChange={(event) => setScope(event.target.value)}><option value="">Choose a conversation</option>{sessions.filter((session) => !members.some((member) => member.scope === session.scope)).map((session) => <option value={session.scope} key={session.scope}>{session.sessionId}{!session.workspaceTools ? ' · enable Workspace tools separately' : ''}</option>)}</select></label><label><span>Access level</span><select value={role} disabled={mutation.busy || project.archived} onChange={(event) => setRole(event.target.value)}>{projectRoles.map((value) => <option value={value} key={value}>{value[0].toUpperCase() + value.slice(1)}</option>)}</select></label></div>
        <p className="field-note">{roleDescriptions[role]}</p>
        {query.value?.nextOffset != null && <button className="text-button" type="button" onClick={() => { setRetained(sessions); setOffset(query.value.nextOffset) }}>Load more conversations</button>}
        <div className="form-actions"><button className="button primary" disabled={!scope || mutation.busy || project.archived}>Review access…</button></div>
      </form>
      {pending && <WorkDialog title={pending.role ? 'Share project access?' : 'Remove project access?'} busy={mutation.busy} onClose={() => setPending(null)}>
        <p>{pending.role ? `“${pending.label}” will have ${pending.role} access to all current and future documents, history, proposals, and task records in “${project.title}”.` : `“${pending.label}” will lose project access. Existing proposals from this source cannot be accepted without current contributor access. Previously copied material cannot be recalled.`}</p>
        {pending.existing && <label><span>New access level</span><select value={pending.role} disabled={mutation.busy} onChange={(event) => setPending({ ...pending, role: event.target.value })}>{projectRoles.map((value) => <option value={value} key={value}>{value[0].toUpperCase() + value.slice(1)}</option>)}</select></label>}
        {pending.role && <p>{roleDescriptions[pending.role]}</p>}
        <p className="field-note">Conversation identity survives renames; deleting and recreating a conversation does not retain its membership. Live delegated children use their parent’s current access. Private transcripts and resource tool grants are unchanged.</p>
        {changed && <p className="inline-error" role="alert">Project settings or access changed. Close this dialog and review the current access before confirming.</p>}
        <WorkFeedback query={mutation} /><div className="form-actions"><button className="button ghost" disabled={mutation.busy} onClick={() => setPending(null)}>Cancel</button><button className="button primary" disabled={mutation.busy || changed} onClick={() => mutation.run('member', { id: project.id, version: pending.version, scope: pending.scope, role: pending.role }, () => { setPending(null); setScope('') })}>{mutation.busy ? 'Saving access…' : pending.role ? 'Confirm access' : 'Remove access'}</button></div>
      </WorkDialog>}
    </section>
    <ProjectClients key={project.id} project={project} />
  </>
}
