::  Gall persistence envelope. Keep its noun layout stable: on-save writes this
::  directly, and harness-store loads each supported version without dropping
::  sessions or credentials. Runtime bookkeeping is not session semantics.
/-  h=harness, hh=harness-hand, ac=acp, oauth=harness-oauth, corpus=harness-corpus, cron=harness-cron, work=harness-workspace
/-  hn=harness-notes
/-  ws=harness-workspace-search
/-  pc=harness-project-client
/-  wc=harness-work-control
/-  hosted=harness-hosted
/-  l=harness-lcm
|%
+$  state-30
  $:  %30
      model-defaults-set=?(%| %&)
      $_  =/  old  *state-29
          +.old(defaults *config:h, peer-base *(unit config:h), sessions *(map session-id:h session:h), summary-models *summary-models:h, corpus *state:corpus)
  ==
::  Frozen config-bearing nouns belong only to persistence migration.
+$  config-0
  $:  url=@t
      model=@t
      key=@t
      headers=(list [name=@t value=@t])
      system=@t
      max-context=@ud
      tools=(list tool-grant:h)
  ==
+$  event-0
  $%  [%config-replaced config=config-0]
      [%input-admitted item=item:h]
      [%input-received input=admitted-input:h]
      [%context-received input-id=input-id:h body=@t]
      [%command-completed input-id=input-id:h name=@t body=@t]
      [%memory-set name=@t body=(unit @t)]
      [%llm-requested req=@ud kind=request-kind:h]
      [%llm-completed req=@ud stop=stop-reason:h usage=usage:h item=item:h]
      [%llm-failed req=@ud err=@t]
      [%tool-requested call-id=@t name=@t]
      [%tool-requested-2 generation=@ud call-id=@t name=@t]
      [%tool-completed call-id=@t name=@t body=@t]
      [%compaction-completed req=@ud summary=@t]
      [%compaction-planned req=@ud plan=compaction-plan:h]
      [%lcm-planned req=@ud plan=lcm-plan:h]
      [%checkpoint-completed req=@ud summary=@t usage=usage:h reply=(unit [input-id=input-id:h body=@t])]
      [%compaction-failed req=@ud err=@t usage=usage:h]
      [%cancelled req=(unit @ud) calls=(set @t) reason=@t]
      [%forked from=session-id:h at=@ud req=(unit @ud) calls=(set @t)]
      [%retried ~]
      [%halted reason=@t]
  ==
+$  session-0  [log=(list event-0) next-req=@ud]
+$  summary-models-0  [compaction=(unit config-0) lcm=(unit config-0)]
+$  view-0
  $:  config=config-0
      summary=(unit @t)
      items=(list item:h)
      pending=(unit [req=@ud kind=request-kind:h])
      wait=(set @t)
      total=usage:h
      err=(unit @t)
      cancelled=(unit @t)
      origin=(unit [from=session-id:h at=@ud])
      compaction=(unit compaction-plan:h)
      compact-usage=usage:h
      compact-attempts=@ud
      memory=(map @t @t)
      revision=@ud
      positions=(list @ud)
      lcm=forest:l
      lcm-plan=(unit lcm-plan:h)
  ==
+$  conversation-0
  $_  =/  old  *conversation:corpus
      old(seen *(list event-0), reverse *(list event-0), forward *(list event-0), incoming *(list event-0), view *view-0)
+$  corpus-0
  $_  =/  old  *state:corpus
      old(scopes *(map scope:corpus conversation-0))
+$  state-29  [%29 xai-auth=state:oauth hosted=state:hosted state-27]
+$  state-28  [%28 hosted=state-0:hosted state-27]
+$  state-27
  $:  %27
      workspace=state:work
      work-controls=state:wc
      project-clients=state:pc
      workspace-search=state:ws
      workspace-notes=state:hn
      legacy-workspace=state-0:work
      state-20
  ==
+$  state-26  [%26 work-controls=state:wc state-24]
+$  state-25  [%25 work-controls=state:wc state-24]
+$  state-24  [%24 project-clients=state:pc state-23]
+$  state-23  [%23 workspace-search=state:ws state-22]
+$  state-22  [%22 workspace-notes=state:hn legacy-workspace=state-0:work state-21]
+$  state-21  [%21 workspace=state-0:work state-20]
+$  state-20
  [%20 schedules=(map @uv schedule:cron) schedule-wake=(unit @da) tlon-cron-imported=? state-19]
+$  stream-progress  [body=@t sent=@ud]
+$  state-0
  $:  %0
      sessions=(map session-id:h session-0)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config-0)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h json)
      acp-through=@ud
  ==
+$  state-1
  $:  %1
      sessions=(map session-id:h session-0)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config-0)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [request-id=json cursor=@ud])
      acp-through=@ud
  ==
+$  state-2
  $:  %2
      sessions=(map session-id:h session-0)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config-0)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])
      acp-through=(map connection-id:v1:ac @ud)
  ==
+$  state-3
  $:  %3
      sessions=(map session-id:h session-0)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config-0)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])
      acp-through=(map connection-id:v1:ac @ud)
      provider-keys=(map @t @t)
      model-requests=(map @ud [connection=connection-id:v1:ac request-id=json])
      next-model-request=@ud
  ==
