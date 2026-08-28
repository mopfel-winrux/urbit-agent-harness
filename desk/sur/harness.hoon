::  harness: types for the head of an on-ship agent harness
::
::    the session log is the state: a closed vocabulary of events,
::    replayed into a view, from which a decider plans the next step.
::    provider shape is openai chat-completions (openrouter).
::
|%
+$  session-id  @t
+$  request-kind  ?(%turn %compaction)
+$  stop-reason  ?(%stop %tool-calls %length %error)
+$  tool-call  [id=@t name=@t args=@t]
+$  usage  [prompt=@ud completion=@ud]
::  context items, provider-native shape
::
+$  item
  $%  [%user body=@t]
      [%assistant body=@t calls=(list tool-call)]
      [%tool call-id=@t name=@t body=@t]
  ==
::  config is data; capabilities absent by default (tools=~)
::
+$  config
  $:  url=@t              ::  chat-completions endpoint
      model=@t
      key=@t              ::  NB: enters event log; fakezod-only posture
      system=@t
      max-context=@ud     ::  rough token budget before compaction
      tools=(list term)   ::  granted tool families
  ==
::  a self-scheduled wakeup: when it fires, prompt enters the session
::
+$  timer  [at=@da every=(unit @dr) prompt=@t]
::  a skill: agent-level knowledge, stored in state (not the desk).
::  the catalog (names + descs) is injected into context when the
::  %skills family is granted; bodies are read on demand
::
+$  skill  [desc=@t body=@t]
::  the closed event vocabulary
::
+$  event
  $%  [%config-replaced =config]
      [%input-admitted =item]
      [%llm-requested req=@ud kind=request-kind]
      [%llm-completed req=@ud stop=stop-reason =usage =item]
      [%llm-failed req=@ud err=@t]
      [%tool-requested call-id=@t name=@t]
      [%tool-completed call-id=@t name=@t body=@t]
      [%compaction-completed req=@ud summary=@t]
      [%retried ~]
  ==
::  a session: the log is the state, newest event first
::
+$  session  [log=(list event) next-req=@ud]
::  derived view, a fold over the log
::
+$  view
  $:  =config
      summary=(unit @t)
      items=(list item)
      pending=(unit [req=@ud kind=request-kind])
      wait=(set @t)                    ::  async tool calls in flight
      total=usage
      err=(unit @t)
  ==
::  the decider's output
::
+$  step
  $%  [%turn ~]
      [%compact ~]
      [%tools calls=(list tool-call)]
  ==
::  pokes
::
+$  action
  $%  [%new sid=session-id =config]
      [%send sid=session-id text=@t]
      [%fork from=session-id to=session-id]
      [%compact sid=session-id]
      [%cancel sid=session-id]
      [%retry sid=session-id]
      [%config sid=session-id =config]
      [%timer-set sid=session-id name=@ta in=@dr every=(unit @dr) prompt=@t]
      [%timer-cancel sid=session-id name=@ta]
      [%skill-add name=@t desc=@t body=@t]
      [%skill-del name=@t]
      ::  internal: session spawning, sent by the agent to itself
      ::
      [%spawn parent=session-id call-id=@t prompt=@t system=(unit @t)]
  ==
::  facts
::
+$  update
  $%  [%event sid=session-id =event]
  ==
--
