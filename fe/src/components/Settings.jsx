import { useState } from 'react'
import AgentSettings from './AgentSettings'
import { BackIcon } from './Icons'
import GlobalSettings from './GlobalSettings'
import McpSettings from './McpSettings'
import SearchSettings from './SearchSettings'
import ProviderSettings from './ProviderSettings'
import SkillSettings from './SkillSettings'
import MemorySettings from './MemorySettings'
import PeerSettings from './PeerSettings'

const baseTabs = [
  ['defaults', 'Defaults'],
  ['memory', 'Memory'],
  ['skills', 'Skills'],
  ['peers', 'Peers'],
  ['mcp', 'MCP'],
  ['search', 'Search'],
]
const providerTabs = [['openrouter', 'OpenRouter'], ['openai', 'OpenAI'], ['anthropic', 'Anthropic'], ['custom', 'Custom']]

export default function Settings({ resources, theme, onThemeChange, onBack, initialTab }) {
  const [tab, setTab] = useState(() => [...baseTabs, ['providers']].some(([id]) => id === initialTab) ? initialTab : resources.chat ? 'conversation' : 'defaults')
  const [provider, setProvider] = useState('openrouter')
  const tabs = resources.chat ? [['conversation', 'Conversation'], ...baseTabs] : [...baseTabs]
  tabs.splice(1, 0, ['providers', 'Providers'])

  return <main className="workspace settings-workspace">
    <header className="topbar"><button className="back-button" onClick={onBack}><BackIcon />Conversations</button></header>
    <div className="settings-content">
      <div className="page-header"><h1>Settings</h1></div>
      <nav className="settings-tabs" aria-label="Settings sections">
        {tabs.map(([id, label]) => <button key={id} className={tab === id ? 'active' : ''} aria-current={tab === id ? 'page' : undefined} onClick={() => setTab(id)}>{label}</button>)}
      </nav>
      {tab === 'conversation' && <AgentSettings resources={resources} theme={theme} onThemeChange={onThemeChange} />}
      {tab === 'defaults' && <GlobalSettings resources={resources} theme={theme} onThemeChange={onThemeChange} />}
      {tab === 'memory' && <MemorySettings />}
      {tab === 'skills' && <SkillSettings />}
      {tab === 'peers' && <PeerSettings />}
      {tab === 'mcp' && <McpSettings resources={resources} />}
      {tab === 'search' && <SearchSettings />}
      {tab === 'providers' && <>
        <nav className="provider-options segmented" aria-label="Provider settings">{providerTabs.map(([id, label]) => <button key={id} className={provider === id ? 'active' : ''} aria-current={provider === id ? 'page' : undefined} onClick={() => setProvider(id)}>{label}</button>)}</nav>
        <ProviderSettings key={provider} provider={provider} resources={resources} />
      </>}
    </div>
  </main>
}
