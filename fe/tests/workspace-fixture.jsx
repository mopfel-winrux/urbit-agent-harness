// Synthetic owner workspace. This Vite-only entry is never distributed.
import { StrictMode, useEffect, useState } from 'react'
import { createRoot } from 'react-dom/client'
import { acp } from '../src/acp'
import { EyreSubscription } from '../src/eyreSubscription'
import Workspace from '../src/components/Workspace'
import Sidebar from '../src/components/Sidebar'
import CorpusSearch from '../src/components/CorpusSearch'
import '../src/style.css'

const at = Date.UTC(2026, 8, 10, 14)
const owner = { scope: '0v0', label: 'Owner' }
const researcher = { scope: '0v1', label: 'neighborhood-research' }
const body = '## A Saturday with the neighbors\n\nBring a dish, meet someone new, and help us make the courtyard a welcoming place.\n\n### The plan\n\n- Meet at the courtyard at 11:00.\n- Share lunch at noon.\n- Leave the space better than we found it.\n\nThis is a **synthetic example**, not an announced event.'
const revised = body.replace('Share lunch at noon.', 'Share lunch at noon. Label dishes with their ingredients.')
const revisions = (title, text) => ({ 1: { revision: 1, at, by: owner, title, body: text, sources: [{ label: 'Private planning reference', url: 'https://example.com/private-reference' }] } })
const db = {
  projects: { neighborhood: { id: 'neighborhood', title: 'A good day together', description: 'A small community gathering, planned together. Synthetic example project.', version: 1, archived: false, role: 'owner', members: [{ scope: '0v1', role: 'contributor' }] } },
  artifacts: {
    guide: { id: 'guide', title: 'A Saturday with the neighbors', project: 'neighborhood', head: 1, archived: false, exposure: 0, publication: null, revisions: revisions('A Saturday with the neighbors', body) },
    private: { id: 'private', title: 'My private notes', project: null, head: 1, archived: false, exposure: 0, publication: null, revisions: revisions('My private notes', 'Private draft not intended for project members.') },
    draft: { id: 'draft', title: 'A plan for the afternoon', project: 'neighborhood', head: 0, archived: false, exposure: 0, publication: null, revisions: {} },
  },
  proposals: {
    suggestion: { id: 'suggestion', artifact: 'guide', title: 'A Saturday with the neighbors', base: 1, by: researcher, at, reason: 'Make dietary information easier to find.', status: 'pending', decided: null, decision: '', revision: null, content: { revision: 1, by: researcher, at, title: 'A Saturday with the neighbors', body: revised, sources: [] } },
    draft: { id: 'draft', artifact: 'draft', title: 'A plan for the afternoon', base: 0, by: researcher, at, reason: 'New document', status: 'pending', content: { revision: 0, by: researcher, at, title: 'A plan for the afternoon', body: 'A synthetic draft ready for review.', sources: [] } },
  },
  tasks: { research: { id: 'research', project: 'neighborhood', title: 'Gather the practical details', description: 'List the supplies we need and propose an update to the guide.', version: 1, status: 'open', claimant: null, outcome: '', artifact: null, updated: at } },
  sessions: [{ sessionId: 'neighborhood-research', scope: '0v1', workspaceTools: true }, { sessionId: 'afternoon-plans', scope: '0v2', workspaceTools: false }],
}
const clone = (value) => structuredClone(value)
const metadata = (artifact) => { const { revisions, ...rest } = artifact; return clone({ ...rest, notes: artifact.head ? { notebook: '~lux/harness-artifacts', noteId: '42', path: `/notes/pub/~lux/harness-artifacts/${artifact.id === 'guide' ? '42' : '43'}` } : null }) }
const page = (items, args) => { const offset = args.offset || 0, limit = args.limit || 24; return { items: clone(items.slice(offset, offset + limit)), nextOffset: offset + limit < items.length ? offset + limit : null } }
let version = 0
const watches = new Set()
const changed = () => { version++; for (const watch of watches) watch.onUpdate({ revision: version }) }
EyreSubscription.prototype.run = async function () { watches.add(this); this.onUpdate({ revision: version }); this.connected = true }
EyreSubscription.prototype.close = function () { watches.delete(this); this.connected = false }
acp.start = async () => {}
acp.ship = () => 'lux'
const writes = new Set(['artifact-create', 'artifact-save', 'artifact-rename', 'artifact-archive', 'project-create', 'project-edit', 'member', 'publish', 'unpublish', 'review', 'task-create', 'task-claim', 'task-update'])
window.workFixture = { db, calls: [], failNext: null, changed, watchCount: () => watches.size, externalEdit: () => { const artifact = db.artifacts.guide; artifact.head++; artifact.revisions[artifact.head] = { ...artifact.revisions[1], revision: artifact.head, body: 'A newer revision from another browser.' }; changed() } }
const searchStatus = { indexed: 12, conversations: 2, indexing: false, workspaceRecords: 6, workspaceIndexing: false, workspaceAvailable: true }
const searchToken = 'synthetic-search-v1'
function searchFixture(method, args) {
  window.workFixture.calls.push({ action: method.replace('harness/', ''), args: clone(args) })
  if (method === 'harness/search/read' && window.workFixture.failSearchRead) throw new Error('Search content or access changed. Run the search again.')
  if (window.workFixture.failNext === method) { window.workFixture.failNext = null; throw new Error('Search content or access changed. Run the search again.') }
  if (method === 'harness/search/status') return clone(searchStatus)
  if (method === 'harness/corpus/read') return { body: 'Synthetic retained message: bring a table to the courtyard.', nextOffset: null }
  const guide = db.artifacts.guide
  guide.head = 3
  guide.revisions[2] = { ...guide.revisions[1], revision: 2, body: revised }
  guide.revisions[3] = { ...guide.revisions[1], revision: 3, body: 'Current document: the venue is now the park.' }
  if (method === 'harness/search/query') return { hits: args.cursor ? [
    { kind: 'project', id: 'neighborhood', title: db.projects.neighborhood.title, revision: 0, searchToken, sent: at, snippet: db.projects.neighborhood.description },
    { kind: 'task', id: 'research', project: 'neighborhood', title: db.tasks.research.title, revision: 0, searchToken, sent: at, snippet: db.tasks.research.description },
  ] : [
    { kind: 'artifact', id: 'guide', title: guide.title, head: 3, revision: 2, matchCount: 2, currentMatches: false, archived: false, searchToken, sent: at, snippet: 'Meet at the courtyard at 11:00.' },
    { kind: 'message', scope: '0v1', eventCount: 5, sessionId: 'neighborhood-research', hand: 'tlon', author: '~lux', sent: at, snippet: 'Bring a table to the courtyard.' },
  ], cursor: args.cursor ? null : 'synthetic-next', status: clone(searchStatus) }
  if (args.searchToken !== searchToken) throw new Error('Stale synthetic search token')
  if (method === 'harness/search/versions') return { items: [guide.revisions[2], guide.revisions[1]], nextOffset: null, searchToken }
  if (method === 'harness/search/read') {
    if (args.kind === 'artifact') return { artifact: metadata(guide), content: clone(guide.revisions[args.revision]) }
    return clone(args.kind === 'project' ? db.projects[args.id] : db.tasks[args.id])
  }
  throw new Error(`Unexpected search operation ${method}`)
}
acp.call = async (method, params = {}) => {
  if (method.startsWith('harness/search/') || method === 'harness/corpus/read') return searchFixture(method, params)
  const { action, args = {} } = params
  if (method !== 'harness/workspace') throw new Error(`Unexpected method ${method}`)
  window.workFixture.calls.push({ action, args: clone(args) })
  if (window.workFixture.failNext === action) { window.workFixture.failNext = null; throw new Error('Synthetic save failure. Your draft was not saved.') }
  const artifact = db.artifacts[args.id], project = db.projects[args.id]
  let result
  if (action === 'notes-status' || action === 'notes-resume') return { notebook: '~lux/harness-artifacts', pending: clone(window.workFixture.pending || null) }
  if (action === 'notes-release') {
    if (!window.workFixture.pending || args.confirm !== `release ${window.workFixture.pending.id}`) throw new Error('Confirm the pending operation first')
    window.workFixture.pending = null; changed(); return { released: true }
  }
  if (action === 'artifacts') return page(Object.values(db.artifacts).filter((item) => !args.project || item.project === args.project).map(metadata), args)
  if (action === 'artifact' || action === 'revision') { if (!artifact) throw new Error('Artifact not found'); return { artifact: metadata(artifact), content: clone(artifact.revisions[args.revision || artifact.head] || null) } }
  if (action === 'projects') return page(Object.values(db.projects), args)
  if (action === 'project') return clone(project)
  if (action === 'sessions') return page(db.sessions, args)
  if (action === 'tasks') return page(Object.values(db.tasks).filter((item) => !args.project || item.project === args.project), args)
  if (action === 'revisions') return page(Object.values(artifact.revisions).reverse(), args)
  if (action === 'proposals') return page(Object.values(db.proposals).filter((item) => !args.artifact || item.artifact === args.artifact).map(({ content, ...rest }) => rest), args)
  if (action === 'proposal') { const { content, ...proposal } = db.proposals[args.id]; return { proposal: clone(proposal), content: clone(content) } }
  if (action === 'preview') return { revision: args.revision, head: artifact.head, previewToken: `preview-${args.id}-${args.revision}`, html: '<!doctype html><html><head><meta charset="utf-8"><style>body{font:17px/1.7 system-ui;margin:32px;color:#171917;background:#fff}h1{line-height:1.25}p{max-width:70ch}</style></head><body><h1>A Saturday with the neighbors</h1><p>Bring a dish, meet someone new, and help us make the courtyard a welcoming place.</p><h2>The plan</h2><ul><li>Meet at the courtyard at 11:00.</li><li>Share lunch at noon.</li></ul><p>Synthetic public preview.</p></body></html>' }
  if (action === 'artifact-create') {
    const created = { id: args.id, title: args.title, project: args.project, head: 1, archived: false, exposure: 0, publication: null, revisions: { 1: { ...args, revision: 1, by: owner, at } } }
    db.artifacts[args.id] = created; result = { artifact: metadata(created) }
  } else if (action === 'artifact-save') {
    if (args.base !== artifact.head) throw new Error('Artifact changed; your draft was not overwritten.')
    if (args.title !== artifact.title) throw new Error('Rename the Note separately.')
    artifact.head++; artifact.title = args.title; artifact.revisions[artifact.head] = { ...args, revision: artifact.head, by: owner, at }; result = { artifact: metadata(artifact) }
  } else if (action === 'artifact-rename') {
    artifact.title = args.title; artifact.revisions[artifact.head].title = args.title; result = { artifact: metadata(artifact) }
  } else if (action === 'publish') {
    if (args.confirm !== `${args.id}@${args.revision}` || args.previewToken !== `preview-${args.id}-${args.revision}` || args.head !== artifact.head || args.exposure !== artifact.exposure) throw new Error('Publication changed; preview it again.')
    artifact.exposure++; artifact.publication = { revision: args.revision, path: metadata(artifact).notes.path, at }; result = { artifact: metadata(artifact) }
  } else if (action === 'unpublish') { artifact.exposure++; artifact.publication = null; result = { artifact: metadata(artifact) } }
  else if (action === 'artifact-archive') { artifact.archived = args.archived; result = { artifact: metadata(artifact) } }
  else if (action === 'project-create') { result = db.projects[args.id] = { ...args, version: 1, archived: false, members: [] } }
  else if (action === 'project-edit' || action === 'member') {
    if (args.version !== project.version) throw new Error('Project changed; reload before saving.')
    project.version++
    if (action === 'member') { project.members = project.members.filter((member) => member.scope !== args.scope); if (args.role) project.members.push({ scope: args.scope, role: args.role }) }
    else Object.assign(project, { title: args.title, description: args.description, archived: args.archived })
    result = clone(project)
  } else if (action === 'review') {
    const proposal = db.proposals[args.id], target = db.artifacts[proposal.artifact]
    if (args.accept && proposal.base !== target.head) throw new Error('Proposal is stale; it cannot overwrite a newer revision.')
    proposal.status = args.accept ? 'accepted' : 'rejected'; proposal.decision = args.reason
    if (args.accept) { target.head++; target.title = proposal.content.title; target.revisions[target.head] = { ...proposal.content, revision: target.head }; proposal.revision = target.head }
    result = clone(proposal)
  } else if (action === 'task-create') { result = db.tasks[args.id] = { ...args, version: 1, status: 'open', claimant: null, outcome: '', artifact: null, updated: at } }
  else if (action === 'task-claim' || action === 'task-update') {
    const task = db.tasks[args.id]
    if (args.version !== task.version) throw new Error('Task changed; inspect its current claim.')
    Object.assign(task, { ...args, version: task.version + 1, status: action === 'task-claim' ? 'claimed' : args.status, claimant: args.status === 'open' ? null : task.claimant || owner }); result = clone(task)
  } else throw new Error(`Unexpected workspace operation ${action}`)
  if (writes.has(action)) changed()
  return clone(result)
}

const route = () => { const [kind = 'artifacts', id = ''] = location.hash.replace(/^#\//, '').split('/'); return { kind: kind || 'artifacts', id } }
function Fixture() {
  const [view, setView] = useState(route)
  useEffect(() => { const next = () => setView(route()); window.addEventListener('hashchange', next); return () => window.removeEventListener('hashchange', next) }, [])
  return <div className="app-shell"><Sidebar chats={['neighborhood-research', 'afternoon-plans']} current="" onSelect={() => {}} onNew={() => {}} onSettings={() => {}} onCorpus={() => { location.hash = '#/search' }} corpus={view.kind === 'search'} onWorkspace={(kind) => { location.hash = `#/${kind}` }} work={view.kind} />{view.kind === 'search' ? <CorpusSearch onBack={() => { location.hash = '#/artifacts' }} onOpen={() => {}} /> : <Workspace kind={view.kind} id={view.id} onBack={() => { location.hash = '#/artifacts' }} />}</div>
}
createRoot(document.getElementById('root')).render(<StrictMode><Fixture /></StrictMode>)
