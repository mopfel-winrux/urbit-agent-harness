::  Persistence version conversion, deliberately outside the running head.
::  Load preserves the saved envelope; it does not dispatch work. Explicit
::  constructors make every retained field auditable across version changes.
/-  h=harness, hh=harness-hand, ac=acp, oauth=harness-oauth, corpus=harness-corpus, *harness-store
/+  hl=harness, ht=harness-tools, hd=harness-hand, policy=harness-defaults, index=harness-session-index
|%
++  load
  |=  old-vase=vase
  ^-  state-19
  =/  current  (mule |.(!<(state-19 old-vase)))
  ?:  ?=(%& -.current)  p.current
  [%19 0 ~ ~ ~ (load-18 old-vase)]
++  load-18
  |=  old-vase=vase
  ^-  state-18
  =/  current  (mule |.(!<(state-18 old-vase)))
  ?:  ?=(%& -.current)  p.current
  [%18 ~ ~ (load-17 old-vase)]
++  load-17
  |=  old-vase=vase
  ^-  state-17
  =/  current  (mule |.(!<(state-17 old-vase)))
  ?:  ?=(%& -.current)  p.current
  [%17 0 (load-16 old-vase)]
++  load-16
  |=  old-vase=vase
  ^-  state-16
  =/  current  (mule |.(!<(state-16 old-vase)))
  ?:  ?=(%& -.current)  p.current
  [%16 ~ (load-15 old-vase)]
++  load-15
  |=  old-vase=vase
  ^-  state-15
  =/  current  (mule |.(!<(state-15 old-vase)))
  ?:  ?=(%& -.current)  p.current
  [%15 ~ (load-14 old-vase)]
++  load-14
  |=  old-vase=vase
  ^-  state-14
  =/  current  (mule |.(!<(state-14 old-vase)))
  ?:  ?=(%& -.current)  p.current
  [%14 *summary-models:h *state:corpus ~ (load-13 old-vase)]
++  load-13
  |=  old-vase=vase
  ^-  state-13
  =/  current  (mule |.(!<(state-13 old-vase)))
  ?:  ?=(%& -.current)  p.current
  =/  prior  (load-12 old-vase)
  [%13 (seed:index sessions.prior) prior]
++  load-12
  |=  old-vase=vase
  ^-  state-12
  =/  twelfth  (mule |.(!<(state-12 old-vase)))
  ?:  ?=(%& -.twelfth)  p.twelfth
  %-  migrate-11
  =/  eleventh  (mule |.(!<(state-11 old-vase)))
  ?:  ?=(%& -.eleventh)  p.eleventh
  %-  migrate-10
  =/  tenth  (mule |.(!<(state-10 old-vase)))
  ?:  ?=(%& -.tenth)  p.tenth
  %-  migrate-9
  =/  ninth  (mule |.(!<(state-9 old-vase)))
  ?:  ?=(%& -.ninth)  p.ninth
  %-  migrate-8
  =/  eighth  (mule |.(!<(state-8 old-vase)))
  ?:  ?=(%& -.eighth)  p.eighth
  %-  migrate-7
  =/  latest  (mule |.(!<(state-7 old-vase)))
  ?:  ?=(%& -.latest)  p.latest
  %-  migrate-6
  =/  current  (mule |.(!<(state-6 old-vase)))
  ?:  ?=(%& -.current)  p.current
  =/  fifth  (mule |.(!<(state-5 old-vase)))
  ?:  ?=(%& -.fifth)
    (migrate-5 p.fifth)
  =/  fourth  (mule |.(!<(state-4 old-vase)))
  ?:  ?=(%& -.fourth)
    (migrate-5 (migrate-4 p.fourth))
  =/  third  (mule |.(!<(state-3 old-vase)))
  ?:  ?=(%& -.third)
    (migrate-5 (migrate-4 (migrate-3 p.third)))
  =/  previous  (mule |.(!<(state-2 old-vase)))
  ?:  ?=(%& -.previous)
    (migrate-5 (migrate-4 (migrate-3 (migrate-2 p.previous))))
  =/  prior  (mule |.(!<(state-1 old-vase)))
  ?:  ?=(%& -.prior)
    (migrate-5 (migrate-4 (migrate-3 (migrate-2 (migrate-1 p.prior)))))
  =/  oldest  (mule |.(!<(state-0 old-vase)))
  ?:  ?=(%& -.oldest)
    (migrate-5 (migrate-4 (migrate-3 (migrate-2 (migrate-1 (migrate-0 p.oldest))))))
  ~|  %harness-incompatible-state
  !!
