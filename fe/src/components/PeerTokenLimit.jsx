import { useId, useState } from 'react'
import { api } from '../api'

export default function PeerTokenLimit({ ship, value, onChange, resource, disabled = false }) {
  const note = useId()
  const [resetting, setResetting] = useState(false)
  const [error, setError] = useState('')
  const [reset, setReset] = useState(false)
  const usage = resource.value.usage?.find((entry) => entry.ship === ship)
  const unavailable = disabled || resource.loading || !!resource.error
  async function resetCount() {
    if (resetting || unavailable || !usage || !usage.used) return
    setResetting(true); setError(''); setReset(false)
    try {
      const applied = await api.action({ peerReset: { ship, revision: resource.value.revision } })
      resource.setValue(applied); setReset(true)
    } catch (cause) { setError(cause.message) } finally { setResetting(false) }
  }
  return <div className="peer-token-limit"><label>
    <span>Peer token limit</span>
    <input type="number" min="0" step="1" max={Number.MAX_SAFE_INTEGER} required value={value}
      aria-label={`Peer token limit for ${ship}`} aria-describedby={note} disabled={disabled}
      onChange={(event) => onChange(event.target.value)} />
    <small id={note} className="field-note">0 = unlimited. Counts prompt + response tokens since the last reset; checked before each peer request, not a per-request cap.</small>
  </label>
    <div className="peer-token-count">
      <span role="status">{resource.loading ? 'Loading token count…' : resource.error ? 'Token count unavailable.' : usage ? `${Number(usage.used).toLocaleString()} tokens used${reset ? ' · Count reset.' : ''}` : 'Save this ship to start tracking usage.'}</span>
      <button type="button" className="text-button" aria-label={`Reset token count for ${ship}`} disabled={unavailable || resetting || !usage?.used} onClick={resetCount}>{resetting ? 'Resetting…' : 'Reset count'}</button>
    </div>
    <small className="field-note">Reset applies immediately. Keeps the limit, permissions, and conversation; in-flight usage counts when recorded.</small>
    {error && <p className="inline-error" role="alert">Could not reset token count: {error} <button type="button" className="text-button" disabled={resetting || disabled} onClick={() => { setError(''); void resource.refresh() }}>Refresh token count</button></p>}
  </div>
}
