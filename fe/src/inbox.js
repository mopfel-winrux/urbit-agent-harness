export const inboxStates = [
  ['attention', 'Needs attention'], ['running', 'Running'], ['waiting', 'Waiting'],
  ['finished', 'Finished'], ['all', 'All records'],
]
export const inboxKinds = [
  ['all', 'All sources'], ['proposal', 'Artifact proposals'], ['task', 'Project tasks'],
  ['input', 'Hand work'], ['schedule', 'Schedules'], ['notes', 'Notes operations'],
]
export const sourceLabels = Object.fromEntries(inboxKinds.slice(1))

export function recordCount(counts, state) {
  if (!counts) return null
  if (state === 'all') return Object.values(counts).reduce((sum, count) => sum + count, 0)
  if (state === 'attention') return (counts.uncertain || 0) + (counts.blocked || 0) + (counts.approval || 0)
  return counts[state] || 0
}

export function recordStatus(row) {
  if (row.kind === 'task') return { open: 'Available to claim', claimed: 'Claimed · not execution evidence', blocked: 'Task blocked', done: 'Task marked done' }[row.status] || 'Task status unavailable'
  if (row.kind === 'proposal') return { pending: 'Awaiting approval', accepted: 'Proposal accepted', rejected: 'Proposal rejected' }[row.status] || 'Proposal status unavailable'
  if (row.kind === 'schedule') return { active: 'Scheduled', paused: 'Schedule paused', complete: 'Schedule ended', cancelled: 'Schedule cancelled' }[row.status] || 'Schedule status unavailable'
  if (row.kind === 'notes') return row.uncertain ? 'Notes result uncertain' : 'Waiting for Notes'
  if (row.kind === 'input') {
    if (row.delivery === 'uncertain') return 'Delivery uncertain'
    if (row.delivery === 'failed') return 'Delivery failed'
    if (row.execution === 'failed') return 'Execution failed'
    if (row.delivery === 'claimed') return 'Send claimed · awaiting receipt'
    if (row.delivery === 'pending') return 'Waiting to send'
    if (row.delivery === 'abandoned') return 'Delivery abandoned'
    if (row.delivery === 'delivered') return row.execution === 'cancelled' ? 'Cancelled · reply recorded delivered' : 'Reply recorded delivered'
    return { running: 'Running', queued: 'Queued', cancelled: 'Execution cancelled', completed: 'Execution complete · no delivery record' }[row.execution] || 'Work status unavailable'
  }
  return 'Status unavailable'
}

export function recordContext(row) {
  if (row.kind === 'task') return `${row.projectTitle || row.project} · ${row.claimant ? `Claimed by ${row.claimant.label}` : 'Unclaimed'}`
  if (row.kind === 'proposal') return `${row.by?.label || 'Unknown source'} · Base revision ${row.base}`
  if (row.kind === 'schedule') return `${row.hand || 'Hand'} · ${row.scheduleKind === 'reminder' ? 'Literal reminder' : 'Recurring model task'} · ${row.remaining} runs remaining`
  if (row.kind === 'input') return [row.hand || 'Hand', row.actor, row.destination].filter(Boolean).join(' · ')
  return row.action || 'Native Notes operation'
}

export function recordLinks(row) {
  const id = encodeURIComponent(row.id)
  if (row.kind === 'task') return [{ label: 'Open task', href: `#/projects/${encodeURIComponent(row.project)}?task=${id}` }]
  if (row.kind === 'proposal') return [{ label: row.status === 'pending' ? 'Review proposal' : 'Open proposal', href: `#/artifacts/${encodeURIComponent(row.artifact)}?proposal=${id}` }]
  if (row.kind === 'schedule') return [{ label: 'Open schedules', href: '#/settings?tab=schedules' }]
  if (row.kind === 'notes') return [{ label: 'Inspect Notes operation', href: `#/artifacts/${encodeURIComponent(row.artifact)}` }]
  return [
    ...(row.sessionId ? [{ label: 'Open conversation', href: `#/${encodeURIComponent(row.sessionId)}` }] : []),
    ...(row.hand === 'tlon' ? [{ label: 'Delivery diagnostics', href: '#/tlon?work=1' }] : []),
  ]
}

// Mount-local reads only. A hidden or departed inbox owes no safety polling;
// focus performs one fresh read, sharing an already outstanding request.
export function createInboxPolling(read, { isHidden, setTimer = setTimeout, clearTimer = clearTimeout, interval = 30_000 }) {
  let live = true, timer, pending
  const clear = () => { clearTimer(timer); timer = undefined }
  const refresh = () => {
    clear()
    if (!live || isHidden()) return Promise.resolve()
    if (pending) return pending
    pending = Promise.resolve().then(read).finally(() => {
      pending = null
      if (live && !isHidden()) timer = setTimer(refresh, interval)
    })
    return pending
  }
  return { refresh, visibilityChanged: refresh, stop: () => { live = false; clear() } }
}
