import { Select } from './Picker'
import { authMethod, withAuth } from '../providerConfig'
import { useResource } from '../useResource'

export function RunnerSelect({ value, onChange }) {
  const runners = useResource('runners', [], 15_000)
  const selected = value.url?.startsWith('connected://') ? value.url.slice(12) : ''
  const rows = runners.value || []
  return <>
    <Select label="Connected runner" required value={selected} disabled={runners.loading} onValueChange={(nextValue) => onChange(withAuth({ ...value, url: `connected://${nextValue}` }, 'connected'))}>
      <Select.Option value="">{runners.loading ? 'Loading runners…' : 'Choose a runner'}</Select.Option>
      {selected && !rows.some((row) => row.id === selected) && <Select.Option value={selected} disabled>Unavailable runner ({selected})</Select.Option>}
      {rows.map((row) => <Select.Option key={row.id} value={row.id} disabled={row.status === 'revoked'}>{row.label} · {row.status}</Select.Option>)}
    </Select>
    {runners.error && <p className="inline-error" role="alert">{runners.error} <button className="text-button" type="button" onClick={() => runners.refresh()}>Retry</button></p>}
    <p className="field-note">Each connection chooses its local agent and model. Add connections in Settings → Providers → Connected agent, then choose one for each conversation. Start a fresh conversation at the context limit; compaction changes the local agent’s saved transcript.</p>
  </>
}

// Shared by provider, defaults and conversation settings. Only Custom edits
// the transport address; built-ins choose credentials and derive the route.
export default function ProviderRoute({ provider, value, onChange }) {
  if (provider === 'connected') return <RunnerSelect value={value} onChange={onChange} />
  if (provider === 'custom') return <label><span>Endpoint</span><input type="url" required value={value.url || ''} onChange={(event) => onChange({ ...value, url: event.target.value })} placeholder="https://inference.example/v1/chat/completions" /></label>
  if (!['openai', 'anthropic', 'xai'].includes(provider)) return null
  const methods = provider === 'openai' ? ['device', 'api-key'] : ['api-key', 'device']
  return <Select label="Authentication" value={authMethod(provider, value)} onValueChange={(nextValue) => onChange(withAuth(value, provider, nextValue))}>
    {methods.map(method => <Select.Option key={method} value={method}>{method === 'api-key' ? 'API key' : provider === 'openai' ? 'Device login (ChatGPT)' : provider === 'xai' ? 'Device login (Grok)' : 'Browser login (Claude)'}</Select.Option>)}
  </Select>
}
