::  Ephemeral presentation, not a work queue. Many actors and threads share
::  one Tlon context, so aggregate first and clear only when all are settled.
::  A short lease expires on crashes; renewal carries no prompts or tool args.
/-  t=harness-tlon, pr=tlon-presence
|%
++  context
  |=  to=destination:t
  ^-  path
  ?-  -.to
    %dm       /dm/(scot %p who.to)
    %channel  /channel/[kind.nest.to]/(scot %p ship.nest.to)/[name.nest.to]
  ==
++  merge
  |=  [active=(map path ?) to=destination:t tools=?]
  ^+  active
  =/  ctx  (context to)
  (~(put by active) ctx |(tools (~(gut by active) ctx |)))
++  sync
  |=  [our=@p now=@da old=(map path presence-lease:t) active=(map path ?)]
  ^-  (quip card:agent:gall (map path presence-lease:t))
  =/  cards=(list card:agent:gall)  ~
  =/  next=(map path presence-lease:t)  ~
  =^  cards  next
    %+  roll  ~(tap by old)
    |=  [[ctx=path lease=presence-lease:t] acc=[cards=(list card:agent:gall) next=(map path presence-lease:t)]]
    ?:  (~(has by active) ctx)  acc
    :_  next.acc
    [[%pass /presence %agent [our %presence] %poke %presence-action-1 !>(`action-1:pr`[%clear ctx our %computing])] cards.acc]
  =/  seed=[cards=(list card:agent:gall) next=(map path presence-lease:t)]  [cards next]
  %+  roll  ~(tap by active)
  |=  [[ctx=path tools=?] acc=_seed]
  =/  previous  (~(get by old) ctx)
  ?:  ?&(?=(^ previous) =(tools tools.u.previous) (lth now (add at.u.previous ~s10)))
    [cards.acc (~(put by next.acc) ctx u.previous)]
  =/  display=display:pr
    :-  ~
    :-  `?:(tools 'Using tools...' 'Thinking...')
    `?:(tools '{"protocol":"tlon.computing-status.v1","thinking":false,"toolCalls":[{"toolName":"tools","label":"Using tools..."}]}' '{"protocol":"tlon.computing-status.v1","thinking":true,"toolCalls":[]}')
  :_  (~(put by next.acc) ctx [now tools])
  [[%pass /presence %agent [our %presence] %poke %presence-action-1 !>(`action-1:pr`[%set ~ [ctx our %computing] `~s30 display])] cards.acc]
--
