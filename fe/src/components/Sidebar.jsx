import { HarnessIcon, PlusIcon, RenameIcon, SettingsIcon, TrashIcon } from './Icons'

export default function Sidebar({ chats, current, onSelect, onNew, onRename, onDelete, settings, onSettings }) {
  return (
    <aside className="sidebar">
      <div className="brand"><HarnessIcon size={20} /><span>Harness</span></div>
      <div className="sidebar-heading"><span>Conversations</span><button className="icon-button" onClick={onNew} title="New conversation"><PlusIcon /></button></div>
      <nav className="chat-list">
        {chats.map((chat) => (
          <div className="chat-row" key={chat}>
            <button className={chat === current && !settings ? 'chat-link active' : 'chat-link'} onClick={() => onSelect(chat)}>
              <span className="chat-mark" />
              <span className="truncate">{chat}</span>
            </button>
            <div className="chat-actions">
              <button onClick={() => onRename(chat)} title={`Rename ${chat}`}><RenameIcon /></button>
              <button onClick={() => onDelete(chat)} title={`Delete ${chat}`}><TrashIcon /></button>
            </div>
          </div>
        ))}
      </nav>
      <div className="sidebar-spacer" />
      <button className={settings ? 'sidebar-action active' : 'sidebar-action'} onClick={onSettings}><SettingsIcon /><span>Settings</span></button>
    </aside>
  )
}
