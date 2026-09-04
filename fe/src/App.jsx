import { useEffect, useState } from 'react'
import Chat from './components/Chat'
import ConversationModal from './components/ConversationModal'
import Settings from './components/Settings'
import Sidebar from './components/Sidebar'
import Welcome from './components/Welcome'
import { useConversations } from './useConversations'
import { acp } from './acp'

function route() {
  const value = location.hash.replace(/^#\/?/, '')
  try {
    if (value === 'settings') return { page: 'settings', chat: '' }
    if (value.startsWith('settings/')) return { page: 'settings', chat: decodeURIComponent(value.slice(9)) }
    return { page: 'chat', chat: value ? decodeURIComponent(value) : '' }
  } catch { return { page: 'chat', chat: '' } }
}

export default function App() {
  const [view, setView] = useState(route)
  const [dialog, setDialog] = useState(null)
  const [error, setError] = useState('')
  const [theme, setTheme] = useState(() => localStorage.getItem('harness-theme') || 'system')
  const { chat: current, page } = view
  const settings = page === 'settings'
  const conversations = useConversations(current, choose)
  const { chats, loading, resources } = conversations

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
    if (!settings && chats.length && !chats.includes(current)) choose(chats[0], false)
  }, [chats, current, settings])

  function choose(chat, push = true) {
    setView({ page: 'chat', chat }); setError('')
    if (push) history.pushState({}, '', `#/${encodeURIComponent(chat)}`)
  }

  function openSettings() {
    setView({ page: 'settings', chat: current }); setError('')
    history.pushState({}, '', current ? `#/settings/${encodeURIComponent(current)}` : '#/settings')
  }

  async function createChat(name) {
    await conversations.create(name)
  }

  async function renameChat(name) {
    await conversations.rename(dialog?.chat, name)
  }

  async function forkChat(name) {
    const result = await acp.call('harness/session/fork', { sessionId: dialog.chat, eventCount: dialog.eventCount, name })
    await conversations.refresh()
    choose(result.sessionId)
  }

  async function deleteChat(name) {
    if (!confirm(`Delete “${name}” and its transcript?`)) return
    setError('')
    try {
      await conversations.remove(name)
    } catch (cause) { setError(cause.message) }
  }

  const toggleTheme = () => setTheme((value) => ({ system: 'light', light: 'dark', dark: 'system' })[value] || 'system')

  return <div className="app-shell">
    <Sidebar chats={chats} current={current} onSelect={choose} onNew={() => setDialog({ mode: 'create' })} onRename={(chat) => setDialog({ mode: 'rename', chat })} onDelete={deleteChat} settings={settings} onSettings={openSettings} />
    {settings
      ? <Settings resources={resources} theme={theme} onThemeChange={setTheme} onBack={() => choose(current)} />
      : current ? <Chat key={current} chat={current} theme={theme} onToggleTheme={toggleTheme} onSettings={openSettings} onSelect={choose} onFork={(eventCount) => setDialog({ mode: 'fork', chat: current, eventCount })} /> : <Welcome loading={loading} onNew={() => setDialog({ mode: 'create' })} />}
    {(error || conversations.error) && <div className="global-error" onClick={() => setError('')}>{error || conversations.error}</div>}
    {dialog && <ConversationModal mode={dialog.mode} initialName={dialog.mode === 'fork' ? `${dialog.chat.slice(0, 50)}-branch` : dialog.chat || ''} onClose={() => setDialog(null)} onSave={dialog.mode === 'fork' ? forkChat : dialog.mode === 'rename' ? renameChat : createChat} />}
  </div>
}
