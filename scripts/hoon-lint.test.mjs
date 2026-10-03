import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { copyFileSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import test from 'node:test'

const hook = new URL('../.githooks/pre-commit', import.meta.url).pathname

test('Hoon hook checks staged blobs and preserves partial staging', (t) => {
  const directory = mkdtempSync(join(tmpdir(), 'harness-hoon-hook-'))
  t.after(() => rmSync(directory, { recursive: true, force: true }))
  const run = (command, args) => spawnSync(command, args, { cwd: directory, encoding: 'utf8' })
  const git = (...args) => {
    const result = run('git', args)
    assert.equal(result.status, 0, result.stderr)
    return result.stdout
  }
  git('init', '--quiet')
  copyFileSync(new URL('../.hoon-lint.json', import.meta.url), join(directory, '.hoon-lint.json'))
  const source = join(directory, 'example with spaces.hoon')
  const canonical = '|=  a=@ud\n(add a 1)\n'
  const unformatted = '|=    a=@ud\n(add a 1)\n'
  const check = () => run('sh', [hook])

  // An unstaged Hoon file is outside the commit.
  writeFileSync(source, unformatted)
  assert.equal(check().status, 0)
  writeFileSync(source, canonical)
  git('add', '--', source)
  writeFileSync(source, unformatted)
  const staged = git('ls-files', '--stage')
  const passed = check()
  assert.equal(passed.status, 0, passed.stdout + passed.stderr)
  assert.equal(git('ls-files', '--stage'), staged)
  assert.equal(readFileSync(source, 'utf8'), unformatted)

  // A formatted working copy cannot hide an unformatted staged blob.
  git('add', '--', source)
  writeFileSync(source, canonical)
  const rejectedIndex = git('ls-files', '--stage')
  const rejected = check()
  assert.equal(rejected.status, 1, rejected.stdout + rejected.stderr)
  assert.match(rejected.stdout + rejected.stderr, /H100/)
  assert.equal(git('ls-files', '--stage'), rejectedIndex)
  assert.equal(readFileSync(source, 'utf8'), canonical)
})
