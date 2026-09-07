import { MenuIcon, PlusIcon, RenameIcon, SettingsIcon, TrashIcon } from './Icons'
import TlonIcon from './TlonIcon'
import { useEffect, useRef, useState } from 'react'
import { CONVERSATION_PAGE_SIZE, conversationPage } from '../conversations'

export default function Sidebar({ chats, current, onSelect, onNew, onRename, onDelete, settings, onSettings, tlon, onTlon }) {
  const [search, setSearch] = useState('')
  const [limit, setLimit] = useState(CONVERSATION_PAGE_SIZE)
  const [mobile, setMobile] = useState(() => matchMedia('(max-width: 760px)').matches)
  const drawer = useRef(null)
  useEffect(() => {
    const query = matchMedia('(max-width: 760px)')
    const update = () => setMobile(query.matches)
    query.addEventListener('change', update)
    return () => query.removeEventListener('change', update)
  }, [])
  const act = (callback, ...args) => { drawer.current?.close(); callback?.(...args) }
  const { visible, remaining } = conversationPage(chats, search, limit)
  const navigation = (
    <aside className="sidebar">
      <div className="brand"><img className="brand-logo" src={`${import.meta.env.BASE_URL}harness-logo.png`} alt="Harness" width="32" height="32" /><span aria-hidden="true">Harness</span>{mobile && <button className="close-button" aria-label="Close navigation" onClick={() => drawer.current.close()}>×</button>}</div>
      <div className="sidebar-heading"><span>Conversations</span><button className="icon-button" onClick={() => act(onNew)} title="New conversation" aria-label="New conversation"><PlusIcon /></button></div>
      <input className="conversation-search" type="search" aria-label="Search conversations" placeholder="Search" value={search} onChange={(event) => { setSearch(event.target.value); setLimit(CONVERSATION_PAGE_SIZE) }} />
      <nav className="chat-list" aria-label="Conversations">
        {visible.map((chat) => (
          <div className="chat-row" key={chat}>
            <button className={chat === current && !settings ? 'chat-link active' : 'chat-link'} onClick={() => act(onSelect, chat)} title={chat} aria-label={chat} aria-current={chat === current && !settings ? 'page' : undefined}>
              <span className="chat-mark" />
              <span className="truncate">{chat}</span>
            </button>
            <div className="chat-actions">
              <button onClick={() => act(onRename, chat)} title={`Rename ${chat}`} aria-label={`Rename ${chat}`}><RenameIcon /></button>
              <button onClick={() => act(onDelete, chat)} title={`Delete ${chat}`} aria-label={`Delete ${chat}`}><TrashIcon /></button>
            </div>
          </div>
        ))}
        {!visible.length && search && <p className="conversation-empty" role="status">No matches</p>}
        {remaining > 0 && <button className="conversation-load-more text-button" onClick={() => setLimit((value) => value + CONVERSATION_PAGE_SIZE)} aria-label={`Load more conversations (${remaining} remaining)`}>Load more</button>}
      </nav>
      <div className="sidebar-spacer" />
      <button className={tlon ? 'sidebar-action active' : 'sidebar-action'} onClick={() => act(onTlon)} title="Tlon" aria-label="Tlon" aria-current={tlon ? 'page' : undefined}><TlonIcon /><span>Tlon</span></button>
      <button className={settings ? 'sidebar-action active' : 'sidebar-action'} onClick={() => act(onSettings)} title="Settings" aria-label="Settings" aria-current={settings ? 'page' : undefined}><SettingsIcon /><span>Settings</span></button>
    </aside>
  )
  if (!mobile) return navigation
  return <>
    <header className="mobile-navigation">
      <button className="back-button" onClick={() => drawer.current.showModal()} aria-label="Open navigation"><MenuIcon />Harness</button>
      <button className="icon-button" onClick={onNew} aria-label="New conversation"><PlusIcon /></button>
    </header>
    <dialog className="navigation-drawer" ref={drawer} aria-label="Navigation" onClick={(event) => { if (event.target === event.currentTarget) drawer.current.close() }}>{navigation}</dialog>
  </>
}
