import { api, paths, waitFor } from './api'
import { useGrub } from './useGrub'

const MAIN_CHATS = ['main']

export function useConversations(ball, agent, current, onSelect) {
  const roads = paths(ball, agent, current)
  const state = useGrub(paths(ball, agent, 'main').chats, MAIN_CHATS)
  const chats = Array.isArray(state.value) && state.value.length ? state.value : MAIN_CHATS

  async function manifest(accepts) {
    const value = await waitFor(
      () => api.read(roads.chats),
      (names) => Array.isArray(names) && accepts(names),
    )
    state.setValue(value)
    return value
  }

  async function create(name) {
    if (chats.includes(name)) throw new Error('A conversation with that name already exists.')
    await api.poke(roads.agentMain, { action: 'create-chat', name })
    await manifest((names) => names.includes(name))
    onSelect(name)
  }

  async function remove(name) {
    if (name === 'main') throw new Error('The main conversation is protected.')
    await api.poke(roads.agentMain, { action: 'delete-chat', name })
    await manifest((names) => !names.includes(name))
    if (name === current) onSelect(chats.find((item) => item !== name) || 'main')
  }

  async function rename(from, name) {
    if (!from || from === 'main' || from === name) return
    if (chats.includes(name)) throw new Error('A conversation with that name already exists.')

    const source = paths(ball, agent, from)
    const target = paths(ball, agent, name)
    const [status, transcript] = await Promise.all([
      api.read(source.status),
      api.read(source.transcript),
    ])
    if (status?.state !== 'idle') throw new Error('Interrupt this conversation before renaming it.')
    if (!Array.isArray(transcript)) throw new Error('Could not read this conversation.')

    await api.poke(roads.agentMain, { action: 'create-chat', name })
    await manifest((names) => names.includes(name))
    await api.over(target.transcript, transcript)
    await waitFor(
      () => api.read(target.transcript),
      (value) => JSON.stringify(value) === JSON.stringify(transcript),
    )
    await api.poke(roads.agentMain, { action: 'delete-chat', name: from })
    await manifest((names) => !names.includes(from))
    if (current === from) onSelect(name)
  }

  return { chats, error: state.error, roads, create, remove, rename }
}