+$  state-4
  $:  %4
      sessions=(map session-id:h session-0)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config-0)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])
      acp-through=(map connection-id:v1:ac @ud)
      provider-keys=(map @t @t)
      model-requests=(map @ud [connection=connection-id:v1:ac request-id=json])
      next-model-request=@ud
  ==
+$  state-5
  $:  %5
      sessions=(map session-id:h session-0)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config-0)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])
      acp-through=(map connection-id:v1:ac @ud)
      provider-keys=(map @t @t)
      model-requests=(map @ud [connection=connection-id:v1:ac request-id=json])
      next-model-request=@ud
      defaults=config-0
      mcp-servers=(map mcp-server-id:h mcp-server:h)
  ==
+$  state-6
  $:  %6
      sessions=(map session-id:h session-0)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config-0)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])
      acp-through=(map connection-id:v1:ac @ud)
      provider-keys=(map @t @t)
      model-requests=(map @ud [connection=connection-id:v1:ac request-id=json])
      next-model-request=@ud
      defaults=config-0
      mcp-servers=(map mcp-server-id:h mcp-server:h)
      streams=(map [session-id:h @ud] stream-progress)
  ==
+$  state-7
  $:  %7
      sessions=(map session-id:h session-0)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config-0)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])
      acp-through=(map connection-id:v1:ac @ud)
      provider-keys=(map @t @t)
      model-requests=(map @ud [connection=connection-id:v1:ac request-id=json])
      next-model-request=@ud
      defaults=config-0
      mcp-servers=(map mcp-server-id:h mcp-server:h)
      streams=(map [session-id:h @ud] stream-progress)
      hands=state-0:hh
  ==
+$  state-8
  $:  %8
      sessions=(map session-id:h session-0)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config-0)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])
      acp-through=(map connection-id:v1:ac @ud)
      provider-keys=(map @t @t)
      model-requests=(map @ud [connection=connection-id:v1:ac request-id=json])
      next-model-request=@ud
      defaults=config-0
      mcp-servers=(map mcp-server-id:h mcp-server:h)
      streams=(map [session-id:h @ud] stream-progress)
      hands=state:hh
  ==
+$  state-9
  $:  %9
      sessions=(map session-id:h session-0)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config-0)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])
      acp-through=(map connection-id:v1:ac @ud)
      provider-keys=(map @t @t)
      model-requests=(map @ud [connection=connection-id:v1:ac request-id=json])
      next-model-request=@ud
      defaults=config-0
      mcp-servers=(map mcp-server-id:h mcp-server:h)
      streams=(map [session-id:h @ud] stream-progress)
      hands=state:hh
      openai-auth=state:oauth
  ==
+$  state-10
  $:  %10
      sessions=(map session-id:h session-0)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config-0)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])
      acp-through=(map connection-id:v1:ac @ud)
      provider-keys=(map @t @t)
      model-requests=(map @ud [connection=connection-id:v1:ac request-id=json])
      next-model-request=@ud
      defaults=config-0
      mcp-servers=(map mcp-server-id:h mcp-server:h)
      streams=(map [session-id:h @ud] stream-progress)
      hands=state:hh
      openai-auth=state:oauth
  ==
+$  state-11
  $:  %11
      sessions=(map session-id:h session-0)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config-0)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])
      acp-through=(map connection-id:v1:ac @ud)
      provider-keys=(map @t @t)
      model-requests=(map @ud [connection=connection-id:v1:ac request-id=json])
      next-model-request=@ud
      defaults=config-0
      mcp-servers=(map mcp-server-id:h mcp-server:h)
      streams=(map [session-id:h @ud] stream-progress)
      hands=state:hh
      openai-auth=state:oauth
      search-config=search-config:h
      search-requests=search-requests:h
  ==
+$  state-18
  [%18 remote-access=(map @p peer-access:h) announced-access=(map @p peer-grant:h) state-17]
+$  state-19
  $:  %19
      local-mcp-seen=@ud
      local-mcp=(map [session-id:h @t] local-mcp-progress:h)
      peer-receipts=(map [@p ask-id:h] peer-receipt:h)
      peer-active=(map session-id:h [ship=@p id=ask-id:h])
      state-18
  ==
+$  state-17  [%17 welcome-seen=@ud state-16]
+$  state-16  [%16 peer-budget-resets=(map @p @ud) state-15]
+$  state-15  [%15 peer-limits=(map @p @ud) state-14]
+$  state-14
  $:  %14
      summary-models=summary-models-0
      corpus=corpus-0
      corpus-wake=(unit @da)
      state-13
  ==
+$  state-13  [%13 modified=(map session-id:h @da) state-12]
+$  state-12
  $:  %12
      sessions=(map session-id:h session-0)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config-0)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])
      acp-through=(map connection-id:v1:ac @ud)
      provider-keys=(map @t @t)
      model-requests=(map @ud [connection=connection-id:v1:ac request-id=json])
      next-model-request=@ud
      defaults=config-0
      mcp-servers=(map mcp-server-id:h mcp-server:h)
      streams=(map [session-id:h @ud] stream-progress)
      hands=state:hh
      openai-auth=state:oauth
      search-config=search-config:h
      search-requests=search-requests:h
  ==
--
