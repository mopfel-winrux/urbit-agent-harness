export default function HeaderEditor({ value = [], onChange, note = 'Content-Type is automatic. Add authentication or server-specific headers here.' }) {
  const replace = (index, next) => onChange(value.map((entry, at) => at === index ? next : entry))
  return <div className="header-editor">
    <div className="field-heading"><span>Request headers</span><button type="button" className="text-button" onClick={() => onChange([...value, { name: '', value: '' }])}>Add header</button></div>
    {!value.length && <p className="field-note">{note}</p>}
    {value.map((header, index) => <div className="header-row" key={index}>
      <input aria-label="Header name" value={header.name || ''} onChange={(event) => replace(index, { ...header, name: event.target.value })} placeholder="authorization" />
      <input aria-label="Header value" type={/authorization|token|key/i.test(header.name) ? 'password' : 'text'} value={header.value || ''} onChange={(event) => replace(index, { ...header, value: event.target.value })} placeholder="value" />
      <button type="button" className="remove-header" onClick={() => onChange(value.filter((_, at) => at !== index))} aria-label="Remove header">×</button>
    </div>)}
  </div>
}
