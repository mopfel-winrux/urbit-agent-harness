import { useRef, useState } from 'react'
import { createRoot } from 'react-dom/client'
import { Select, Combobox } from '../src/components/Picker'
import '../src/style.css'

function Fixture() {
  const [value, setValue] = useState(''), [model, setModel] = useState('')
  const [disabled, setDisabled] = useState(false), [revoked, setRevoked] = useState(false)
  const [saved, setSaved] = useState(0), dialog = useRef(null)
  const options = <>
    <Select.Option value="">Choose a runner</Select.Option>
    <Select.Option value="claude">Claude Code · laptop</Select.Option>
    <Select.Option value="revoked" disabled>Retired connection · revoked</Select.Option>
    <Select.Option value="codex" disabled={revoked}>Codex · workstation</Select.Option>
    <Select.Option value="long">Research and implementation agent · shared development workstation with a very long connection name</Select.Option>
  </>
  return <main className="settings-grid" style={{ maxWidth: 700, margin: '24px auto', padding: 16 }}>
    <h1>In-page picker fixture</h1>
    <form className="panel settings-panel settings-grid" onSubmit={event => { event.preventDefault(); setSaved(saved + 1) }}>
      <fieldset disabled={disabled} className="memory-model-fields" data-testid="fieldset">
        <Select label="Connected runner" required name="runner" value={value} onValueChange={setValue}>{options}</Select>
        <Combobox label="Model" options={Array.from({ length: 1000 }, (_, index) => `provider/model-${index}`)} value={model} onValueChange={setModel} />
      </fieldset>
      <button className="button primary">Save choices</button>
      <output aria-label="Saved choices">{saved}</output>
    </form>
    <button className="button" onClick={() => setDisabled(!disabled)}>Toggle fieldset</button>
    <button className="button" onClick={() => setRevoked(!revoked)}>Toggle Codex availability</button>
    <button className="button" onClick={() => dialog.current.showModal()}>Open dialog</button>
    <dialog ref={dialog} className="conversation-dialog"><div className="modal-card settings-grid" style={{ padding: 24 }}>
      <h2>Dialog choices</h2>
      <Select label="Dialog runner" value={value} onValueChange={setValue}>{options}</Select>
      <button className="button" onClick={() => dialog.current.close()}>Close dialog</button>
    </div></dialog>
    <output aria-label="Current runner">{value}</output><output aria-label="Current model">{model}</output>
  </main>
}
createRoot(document.getElementById('root')).render(<Fixture />)
