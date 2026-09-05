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
let snapshot = {
  revision: 3, phase: 'idle', model: 'provider/a-long-model-name', usage: { prompt: 120, completion: 80 }, compactions: 0,
  entries: [
    { id: '1', eventCount: 1, role: 'user', body: 'Please explain **the harness** with examples.' },
    { id: '2', eventCount: 2, role: 'assistant', calls: [], body: markdown },
  ],
}
const publish = (next) => {
  snapshot = { ...snapshot, ...next, revision: snapshot.revision + 1 }
  acp.dispatchEvent(new CustomEvent('session/update', { detail: { sessionId: chat, update: { sessionUpdate: 'test_snapshot' } } }))
}
const heldPrompts = []
window.harnessFixture = { sent: [], update: publish, holdPrompts: false,
  completePrompt: (index) => heldPrompts[index]?.({ stopReason: 'end_turn' }) }
acp.start = async () => {}
acp.call = async (method, params) => {
  if (method === 'harness/session/snapshot') return { ...snapshot, entries: params.since === snapshot.revision ? null : snapshot.entries }
  if (method === 'session/cancel') { publish({ phase: 'idle', streaming: '' }); return {} }
  if (method === 'session/prompt') {
    window.harnessFixture.sent.push(params.prompt[0].text)
    publish({ phase: 'thinking', streaming: 'A **streamed** answer with `inline code`…' })
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
    <Sidebar chats={[chat, 'reading-list', 'daily-notes']} current={current} onSelect={setCurrent} onNew={() => setModal(true)} onRename={() => setModal(true)} onDelete={() => {}} onSettings={() => {}} />
    <Chat key={current} chat={current} theme={theme} onToggleTheme={() => {
      const next = ({ system: 'light', light: 'dark', dark: 'system' })[theme]
      document.documentElement.dataset.theme = next; setTheme(next)
    }} onSettings={() => {}} onFork={() => setModal(true)} onSelect={setCurrent} />
    {modal && <ConversationModal mode="create" initialName="" onSave={async () => {}} onClose={() => setModal(false)} />}
  </div>
}

createRoot(document.getElementById('root')).render(<StrictMode><Fixture /></StrictMode>)
