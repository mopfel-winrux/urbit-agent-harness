import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { api, resourcesFor } from '../src/api'
import { defaultConfig } from '../src/defaults'
import GlobalSettings from '../src/components/GlobalSettings'
import '../src/style.css'

const pending = new Map()
window.settingsFixture = { requests: [], saves: [], resolve: (id, value) => pending.get(id)(value) }
api.read = async (path) => path === 'defaults' ? defaultConfig() : []
api.models = (provider) => new Promise((resolve) => {
  const id = window.settingsFixture.requests.length
  pending.set(id, resolve)
  window.settingsFixture.requests.push({ id, provider })
})
api.action = async ({ defaults }) => {
  window.settingsFixture.saves.push(defaults)
  return defaults
}
createRoot(document.getElementById('root')).render(<StrictMode><GlobalSettings resources={resourcesFor('')} theme="system" onThemeChange={() => {}} /></StrictMode>)
