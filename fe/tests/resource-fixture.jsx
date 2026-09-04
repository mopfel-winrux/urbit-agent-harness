// Real hook, controlled ACP reads. Served by Vite only, not built into the app.
import { StrictMode, useState } from 'react'
import { createRoot } from 'react-dom/client'
import { api } from '../src/api'
import { useResource } from '../src/useResource'

const pending = new Map()
window.resourceFixture = { reads: [], resolve: (id, value) => pending.get(id)(value) }
api.read = (path) => new Promise((resolve) => {
  const id = window.resourceFixture.reads.length
  pending.set(id, resolve)
  window.resourceFixture.reads.push({ id, path })
})

function Fixture() {
  const [path, setPath] = useState('a')
  const resource = useResource(path, 'loading')
  Object.assign(window.resourceFixture, { select: setPath, save: resource.setValue, refresh: resource.refresh })
  return <><output aria-label="Resource">{path}</output><output aria-label="Value">{resource.value}</output></>
}
createRoot(document.getElementById('root')).render(<StrictMode><Fixture /></StrictMode>)
