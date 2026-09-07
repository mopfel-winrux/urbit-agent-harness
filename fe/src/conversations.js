export const CONVERSATION_PAGE_SIZE = 20

export function sortConversations(sessions) {
  return [...sessions].sort((a, b) => (b.modifiedAt || 0) - (a.modifiedAt || 0)
    || a.sessionId.localeCompare(b.sessionId)).map((session) => session.sessionId)
}

export function conversationPage(chats, search, limit = CONVERSATION_PAGE_SIZE) {
  const needle = search.trim().toLocaleLowerCase()
  const matches = needle ? chats.filter((chat) => chat.toLocaleLowerCase().includes(needle)) : chats
  return { visible: matches.slice(0, limit), remaining: Math.max(0, matches.length - limit), total: matches.length }
}
