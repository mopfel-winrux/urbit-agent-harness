import { useId, useState } from 'react'
import { canonicalShip, suggestPeople } from '../people'

export default function ShipPicker({ label, value = '', contacts = [], exclude = [], onChange }) {
  const id = useId()
  const [query, setQuery] = useState('')
  const [open, setOpen] = useState(false)
  const [active, setActive] = useState(0)
  const matches = suggestPeople(query, contacts, exclude)
  const person = contacts.find((entry) => entry.ship === value)
  const choose = (ship) => { onChange(ship); setQuery(''); setOpen(false) }
  function keyDown(event) {
    if (event.key === 'Escape') setOpen(false)
    if (event.key === 'ArrowDown') { event.preventDefault(); setActive((n) => Math.max(0, Math.min(n + 1, matches.length - 1))) }
    if (event.key === 'ArrowUp') { event.preventDefault(); setActive((n) => Math.max(0, n - 1)) }
    if (event.key === 'Enter' && open) {
      event.preventDefault()
      const ship = matches[active]?.ship || canonicalShip(query)
      if (ship && !exclude.includes(ship)) choose(ship)
    }
  }
  return <div className="ship-picker" onBlur={(event) => { if (!event.currentTarget.contains(event.relatedTarget)) setOpen(false) }}>
    <label htmlFor={id}>{label}</label>
    <input id={id} role="combobox" autoComplete="off" aria-autocomplete="list" aria-expanded={open} aria-controls={`${id}-list`} aria-activedescendant={open && matches[active] ? `${id}-${active}` : undefined}
      placeholder="Search @p or nickname" value={open ? query : value}
      onFocus={() => { setOpen(true); setQuery(''); setActive(0) }} onKeyDown={keyDown}
      onChange={(event) => { setQuery(event.target.value); setActive(0); setOpen(true) }} />
    {!open && person?.nickname && <small>{person.nickname}</small>}
    {open && <div className="people-suggestions" id={`${id}-list`} role="listbox">
      {matches.map((entry, index) => <button type="button" id={`${id}-${index}`} role="option" aria-selected={index === active} key={entry.ship} onClick={() => choose(entry.ship)}>
        <span><strong>{entry.nickname || entry.ship}</strong>{entry.nickname && <small>{entry.ship}</small>}</span>
        {entry.contact && <small>Contact</small>}
      </button>)}
      {!matches.length && <p>Enter a valid ship name or search your contacts.</p>}
    </div>}
  </div>
}