++  migrate-0
  |=  old=state-0
  ^-  state-1
  =/  prompts=(map session-id:h [request-id=json cursor=@ud])
    %+  roll  ~(tap by acp-prompts.old)
    |=  [[sid=session-id:h request-id=json] acc=(map session-id:h [request-id=json cursor=@ud])]
    =/  maybe-session  (~(get by sessions.old) sid)
    =/  cursor=@ud
      ?~  maybe-session  0
      (lent items:(play:hl log.u.maybe-session))
    (~(put by acc) sid [request-id cursor])
  :*  %1
      sessions.old
      timers.old
      subs.old
      skills.old
      staged.old
      rehearsals.old
      peers.old
      peer-base.old
      asks.old
      serving.old
      jobs.old
      api-key.old
      prompts
      acp-through.old
  ==
++  migrate-1
  |=  old=state-1
  ^-  state-2
  =/  prompts=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])
    %+  roll  ~(tap by acp-prompts.old)
    |=  [[sid=session-id:h prompt=[request-id=json cursor=@ud]] acc=(map session-id:h [connection=connection-id:v1:ac request-id=json cursor=@ud])]
    (~(put by acc) sid [acp-id:policy request-id.prompt cursor.prompt])
  :*  %2
      sessions.old
      timers.old
      subs.old
      skills.old
      staged.old
      rehearsals.old
      peers.old
      peer-base.old
      asks.old
      serving.old
      jobs.old
      api-key.old
      prompts
      (~(put by *(map connection-id:v1:ac @ud)) acp-id:policy acp-through.old)
  ==
++  migrate-2
  |=  old=state-2
  ^-  state-3
  =/  keys=(map @t @t)
    ?:  =('' api-key.old)  *(map @t @t)
    (~(put by *(map @t @t)) 'openrouter' api-key.old)
  :*  %3
      sessions.old
      timers.old
      subs.old
      skills.old
      staged.old
      rehearsals.old
      peers.old
      peer-base.old
      asks.old
      serving.old
      jobs.old
      api-key.old
      acp-prompts.old
      acp-through.old
      keys
      *(map @ud [connection=connection-id:v1:ac request-id=json])
      1
  ==
++  migrate-3
  |=  old=state-3
  ^-  state-4
  =/  enabled=(map session-id:h session:h)
    %+  roll  ~(tap by sessions.old)
    |=  [[sid=session-id:h ses=session:h] acc=(map session-id:h session:h)]
    =/  cfg=config:h  config:(play:hl log.ses)
    =/  next=session:h
      [[[%config-replaced cfg(tools all-tools:ht)] log.ses] next-req.ses]
    (~(put by acc) sid next)
  :*  %4
      enabled
      timers.old
      subs.old
      skills.old
      staged.old
      rehearsals.old
      peers.old
      peer-base.old
      asks.old
      serving.old
      jobs.old
      api-key.old
      acp-prompts.old
      acp-through.old
      provider-keys.old
      model-requests.old
      next-model-request.old
  ==
++  migrate-4
  |=  old=state-4
  ^-  state-5
  :*  %5
      sessions.old
      timers.old
      subs.old
      skills.old
      staged.old
      rehearsals.old
      peers.old
      peer-base.old
      asks.old
      serving.old
      jobs.old
      api-key.old
      acp-prompts.old
      acp-through.old
      provider-keys.old
      model-requests.old
      next-model-request.old
      builtin-config:policy
      *(map mcp-server-id:h mcp-server:h)
  ==
++  migrate-5
  |=  old=state-5
  ^-  state-6
  :*  %6
      sessions.old
      timers.old
      subs.old
      skills.old
      staged.old
      rehearsals.old
      peers.old
      peer-base.old
      asks.old
      serving.old
      jobs.old
      api-key.old
      acp-prompts.old
      acp-through.old
      provider-keys.old
      model-requests.old
      next-model-request.old
      defaults.old
      mcp-servers.old
      *(map [session-id:h @ud] stream-progress)
  ==
