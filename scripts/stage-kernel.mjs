// Gall and thread support share the kernel's userspace API.
import { execFileSync } from 'node:child_process'
import { mkdir, writeFile } from 'node:fs/promises'
import path from 'node:path'

const revision = 'ea4ce447f830e4cb580b725b7850d7b412b6424d'
const checkout = 'desk-deps/urbit'
const output = process.argv[2]
if (!output) throw new Error('Expected assembled desk directory')
const git = (...args) => execFileSync('git', ['-C', checkout, ...args], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] })
await mkdir(checkout, { recursive: true })
git('init', '--quiet')
try { git('cat-file', '-e', `${revision}^{commit}`) } catch {
  git('fetch', '--depth', '1', 'https://github.com/urbit/urbit', revision)
}
function readSource(file) {
  const source = git('show', `${revision}:${file}`)
  if (git('ls-tree', revision, '--', file).startsWith('120000 ')) {
    return readSource(path.posix.normalize(path.posix.join(path.posix.dirname(file), source.trim())))
  }
  return source
}
for (const file of [
  'lib/default-agent.hoon', 'lib/dbug.hoon', 'lib/skeleton.hoon',
  'lib/verb.hoon', 'sur/verb.hoon', 'lib/strand.hoon',
  'lib/strandio.hoon', 'sur/spider.hoon', 'mar/seal.hoon',
]) {
  const source = readSource(`pkg/arvo/${file}`)
  const target = path.join(output, file)
  await mkdir(path.dirname(target), { recursive: true })
  await writeFile(target, source)
}
execFileSync('patch', ['--batch', '--fuzz=0', '-p1', '-d', output, '-i', path.resolve('scripts/patches/grubbery-gall.patch')], { stdio: 'inherit' })
console.log(`Gall support: ${revision.slice(0, 12)}`)
