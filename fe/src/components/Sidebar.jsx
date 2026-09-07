import { PlusIcon, RenameIcon, SettingsIcon, TrashIcon } from './Icons'
import TlonIcon from './TlonIcon'
import { useState } from 'react'
import { CONVERSATION_PAGE_SIZE, conversationPage } from '../conversations'

export default function Sidebar({ chats, current, onSelect, onNew, onRename, onDelete, settings, onSettings, tlon, onTlon }) {
  const [search, setSearch] = useState('')
  const [limit, setLimit] = useState(CONVERSATION_PAGE_SIZE)
  const { visible, remaining } = conversationPage(chats, search, limit)
  return (
    <aside className="sidebar">
      <div className="brand"><img className="brand-logo" src={`${import.meta.env.BASE_URL}harness-logo.png`} alt="Harness" width="32" height="32" /><span aria-hidden="true">Harness</span></div>
      <div className="sidebar-heading"><span>Conversations</span><button className="icon-button" onClick={onNew} title="New conversation" aria-label="New conversation"><PlusIcon /></button></div>
      <input className="conversation-search" type="search" aria-label="Search conversations" placeholder="Search" value={search} onChange={(event) => { setSearch(event.target.value); setLimit(CONVERSATION_PAGE_SIZE) }} />
      <nav className="chat-list" aria-label="Conversations">
        {visible.map((chat) => (
          <div className="chat-row" key={chat}>
            <button className={chat === current && !settings ? 'chat-link active' : 'chat-link'} onClick={() => onSelect(chat)} title={chat} aria-label={chat} aria-current={chat === current && !settings ? 'page' : undefined}>
              <span className="chat-mark" />
              <span className="chat-initial" aria-hidden="true">{chat.split('-').map((part) => part[0]).join('').slice(0, 2)}</span>
              <span className="truncate">{chat}</span>
            </button>
            <div className="chat-actions">
              <button onClick={() => onRename(chat)} title={`Rename ${chat}`} aria-label={`Rename ${chat}`}><RenameIcon /></button>
              <button onClick={() => onDelete(chat)} title={`Delete ${chat}`} aria-label={`Delete ${chat}`}><TrashIcon /></button>
            </div>
          </div>
        ))}
        {!visible.length && search && <p className="conversation-empty" role="status">No matches</p>}
        {remaining > 0 && <button className="conversation-load-more text-button" onClick={() => setLimit((value) => value + CONVERSATION_PAGE_SIZE)} aria-label={`Load more conversations (${remaining} remaining)`}>Load more</button>}
      </nav>
      <div className="sidebar-spacer" />
      <button className={tlon ? 'sidebar-action active' : 'sidebar-action'} onClick={onTlon} title="Tlon" aria-label="Tlon"><TlonIcon /><span>Tlon</span></button>
      <button className={settings ? 'sidebar-action active' : 'sidebar-action'} onClick={onSettings} title="Settings" aria-label="Settings"><SettingsIcon /><span>Settings</span></button>
    </aside>
  )
}
