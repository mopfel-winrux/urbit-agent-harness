import { PlusIcon } from './Icons'

export default function Welcome({ loading, onNew }) {
  return <main className="workspace welcome-workspace">
    <div className="empty-chat">
      <div className="empty-orbit"><span /></div>
      <span className="eyebrow">Harness</span>
      <h2>{loading ? 'Connecting to your ship…' : 'Start a conversation'}</h2>
      <p>{loading ? 'Opening the ACP channel and finding your sessions.' : 'Each conversation runs independently, so work can continue in parallel.'}</p>
      {!loading && <button className="button primary welcome-button" onClick={onNew}><PlusIcon />New conversation</button>}
    </div>
  </main>
}
