import { useState } from 'react'
import AgentSettings from './AgentSettings'
import { BackIcon } from './Icons'
import GlobalSettings from './GlobalSettings'
import McpSettings from './McpSettings'
import ProviderSettings from './ProviderSettings'

const baseTabs = [
  ['defaults', 'Defaults'],
  ['mcp', 'MCP'],
  ['openrouter', 'OpenRouter'],
  ['openai', 'OpenAI'],
  ['anthropic', 'Anthropic'],
  ['custom', 'Custom'],
]

export default function Settings({ roads, theme, onThemeChange, onBack }) {
  const [tab, setTab] = useState(roads.chat ? 'conversation' : 'defaults')
  const tabs = roads.chat ? [['conversation', 'Conversation'], ...baseTabs] : baseTabs

  return <main className="workspace settings-workspace">
    <header className="topbar"><button className="back-button" onClick={onBack}><BackIcon />Conversations</button></header>
    <div className="settings-content">
      <div className="page-header"><span className="eyebrow">Configuration</span><h1>Settings</h1></div>
      <nav className="settings-tabs" aria-label="Settings sections">
        {tabs.map(([id, label]) => <button key={id} className={tab === id ? 'active' : ''} onClick={() => setTab(id)}>{label}</button>)}
      </nav>
      {tab === 'conversation' && <AgentSettings roads={roads} theme={theme} onThemeChange={onThemeChange} />}
      {tab === 'defaults' && <GlobalSettings roads={roads} theme={theme} onThemeChange={onThemeChange} />}
      {tab === 'mcp' && <McpSettings roads={roads} />}
      {['openrouter', 'openai', 'anthropic', 'custom'].includes(tab) && <ProviderSettings provider={tab} roads={roads} />}
    </div>
  </main>
}
