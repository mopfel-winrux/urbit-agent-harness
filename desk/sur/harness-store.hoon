::  Gall persistence envelope. Runtime bookkeeping is not session semantics.
/-  h=harness, hh=harness-hand, ac=acp, oauth=harness-oauth, corpus=harness-corpus, cron=harness-cron, work=harness-workspace
/-  hn=harness-notes
/-  ws=harness-workspace-search
/-  pc=harness-project-client
/-  wc=harness-work-control
/-  hosted=harness-hosted
|%
+$  state-0
  $:  %0
      model-defaults-set=$~(| ?)
      xai-auth=state:oauth
      hosted=state:hosted
      workspace=state:work
      work-controls=state:wc
      project-clients=state:pc
      workspace-search=state:ws
      workspace-notes=state:hn
      schedules=(map @uv schedule:cron)
      schedule-wake=(unit @da)
      local-mcp-seen=@ud
      local-mcp=(map [session-id:h @t] local-mcp-progress:h)
      peer-receipts=(map [@p ask-id:h] peer-receipt:h)
      peer-active=(map session-id:h [ship=@p id=ask-id:h])
      remote-access=(map @p peer-access:h)
      announced-access=(map @p peer-grant:h)
      welcome-seen=@ud
      peer-budget-resets=(map @p @ud)
      peer-limits=(map @p @ud)
      summary-models=summary-models:h
      corpus=state:corpus
      corpus-wake=(unit @da)
      modified=(map session-id:h @da)
      sessions=(map session-id:h session:h)
      timers=(map [session-id:h @ta] timer:h)
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      skills=(map @t skill:h)
      staged=(map @t skill:h)
      rehearsals=(map session-id:h @t)
      peers=(map ship peer-grant:h)
      peer-base=(unit config:h)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      api-key=@t
      acp-prompts=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])
      acp-through=(map connection-id:v1:ac @ud)
      provider-keys=(map @t @t)
      model-requests=(map @ud [connection=connection-id:v1:ac request-id=json])
      next-model-request=@ud
      defaults=config:h
      mcp-servers=(map mcp-server-id:h mcp-server:h)
      streams=(map [session-id:h @ud] stream-progress)
      hands=state:hh
      openai-auth=state:oauth
      search-config=search-config:h
      search-requests=search-requests:h
  ==
+$  stream-progress  [body=@t sent=@ud]
--
