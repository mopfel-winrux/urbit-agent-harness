// Build-time source imports. Pin the protocol vocabulary independently of the
// installed Groups desk; public versioned marks remain the runtime boundary.
import { execFileSync } from 'node:child_process'
import { mkdir, writeFile } from 'node:fs/promises'
import path from 'node:path'

const revision = '666d17bb6ebd1ec3aac194db386afe81310d12d0'
const checkout = 'desk-deps/tlon'
const output = process.argv[2]
if (!output) throw new Error('Expected assembled desk directory')
const git = (...args) => execFileSync('git', ['-C', checkout, ...args], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] })
await mkdir(checkout, { recursive: true })
// Always initialize here: rev-parse would otherwise discover the parent repo.
git('init', '--quiet')
try { git('cat-file', '-e', `${revision}^{commit}`) } catch {
  git('fetch', '--depth', '1', 'https://github.com/tloncorp/tlon-apps', revision)
}
const visited = new Set()
async function stage(kind, name) {
  const key = `${kind}/${name}`
  if (visited.has(key)) return
  visited.add(key)
  const source = git('show', `${revision}:desk/${key}.hoon`)
  const lines = []
  for (const line of source.split('\n')) {
    if (!/^\/[+-]  /.test(line)) { lines.push(line); continue }
    const depKind = line.startsWith('/-') ? 'sur' : 'lib'
    const imports = []
    for (const token of line.slice(4).split(/[, ]+/).filter(Boolean)) {
      const [alias, dep] = token.includes('=') ? token.split('=') : [token, token.replace(/^\*/, '')]
      await stage(depKind, dep)
      imports.push(alias.startsWith('*') ? `*tlon-${dep}` : `${alias}=tlon-${dep}`)
    }
    lines.push(`${line.slice(0, 4)}${imports.join(', ')}`)
  }
  const target = path.join(output, kind, `tlon-${name}.hoon`)
  await mkdir(path.dirname(target), { recursive: true })
  await writeFile(target, lines.join('\n'))
}
for (const name of ['activity-ver', 'chat-ver', 'channels', 'contacts', 'story', 'groups']) await stage('sur', name)
console.log(`Tlon: ${visited.size} namespaced protocol dependencies at ${revision.slice(0, 12)}`)
