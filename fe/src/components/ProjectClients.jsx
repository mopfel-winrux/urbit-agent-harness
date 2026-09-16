import { useRef, useState } from 'react'
import { useWorkspace } from '../useWorkspace'
import { workId } from '../workspace'
import { clientStatusLabels, generateProjectKey, projectReadEndpoint } from '../projectAccess'
import { WorkDialog, WorkFeedback, WorkPager, useWorkMutation, workDate } from './WorkspaceCommon'
import './project-access.css'

function NewClientKey({ project, onClose }) {
  const [id] = useState(workId)
  const [base] = useState(project.version)
  const [label, setLabel] = useState('')
  const [days, setDays] = useState('7')
  const [confirmed, setConfirmed] = useState(false)
  const [issued, setIssued] = useState(null)
  const [revealed, setRevealed] = useState(false)
  const [copyStatus, setCopyStatus] = useState('')
  const request = useRef(null)
  const mutation = useWorkMutation()
  const changed = project.version !== base || project.archived
  const attempt = async (event) => {
    event.preventDefault()
    if (!confirmed || mutation.busy || (!request.current && changed)) return
    try {
      request.current ||= { id, project: project.id, version: base, label: label.trim(), days: Number(days), key: generateProjectKey() }
      await mutation.run('client-create', request.current, setIssued)
    } catch (error) { mutation.setError(error.message) }
  }
  const copy = async () => {
    try { await navigator.clipboard.writeText(request.current.key); setCopyStatus('Key copied. Store it securely.') }
    catch { setCopyStatus('Clipboard unavailable. Reveal the key and copy it manually.') }
  }
  return <WorkDialog title={issued ? 'Read-only key created' : 'Create a read-only project key?'} busy={mutation.busy} onClose={onClose}>
    {issued ? <>
      <p><strong>{issued.label}</strong> can read the documents, accepted history, proposals, and task records in <strong>{project.title}</strong> until {workDate(issued.expires)}. It cannot read conversations or make changes.</p>
      <p className="work-notice">Save this key now. Closing this dialog discards the local copy; Harness cannot show it again. Anyone holding it can read this project until it expires or you revoke it.</p>
      <label><span>Project bearer key</span><input className="project-key-value" type={revealed ? 'text' : 'password'} autoComplete="off" spellCheck={false} readOnly value={request.current.key} onFocus={(event) => event.target.select()} /></label>
      <div className="work-actions project-key-actions"><button className="button ghost" onClick={() => setRevealed(!revealed)}>{revealed ? 'Hide key' : 'Reveal key'}</button><button className="button ghost" onClick={copy}>Copy key</button></div>
      {copyStatus && <p role="status">{copyStatus}</p>}
      <label><span>Read endpoint · POST JSON</span><input readOnly value={projectReadEndpoint(location.origin)} onFocus={(event) => event.target.select()} /></label>
      <p className="field-note">Send the key in the Authorization: Bearer header, never in a URL. Use HTTPS for remote access. Request example:</p>
      <pre className="project-read-example">{JSON.stringify({ action: 'project', args: { id: project.id } }, null, 2)}</pre>
      <div className="form-actions"><button className="button primary" onClick={onClose}>Done</button></div>
    </> : <form onSubmit={attempt}>
      <p>This key will read all current and future documents, accepted history, proposals, and task records in <strong>{project.title}</strong>. It grants no conversation access, tool execution, changes, approvals, or publication.</p>
      <label><span>Client label</span><input autoFocus required maxLength={128} value={label} disabled={mutation.busy || !!request.current} onChange={(event) => setLabel(event.target.value)} placeholder="For example, my project dashboard" /></label>
      <label><span>Key expires after</span><select value={days} disabled={mutation.busy || !!request.current} onChange={(event) => setDays(event.target.value)}><option value="1">1 day</option><option value="7">7 days</option><option value="30">30 days</option></select></label>
      <p className="field-note">Expiry is fixed at creation. Archiving suspends the key; restoring the project restores an unexpired, unrevoked key. Revoking is permanent. Previously read or copied material cannot be recalled.</p>
      <label className="project-key-confirm"><input type="checkbox" checked={confirmed} disabled={mutation.busy || !!request.current} onChange={(event) => setConfirmed(event.target.checked)} /><span>I want anyone holding this key to have read access to this project.</span></label>
      {changed && !request.current && <p className="inline-error" role="alert">Project settings or access changed. Close this dialog and review the project before creating a key.</p>}
      <WorkFeedback query={mutation} />
      {mutation.error && request.current && <p className="field-note">Creation is not confirmed. Retrying sends the same identity and key without extending its expiry. If you close now, inspect the credential list and revoke any key whose local copy you lost.</p>}
      <div className="form-actions"><button type="button" className="button ghost" disabled={mutation.busy} onClick={onClose}>Cancel</button><button className="button primary" disabled={mutation.busy || !confirmed || !label.trim() || (!request.current && changed)}>{mutation.busy ? 'Creating…' : request.current ? 'Retry same key' : 'Create read-only key'}</button></div>
    </form>}
  </WorkDialog>
}

