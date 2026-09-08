import { useId } from 'react'

export default function PeerTokenLimit({ ship, value, onChange, disabled = false }) {
  const note = useId()
  return <label>
    <span>Peer token limit</span>
    <input type="number" min="0" step="1" max={Number.MAX_SAFE_INTEGER} required value={value}
      aria-label={`Peer token limit for ${ship}`} aria-describedby={note} disabled={disabled}
      onChange={(event) => onChange(event.target.value)} />
    <small id={note} className="field-note">0 = unlimited. Checked against lifetime prompt + response tokens before each peer request; not the model’s context window.</small>
  </label>
}
