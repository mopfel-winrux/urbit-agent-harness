import assert from 'node:assert/strict'
import { readFile, readdir } from 'node:fs/promises'
import test from 'node:test'

test('frontend choices do not invoke native select or datalist popups', async () => {
  const directory = new URL('./', import.meta.url)
  for (const path of await readdir(directory, { recursive: true })) {
    if (!path.endsWith('.jsx')) continue
    const source = await readFile(new URL(path, directory), 'utf8')
    assert.doesNotMatch(source, /<(?:select|datalist|option)\b|\bshowPicker\s*\(/, path)
    assert.doesNotMatch(source, /<input\b[^>]*\blist\s*=/, path)
  }
})
