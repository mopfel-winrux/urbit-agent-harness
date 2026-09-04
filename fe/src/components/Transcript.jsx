import { transcriptEntries } from '../session'

function ToolEntry({ entry }) {
  return <details className={`tool-entry ${entry.status === 'in_progress' ? 'running' : 'complete'}`}>
    <summary><span className="tool-dot" /><strong>{entry.title || 'tool'}</strong><small>{entry.status === 'in_progress' ? 'running' : 'completed'}</small></summary>
    <pre>{entry.body}</pre>
  </details>
}

function ThinkingMessage({ streaming, phase }) {
  return <article className={`message assistant thinking-message ${streaming ? 'streaming' : ''}`}>
    <div className="message-label">{phase === 'compacting' ? 'Summarizing context' : phase === 'tools' ? 'Working' : 'harness'}</div>
    <div className="message-body">{streaming || <span className="thinking-dots" role="status" aria-label="Thinking"><i /><i /><i /></span>}</div>
  </article>
}

export default function Transcript({ items, pending, thinking, streaming, phase, onFork }) {
  const entries = transcriptEntries(items)
  if (!entries.length && !pending && !thinking) return <div className="empty-chat">
    <div className="empty-orbit"><span /></div><span className="eyebrow">New conversation</span>
    <h2>What should we work on?</h2><p>Start a conversation, inspect tool work as it happens, and return whenever you like.</p>
  </div>
  return <>{entries.map((entry) => entry.type === 'tool'
    ? <ToolEntry key={entry.id} entry={entry} />
    : <article className={`message ${entry.role}`} key={entry.id}>
      <div className="message-label">{entry.role === 'assistant' ? 'harness' : entry.role}
        {entry.role === 'assistant' && !entry.calls?.length && <button className="branch-button" onClick={() => onFork(entry.eventCount)} title="Start a new conversation from this reply">Branch from here</button>}
      </div><div className="message-body">{entry.body}</div>
    </article>)}
    {pending && <article className="message user pending"><div className="message-label">user</div><div className="message-body">{pending.text}</div></article>}
    {thinking && <ThinkingMessage streaming={streaming} phase={phase} />}
  </>
}
