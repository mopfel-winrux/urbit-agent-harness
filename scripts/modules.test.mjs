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

test('default native tests do not construct full Gall agents', async () => {
  const tests = new URL('../desk/tests/', import.meta.url)
  for (const name of await readdir(tests)) {
    if (!name.endsWith('.hoon')) continue
    assert.doesNotMatch(name, /benchmark/, 'large corpus benchmarks must be opt-in')
    const source = await readFile(new URL(name, tests), 'utf8')
    assert.doesNotMatch(source, /^\/=\s+.*\/app\//m,
      `${name}: full-agent fixtures belong in tests-integration, outside the default 2 GB loom suite`)
  }
})

test('semantic head depends on nouns, not providers or transports', () => {
  for (const name of ['harness', 'harness-context', 'harness-memory', 'harness-lcm']) {
    assert.deepEqual(dependencies(name), name === 'harness' ? ['harness-lcm'] : [])
    assert.doesNotMatch(code(name), /\bjson\b|\.\^\(|%pass|bowl:gall/)
  }
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

test('run inspection stays local and the adapter has no Steward export or trust effects', async () => {
  assert.equal(sources.has('harness-run-report'), false, 'no orphaned export-only projection')
  const adapter = await readFile(new URL('../desk/app/harness-tlon.hoon', import.meta.url), 'utf8')
  assert.doesNotMatch(adapter, /sync-lenses|harness-tlon-lens|%steward|trust-policy|pointer:lens/)
  assert.doesNotMatch(code('harness-tlon-io'), /steward|trust-policy/)
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

test('history pagination is bounded, read-only and follows current lane authority', async () => {
  const reader = code('harness-tlon-history-read')
  assert.doesNotMatch(reader, /%poke|%pass|%watch|harness-store/)
  assert.match(reader, /\(lte count 65\)/)
  assert.match(reader, /\/older\/\(scot %ud u.before\)/)
  assert.doesNotMatch(code('harness-tlon-history-page'), /\.\^\(|%pass|bowl:gall/)
  const adapter = await readFile(new URL('../desk/app/harness-tlon.hoon', import.meta.url), 'utf8')
  const tool = adapter.split('++  tool\n')[1].split('\n++  ')[0]
  assert.ok(tool.indexOf('(tool-authority req)') < tool.indexOf("=('tlon_history_page'"))
  assert.match(tool, /sham \[sid.req epoch.u.lane actor.u.lane to.u.lane name.call.req needle\]/)
  assert.match(tool, /load:~\(\. history-read bowl\) to.u.lane before/)
})

test('Tlon addressing cannot become a second memory or command authority', () => {
  assert.doesNotMatch(code('harness-tlon-input'), /%memory-set|%command-completed|harness-provider|harness-memory|harness-command|%pass|\.\^\(/)
  assert.match(code('harness-tlon-policy'), /text:input our content.event/)
  assert.doesNotMatch(code('harness-memory'), /\.\^\(|%pass|bowl:gall|harness-store|session-id/)
})

test('Tlon messages are driven by head facts and receipts, never maintenance wakes', async () => {
  const adapter = await readFile(new URL('../desk/app/harness-tlon.hoon', import.meta.url), 'utf8')
  const arm = (name) => adapter.split(`++  ${name}\n`)[1]?.split('\n++  ')[0]
  assert.match(arm('on-arvo'), /maintain:cor/)
  assert.doesNotMatch(arm('maintain'), /reconcile|%claim|publish/)
  assert.match(arm('agent'), /\[%head ~\][\s\S]*%fact[\s\S]*reconcile/)
  assert.match(arm('agent'), /%receipt phase\)[\s\S]*attempt\.u\.delivery[\s\S]*reconcile\(deliveries/)
  assert.doesNotMatch(code('harness-tlon-clock'), /deliveries|observations|outbox|jobs/)
  assert.match(arm('watch-head'), /%watch \/hand-events/)
  assert.match(arm('claimed'), /%claim stage\.u\.delivery/)
  assert.match(arm('claimed'), /attempt:\(get-control:hd db id\)/)
})
