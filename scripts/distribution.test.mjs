// Test the assembled artifact, not the development mount: leftover files can
// hide missing dependencies. Run `zig build` before this suite.
import assert from 'node:assert/strict'
import { createHash } from 'node:crypto'
import test from 'node:test'
import { access, readFile, readdir } from 'node:fs/promises'

const desk = new URL('../zig-out/', import.meta.url)
test('the optional JS executor bundles the expected QuickJS binary', async () => {
  const wasm = await readFile(new URL('quick-js-emcc.wasm', desk))
  assert.equal(createHash('sha256').update(wasm).digest('hex'), 'aa83708e03d77e610a576da47eb77ea4b3e0483c88bf9367ed66dc66810f8423')
  for (const name of ['lib/thread-builder-js.hoon', 'lib/wasm/lia.hoon', 'lib/wasm/parser.hoon', 'lib/wasm/runner/engine.hoon', 'sur/wasm/lia.hoon', 'sur/spider.hoon', 'mar/wasm.hoon']) await access(new URL(name, desk))
})
test('the distribution has no Steward export integration', async () => {
  await assert.rejects(access(new URL('sur/tlon-steward-lens.hoon', desk)))
  await assert.rejects(access(new URL('lib/harness-tlon-lens.hoon', desk)))
  await assert.rejects(access(new URL('lib/harness-run-report.hoon', desk)))
  await assert.rejects(access(new URL('sur/tlon-steward/lens.hoon', desk)))
})
test('the distribution declares only the five Harness agents', async () => {
  const bill = await readFile(new URL('desk.bill', desk), 'utf8')
  const agents = [...bill.matchAll(/%([a-z-]+)/g)].map((m) => m[1]).sort()
  assert.deepEqual(agents, ['acp', 'harness', 'harness-fileserver', 'harness-grub', 'harness-tlon'])
  assert.deepEqual((await readdir(new URL('app/', desk))).filter((p) => p.endsWith('.hoon')).sort(), agents.map((a) => `${a}.hoon`).sort())
})
test('agent Ford file imports exist without development-mount leftovers', async () => {
  for (const file of await readdir(new URL('app/', desk), { recursive: true })) {
    if (!file.endsWith('.hoon')) continue
    const source = await readFile(new URL(`app/${file}`, desk), 'utf8')
    for (const [, path] of source.matchAll(/^\/=\s+\S+\s+\/([^\s]+)\s*$/gm)) {
      assert.ok(!path.startsWith('tests/'), `${file} imports a development test: ${path}`)
      await assert.doesNotReject(access(new URL(`${path}.hoon`, desk)), `${file} imports a missing file: ${path}`)
    }
  }
})
test('the distribution includes its own tests, not the runtime development suite', async () => {
  const shipped = (await readdir(new URL('tests/', desk))).sort()
  const own = (await readdir(new URL('../desk/tests/', import.meta.url))).sort()
  assert.deepEqual(shipped, own)
})
test('dynamic marks cover compiler bootstrap and the native noun exchange', async () => {
  assert.deepEqual((await readdir(new URL('gub/mar/', desk))).sort(), ['hoon.hoon', 'kelvin.hoon', 'mime.hoon', 'noun.hoon', 'tang.hoon'])
})
test('runtime startup does not activate desktop-only bridges', async () => {
  const source = await readFile(new URL('app/harness-grub.hoon', desk), 'utf8')
  const startup = source.split('++  cold-start\n')[1].split('\n++  ')[0]
  for (const service of ['dill', 'jael', 'peer', 'push']) assert.ok(!startup.includes(`sync-${service}`), service)
  for (const service of ['gub', 'clay', 'bowl', 'gall', 'lick', 'eyre']) assert.ok(startup.includes(`sync-${service}`), service)
  assert.ok(!source.includes('(ensure-dir /sys/clay/desks/base)'))
  assert.ok(source.includes('(ensure-dir /sys/clay/desks/harness)'))
  assert.ok(!source.includes('%connect [~ /grubbery/push]'))
})
