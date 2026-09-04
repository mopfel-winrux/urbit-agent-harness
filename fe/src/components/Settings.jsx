import { useState } from 'react'
import AgentSettings from './AgentSettings'
import { BackIcon } from './Icons'
import ProviderSettings from './ProviderSettings'

const tabs = [
  ['agent', 'Agent'],
  ['anthropic', 'Anthropic'],
  ['openrouter', 'OpenRouter'],
]

export default function Settings({ roads, theme, onThemeChange, onBack }) {
  const [tab, setTab] = useState('agent')

  return <main className="workspace settings-workspace">
    <header className="topbar"><button className="back-button" onClick={onBack}><BackIcon />Conversations</button></header>
    <div className="settings-content">
      <div className="page-header"><span className="eyebrow">Configuration</span><h1>Settings</h1></div>
      <nav className="settings-tabs" aria-label="Settings sections">
        {tabs.map(([id, label]) => <button key={id} className={tab === id ? 'active' : ''} onClick={() => setTab(id)}>{label}</button>)}
      </nav>
      {tab === 'agent'
        ? <AgentSettings roads={roads} theme={theme} onThemeChange={onThemeChange} />
        : <ProviderSettings provider={tab} roads={roads} />}
    </div>
  </main>
}