export default function ProjectClients({ project }) {
  const [offset, setOffset] = useState(0)
  const query = useWorkspace('clients', { project: project.id, offset, limit: 24 })
  const [create, setCreate] = useState(false)
  const [revoke, setRevoke] = useState(null)
  const mutation = useWorkMutation()
  const items = query.value?.items || []
  return <section className="project-client-section" aria-labelledby="project-clients-heading">
    <div className="section-title"><h2 id="project-clients-heading">Read-only client access</h2><button className="button ghost" disabled={project.archived || query.loading || !!query.error} onClick={() => setCreate(true)}>Create read-only key…</button></div>
    <p>Let a script or another app read this project without giving it your ship login. Client keys are separate from conversation roles and never become maintainers.</p>
    <p className="field-note">Use HTTPS remotely and expose only the project read endpoint. Keys do not protect other independently exposed ship endpoints. The ship’s event logs and backups still need protection.</p>
    <WorkFeedback query={query} /><WorkFeedback query={mutation} />
    {query.error && !!items.length && <p className="work-notice">Showing the last successful credential read, not current access. Refresh before acting.</p>}
    {!query.loading && !query.error && !items.length && <p className="work-empty">No client keys in this view. Creating a key grants read access to this project only, with a fixed expiry and an explicit revoke action.</p>}
    <div className="work-members">{items.map((client) => <div className="work-member" key={client.id}>
      <div><strong>{client.label}</strong><span className="work-record-meta">{clientStatusLabels[client.status] || 'Status unavailable'} · Expires {workDate(client.expires)}</span><code className="project-client-id">{client.id}</code></div>
      {client.status !== 'revoked' && <button className="text-button danger-text" disabled={mutation.busy || !!query.error} onClick={() => setRevoke(client)}>Revoke…</button>}
    </div>)}</div>
    <WorkPager query={query} offset={offset} onOffset={setOffset} />
    {create && <NewClientKey project={project} onClose={() => { setCreate(false); setOffset(0) }} />}
    {revoke && <WorkDialog title="Revoke this project key?" busy={mutation.busy} onClose={() => setRevoke(null)}><p><strong>{revoke.label}</strong> will permanently lose read access to <strong>{project.title}</strong> through this key.</p><p className="field-note">This stops subsequent reads, not copies already made or a read already accepted by the ship. It does not change conversation membership or other keys.</p><WorkFeedback query={mutation} /><div className="form-actions"><button className="button ghost" disabled={mutation.busy} onClick={() => setRevoke(null)}>Cancel</button><button className="button primary" disabled={mutation.busy} onClick={() => mutation.run('client-revoke', { id: revoke.id, project: project.id }, () => setRevoke(null))}>{mutation.busy ? 'Revoking…' : 'Revoke key'}</button></div></WorkDialog>}
  </section>
}