++  migrate-6
  |=  old=state-6
  ^-  state-7
  :*  %7
      sessions.old
      timers.old
      subs.old
      skills.old
      staged.old
      rehearsals.old
      peers.old
      peer-base.old
      asks.old
      serving.old
      jobs.old
      api-key.old
      acp-prompts.old
      acp-through.old
      provider-keys.old
      model-requests.old
      next-model-request.old
      defaults.old
      mcp-servers.old
      streams.old
      *state-0:hh
  ==
++  migrate-7
  |=  old=state-7
  ^-  state-8
  :*  %8
      sessions.old
      timers.old
      subs.old
      skills.old
      staged.old
      rehearsals.old
      peers.old
      peer-base.old
      asks.old
      serving.old
      jobs.old
      api-key.old
      acp-prompts.old
      acp-through.old
      provider-keys.old
      model-requests.old
      next-model-request.old
      defaults.old
      mcp-servers.old
      streams.old
      (migrate:hd hands.old)
  ==
++  migrate-8
  |=  old=state-8
  ^-  state-9
  :*  %9
      sessions.old
      timers.old
      subs.old
      skills.old
      staged.old
      rehearsals.old
      peers.old
      peer-base.old
      asks.old
      serving.old
      jobs.old
      api-key.old
      acp-prompts.old
      acp-through.old
      provider-keys.old
      model-requests.old
      next-model-request.old
      defaults.old
      mcp-servers.old
      streams.old
      hands.old
      *state:oauth
  ==
++  migrate-9
  |=  old=state-9
  ^-  state-10
  =/  servers=(list @t)  ~(tap in ~(key by mcp-servers.old))
  =.  sessions.old
    %+  roll  ~(tap by sessions.old)
    |=  [[sid=session-id:h ses=session:h] acc=(map session-id:h session:h)]
    =/  cfg  config:(play:hl log.ses)
    =/  scoped  (scope-mcp:ht tools.cfg servers)
    ?:  =(scoped tools.cfg)  (~(put by acc) sid ses)
    (~(put by acc) sid ses(log [[%config-replaced cfg(tools scoped)] log.ses]))
  =.  defaults.old  defaults.old(tools (scope-mcp:ht tools.defaults.old servers))
  =.  peer-base.old
    ?~  peer-base.old  ~
    `u.peer-base.old(tools (scope-mcp:ht tools.u.peer-base.old servers))
  =.  peers.old
    %+  roll  ~(tap by peers.old)
    |=  [[ship=@p grant=peer-grant:h] acc=(map @p peer-grant:h)]
    (~(put by acc) ship grant(tools (scope-mcp:ht tools.grant servers)))
  [%10 +.old]
++  migrate-10
  |=  old=state-10
  ^-  state-11
  :*  %11
      sessions.old
      timers.old
      subs.old
      skills.old
      staged.old
      rehearsals.old
      peers.old
      peer-base.old
      asks.old
      serving.old
      jobs.old
      api-key.old
      acp-prompts.old
      acp-through.old
      provider-keys.old
      model-requests.old
      next-model-request.old
      defaults.old
      mcp-servers.old
      streams.old
      hands.old
      openai-auth.old
      [%brave '']
      *search-requests:h
  ==
++  migrate-11
  |=  old=state-11
  ^-  state-12
  =.  sessions.old
    %+  roll  ~(tap by sessions.old)
    |=  [[sid=session-id:h ses=session:h] acc=(map session-id:h session:h)]
    =/  cfg  config:(play:hl log.ses)
    =/  scoped  (scope-clay:ht tools.cfg)
    ?:  =(scoped tools.cfg)  (~(put by acc) sid ses)
    (~(put by acc) sid ses(log [[%config-replaced cfg(tools scoped)] log.ses]))
  =.  defaults.old  defaults.old(tools (scope-clay:ht tools.defaults.old))
  =.  peer-base.old
    ?~  peer-base.old  ~
    `u.peer-base.old(tools (scope-clay:ht tools.u.peer-base.old))
  =.  peers.old
    %+  roll  ~(tap by peers.old)
    |=  [[ship=@p grant=peer-grant:h] acc=(map @p peer-grant:h)]
    (~(put by acc) ship grant(tools (scope-clay:ht tools.grant)))
  [%12 +.old]
--
