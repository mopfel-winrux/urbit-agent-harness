import { Children, Fragment, isValidElement, useEffect, useId, useLayoutEffect, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { CheckIcon, ChevronDownIcon } from './Icons'
import './picker.css'

const text = node => Children.toArray(node).map(child => isValidElement(child) ? text(child.props.children) : String(child)).join('')
function choices(children) {
  return Children.toArray(children).flatMap(child => {
    if (!isValidElement(child)) return []
    if (child.type === Fragment) return choices(child.props.children)
    return [{ value: String(child.props.value), label: text(child.props.children), disabled: !!child.props.disabled }]
  })
}

export function Select({ children, ...props }) {
  return <Picker {...props} options={choices(children)} />
}
Select.Option = function Option() { return null }

export function Combobox({ options, ...props }) {
  return <Picker {...props} editable options={options.map(value => ({ value, label: value }))} />
}

function Picker({ label, value = '', options, onValueChange, editable = false, disabled = false, required = false, name, placeholder, id: suppliedId, ...props }) {
  const generatedId = useId(), id = suppliedId || generatedId
  const labelId = `${id}-label`, listId = `${id}-list`, errorId = `${id}-error`
  const control = useRef(null), panel = useRef(null), typeahead = useRef({ text: '', at: 0 }), keyboard = useRef(true)
  const [open, setOpen] = useState(false), [active, setActive] = useState(-1)
  const [filter, setFilter] = useState(false), [invalid, setInvalid] = useState(false)
  const [position, setPosition] = useState(null)
  const current = String(value ?? '')
  const matches = editable && filter ? options.filter(option => option.label.toLocaleLowerCase().includes(current.toLocaleLowerCase())) : options
  const visible = editable ? matches.slice(0, 100) : matches
  const enabled = visible.map((option, index) => option.disabled ? -1 : index).filter(index => index >= 0)
  const selected = options.find(option => option.value === current)
  const activeOption = visible[active]?.disabled ? null : visible[active]
  const isDisabled = () => !control.current || control.current.matches(':disabled')

  function show(edge) {
    if (isDisabled()) return
    keyboard.current = true
    setFilter(false)
    const selectedIndex = options.findIndex(option => option.value === current && !option.disabled)
    const available = options.map((option, index) => option.disabled ? -1 : index).filter(index => index >= 0)
    setActive(edge === 'last' ? available.at(-1) ?? -1 : edge === 'first' ? available[0] ?? -1 : selectedIndex >= 0 ? selectedIndex : available[0] ?? -1)
    setPosition(null); setOpen(true)
  }
  function choose(index) {
    const option = visible[index]
    if (!option || option.disabled || isDisabled()) { setOpen(false); return }
    onValueChange(option.value)
    setInvalid(false); setOpen(false)
    control.current.focus({ preventScroll: true })
  }
  function keyDown(event) {
    if (event.nativeEvent.isComposing || isDisabled()) return
    keyboard.current = true
    if (event.key === 'Escape' && open) {
      event.preventDefault(); event.stopPropagation(); setOpen(false); return
    }
    if (event.key === 'Tab') { setOpen(false); return }
    if (['ArrowDown', 'ArrowUp'].includes(event.key)) {
      event.preventDefault()
      if (!open) { show(event.key === 'ArrowUp' ? 'last' : undefined); return }
      const at = enabled.indexOf(active), step = event.key === 'ArrowDown' ? 1 : -1
      setActive(enabled.length ? at < 0 ? step > 0 ? enabled[0] : enabled.at(-1) : enabled[(at + step + enabled.length) % enabled.length] : -1)
      return
    }
    if ((!editable || (open && event.ctrlKey)) && ['Home', 'End'].includes(event.key)) {
      event.preventDefault()
      if (!open) show(event.key === 'End' ? 'last' : 'first')
      else setActive(event.key === 'End' ? enabled.at(-1) ?? -1 : enabled[0] ?? -1)
      return
    }
    if (event.key === 'Enter' || (!editable && event.key === ' ')) {
      if (open) { event.preventDefault(); event.stopPropagation(); if (activeOption) choose(active); else setOpen(false) }
      else if (!editable) { event.preventDefault(); show() }
      return
    }
    if (!editable && event.key.length === 1 && !event.ctrlKey && !event.altKey && !event.metaKey) {
      event.preventDefault()
      const now = performance.now(), letter = event.key.toLocaleLowerCase()
      const prior = now - typeahead.current.at < 700 ? typeahead.current.text : ''
      const query = prior + letter
      typeahead.current = { text: query, at: now }
      const prefix = [...query].every(char => char === letter) ? letter : query
      const start = prefix.length === 1 ? active + 1 : Math.max(0, active)
      const order = [...enabled.filter(index => index >= start), ...enabled.filter(index => index < start)]
      const found = order.find(index => visible[index].label.toLocaleLowerCase().startsWith(prefix))
      if (!open) show()
      if (found !== undefined) setActive(found)
    }
  }

  useLayoutEffect(() => {
    if (!open) return
    if (isDisabled()) { setOpen(false); return }
    if (active >= visible.length || visible[active]?.disabled) setActive(-1)
  })
  useLayoutEffect(() => {
    if (!open || !panel.current) return
    const anchor = control.current, popup = panel.current
    function place(event) {
      if (event?.target instanceof Node && popup.contains(event.target)) return
      const rect = anchor.getBoundingClientRect(), viewport = window.visualViewport
      const topEdge = viewport?.offsetTop || 0, leftEdge = viewport?.offsetLeft || 0
      const height = viewport?.height || window.innerHeight, width = viewport?.width || window.innerWidth
      const below = topEdge + height - rect.bottom - 12, above = rect.top - topEdge - 12
      const desired = Math.min(320, popup.scrollHeight)
      const up = below < desired && above > below
      const maxHeight = Math.max(0, Math.min(320, up ? above : below))
      const popupWidth = Math.min(rect.width, width - 24)
      const next = { position: 'fixed', width: popupWidth, maxHeight,
        left: Math.max(leftEdge + 12, Math.min(rect.left, leftEdge + width - popupWidth - 12)),
        top: up ? rect.top - Math.min(desired, maxHeight) - 6 : rect.bottom + 6 }
      setPosition(previous => JSON.stringify(previous) === JSON.stringify(next) ? previous : next)
    }
    place()
    const resize = new ResizeObserver(() => place())
    resize.observe(anchor); resize.observe(popup)
    window.addEventListener('scroll', place, true); window.addEventListener('resize', place)
    window.visualViewport?.addEventListener('resize', place)
    window.visualViewport?.addEventListener('scroll', place)
    return () => {
      resize.disconnect()
      window.removeEventListener('scroll', place, true); window.removeEventListener('resize', place)
      window.visualViewport?.removeEventListener('resize', place)
      window.visualViewport?.removeEventListener('scroll', place)
    }
  }, [open, visible.length])
  useEffect(() => {
    if (!open) return
    function outside(event) {
      if (!control.current?.parentElement.contains(event.target) && !panel.current?.contains(event.target)) setOpen(false)
    }
    document.addEventListener('pointerdown', outside, true)
    document.addEventListener('focusin', outside, true)
    const observer = new MutationObserver(() => { if (isDisabled()) setOpen(false) })
    for (let parent = control.current.parentElement; parent; parent = parent.parentElement) {
      if (parent.tagName === 'FIELDSET') observer.observe(parent, { attributes: true, attributeFilter: ['disabled'] })
    }
    return () => {
      document.removeEventListener('pointerdown', outside, true)
      document.removeEventListener('focusin', outside, true)
      observer.disconnect()
    }
  }, [open])
  useLayoutEffect(() => {
    if (open && activeOption && keyboard.current) document.getElementById(`${id}-option-${active}`)?.scrollIntoView({ block: 'nearest' })
  }, [open, active, id, activeOption?.value])

  const accessibility = {
    id, ref: control, role: 'combobox', disabled, 'aria-labelledby': labelId,
    'aria-expanded': open, 'aria-controls': open ? listId : undefined, 'aria-haspopup': 'listbox',
    'aria-activedescendant': open && activeOption ? `${id}-option-${active}` : undefined,
    'aria-required': required || undefined, 'aria-invalid': invalid || undefined,
    'aria-describedby': [props['aria-describedby'], invalid && errorId].filter(Boolean).join(' ') || undefined,
    onKeyDown: keyDown,
  }
  const popup = open && createPortal(<div ref={panel} className="picker-popup" style={position || { position: 'fixed', visibility: 'hidden' }} onPointerDown={event => event.preventDefault()}>
    <div id={listId} role="listbox" aria-labelledby={labelId}>
      {visible.map((option, index) => <div key={option.value} id={`${id}-option-${index}`} role="option"
        aria-selected={option.value === current} aria-disabled={option.disabled || undefined} data-value={option.value}
        className={`picker-option${index === active ? ' active' : ''}`}
        onPointerMove={event => { if (event.pointerType === 'mouse' && !option.disabled) { keyboard.current = false; setActive(index) } }}
        onClick={event => { event.preventDefault(); event.stopPropagation(); choose(index) }}>
        <span>{option.label}</span><span className="picker-check">{option.value === current && <CheckIcon />}</span>
      </div>)}
    </div>
    {!visible.length && <p className="picker-note" role="status">{editable ? 'No suggestions. Use the name you entered.' : 'No choices available.'}</p>}
    {matches.length > visible.length && <p className="picker-note">Showing {visible.length} of {matches.length}. Type to narrow the list.</p>}
  </div>, control.current?.closest('dialog') || document.body)

  return <label className="picker-field" htmlFor={id}>
    <span id={labelId}>{label}</span>
    <span className="picker-control">
      {editable ? <input {...props} {...accessibility} name={name} required={required} value={current} placeholder={placeholder}
        autoComplete="off" aria-autocomplete="list" className="picker-input"
        onClick={() => { if (!open) show() }}
        onChange={event => { onValueChange(event.target.value); setInvalid(false); setFilter(true); setActive(-1); setOpen(true) }} />
        : <button {...props} {...accessibility} type="button" className="picker-trigger" onClick={() => open ? setOpen(false) : show()}>
          <span>{selected?.label || current || placeholder || 'Choose an option'}</span><ChevronDownIcon />
        </button>}
      {editable && <span className="picker-input-chevron" aria-hidden="true"><ChevronDownIcon /></span>}
      {!editable && (required || name) && <input className="picker-validation" aria-hidden="true" tabIndex={-1} name={name}
        value={current} required={required} disabled={disabled} autoComplete="off" onChange={() => {}}
        onInvalid={event => { event.preventDefault(); setInvalid(true); control.current?.focus() }} />}
    </span>
    {invalid && <span id={errorId} className="picker-error" role="alert">Choose an option.</span>}
    {popup}
  </label>
}
