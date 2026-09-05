// Architectural checks complement behavior tests: keep dependency direction
// legible as capabilities are added. File size is a guideline, not a test.
import assert from 'node:assert/strict'
import test from 'node:test'
import { readFile, readdir } from 'node:fs/promises'

const directory = new URL('../desk/lib/', import.meta.url)
const sources = new Map(await Promise.all((await readdir(directory))
  .filter((name) => /^harness(?:-.*)?\.hoon$/.test(name))
  .map(async (name) => [name.slice(0, -5), await readFile(new URL(name, directory), 'utf8')])))
const code = (name) => sources.get(name).split('\n').filter((line) => !line.trimStart().startsWith('::')).join('\n')
const dependencies = (name) => [...code(name).matchAll(/^\/\+\s+(.+)$/gm)]
  .flatMap((match) => match[1].split(',').map((entry) => entry.trim().split('=').at(-1).replace(/^\*/, '')))

test('semantic head depends on nouns, not providers or transports', () => {
  assert.deepEqual(dependencies('harness'), [])
  assert.doesNotMatch(code('harness'), /\bjson\b|\.\^\(|%pass|bowl:gall/)
})

test('client settlement consumes the core outcome instead of defining completion', async () => {
  const agent = await readFile(new URL('../desk/app/harness.hoon', import.meta.url), 'utf8')
  for (const name of ['settle-acp', 'settle-hands', 'settle-sub', 'settle-asks']) {
    const arm = agent.split(`++  ${name}\n`)[1]?.split('\n++  ')[0]
    assert.ok(arm, `Missing settlement boundary: ${name}`)
    assert.match(arm, /outcome:hl/)
    assert.doesNotMatch(arm, /rear items|pending\.v|wait\.v|\[\[%cancelled/)
  }
})

test('concrete bindings cannot import the session store or become an orchestrator', () => {
  for (const name of ['harness-effects', 'harness-acp']) {
    assert.doesNotMatch(code(name), /harness-store|state-\d|sessions=\(map/)
    assert.ok(!dependencies(name).includes('harness-session'))
  }
})

test('Harness libraries have no dependency cycles', () => {
  const done = new Set()
  function visit(name, path = []) {
    assert.ok(!path.includes(name), `Dependency cycle: ${[...path, name].join(' -> ')}`)
    if (done.has(name) || !sources.has(name)) return
    for (const next of dependencies(name)) visit(next, [...path, name])
    done.add(name)
  }
  for (const name of sources.keys()) visit(name)
})

test('Tlon is a replaceable hand, not an inference engine', async () => {
  for (const name of ['harness', 'harness-session', 'harness-hand']) {
    assert.doesNotMatch(code(name), /tlon|groups|contacts/)
  }
  for (const name of ['harness-tlon-policy', 'harness-tlon-story']) {
    assert.doesNotMatch(code(name), /\.\^\(|%pass|bowl:gall/)
  }
  const adapter = await readFile(new URL('../desk/app/harness-tlon.hoon', import.meta.url), 'utf8')
  assert.doesNotMatch(adapter, /%connect\b|%request.*%iris|harness-provider|harness-store/)
  assert.match(adapter, /%harness-hand/)
})
