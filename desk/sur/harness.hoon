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
::  Payloads may remain inline today, but every boundary can name durable
::  content without depending on a transport or storage implementation.
::
+$  payload-ref  [hash=@ux bytes=@ud media=@t]
+$  effect-id
  $%  [%inference req=@ud]
      [%tool call-id=@t]
      [%peer ask=@uv]
  ==
+$  effect-target
  $%  [%provider name=@t model=@t]
      [%capability family=term name=@t]
      [%ship =ship]
  ==
+$  effect-intent
  $:  id=effect-id
      target=effect-target
      payload=(unit payload-ref)
  ==
+$  effect-result
  $%  [%ok payload=(unit payload-ref)]
      [%error message=@t retryable=?]
      [%abandoned reason=@t]
  ==
+$  effect-receipt  [id=effect-id result=effect-result]
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
      key=@t              ::  ingress-only; blanked before the config event
      headers=(list [name=@t value=@t])
      system=@t
      max-context=@ud     ::  rough token budget before compaction
      tools=(list term)   ::  granted tool families
  ==
::  Remote, stateless Streamable HTTP MCP server. Headers are held in
::  agent state and copied only onto requests to this exact endpoint.
::
+$  mcp-server-id  @t
+$  mcp-server
  $:  name=@t
      url=@t
      headers=(list [name=@t value=@t])
      enabled=?
  ==
::  a self-scheduled wakeup: when it fires, prompt enters the session
::
+$  timer  [at=@da every=(unit @dr) prompt=@t]
::  a skill: agent-level knowledge, stored in state (not the desk).
::  the catalog (names + descs) is injected into context when the
::  %skills family is granted; bodies are read on demand
::
+$  skill  [desc=@t body=@t]
::  agent-to-agent over ames: peer-as-tool. identity-based grants;
::  asks land in a durable sandboxed session per peer. the answer
::  crosses the wire; the data doesn't
::
+$  ask-id  @uv
+$  peer-grant
  $:  tools=(list term)     ::  ~ for strangers
      model=(unit @t)       ::  override; cheap model for low-trust
      budget=@ud            ::  lifetime token cap for their session; 0 = no cap
      inflows=(set @t)      ::  skill names their session may see
  ==
::  the wire protocol: mark %harness-a2a-0, typed and growable
::
+$  a2a
  $%  [%ask id=ask-id kind=%text prompt=@t]
      [%answer id=ask-id result=(each @t @t)]
  ==
::  Every admitted input says where it came from and where a response belongs.
::  %input-admitted remains readable so existing session logs still replay.
::
+$  input-id  @uv
+$  input-source
  $%  [%acp client=@t]
      [%poke =ship]
      [%timer name=@ta]
      [%webhook path=@t]
      [%peer =ship ask=ask-id]
      [%subagent parent=session-id call-id=@t]
      [%rehearsal parent=session-id call-id=@t skill=@t]
      [%hand binding=@t hand=@t address=@t event=@t actor=@t]
  ==
+$  reply-target
  $%  [%acp client=@t]
      [%http id=@ta]
      [%peer =ship ask=ask-id]
      [%session sid=session-id call-id=@t]
      [%hand binding=@t]
  ==
+$  admitted-input
  $:  id=input-id
      source=input-source
      actor=(unit @p)
      reply=(unit reply-target)
      at=@da
      =item
  ==
::  the closed event vocabulary
::
+$  event
  $%  [%config-replaced =config]
      [%input-admitted =item]
      [%input-received input=admitted-input]
      [%llm-requested req=@ud kind=request-kind]
      [%llm-completed req=@ud stop=stop-reason =usage =item]
      [%llm-failed req=@ud err=@t]
      [%tool-requested call-id=@t name=@t]
      [%tool-completed call-id=@t name=@t body=@t]
      [%compaction-completed req=@ud summary=@t]
      [%cancelled req=(unit @ud) calls=(set @t) reason=@t]
      [%forked from=session-id at=@ud req=(unit @ud) calls=(set @t)]
      [%retried ~]
      [%halted reason=@t]
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
      cancelled=(unit @t)             ::  stopped until new input or retry
      origin=(unit [from=session-id at=@ud])
  ==
::  the decider's output
::
+$  step
  $%  [%turn ~]
      [%compact ~]
      [%tools calls=(list tool-call)]
      [%halt reason=@t]
  ==
::  pokes
::
+$  action
  $%  [%new sid=session-id =config]
      [%send sid=session-id text=@t]
      [%fork from=session-id to=session-id]
      [%fork-at from=session-id to=session-id at=@ud]
      [%compact sid=session-id]
      [%cancel sid=session-id]
      [%delete sid=session-id]
      [%retry sid=session-id]
      [%config sid=session-id =config]
      [%timer-set sid=session-id name=@ta in=@dr every=(unit @dr) prompt=@t]
      [%timer-cancel sid=session-id name=@ta]
      [%skill-add name=@t desc=@t body=@t]
      [%skill-del name=@t]
      [%set-key key=@t]
      ::  governance: a human can promote or drop a proposed skill
      ::
      [%commit-skill name=@t]
      [%discard-skill name=@t]
      [%grant =ship grant=peer-grant]
      [%revoke =ship]
      [%peer-config =config]
      [%defaults =config]
      [%mcp-config servers=(list [id=mcp-server-id server=mcp-server])]
      ::  internal: session spawning, sent by the agent to itself
      ::
      [%spawn parent=session-id call-id=@t prompt=@t system=(unit @t)]
      ::  internal: an ask_peer tool call, sent by the agent to itself
      ::
      [%ask-peer sid=session-id call-id=@t =ship prompt=@t]
      ::  internal: a run_js tool call, sent by the agent to itself
      ::
      [%run-js sid=session-id call-id=@t code=@t]
      ::  internal: a rehearse_skill tool call — spawn a rehearsal child
      ::  session that sees the staged skill, to test it before committing
      ::
      [%rehearse sid=session-id call-id=@t name=@t input=@t]
  ==
::  facts
::
+$  update
  $%  [%event sid=session-id =event]
  ==
--
