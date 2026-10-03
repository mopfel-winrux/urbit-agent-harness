// Isolated component integration: real chat components, deterministic ACP
// snapshots. This entry is served only by Vite, never included in desk/web.
import { StrictMode, useState } from 'react'
import { createRoot } from 'react-dom/client'
import { acp } from '../src/acp'
import Chat from '../src/components/Chat'
import Sidebar from '../src/components/Sidebar'
import ConversationModal from '../src/components/ConversationModal'
import '../src/style.css'

const markdown = `## A small head, capable hands

The **ship owns the session**. Clients can come and go without losing *continuity*.

1. Admit an input.
2. Record its effects.
   - Keep the transcript intact.
   - Give each client its own view.

> The interface is a window into the work, not its owner.

Use \`session/prompt\` to start a turn. ~~Polling owns the run.~~

| Capability | Boundary | Property |
| :--- | :---: | ---: |
| Native app | Typed nouns | Replayable |
| Editor | ACP | Independent |

- [x] Preserve history
- [ ] Add a new hand

\`\`\`js
const session = { model: 'example', prompt: '${'long-value-'.repeat(30)}' };
console.log(session);
\`\`\`

[Documentation](https://example.com/docs) and a note.[^note]

[^note]: A footnote should not navigate away from the conversation.

![Reference image](https://example.com/no-background-request.png)

<script>window.markdownExecuted = true</script>
<img src=x onerror="window.markdownExecuted=true">
[Unsafe link](javascript:alert%281%29)
`

const chat = 'research-notes-with-a-very-long-conversation-name-that-must-not-overflow'
const sidebarChats = new URLSearchParams(location.search).has('many')
  ? [chat, ...Array.from({ length: 46 }, (_, index) => `conversation-${String(index).padStart(2, '0')}`)]
  : [chat, 'reading-list', 'daily-notes']
let snapshot = {
  revision: 3, phase: 'idle', model: 'provider/a-long-model-name', usage: { prompt: 120, completion: 80 }, compactions: 0,
  entries: [
    { id: '1', eventCount: 1, role: 'user', body: 'Please explain **the harness** with examples.' },
    { id: '2', eventCount: 2, role: 'assistant', calls: [], body: markdown },
  ],
}
const historyRows = new URLSearchParams(location.search).has('history')
  ? Array.from({ length: Number(new URLSearchParams(location.search).get('history-count')) || 95 }, (_, index) => ({ id: String(index + 1), eventCount: index + 1, role: 'assistant', calls: [], body: `History reply ${index + 1}` }))
  : null
if (historyRows) snapshot = { ...snapshot, revision: historyRows.length, before: historyRows.length - 39, entries: historyRows.slice(-40) }
const publish = (next, notify = true, kind = 'test_snapshot') => {
  snapshot = { ...snapshot, ...next, revision: snapshot.revision + 1 }
  if (notify) acp.dispatchEvent(new CustomEvent('session/update', { detail: { sessionId: chat, update: { sessionUpdate: kind } } }))
}
const stream = (text) => {
  if (snapshot.phase !== 'thinking') snapshot = { ...snapshot, phase: 'thinking', streaming: '', revision: snapshot.revision + 1 }
  const offset = new TextEncoder().encode(snapshot.streaming || '').length
  snapshot = { ...snapshot, streaming: (snapshot.streaming || '') + text }
  acp.dispatchEvent(new CustomEvent('session/update', { detail: { sessionId: chat,
    update: { sessionUpdate: 'harness_agent_stream_chunk', revision: snapshot.revision, offset, content: { type: 'text', text } },
  } }))
}
const heldPrompts = []
const heldSnapshots = []
window.harnessFixture = { sent: [], update: publish, stream, holdPrompts: false, snapshotReads: 0, holdSnapshots: false,
  completeSnapshot: (index) => heldSnapshots[index]?.(),
  completePrompt: (index) => heldPrompts[index]?.({ stopReason: 'end_turn' }) }
