import { useState } from 'react'
import { useInbox } from '../useInbox'
import { inboxKinds, inboxStates, recordContext, recordCount, recordLinks, recordStatus, sourceLabels } from '../inbox'
import { workDate } from './WorkspaceCommon'
import './inbox.css'

function Evidence({ row }) {
  return <details className="inbox-evidence">
    <summary>Recorded evidence</summary>
    <dl>
      <div><dt>Record</dt><dd><code>{row.id}</code></dd></div>
      {row.at != null && <div><dt>Evidence time</dt><dd>{workDate(row.at)}</dd></div>}
      {row.version != null && <div><dt>Task version</dt><dd>{row.version}</dd></div>}
      {row.kind === 'proposal' && <><div><dt>Base revision</dt><dd>{row.base}</dd></div><div><dt>Proposal status</dt><dd>{row.status}</dd></div></>}
      {row.kind === 'input' && <>
        <div><dt>Execution</dt><dd>{row.execution || 'Unavailable'}</dd></div>
        <div><dt>Delivery record</dt><dd>{row.delivery || 'No record'}</dd></div>
        <div><dt>Attempt</dt><dd>{row.attempt}</dd></div>
        <div><dt>Binding</dt><dd><code>{row.binding}</code>{row.bindingEnabled === false ? ' · Disabled or retired' : ''}</dd></div>
        {row.externalId && <div><dt>Native reference</dt><dd><code>{row.externalId}</code></dd></div>}
      </>}
      {row.kind === 'schedule' && <>
        <div><dt>Timing</dt><dd>{row.schedule}</dd></div>
        {row.status === 'active' && <div><dt>Next due</dt><dd>{row.next}</dd></div>}
        {row.lastInput && <div><dt>Latest run record</dt><dd><code>{row.lastInput}</code></dd></div>}
      </>}
      {row.kind === 'notes' && <div><dt>Sent to Notes</dt><dd>{row.sent ? 'Yes · result still pending' : 'Not yet sent'}</dd></div>}
    </dl>
    {row.kind === 'input' && <p className="field-note">A delivery receipt records what the hand confirmed, not necessarily remote arrival. Check the native conversation before retrying an uncertain send.</p>}
    {row.kind === 'task' && <p className="field-note">Task status is a claim or recorded outcome, not proof of execution or external effects.</p>}
    {row.kind === 'proposal' && <p className="field-note">Open the proposal to inspect its exact changes and current approval conditions. This list does not approve or publish it.</p>}
    {row.kind === 'schedule' && <p className="field-note">This is the schedule, not an execution receipt. Its admitted runs appear separately under Hand work.</p>}
    {row.kind === 'notes' && <p className="field-note">Do not repeat a document change because its result is missing. Inspect the pending operation first.</p>}
  </details>
}

function Record({ row }) {
  return <li className="inbox-record">
    <div className="inbox-record-heading"><div><h2>{row.title || 'Untitled work record'}</h2><p className="inbox-context">{sourceLabels[row.kind] || 'Work record'} · {recordContext(row)}</p></div><span className={`work-label inbox-state ${row.state}`}>{recordStatus(row)}</span></div>
    {row.detail && <p className="inbox-detail">{row.detail}</p>}
    <div className="inbox-record-footer"><div className="work-actions">{recordLinks(row).map((link) => <a key={link.href} href={link.href}>{link.label}</a>)}</div>{row.at != null && <time dateTime={new Date(row.at).toISOString()}>{workDate(row.at)}</time>}</div>
    <Evidence row={row} />
  </li>
}

export default function WorkInbox() {
  const [page, setPage] = useState({ state: 'attention', kind: 'all', cursor: null })
  const query = useInbox({ ...page, limit: 24 })
  const value = query.value
  const counts = query.error ? null : value?.counts
  const change = (patch) => setPage((previous) => ({ ...previous, ...patch, cursor: null }))
  const refresh = () => { if (page.cursor) change({}); else void query.refresh() }
  const total = recordCount(counts, page.state)
  return <div className="work-content inbox-content">
    <div className="work-heading"><div className="page-header"><h1>Work inbox</h1><p>Review what needs you. Follow each record back to its evidence.</p></div><button className="button ghost" disabled={query.refreshing} onClick={refresh}>{query.refreshing ? 'Refreshing…' : 'Refresh inbox'}</button></div>
    <nav className="work-tabs inbox-filters" aria-label="Work state">{inboxStates.map(([key, label]) => <button key={key} aria-pressed={page.state === key} onClick={() => change({ state: key })}>{label}<span className="inbox-count">{recordCount(counts, key) ?? '—'}</span></button>)}</nav>
    <div className="inbox-toolbar"><label><span>Source</span><select value={page.kind} onChange={(event) => change({ kind: event.target.value })}>{inboxKinds.map(([key, label]) => <option key={key} value={key}>{label}</option>)}</select></label><p className="field-note">{query.error ? 'Current status unavailable' : query.loading ? 'Reading retained work…' : `${total} retained ${total === 1 ? 'record' : 'records'}`}{page.cursor ? ' · Later page' : ''}</p></div>
    {query.error && <div className="inline-error" role="alert"><p>{query.error}</p>{value && <p>Showing the last successful read, not current status.</p>}<button className="text-button" disabled={query.refreshing} onClick={refresh}>Refresh from first page</button></div>}
    {query.loading && <div className="inbox-loading" role="status">Loading work records…</div>}
    {!query.loading && !query.error && !value?.items?.length && <div className="work-empty"><h2>{page.state === 'attention' ? 'No retained records need attention' : 'No records in this view'}</h2><p>{page.state === 'attention' ? 'Approvals, blocked work, and uncertain results will appear here. Running and waiting records are in their own views.' : 'Try another state or source to inspect the other retained work.'}</p><p>Ordinary conversations and work not yet admitted by a hand are outside this inbox.</p></div>}
    {!!value?.items?.length && <ul className="inbox-records" aria-label="Work records" aria-busy={query.refreshing}>{value.items.map((row) => <Record row={row} key={`${row.kind}:${row.id}`} />)}</ul>}
    <div className="work-pagination">{page.cursor && <button className="button ghost" onClick={() => change({})}>First page</button>}{value?.cursor && <button className="button ghost" disabled={query.loading || query.refreshing || !!query.error} onClick={() => setPage((previous) => ({ ...previous, cursor: value.cursor }))}>Next page</button>}</div>
    <footer className="inbox-scope"><p>Counts are records, not unique tasks. Project tasks, proposals, schedules, admitted hand work, and pending Notes operations are included. Unbound conversations and pre-admission diagnostics remain in their existing views.</p>{value?.observedAt && <p>Last successful read: {workDate(value.observedAt)}. Refreshes while this view is visible.</p>}</footer>
  </div>
}
