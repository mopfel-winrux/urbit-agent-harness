import { authMethod, withAuth } from '../providerConfig'

// Shared by provider, defaults and conversation settings. Only Custom edits
// the transport address; built-ins choose credentials and derive the route.
export default function ProviderRoute({ provider, value, onChange }) {
  if (provider === 'custom') return <label><span>Endpoint</span><input type="url" required value={value.url || ''} onChange={(event) => onChange({ ...value, url: event.target.value })} placeholder="https://inference.example/v1/chat/completions" /></label>
  if (!['openai', 'anthropic'].includes(provider)) return null
  return <label><span>Authentication</span><select value={authMethod(provider, value)} onChange={(event) => onChange(withAuth(value, provider, event.target.value))}>
    <option value="api-key">API key</option>
    <option value="device">{provider === 'openai' ? 'Device login (ChatGPT)' : 'Browser login (Claude)'}</option>
  </select></label>
}
