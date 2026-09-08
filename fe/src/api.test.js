import assert from 'node:assert/strict'
import test from 'node:test'

import { api, resourcesFor, scryUrl } from './api.js'
import { acp } from './acp.js'
import { DEFAULT_SYSTEM_PROMPT, defaultConfig } from './defaults.js'

test('native Harness scries encode the typed Gall namespace', () => {
  assert.equal(scryUrl('session/research-notes'), '/~/scry/harness/session/research-notes.json')
  assert.equal(scryUrl('sessions'), '/~/scry/harness/sessions.json')
})

test('settings resource keys address the shared Harness session surface', () => {
  assert.deepEqual(resourcesFor('notes'), {
    chat: 'notes',
    session: 'session/notes',
    tools: 'tools',
    defaults: 'defaults',
    mcp: 'mcp',
  })
})

test('new conversations default to an OpenAI-compatible endpoint', () => {
  const config = defaultConfig()
  assert.match(config.url, /openrouter\.ai/)
  assert.equal(config.model, 'z-ai/glm-5.3-flash')
  assert.equal(config['max-context'], 1_310_720)
  assert.deepEqual(config.tools, [{ clay: '/' }, 'web', 'curl', 'skills', 'skill-write', 'author', 'subagents', 'peers', 'corpus'])
  assert.deepEqual(config.headers, [])
})

test('the default context presents Harness as a durable, bounded agent', () => {
  const config = defaultConfig()
  assert.equal(config.system, DEFAULT_SYSTEM_PROMPT)
  assert.match(config.system, /transcript as working memory/)
  assert.match(config.system, /no ambient shell, filesystem, network, or authority/)
  assert.match(config.system, /When a task matches a skill catalog entry, read the skill/)
  assert.match(config.system, /list_mcp_tools before call_mcp_tool/)
  assert.match(config.system, /never retry blindly/)
  assert.match(config.system, /survive compaction verbatim/)
  assert.match(config.system, /Do not use shared skills to store private conversation facts/)
  assert.match(config.system, /changing them is a separate, explicitly authorized task/)
  assert.doesNotMatch(config.system, /Prefer the staged/)
})

test('bootstrap grants are fresh per conversation and preserve explicit overrides', () => {
  const first = defaultConfig()
  first.tools.push('future-tool')
  first.tools[0].clay = '/narrow'
  assert.deepEqual(defaultConfig().tools, [{ clay: '/' }, 'web', 'curl', 'skills', 'skill-write', 'author', 'subagents', 'peers', 'corpus'])
  assert.deepEqual(defaultConfig({ tools: ['clay', 'mcp'] }).tools, ['clay', 'mcp'])
  assert.ok(!defaultConfig().tools.includes('code'))
  assert.deepEqual(defaultConfig({ tools: ['code'] }).tools, ['code'])
})

test('skill settings use acknowledged owner ACP operations with literal names and revisions', async () => {
  const start = acp.start, call = acp.call, seen = []
  acp.start = async () => {}
  acp.call = async (...args) => { seen.push(args); return { acknowledged: true } }
  try {
    await api.read('skills')
    await api.read('skill/report / 雪')
    const skill = { name: 'report / 雪', desc: 'When relevant', body: 'Keep\ntext', revision: '0v1' }
    assert.deepEqual(await api.action({ saveSkill: skill }), { acknowledged: true })
    await api.action({ deleteSkill: { name: skill.name, revision: skill.revision } })
    assert.deepEqual(seen, [['harness/skills'], ['harness/skill', { name: skill.name }],
      ['harness/skill/save', skill], ['harness/skill/delete', { name: skill.name, revision: skill.revision }]])
  } finally { acp.start = start; acp.call = call }
})

test('corpus and optional summary settings share the owner ACP facade', async () => {
  const start = acp.start, call = acp.call, seen = []
  acp.start = async () => {}
  acp.call = async (...args) => { seen.push(args); return { acknowledged: true } }
  try {
    const models = { compaction: null, lcm: null }
    await api.read('summary-models')
    await api.action({ summaryModels: models })
    await api.read('corpus/status')
    await api.corpus('search', { query: '雪 evidence', limit: 20, cursor: 'opaque' })
    await api.corpus('read', { scope: '0v1', eventCount: 17, offset: 12000 })
    await api.corpus('expand', { scope: '0v1', eventCount: 19 })
    await assert.rejects(api.corpus('delete'), /Unsupported/)
    assert.deepEqual(seen, [
      ['harness/summary-models'], ['harness/summary-models/configure', { models }], ['harness/corpus/status'],
      ['harness/corpus/search', { query: '雪 evidence', limit: 20, cursor: 'opaque' }],
      ['harness/corpus/read', { scope: '0v1', eventCount: 17, offset: 12000 }],
      ['harness/corpus/expand', { scope: '0v1', eventCount: 19 }],
    ])
  } finally { acp.start = start; acp.call = call }
})

test('peer settings use the acknowledged owner ACP facade with revision fencing', async () => {
  const start = acp.start, call = acp.call, seen = []
  acp.start = async () => {}
  acp.call = async (...args) => { seen.push(args); return { revision: 'new', grants: [], trusted: [], config: null } }
  try {
    const policy = { revision: 'old', grants: [], config: null }
    await api.read('peers')
    assert.equal((await api.action({ peers: policy })).revision, 'new')
    assert.deepEqual(seen, [['harness/peers'], ['harness/peers/configure', policy]])
  } finally { acp.start = start; acp.call = call }
})
