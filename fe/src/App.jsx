import { useEffect, useState } from 'react'
import { ballUrl, DEFAULT_BALL } from './api'
import Chat from './components/Chat'
import ConversationModal from './components/ConversationModal'
import Settings from './components/Settings'
import Sidebar from './components/Sidebar'
import { useConversations } from './useConversations'

const AGENT = 'main'

function route() {
  const value = location.hash.replace(/^#\/?/, '')
  if (value === 'settings') return { page: 'settings', chat: 'main' }
  try { return { page: 'chat', chat: value ? decodeURIComponent(value) : 'main' } } catch { return { page: 'chat', chat: 'main' } }
}

export default function App() {
  const [view, setView] = useState(route)
  const [dialog, setDialog] = useState(null)
  const [error, setError] = useState('')
  const [theme, setTheme] = useState(() => localStorage.getItem('harness-theme') || 'system')
  const { chat: current, page } = view
  const settings = page === 'settings'
  const conversations = useConversations(DEFAULT_BALL, AGENT, current, choose)
  const { chats, roads: baseRoads } = conversations

  useEffect(() => {
    document.documentElement.dataset.theme = theme
    localStorage.setItem('harness-theme', theme)
  }, [theme])
  useEffect(() => {
    const navigate = () => setView(route())
    addEventListener('popstate', navigate)
    addEventListener('hashchange', navigate)
    return () => {
      removeEventListener('popstate', navigate)
      removeEventListener('hashchange', navigate)
    }
  }, [])
  useEffect(() => {
    if (!settings && !chats.includes(current)) choose(chats[0] || 'main', false)
  }, [chats, current, settings])

  function choose(chat, push = true) {
    setView({ page: 'chat', chat }); setError('')
    if (push) history.pushState({}, '', `#/${encodeURIComponent(chat)}`)
  }

  function openSettings() {
    setView({ page: 'settings', chat: current }); setError('')
    history.pushState({}, '', '#/settings')
  }

  async function createChat(name) {
    await conversations.create(name)
  }

  async function renameChat(name) {
    await conversations.rename(dialog?.chat, name)
  }

  async function deleteChat(name) {
    if (chats.length === 1) { setError('Keep at least one conversation.'); return }
    if (!confirm(`Delete “${name}” and its transcript?`)) return
    setError('')
    try {
      await conversations.remove(name)
    } catch (cause) { setError(cause.message) }
  }

  const toggleTheme = () => setTheme((value) => value === 'dark' ? 'light' : 'dark')

  return <div className="app-shell">
    <Sidebar chats={chats} current={current} onSelect={choose} onNew={() => setDialog({ mode: 'create' })} onRename={(chat) => setDialog({ mode: 'rename', chat })} onDelete={deleteChat} settings={settings} onSettings={openSettings} inspectUrl={ballUrl(baseRoads.agentRoot)} />
    {settings
      ? <Settings roads={baseRoads} theme={theme} onThemeChange={setTheme} onBack={() => choose(current)} />
      : <Chat chat={current} roads={baseRoads} theme={theme} onToggleTheme={toggleTheme} />}
    {(error || conversations.error) && <div className="global-error" onClick={() => setError('')}>{error || conversations.error}</div>}
    {dialog && <ConversationModal mode={dialog.mode} initialName={dialog.chat || ''} onClose={() => setDialog(null)} onSave={dialog.mode === 'rename' ? renameChat : createChat} />}
  </div>
}