window.harnessFixture.runReads = []
window.harnessFixture.runs = [
  { lensId: '0v2', createdAt: Date.UTC(2026, 9, 2, 14), preview: 'Explain the head and its hands.', status: 'completed', model: 'test-model', provider: 'fixture',
    context: { description: 'Journal context at first dispatch; previews are bounded. Provider reasoning and transport credentials are excluded.', sources: [
      { kind: 'system', label: 'System instructions', included: true, preview: 'Answer using the recorded evidence.' },
      { kind: 'message', label: 'user', included: true, preview: 'Explain the head and its hands.' },
    ] },
    tools: { callCount: 1, runs: [{ id: 'read', name: 'read_file', status: 'completed', argumentDetail: '{"path":"architecture.md"}', resultSummary: 'The journal belongs to the head. Adapters own delivery.' }] },
    lifecycle: { completedAt: null, durationMs: null }, reply: 'The head owns the journal; hands adapt its effects to their destinations.' },
  { lensId: '0v1', createdAt: Date.UTC(2026, 9, 1, 14), preview: 'Read the project notes.', status: 'error', model: 'test-model', error: 'The requested file is unavailable.', context: { sources: [] }, tools: { callCount: 0, runs: [] }, reply: null },
]
acp.start = async () => {}
acp.call = async (method, params) => {
  if (method === 'harness/session/runs') {
    window.harnessFixture.runReads.push(params)
    if (window.harnessFixture.runError) throw new Error(window.harnessFixture.runError)
    const runs = structuredClone(window.harnessFixture.runs)
    return params.lensId ? runs.find((run) => run.lensId === params.lensId) : { runs, before: null }
  }
  if (method === 'harness/session/history') {
    const older = historyRows.filter((row) => row.eventCount < params.before)
    const entries = older.slice(-40)
    return { revision: snapshot.revision, entries, before: older.length > 40 ? entries[0].eventCount : null }
  }
  if (method === 'harness/session/snapshot') {
    window.harnessFixture.snapshotReads++
    const result = { ...snapshot, entries: params.since === snapshot.revision ? null : snapshot.entries }
    if (window.harnessFixture.holdSnapshots) await new Promise((resolve) => heldSnapshots.push(resolve))
    return result
  }
  if (method === 'session/cancel') { publish({ phase: 'idle', streaming: '' }); return {} }
  if (method === 'session/prompt') {
    window.harnessFixture.sent.push(params.prompt[0].text)
    if (!window.harnessFixture.holdAdmission) publish({ phase: 'thinking', streaming: 'A **streamed** answer with `inline code`…' })
    if (window.harnessFixture.holdPrompts) return new Promise((resolve) => heldPrompts.push(resolve))
    return { stopReason: 'end_turn' }
  }
  throw new Error(`Unexpected fixture method: ${method}`)
}
acp.notify = async () => publish({ phase: 'idle', streaming: '' })

function Fixture() {
  const [modal, setModal] = useState(false)
  const [theme, setTheme] = useState('system')
  const [current, setCurrent] = useState(chat)
  return <div className="app-shell">
    <Sidebar chats={sidebarChats} current={current} onSelect={setCurrent} onNew={() => setModal(true)} onRename={() => setModal(true)} onDelete={() => {}} onSettings={() => {}} />
    <Chat key={current} chat={current} theme={theme} onToggleTheme={() => {
      const next = ({ system: 'light', light: 'dark', dark: 'system' })[theme]
      document.documentElement.dataset.theme = next; setTheme(next)
    }} onSettings={() => {}} onFork={() => setModal(true)} onSelect={setCurrent} />
    {modal && <ConversationModal mode="create" initialName="" onSave={async () => {}} onClose={() => setModal(false)} />}
  </div>
}

createRoot(document.getElementById('root')).render(<StrictMode><Fixture /></StrictMode>)
