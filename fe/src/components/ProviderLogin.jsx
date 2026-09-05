import { useEffect, useRef, useState } from 'react'

const OPENAI_CLIENT_ID = 'app_EMoamEEZ73f0CkXaXp7hrann'
const OPENAI_AUTH = 'https://auth.openai.com'

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

async function jsonRequest(url, options) {
  const response = await fetch(url, options)
  if (!response.ok) {
    const message = await response.text()
    const error = new Error(message || `Authentication returned HTTP ${response.status}`)
    error.status = response.status
    throw error
  }
  return response.json()
}

function jwtPayload(token) {
  try {
    const body = token.split('.')[1].replaceAll('-', '+').replaceAll('_', '/')
    return JSON.parse(atob(body.padEnd(Math.ceil(body.length / 4) * 4, '=')))
  } catch { return {} }
}

export function OpenAIDeviceLogin({ onCredential }) {
  const [flow, setFlow] = useState(null)
  const [state, setState] = useState('idle')
  const [error, setError] = useState('')
  const live = useRef(true)

  useEffect(() => { live.current = true; return () => { live.current = false } }, [])

  async function start() {
    const loginWindow = window.open('about:blank', '_blank')
    if (loginWindow) loginWindow.opener = null
    setState('starting'); setError('')
    try {
      const device = await jsonRequest(`${OPENAI_AUTH}/api/accounts/deviceauth/usercode`, {
        method: 'POST', headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ client_id: OPENAI_CLIENT_ID }),
      })
      const next = { ...device, verificationUrl: `${OPENAI_AUTH}/codex/device` }
      if (!live.current) return
      setFlow(next); setState('waiting')
      if (loginWindow) loginWindow.location = next.verificationUrl
      void complete(next)
    } catch (cause) {
      loginWindow?.close(); setError(cause.message); setState('idle')
    }
  }

  async function complete(device) {
    const deadline = Date.now() + 15 * 60_000
    while (live.current && Date.now() < deadline) {
      await wait(Math.max(2, Number(device.interval) || 5) * 1000)
      try {
        const code = await jsonRequest(`${OPENAI_AUTH}/api/accounts/deviceauth/token`, {
          method: 'POST', headers: { 'content-type': 'application/json' },
          body: JSON.stringify({ device_auth_id: device.device_auth_id, user_code: device.user_code }),
        })
        const tokens = await jsonRequest(`${OPENAI_AUTH}/oauth/token`, {
          method: 'POST', headers: { 'content-type': 'application/x-www-form-urlencoded' },
          body: new URLSearchParams({
            grant_type: 'authorization_code', code: code.authorization_code,
            redirect_uri: `${OPENAI_AUTH}/deviceauth/callback`, client_id: OPENAI_CLIENT_ID,
            code_verifier: code.code_verifier,
          }),
        })
        const claims = jwtPayload(tokens.id_token || tokens.access_token)
        const account = claims['https://api.openai.com/auth']?.chatgpt_account_id || claims.chatgpt_account_id || ''
        if (!live.current) return
        await onCredential({ token: tokens.access_token, refreshToken: tokens.refresh_token || '', account })
        if (live.current) setState('connected')
        return
      } catch (cause) {
        if (cause.status === 403 || cause.status === 404) continue
        if (live.current) { setError(cause.message); setState('idle') }
        return
      }
    }
    if (live.current) { setError('The device code expired. Start a new login.'); setState('idle') }
  }

  return <div className="login-panel">
    <div><strong>ChatGPT device login</strong><p>Use a ChatGPT plan through the Codex Responses endpoint. The one-time code expires after 15 minutes.</p></div>
    {flow && state === 'waiting' && <div className="device-code"><span>Enter this code</span><strong>{flow.user_code}</strong><a href={flow.verificationUrl} target="_blank" rel="noreferrer">Open sign-in page</a></div>}
    {state === 'connected' ? <span className="status good">connected</span> : <button type="button" className="button ghost" disabled={state !== 'idle'} onClick={start}>{state === 'starting' ? 'Starting…' : state === 'waiting' ? 'Waiting for sign-in…' : 'Sign in with device code'}</button>}
    {error && <div className="inline-error">{error}</div>}
  </div>
}

export function AnthropicDeviceLogin({ onCredential }) {
  const [credential, setCredential] = useState('')
  const [state, setState] = useState('idle')
  const [error, setError] = useState('')

  async function connect() {
    setState('saving'); setError('')
    try {
      let parsed = {}
      try { parsed = JSON.parse(credential) } catch { parsed = { access_token: credential.trim() } }
      const token = parsed.access_token || parsed['auth-token'] || parsed.oauth_token || parsed.token || ''
      if (!token) throw new Error('Paste the credential JSON or setup token first.')
      await onCredential({ token, refreshToken: parsed.refresh_token || parsed['refresh-token'] || '' })
      setCredential(''); setState('connected')
    } catch (cause) { setError(cause.message); setState('idle') }
  }

  return <div className="login-panel">
    <div><strong>Claude browser login</strong><p>Run <code>claude setup-token</code> and complete the browser prompt, then paste the setup token below. Credential JSON from <code>ant auth print-credentials</code> is also accepted.</p></div>
    <textarea rows="3" value={credential} onChange={(event) => setCredential(event.target.value)} placeholder="Credential JSON or setup token" />
    <button type="button" className="button ghost" disabled={state === 'saving' || !credential.trim()} onClick={connect}>{state === 'saving' ? 'Connecting…' : state === 'connected' ? 'Connected' : 'Connect browser login'}</button>
    {error && <div className="inline-error">{error}</div>}
  </div>
}
