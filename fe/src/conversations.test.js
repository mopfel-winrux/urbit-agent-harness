import assert from 'node:assert/strict'
import test from 'node:test'
import { conversationPage, sortConversations } from './conversations.js'

test('conversations sort by durable modification time with stable ties and unknown history last', () => {
  const input = [{ sessionId: 'a', modifiedAt: 100 }, { sessionId: 'z', modifiedAt: 300 },
    { sessionId: 'b', modifiedAt: 100 }, { sessionId: 'legacy', modifiedAt: null }]
  assert.deepEqual(sortConversations(input), ['z', 'a', 'b', 'legacy'])
  assert.equal(input[0].sessionId, 'a')
})

test('conversation pages contain twenty results and load more preserves order', () => {
  const chats = Array.from({ length: 47 }, (_, n) => `chat-${n}`)
  assert.deepEqual(conversationPage(chats, ''), { visible: chats.slice(0, 20), remaining: 27, total: 47 })
  assert.equal(conversationPage(chats, '', 40).remaining, 7)
  assert.deepEqual(conversationPage(chats, '', 60).visible, chats)
})

test('search covers unloaded conversations, is case-insensitive and preserves modification order', () => {
  const chats = [...Array.from({ length: 25 }, (_, n) => `noise-${n}`), 'Weekly Notes', 'notes archive']
  assert.deepEqual(conversationPage(chats, ' NOTES ').visible, ['Weekly Notes', 'notes archive'])
  assert.deepEqual(conversationPage(chats, 'missing'), { visible: [], remaining: 0, total: 0 })
})
