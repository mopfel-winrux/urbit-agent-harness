::  harness: the head of an on-ship agent harness
::
::    a gall agent that owns sessions (event logs), drives the pure
::    core in /lib/harness, and speaks to the provider through iris.
::    surfaces: pokes (%harness-action), facts on /session/[sid],
::    scries at /x/sessions and /x/session/[sid]. the chat ui is
::    served from /web by %harness-fileserver.
::
/-  h=harness, spider, ac=acp
/+  hl=harness, hg=harness-grub, default-agent, dbug
|%
+$  model-info  [id=@t context=(unit @ud)]
+$  stream-progress  [body=@t sent=@ud]
+$  state-0
  $:  %0
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
      acp-prompts=(map session-id:h json)
      acp-through=@ud
  ==
+$  state-1
  $:  %1
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
      acp-prompts=(map session-id:h [request-id=json cursor=@ud])
      acp-through=@ud
  ==
+$  state-2
  $:  %2
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
  ==
+$  state-3
  $:  %3
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
  ==
+$  state-4
  $:  %4
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
  ==
+$  state-5
  $:  %5
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
  ==
+$  state-6
  $:  %6
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
  ==
+$  card  card:agent:gall
--
%-  agent:dbug
=|  state-6
=*  state  -
^-  agent:gall
=<
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)
    hc    ~(. +> bowl)
::
++  on-init
  ^-  (quip card _this)
  :_  this(defaults builtin-config:hc)
  :~  [%pass /eyre/connect %arvo %e %connect [~ /harness-api] dap.bowl]
      acp-open-card:hc
      acp-watch-card:hc
      (watch:hg our.bowl shadow-channel:hc)
  ==
::
++  on-save  !>(state)
::
++  on-load
  |=  old-vase=vase
  ^-  (quip card _this)
  =/  current  (mule |.(!<(state-6 old-vase)))
  =/  new=state-6
    ?:  ?=(%& -.current)  p.current
    =/  fifth  (mule |.(!<(state-5 old-vase)))
    ?:  ?=(%& -.fifth)
      (migrate-5:hc p.fifth)
    =/  fourth  (mule |.(!<(state-4 old-vase)))
    ?:  ?=(%& -.fourth)
      (migrate-5:hc (migrate-4:hc p.fourth))
    =/  third  (mule |.(!<(state-3 old-vase)))
    ?:  ?=(%& -.third)
      (migrate-5:hc (migrate-4:hc (migrate-3:hc p.third)))
    =/  previous  (mule |.(!<(state-2 old-vase)))
    ?:  ?=(%& -.previous)
      (migrate-5:hc (migrate-4:hc (migrate-3:hc (migrate-2:hc p.previous))))
    =/  prior  (mule |.(!<(state-1 old-vase)))
    ?:  ?=(%& -.prior)
      (migrate-5:hc (migrate-4:hc (migrate-3:hc (migrate-2:hc (migrate-1:hc p.prior)))))
    =/  oldest  (mule |.(!<(state-0 old-vase)))
    ?:  ?=(%& -.oldest)
      (migrate-5:hc (migrate-4:hc (migrate-3:hc (migrate-2:hc (migrate-1:hc (migrate-0:hc p.oldest))))))
    ~?  &  [dap.bowl %incompatible-state-dropped]
    *state-6
  :_  this(state new)
  =/  base=(list card)
    :~  [%pass /eyre/connect %arvo %e %connect [~ /harness-api] dap.bowl]
        acp-open-card:hc
        acp-watch-card:hc
        (watch:hg our.bowl shadow-channel:hc)
    ==
  %+  weld  base
  %+  turn  ~(tap by sessions.new)
  |=  [sid=session-id:h ses=session:h]
  (shadow-put-card:hc sid ses)
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+  mark  (on-poke:def mark vase)
      %harness-action
    =^  cards  state  (handle-action:hc !<(action:h vase))
    [cards this]
  ::
      %noun
    =^  cards  state  (handle-action:hc ;;(action:h q.vase))
    [cards this]
  ::
      %handle-http-request
    =+  !<([eyre-id=@ta req=inbound-request:eyre] vase)
    =^  cards  state  (serve:hc eyre-id req)
    [cards this]
  ::
      %harness-a2a-0
    =^  cards  state  (handle-a2a:hc src.bowl !<(a2a:h vase))
    [cards this]
  ==
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+  path  (on-watch:def path)
    [%session @ ~]       `this
    [%http-response *]   `this
  ==
::
++  on-leave  |=(path `this)
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  (on-peek:def path)
      [%x %sessions ~]
    :^  ~  ~  %json
    !>  ^-  json
    :-  %a
    %+  turn  ~(tap in ~(key by sessions))
    |=(sid=session-id:h `json`[%s sid])
  ::
      [%x %session @ ~]
    =/  sid=session-id:h  i.t.t.path
    =/  ses  (~(get by sessions) sid)
    ?~  ses  [~ ~]
    ``json+!>((view-json:hl (play:hl log.u.ses)))
  ::
      [%x %events @ ~]
    =/  sid=session-id:h  i.t.t.path
    =/  ses  (~(get by sessions) sid)
    ?~  ses  [~ ~]
    :^  ~  ~  %json
    !>  ^-  json
    [%a (turn (flop log.u.ses) event-json:hl)]
  ::
      [%x %status ~]
    :^  ~  ~  %json
    !>  ^-  json
    (pairs:enjs:format ~[['has-key' %b !=('' api-key)]])
  ::
      [%x %tools ~]
    :^  ~  ~  %json
    !>  ^-  json
    [%a (turn all-tools:hl |=(t=term `json`[%s t]))]
  ::
      [%x %defaults ~]
    ``json+!>((config-json:hl defaults))
  ::
      [%x %mcp ~]
    :^  ~  ~  %json
    !>  ^-  json
    [%a (turn ~(tap by mcp-servers) mcp-server-json:hc)]
  ::
      [%x %skills ~]
    ``json+!>((skills-json:hl skills))
  ::
      [%x %staged ~]
    ``json+!>((skills-json:hl staged))
  ::
      [%x %peers ~]
    :^  ~  ~  %json
    !>  ^-  json
    :-  %a
    %+  turn  ~(tap by peers)
    |=  [=ship g=peer-grant:h]
    ^-  json
    %-  pairs:enjs:format
    :~  ['ship' %s (scot %p ship)]
        ['tools' %a (turn tools.g |=(t=term `json`[%s t]))]
        ['budget' (numb:enjs:format budget.g)]
        ['inflows' %a (turn ~(tap in inflows.g) |=(n=@t `json`[%s n]))]
    ==
  ::
      [%x %timers ~]
    :^  ~  ~  %json
    !>  ^-  json
    :-  %a
    %+  turn  ~(tap by timers)
    |=  [[sid=session-id:h name=@ta] t=timer:h]
    ^-  json
    %-  pairs:enjs:format
    :~  ['sid' %s sid]
        ['name' %s name]
        ['at' %s (scot %da at.t)]
        ['every' ?~(every.t ~ [%s (scot %dr u.every.t)])]
        ['prompt' %s prompt.t]
    ==
  ==
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+  wire  (on-agent:def wire sign)
      [%harness-grub @ ~]
    ?+  -.sign  `this
        %kick
      [~[(watch:hg our.bowl shadow-channel:hc)] this]
    ::
        %watch-ack
      ?~  p.sign  [shadow-all-cards:hc this]
      [~[(watch:hg our.bowl shadow-channel:hc)] this]
    ::
        %fact
      =/  fac  (take-fact:hg sign)
      ?~  fac  `this
      ?.  ?=(%ack -.res.u.fac)  `this
      ?~  err.res.u.fac  `this
      %-  (slog 'harness: session namespace rejected an update' u.err.res.u.fac)
      `this
    ==
  ::
      [%harness-grub-cmd @ ~]
    ?.  ?=(%poke-ack -.sign)  (on-agent:def wire sign)
    ?^  p.sign
      %-  (slog 'harness: session namespace update failed' u.p.sign)
      `this
    `this
  ::
      [%acp %open ~]
    ?.  ?=(%poke-ack -.sign)  (on-agent:def wire sign)
    ?^  p.sign
      %-  (slog 'harness: could not open ACP transport' u.p.sign)
      `this
    `this
  ::
      [%acp %send ~]
    `this
  ::
      [%acp %ack ~]
    `this
  ::
      [%acp %watch ~]
    ?+  -.sign  (on-agent:def wire sign)
        %kick
      [~[acp-watch-card:hc] this]
    ::
        %watch-ack
      ?~  p.sign  `this
      [~[acp-watch-card:hc] this]
    ::
        %fact
      ?.  ?=(%acp-update-1 p.cage.sign)  `this
      =^  cards  state  (handle-acp-update:hc !<(update:v1:ac q.cage.sign))
      [cards this]
    ==
  ::
      [%a2a %ask @ ~]
    ?.  ?=(%poke-ack -.sign)  (on-agent:def wire sign)
    ?~  p.sign  `this
    =^  cards  state
      (fail-ask:hc (slav %uv i.t.t.wire) 'peer rejected the ask')
    [cards this]
  ::
      [%a2a %answer @ ~]
    `this
  ::
      [%jspoke @ ~]
    ?.  ?=(%poke-ack -.sign)  (on-agent:def wire sign)
    ?~  p.sign  `this
    ::  spider refused to start the thread
    ::
    =^  cards  state  (finish-js:hc i.t.wire 'error: could not start js thread')
    [cards this]
  ::
      [%jswatch @ ~]
    =/  tid=@ta  i.t.wire
    ?+  -.sign  (on-agent:def wire sign)
        %kick  `this
        %watch-ack  `this
        %fact
      =/  body=@t
        ?+  p.cage.sign  'error: unexpected thread result'
            %thread-fail
          =+  !<([=term =tang] q.cage.sign)
          %+  rap  3
          :~  'error: js thread failed: '  term
              '\0a'
              %-  crip
              %-  zing
              (turn tang |=(=tank (weld `tape`~(ram re tank) `tape`"\0a")))
          ==
        ::
            %thread-done
          =/  parsed
            %-  mole  |.
            !<([%0 out=(each cord [err=cord where=cord])] q.cage.sign)
          ?~  parsed  'error: could not read thread result'
          ?:  ?=(%& -.out.u.parsed)  (clip:hl p.out.u.parsed 8.000)
          %+  rap  3
          :~  'js error: '  err.p.out.u.parsed
              ' ('  where.p.out.u.parsed  ')'
          ==
        ==
      =^  cards  state  (finish-js:hc tid body)
      [cards this]
    ==
  ==
::
++  on-arvo
  |=  [=wire sign=sign-arvo]
  ^-  (quip card _this)
  ?+  wire  (on-arvo:def wire sign)
      [%eyre %connect ~]
    ?.  ?=([%eyre %bound *] sign)  (on-arvo:def wire sign)
    ~?  !accepted.sign  [dap.bowl %eyre-bind-failed binding.sign]
    `this
  ::
      [%llm @ @ @ ~]
    =/  sid=session-id:h  i.t.wire
    =/  req=@ud  (slav %ud i.t.t.wire)
    =/  kind=request-kind:h  ;;(request-kind:h i.t.t.t.wire)
    ?.  ?=([%iris %http-response *] sign)  (on-arvo:def wire sign)
    =^  cards  state
      (handle-llm-response:hc sid req kind client-response.sign)
    [cards this]
  ::
      [%models @ ~]
    =/  req=@ud  (slav %ud i.t.wire)
    ?.  ?=([%iris %http-response *] sign)  (on-arvo:def wire sign)
    =^  cards  state  (handle-model-response:hc req client-response.sign)
    [cards this]
  ::
      [%tool @ @ ~]
    =/  sid=session-id:h  i.t.wire
    =/  call-id=@t  i.t.t.wire
    ?.  ?=([%iris %http-response *] sign)  (on-arvo:def wire sign)
    =^  cards  state
      (handle-tool-response:hc sid call-id client-response.sign)
    [cards this]
  ::
      [%timer @ @ ~]
    =/  sid=session-id:h  i.t.wire
    =/  name=@ta  i.t.t.wire
    ?.  ?=([%behn %wake *] sign)  (on-arvo:def wire sign)
    =^  cards  state  (handle-timer-fire:hc sid name error.sign)
    [cards this]
  ::
      [%a2a-timeout @ ~]
    ?.  ?=([%behn %wake *] sign)  (on-arvo:def wire sign)
    =^  cards  state
      (fail-ask:hc (slav %uv i.t.wire) 'peer timed out')
    [cards this]
  ::
      [%jsdog @ ~]
    ?.  ?=([%behn %wake *] sign)  (on-arvo:def wire sign)
    =^  cards  state  (watchdog-js:hc i.t.wire)
    [cards this]
  ==
::
++  on-fail  |=([term tang] `this)
--
::  helper core: everything stateful lives here
::
|_  =bowl:gall
+*  hl-lib  hl
::  ACP is a generic durable duplex transport. Each harness chooses a
::  connection id and implements the protocol methods behind that queue.
::
++  acp-id  'harness'
++  shadow-channel  'sessions'
::  Re-project the authoritative map whenever the runtime subscription returns.
++  shadow-all-cards
  ^-  (list card)
  %+  turn  ~(tap by sessions)
  |=  [sid=session-id:h ses=session:h]
  (shadow-put-card sid ses)
++  shadow-put-card
  |=  [sid=session-id:h ses=session:h]
  ^-  card
  =/  name=@ta  sid
  (send:hg our.bowl shadow-channel [%make-file /agents/main/sessions name %noun ses %.y])
++  shadow-del-card
  |=  sid=session-id:h
  ^-  card
  =/  name=@ta  sid
  (send:hg our.bowl shadow-channel [%cull /agents/main/sessions `name])
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
    (~(put by acc) sid [acp-id request-id.prompt cursor.prompt])
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
      (~(put by *(map connection-id:v1:ac @ud)) acp-id acp-through.old)
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
      [[[%config-replaced cfg(tools all-tools:hl)] log.ses] next-req.ses]
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
      builtin-config
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
++  acp-open-card
  ^-  card
  :*  %pass  /acp/open
      %agent  [our.bowl %acp]  %poke  %acp-action-1
      !>(`action:v1:ac`[%open acp-id])
  ==
++  acp-watch-card
  ^-  card
  [%pass /acp/watch %agent [our.bowl %acp] %watch /v1/agent]
++  acp-action-card
  |=  [=wire act=action:v1:ac]
  ^-  card
  [%pass wire %agent [our.bowl %acp] %poke %acp-action-1 !>(act)]
++  acp-send-card
  |=  [connection=connection-id:v1:ac payload=@t]
  ^-  card
  (acp-action-card /acp/send [%send connection %client payload])
++  acp-ack-card
  |=  [connection=connection-id:v1:ac through=@ud]
  ^-  card
  (acp-action-card /acp/ack [%ack connection %agent through])
::
++  handle-acp-update
  |=  upd=update:v1:ac
  ^-  (quip card _state)
  ?.  ?=(%messages -.upd)  `state
  ?.  =(%agent target.upd)  `state
  =/  connection=connection-id:v1:ac  connection.upd
  =/  through=@ud  (fall (~(get by acp-through) connection) 0)
  =|  cards=(list card)
  =/  remaining  messages.upd
  |-  ^-  (quip card _state)
  ?~  remaining  [cards state]
  =/  sequence  sequence.i.remaining
  ?:  (lte sequence through)
    $(remaining t.remaining)
  =^  admitted  state  (handle-acp-message connection i.remaining)
  =.  acp-through  (~(put by acp-through) connection sequence)
  %=  $
    remaining  t.remaining
    cards      :(weld cards admitted ~[(acp-ack-card connection sequence)])
  ==
::
++  handle-acp-message
  |=  [connection=connection-id:v1:ac msg=message:v1:ac]
  ^-  (quip card _state)
  =/  parsed  (de:json:html payload.msg)
  ?~  parsed  `state
  =/  jon=json  u.parsed
  ?.  ?=([%o *] jon)  `state
  =/  version  (~(get by p.jon) 'jsonrpc')
  ?.  ?=([~ %s *] version)  `state
  ?.  =('2.0' p.u.version)  `state
  =/  method  (~(get by p.jon) 'method')
  ?.  ?=([~ %s *] method)  `state
  =/  id  (~(get by p.jon) 'id')
  =/  params  (~(get by p.jon) 'params')
  ?+  p.u.method
    ?~  id  `state
    [~[(acp-error-card connection u.id '-32601' 'Method not found')] state]
  ::
      %initialize
    ?~  id  `state
    [~[(acp-result-card connection u.id acp-initialize-result)] state]
  ::
      %'session/new'
    ?~  id  `state
    =/  requested  (acp-param-string params 'name')
    =/  sid=session-id:h
      ?~(requested (cat 3 'acp-' (scot %ud sequence.msg)) u.requested)
    ?:  (~(has by sessions) sid)
      [~[(acp-error-card connection u.id '-32603' 'Session id collision')] state]
    =^  made  state  (handle-action [%new sid defaults])
    =/  result=json
      (pairs:enjs:format ~[['sessionId' %s sid]])
    [:(weld made ~[(acp-result-card connection u.id result)]) state]
  ::
      %'session/list'
    ?~  id  `state
    =/  listed=(list json)
      %+  turn  ~(tap in ~(key by sessions))
      |=  sid=session-id:h
      %-  pairs:enjs:format
      :~  ['sessionId' %s sid]
          ['title' %s sid]
          ['cwd' %s '/']
      ==
    =/  result=json  (pairs:enjs:format ~[['sessions' %a listed]])
    [~[(acp-result-card connection u.id result)] state]
  ::
      %'session/load'
    ?~  id  `state
    =/  sid  (acp-param-string params 'sessionId')
    ?~  sid
      [~[(acp-error-card connection u.id '-32602' 'Unknown session')] state]
    ?.  (~(has by sessions) u.sid)
      [~[(acp-error-card connection u.id '-32602' 'Unknown session')] state]
    =/  current=session:h  (need (~(get by sessions) u.sid))
    =/  replay=(list card)
      (acp-item-cards connection u.sid 0 items:(play:hl log.current))
    [:(weld replay ~[(acp-result-card connection u.id (pairs:enjs:format ~))]) state]
  ::
      %'session/resume'
    ?~  id  `state
    =/  sid  (acp-param-string params 'sessionId')
    ?~  sid
      [~[(acp-error-card connection u.id '-32602' 'Unknown session')] state]
    ?.  (~(has by sessions) u.sid)
      [~[(acp-error-card connection u.id '-32602' 'Unknown session')] state]
    [~[(acp-result-card connection u.id (pairs:enjs:format ~))] state]
  ::
      %'session/close'
    ?~  id  `state
    =/  sid  (acp-param-string params 'sessionId')
    ?~  sid
      [~[(acp-error-card connection u.id '-32602' 'Unknown session')] state]
    ?.  (~(has by sessions) u.sid)
      [~[(acp-error-card connection u.id '-32602' 'Unknown session')] state]
    =^  cancelled  state  (handle-action [%cancel u.sid])
    [:(weld cancelled ~[(acp-result-card connection u.id (pairs:enjs:format ~))]) state]
  ::
      %'session/delete'
    ?~  id  `state
    =/  sid  (acp-param-string params 'sessionId')
    ?~  sid
      [~[(acp-error-card connection u.id '-32602' 'Unknown session')] state]
    ?.  (~(has by sessions) u.sid)
      [~[(acp-error-card connection u.id '-32602' 'Unknown session')] state]
    =^  deleted  state  (handle-action [%delete u.sid])
    [:(weld deleted ~[(acp-result-card connection u.id (pairs:enjs:format ~))]) state]
  ::
      %'harness/status'
    ?~  id  `state
    =/  provider=@t  (fall (acp-param-string params 'provider') 'openrouter')
    =/  stored=@t  (fall (~(get by provider-keys) provider) '')
    =/  has=?
      ?|  !=('' stored)
          ?&  =('openrouter' provider)
              !=('' api-key)
          ==
      ==
    =/  result=json
      (pairs:enjs:format ~[['has-key' %b has]])
    [~[(acp-result-card connection u.id result)] state]
  ::
      %'harness/tools'
    ?~  id  `state
    =/  result=json
      [%a (turn all-tools:hl |=(t=term `json`[%s t]))]
    [~[(acp-result-card connection u.id result)] state]
  ::
      %'harness/defaults'
    ?~  id  `state
    [~[(acp-result-card connection u.id (config-json:hl defaults))] state]
  ::
      %'harness/defaults/configure'
    ?~  id  `state
    =/  raw  (acp-param-json params 'config')
    ?~  raw
      [~[(acp-error-card connection u.id '-32602' 'Expected config')] state]
    =/  decoded  (mule |.((json-config:hl u.raw)))
    ?:  ?=(%| -.decoded)
      [~[(acp-error-card connection u.id '-32602' 'Invalid configuration')] state]
    =^  configured  state  (handle-action [%defaults p.decoded])
    [:(weld configured ~[(acp-result-card connection u.id (config-json:hl defaults))]) state]
  ::
      %'harness/mcp/servers'
    ?~  id  `state
    =/  result=json  [%a (turn ~(tap by mcp-servers) mcp-server-json)]
    [~[(acp-result-card connection u.id result)] state]
  ::
      %'harness/mcp/configure'
    ?~  id  `state
    =/  raw  (acp-param-json params 'servers')
    ?~  raw
      [~[(acp-error-card connection u.id '-32602' 'Expected servers')] state]
    =/  decoded  (mule |.((json-mcp-servers u.raw)))
    ?:  ?=(%| -.decoded)
      [~[(acp-error-card connection u.id '-32602' 'Invalid MCP configuration')] state]
    =^  configured  state  (handle-action [%mcp-config p.decoded])
    =/  result=json  [%a (turn ~(tap by mcp-servers) mcp-server-json)]
    [:(weld configured ~[(acp-result-card connection u.id result)]) state]
  ::
      %'harness/session/config'
    ?~  id  `state
    =/  sid  (acp-param-string params 'sessionId')
    ?~  sid
      [~[(acp-error-card connection u.id '-32602' 'Expected sessionId')] state]
    =/  current  (~(get by sessions) u.sid)
    ?~  current
      [~[(acp-error-card connection u.id '-32602' 'Unknown session')] state]
    =/  result=json  (view-json:hl (play:hl log.u.current))
    [~[(acp-result-card connection u.id result)] state]
  ::
      %'harness/session/configure'
    ?~  id  `state
    =/  sid  (acp-param-string params 'sessionId')
    =/  raw  (acp-param-json params 'config')
    ?.  &(?=(^ sid) ?=(^ raw))
      [~[(acp-error-card connection u.id '-32602' 'Expected sessionId and config')] state]
    ?.  (~(has by sessions) u.sid)
      [~[(acp-error-card connection u.id '-32602' 'Unknown session')] state]
    =/  decoded  (mule |.((json-config:hl u.raw)))
    ?:  ?=(%| -.decoded)
      [~[(acp-error-card connection u.id '-32602' 'Invalid configuration')] state]
    =^  configured  state  (handle-action [%config u.sid p.decoded])
    =/  current=session:h  (need (~(get by sessions) u.sid))
    =/  result=json  (view-json:hl (play:hl log.current))
    [:(weld configured ~[(acp-result-card connection u.id result)]) state]
  ::
      %'harness/credential/set'
    ?~  id  `state
    =/  key  (acp-param-string params 'key')
    =/  provider=@t  (fall (acp-param-string params 'provider') 'openrouter')
    ?~  key
      [~[(acp-error-card connection u.id '-32602' 'Expected key')] state]
    =.  provider-keys  (~(put by provider-keys) provider u.key)
    =?  api-key  =('openrouter' provider)  u.key
    =/  result=json
      (pairs:enjs:format ~[['has-key' %b !=('' u.key)]])
    [~[(acp-result-card connection u.id result)] state]
  ::
      %'harness/provider/models'
    ?~  id  `state
    =/  provider  (acp-param-string params 'provider')
    =/  url  (acp-param-string params 'url')
    ?.  &(?=(^ provider) ?=(^ url))
      [~[(acp-error-card connection u.id '-32602' 'Expected provider and url')] state]
    =/  req=@ud  next-model-request
    =.  next-model-request  +(next-model-request)
    =.  model-requests  (~(put by model-requests) req [connection u.id])
    [~[(model-list-card req u.provider u.url)] state]
  ::
      %'harness/session/rename'
    ?~  id  `state
    =/  sid  (acp-param-string params 'sessionId')
    =/  name  (acp-param-string params 'name')
    ?.  &(?=(^ sid) ?=(^ name))
      [~[(acp-error-card connection u.id '-32602' 'Expected sessionId and name')] state]
    ?.  (~(has by sessions) u.sid)
      [~[(acp-error-card connection u.id '-32602' 'Unknown session')] state]
    ?:  (~(has by sessions) u.name)
      [~[(acp-error-card connection u.id '-32602' 'Name already in use')] state]
    =/  current=session:h  (need (~(get by sessions) u.sid))
    =/  view=view:h  (play:hl log.current)
    ?:  |(?=(^ pending.view) !=(~ wait.view))
      [~[(acp-error-card connection u.id '-32600' 'Session is busy')] state]
    ::  A rename changes the address of the same record; it is not a fork and
    ::  therefore does not invent ancestry in the session history.
    ::
    =.  sessions  (~(put by sessions) u.name current)
    =^  deleted  state  (handle-action [%delete u.sid])
    :_  state
    %+  weld  ~[(shadow-put-card u.name current)]
    (weld deleted ~[(acp-result-card connection u.id (pairs:enjs:format ~))])
  ::
      %'session/prompt'
    ?~  id  `state
    =/  sid  (acp-param-string params 'sessionId')
    =/  text  (acp-prompt-text params)
    ?~  sid
      [~[(acp-error-card connection u.id '-32602' 'Expected sessionId and text prompt')] state]
    ?~  text
      [~[(acp-error-card connection u.id '-32602' 'Expected sessionId and text prompt')] state]
    ?.  (~(has by sessions) u.sid)
      [~[(acp-error-card connection u.id '-32602' 'Unknown session')] state]
    ?:  (~(has by acp-prompts) u.sid)
      [~[(acp-error-card connection u.id '-32600' 'A prompt is already running')] state]
    =/  current=session:h  (need (~(get by sessions) u.sid))
    =/  cursor=@ud  (lent items:(play:hl log.current))
    =.  acp-prompts  (~(put by acp-prompts) u.sid [connection u.id cursor])
    =/  event=event:h
      (input-event [%acp connection] `our.bowl `[%acp connection] [%user u.text])
    =^  admitted  current  (record-all u.sid current ~[event])
    =^  driven  state  (drive-put u.sid current)
    [:(weld admitted driven) state]
  ::
      %'session/cancel'
    =/  sid  (acp-param-string params 'sessionId')
    ?~  sid  `state
    =/  pending  (~(get by acp-prompts) u.sid)
    ?~  pending  `state
    =^  cancelled  state  (handle-action [%cancel u.sid])
    =.  acp-prompts  (~(del by acp-prompts) u.sid)
    =/  result=json  (pairs:enjs:format ~[['stopReason' %s 'cancelled']])
    [:(weld cancelled ~[(acp-result-card connection.u.pending request-id.u.pending result)]) state]
  ==
::
++  builtin-config
  ^-  config:h
  :*  'https://openrouter.ai/api/v1/chat/completions'
      'z-ai/glm-5.3-flash'
      ''
      ~
      default-system:hl
      1.310.720
      all-tools:hl
  ==
::
++  acp-initialize-result
  ^-  json
  =/  prompt-capabilities=json
    (pairs:enjs:format ~[['image' %b |] ['audio' %b |] ['embeddedContext' %b |]])
  =/  mcp-capabilities=json
    (pairs:enjs:format ~[['http' %b |] ['sse' %b |]])
  =/  capabilities=json
    %-  pairs:enjs:format
    :~  ['loadSession' %b &]
        ['promptCapabilities' prompt-capabilities]
        ['mcpCapabilities' mcp-capabilities]
        :-  'sessionCapabilities'
        %-  pairs:enjs:format
        :~  ['list' (pairs:enjs:format ~)]
            ['resume' (pairs:enjs:format ~)]
            ['close' (pairs:enjs:format ~)]
            ['delete' (pairs:enjs:format ~)]
        ==
        ['auth' (pairs:enjs:format ~)]
    ==
  =/  info=json
    %-  pairs:enjs:format
    :~  ['name' %s 'urbit-harness']
        ['title' %s 'Urbit Agent Harness']
        ['version' %s '0.1.0']
    ==
  %-  pairs:enjs:format
  :~  ['protocolVersion' (numb:enjs:format 1)]
      ['agentCapabilities' capabilities]
      ['authMethods' %a ~]
      ['agentInfo' info]
  ==
::
++  acp-result-card
  |=  [connection=connection-id:v1:ac id=json result=json]
  ^-  card
  =/  frame=json
    %-  pairs:enjs:format
    :~  ['jsonrpc' %s '2.0']
        ['id' id]
        ['result' result]
    ==
  (acp-send-card connection (en:json:html frame))
++  acp-error-card
  |=  [connection=connection-id:v1:ac id=json code=@t message=@t]
  ^-  card
  =/  error=json
    (pairs:enjs:format ~[['code' %n code] ['message' %s message]])
  =/  frame=json
    %-  pairs:enjs:format
    :~  ['jsonrpc' %s '2.0']
        ['id' id]
        ['error' error]
    ==
  (acp-send-card connection (en:json:html frame))
++  acp-update-card
  |=  [connection=connection-id:v1:ac sid=session-id:h text=@t]
  ^-  card
  =/  content=json
    (pairs:enjs:format ~[['type' %s 'text'] ['text' %s text]])
  =/  update=json
    %-  pairs:enjs:format
    :~  ['sessionUpdate' %s 'agent_message_chunk']
        ['content' content]
    ==
  (acp-session-update-card connection sid update)
++  acp-stream-card
  |=  [connection=connection-id:v1:ac sid=session-id:h text=@t]
  ^-  card
  =/  content=json
    (pairs:enjs:format ~[['type' %s 'text'] ['text' %s text]])
  =/  update=json
    %-  pairs:enjs:format
    :~  ['sessionUpdate' %s 'harness_agent_stream_chunk']
        ['content' content]
    ==
  (acp-session-update-card connection sid update)
++  acp-session-update-card
  |=  [connection=connection-id:v1:ac sid=session-id:h update=json]
  ^-  card
  =/  params=json
    (pairs:enjs:format ~[['sessionId' %s sid] ['update' update]])
  =/  frame=json
    %-  pairs:enjs:format
    :~  ['jsonrpc' %s '2.0']
        ['method' %s 'session/update']
        ['params' params]
    ==
  (acp-send-card connection (en:json:html frame))
++  acp-tool-call-card
  |=  [connection=connection-id:v1:ac sid=session-id:h call=tool-call:h]
  ^-  card
  =/  parsed  (de:json:html args.call)
  =/  raw-input=json
    ?~  parsed
      (pairs:enjs:format ~[['raw' %s args.call]])
    u.parsed
  =/  update=json
    %-  pairs:enjs:format
    :~  ['sessionUpdate' %s 'tool_call']
        ['toolCallId' %s id.call]
        ['title' %s name.call]
        ['status' %s 'in_progress']
        ['rawInput' raw-input]
    ==
  (acp-session-update-card connection sid update)
++  acp-tool-result-card
  |=  [connection=connection-id:v1:ac sid=session-id:h call-id=@t body=@t]
  ^-  card
  =/  text=json
    (pairs:enjs:format ~[['type' %s 'text'] ['text' %s body]])
  =/  content=json
    (pairs:enjs:format ~[['type' %s 'content'] ['content' text]])
  =/  update=json
    %-  pairs:enjs:format
    :~  ['sessionUpdate' %s 'tool_call_update']
        ['toolCallId' %s call-id]
        ['status' %s 'completed']
        ['content' %a ~[content]]
    ==
  (acp-session-update-card connection sid update)
++  acp-item-cards
  |=  [connection=connection-id:v1:ac sid=session-id:h cursor=@ud items=(list item:h)]
  ^-  (list card)
  %-  zing
  %+  turn  (slag cursor items)
  |=  item=item:h
  ^-  (list card)
  ?-  -.item
      %user
    =/  content=json
      (pairs:enjs:format ~[['type' %s 'text'] ['text' %s body.item]])
    =/  update=json
      %-  pairs:enjs:format
      :~  ['sessionUpdate' %s 'user_message_chunk']
          ['content' content]
      ==
    ~[(acp-session-update-card connection sid update)]
      %assistant
    =/  message-cards=(list card)
      ?:(=(0 body.item) ~ ~[(acp-update-card connection sid body.item)])
    (weld message-cards (turn calls.item |=(call=tool-call:h (acp-tool-call-card connection sid call))))
      %tool
    ~[(acp-tool-result-card connection sid call-id.item body.item)]
  ==
::
++  acp-param-string
  |=  [params=(unit json) key=@t]
  ^-  (unit @t)
  ?.  ?=([~ %o *] params)  ~
  =/  value  (~(get by p.u.params) key)
  ?:(?=([~ %s *] value) `p.u.value ~)
++  mcp-server-json
  |=  [id=mcp-server-id:h server=mcp-server:h]
  ^-  json
  %-  pairs:enjs:format
  :~  ['id' %s id]
      ['name' %s name.server]
      ['url' %s url.server]
      :-  'headers'
      :-  %a
      %+  turn  headers.server
      |=  [name=@t value=@t]
      (pairs:enjs:format ~[['name' %s name] ['value' %s value]])
      ['enabled' %b enabled.server]
  ==
++  json-mcp-servers
  =,  dejs:format
  ^-  $-(json (list [id=mcp-server-id:h server=mcp-server:h]))
  (ar (ot ~[id+so name+so url+so headers+(ar (ot ~[name+so value+so])) enabled+bo]))
++  acp-param-json
  |=  [params=(unit json) key=@t]
  ^-  (unit json)
  ?.  ?=([~ %o *] params)  ~
  (~(get by p.u.params) key)
++  acp-prompt-text
  |=  params=(unit json)
  ^-  (unit @t)
  ?.  ?=([~ %o *] params)  ~
  =/  prompt  (~(get by p.u.params) 'prompt')
  ?.  ?=([~ %a *] prompt)  ~
  =/  pieces=(list @t)
    %+  murn  p.u.prompt
    |=  block=json
    ^-  (unit @t)
    ?.  ?=([%o *] block)  ~
    =/  type  (~(get by p.block) 'type')
    ?.  ?=([~ %s *] type)  ~
    ?:  =('text' p.u.type)
      =/  text  (~(get by p.block) 'text')
      ?:(?=([~ %s *] text) `p.u.text ~)
    ?:  =('resource_link' p.u.type)
      =/  name  (~(get by p.block) 'name')
      =/  uri  (~(get by p.block) 'uri')
      ?.  &(?=([~ %s *] name) ?=([~ %s *] uri))  ~
      `(rap 3 '[resource ' p.u.name ': ' p.u.uri ']' ~)
    ~
  ?~  pieces  ~
  `(rap 3 (turn pieces |=(piece=@t (cat 3 piece '\0a'))))
::  +handle-action: admit a command, then drive the session
::
++  handle-action
  |=  act=action:h
  ^-  (quip card _state)
  ?-  -.act
      %new
    =/  cfg=config:h  config.act
    =?  provider-keys  !=('' key.cfg)
      (~(put by provider-keys) (provider-for-url url.cfg) key.cfg)
    =.  cfg  cfg(key '')
    =/  ses=session:h  [~[[%config-replaced cfg]] 0]
    =^  cards  state  (drive-put sid.act ses)
    [cards state]
  ::
      %send
    =/  ses  (need-session sid.act)
    =/  event=event:h
      (input-event [%poke src.bowl] `src.bowl ~ [%user text.act])
    =^  cs1  ses
      (record-all sid.act ses ~[event])
    =^  cs2  state  (drive-put sid.act ses)
    [(weld cs1 cs2) state]
  ::
      %fork
    =/  ses  (need-session from.act)
    =/  v  (play:hl log.ses)
    =/  req=(unit @ud)  ?~(pending.v ~ `req.u.pending.v)
    =/  event=event:h
      [%forked from.act (lent log.ses) req wait.v]
    =^  cards  ses  (record-all to.act ses ~[event])
    :-  (snoc cards (shadow-put-card to.act ses))
    state(sessions (~(put by sessions) to.act ses))
  ::
      %compact
    =/  ses  (need-session sid.act)
    =/  v  (play:hl log.ses)
    ?^  pending.v  `state
    =^  cards  ses  (issue-llm sid.act ses %compaction v)
    :-  cards
    state(sessions (~(put by sessions) sid.act ses))
  ::
      %cancel
    =/  ses  (need-session sid.act)
    =/  v  (play:hl log.ses)
    =/  req=(unit @ud)  ?~(pending.v ~ `req.u.pending.v)
    =/  event=event:h
      [%cancelled req wait.v 'cancelled by client']
    =.  streams
      %-  ~(gas by *(map [session-id:h @ud] stream-progress))
      (skip ~(tap by streams) |=([[s=session-id:h @ud] stream-progress] =(s sid.act)))
    =^  cards  ses  (record-all sid.act ses ~[event])
    :-  (snoc cards (shadow-put-card sid.act ses))
    state(sessions (~(put by sessions) sid.act ses))
  ::
      %delete
    ::  drop the session and everything scoped to it: pending timers
    ::  (cancel their behn), subagent links (as child or parent),
    ::  peer-serving queue, in-flight js jobs (stop the thread), and
    ::  outgoing asks. late results for any of these no-op on lookup.
    ::  a fork is an independent copy, so deleting never orphans one
    ::
    =/  sid  sid.act
    ?.  (~(has by sessions) sid)  `state
    =|  cards=(list card)
    ::  timers
    =/  tkeys  (skim ~(tap in ~(key by timers)) |=([s=session-id:h *] =(s sid)))
    =.  cards
      %+  weld  cards
      %+  turn  tkeys
      |=  [s=session-id:h name=@ta]
      (rest-card s name at:(~(got by timers) [s name]))
    =.  timers
      %-  ~(gas by *(map [session-id:h @ta] timer:h))
      (skip ~(tap by timers) |=([[s=session-id:h @ta] timer:h] =(s sid)))
    ::  subagent links (this session as child, or as parent)
    =.  subs
      %-  ~(gas by *(map session-id:h [session-id:h @t]))
      %+  skip  ~(tap by subs)
      |=  [child=session-id:h parent=session-id:h *]
      |(=(child sid) =(parent sid))
    ::  peer-serving queue
    =.  serving  (~(del by serving) sid)
    ::  in-flight js jobs for this session: stop the thread, drop the job
    =/  jkeys  (skim ~(tap by jobs) |=([tid=@ta s=session-id:h *] =(s sid)))
    =.  cards
      %+  weld  cards
      %+  turn  jkeys
      |=  [tid=@ta *]
      ^-  card
      :*  %pass  `wire`[%jsstop tid ~]
          %agent  [our.bowl %spider]  %poke  %spider-stop  !>([tid &])
      ==
    =.  jobs
      %-  ~(gas by *(map @ta [session-id:h @t @da]))
      (skip ~(tap by jobs) |=([tid=@ta s=session-id:h *] =(s sid)))
    ::  outgoing asks originated by this session
    =.  asks
      %-  ~(gas by *(map ask-id:h [session-id:h @t ship]))
      (skip ~(tap by asks) |=([id=ask-id:h s=session-id:h *] =(s sid)))
    =.  streams
      %-  ~(gas by *(map [session-id:h @ud] stream-progress))
      (skip ~(tap by streams) |=([[s=session-id:h @ud] stream-progress] =(s sid)))
    =.  cards  (snoc cards (shadow-del-card sid))
    =.  sessions  (~(del by sessions) sid)
    ::  close the ui subscription for this session
    :_  state
    (snoc cards [%give %kick ~[`path`[%session `@ta`sid ~]] ~])
  ::
      %retry
    =/  ses  (need-session sid.act)
    =^  cs1  ses  (record-all sid.act ses ~[[%retried ~]])
    =^  cs2  state  (drive-put sid.act ses)
    [(weld cs1 cs2) state]
  ::
      %config
    =/  ses  (need-session sid.act)
    =/  cfg=config:h  config.act
    =?  provider-keys  !=('' key.cfg)
      (~(put by provider-keys) (provider-for-url url.cfg) key.cfg)
    =.  cfg  cfg(key '')
    =^  cs1  ses
      (record-all sid.act ses ~[[%config-replaced cfg]])
    =^  cs2  state  (drive-put sid.act ses)
    [(weld cs1 cs2) state]
  ::
      %spawn
    ::  internal, from our own drive loop: create the child session
    ::  from the parent's current config, sans %subagents (depth 1)
    ::
    ?>  =(our.bowl src.bowl)
    ?.  (authorized-call parent.act call-id.act 'run_subagent')  `state
    =/  pses  (~(get by sessions) parent.act)
    ?~  pses  `state
    =/  pv  (play:hl log.u.pses)
    =/  csid=session-id:h  (rap 3 parent.act '--' call-id.act ~)
    =/  ccfg=config:h
      %=  config.pv
        tools   (skip tools.config.pv |=(t=term =(%subagents t)))
        system  %+  fall  system.act
                %^  cat  3  system.config.pv
                ' You are a subagent: complete the task and reply with only your final answer.'
      ==
    =/  cses=session:h
      :_  0
      :~  (input-event [%subagent parent.act call-id.act] `our.bowl `[%session parent.act call-id.act] [%user prompt.act])
          [%config-replaced ccfg]
      ==
    =.  subs  (~(put by subs) csid [parent.act call-id.act])
    =^  cards  state  (drive-put csid cses)
    [cards state]
  ::
      %rehearse
    ::  internal, from our own drive loop: spawn a rehearsal child that
    ::  can see the staged skill under test. it is an ordinary subagent
    ::  (answer returns to the parent's tool call via +settle) plus an
    ::  entry in `rehearsals` so +skills-visible shows it the staged skill
    ::
    ?>  =(our.bowl src.bowl)
    ?.  (authorized-call sid.act call-id.act 'rehearse_skill')  `state
    ?.  (~(has by staged) name.act)
      ::  nothing staged by that name: answer the tool call immediately
      =/  pses  (~(get by sessions) sid.act)
      ?~  pses  `state
      =^  cs1  u.pses
        %^  record-all  sid.act  u.pses
        ~[[%tool-completed call-id.act 'rehearse_skill' (cat 3 'error: no staged skill named ' name.act)]]
      =^  cs2  state  (drive-put sid.act u.pses)
      [(weld cs1 cs2) state]
    =/  pses  (~(get by sessions) sid.act)
    ?~  pses  `state
    =/  pv  (play:hl log.u.pses)
    =/  csid=session-id:h  (rap 3 'rehearse--' sid.act '--' call-id.act ~)
    =/  ccfg=config:h
      %=  config.pv
        ::  a rehearsal is sandboxed: it can read skills and run code,
        ::  but never mutate the live library, spawn, or reach peers
        ::
        tools   %+  skip  tools.config.pv
                |=(t=term ?=(?(%author %skill-write %subagents %peers) t))
        system  %+  rap  3
                :~  system.config.pv
                    ' You are a rehearsal: a sandboxed test of a skill named "'
                    name.act  '". Follow the skill and complete the task; '
                    'reply with only your final result.'
                ==
      ==
    =/  cses=session:h
      :_  0
      :~  (input-event [%rehearsal sid.act call-id.act name.act] `our.bowl `[%session sid.act call-id.act] [%user input.act])
          [%config-replaced ccfg]
      ==
    =.  subs  (~(put by subs) csid [sid.act call-id.act])
    =.  rehearsals  (~(put by rehearsals) csid name.act)
    =^  cards  state  (drive-put csid cses)
    [cards state]
  ::
      %commit-skill
    ::  promote a staged skill into the live library
    ::
    =/  s  (~(get by staged) name.act)
    ?~  s  `state
    :-  ~
    %=  state
      skills  (~(put by skills) name.act u.s)
      staged  (~(del by staged) name.act)
    ==
  ::
      %discard-skill
    `state(staged (~(del by staged) name.act))
  ::
      %timer-set
    =/  key  [sid.act name.act]
    =/  at=@da  (add now.bowl in.act)
    =/  old  (~(get by timers) key)
    :_  state(timers (~(put by timers) key [at every.act prompt.act]))
    %-  zing
    :~  ?~  old  ~
        ~[(rest-card sid.act name.act at.u.old)]
      ::
        ~[(wait-card sid.act name.act at)]
    ==
  ::
      %timer-cancel
    =/  key  [sid.act name.act]
    =/  old  (~(get by timers) key)
    ?~  old  `state
    :-  ~[(rest-card sid.act name.act at.u.old)]
    state(timers (~(del by timers) key))
  ::
      %skill-add
    `state(skills (~(put by skills) name.act [desc.act body.act]))
  ::
      %skill-del
    `state(skills (~(del by skills) name.act))
  ::
      %grant
    `state(peers (~(put by peers) ship.act grant.act))
  ::
      %revoke
    `state(peers (~(del by peers) ship.act))
  ::
      %set-key
    `state(api-key key.act)
  ::
      %peer-config
    =/  cfg=config:h  config.act
    =?  provider-keys  !=('' key.cfg)
      (~(put by provider-keys) (provider-for-url url.cfg) key.cfg)
    `state(peer-base `cfg(key ''))
  ::
      %defaults
    =/  cfg=config:h  config.act
    =?  provider-keys  !=('' key.cfg)
      (~(put by provider-keys) (provider-for-url url.cfg) key.cfg)
    `state(defaults cfg(key ''))
  ::
      %mcp-config
    =/  next=(map mcp-server-id:h mcp-server:h)
      (~(gas by *(map mcp-server-id:h mcp-server:h)) servers.act)
    `state(mcp-servers next)
  ::
      %ask-peer
    ::  internal, from our own drive loop: send a typed ask over ames
    ::  and start the timeout clock
    ::
    ?>  =(our.bowl src.bowl)
    ?.  (authorized-call sid.act call-id.act 'ask_peer')  `state
    =/  id=ask-id:h  `@uv`(end [3 16] (shas %a2a-ask eny.bowl))
    =.  asks  (~(put by asks) id [sid.act call-id.act ship.act])
    :_  state
    :~  :*  %pass  `wire`[%a2a %ask (scot %uv id) ~]
            %agent  [ship.act dap.bowl]  %poke
            %harness-a2a-0  !>(`a2a:h`[%ask id %text prompt.act])
        ==
        :*  %pass  `wire`[%a2a-timeout (scot %uv id) ~]
            %arvo  %b  %wait  (add now.bowl ~m2)
        ==
    ==
  ::
      %run-js
    ::  Native code execution is an optional hand and is not bundled.
    ?>  =(our.bowl src.bowl)
    ?.  (authorized-call sid.act call-id.act 'run_js')  `state
    =/  mses  (~(get by sessions) sid.act)
    ?~  mses  `state
    =^  cs1  u.mses
      %^  record-all  sid.act  u.mses
      ~[[%tool-completed call-id.act 'run_js' 'error: code execution is not installed']]
    =^  cs2  state  (drive-put sid.act u.mses)
    [(weld cs1 cs2) state]
  ==
::  +js-timeout: watchdog deadline for a run_js thread
::
++  js-timeout  ~s30
::  +watchdog-js: the deadline fired before the thread returned. stop
::  the spider thread and report a timeout. NB this only unwedges the
::  ship if the thread is between events (an i/o wait or a yielding
::  loop); a tight compute loop blocks until its event finishes
::
++  watchdog-js
  |=  tid=@ta
  ^-  (quip card _state)
  ?.  (~(has by jobs) tid)  `state
  =/  stop=card
    :*  %pass  `wire`[%jsstop tid ~]
        %agent  [our.bowl %spider]  %poke
        %spider-stop  !>([tid &])
    ==
  =^  cs  state
    (finish-js tid (rap 3 'error: js thread timed out after ' (scot %ud (div js-timeout ~s1)) 's' ~))
  ::  finish-js queues a %rest for the (already-fired) dog; harmless.
  ::  prepend the stop so the thread is actually killed
  ::
  [[stop cs] state]
::  +run-js-poke: a run_js tool call becomes a poke to ourselves
::
++  run-js-poke
  |=  [sid=session-id:h call-id=@t code=@t]
  ^-  card
  :*  %pass  `wire`[%runjs `@ta`sid `@ta`call-id ~]
      %agent  [our.bowl dap.bowl]  %poke
      %harness-action  !>(`action:h`[%run-js sid call-id code])
  ==
::  +rehearse-poke: a rehearse_skill tool call becomes a poke to ourselves
::
++  rehearse-poke
  |=  [sid=session-id:h call-id=@t name=@t input=@t]
  ^-  card
  :*  %pass  `wire`[%reh `@ta`sid `@ta`call-id ~]
      %agent  [our.bowl dap.bowl]  %poke
      %harness-action  !>(`action:h`[%rehearse sid call-id name input])
  ==
::  +finish-js: deliver a run_js result (or error) as a tool event,
::  clear the job, and cancel its watchdog
::
++  finish-js
  |=  [tid=@ta body=@t]
  ^-  (quip card _state)
  =/  job  (~(get by jobs) tid)
  ?~  job  `state
  =.  jobs  (~(del by jobs) tid)
  =/  stop=card  [%pass `wire`[%jsdog tid ~] %arvo %b %rest deadline.u.job]
  =/  mses  (~(get by sessions) sid.u.job)
  ?~  mses  [~[stop] state]
  ?.  (authorized-call sid.u.job call-id.u.job 'run_js')  [~[stop] state]
  =^  cs1  u.mses
    %^  record-all  sid.u.job  u.mses
    ~[[%tool-completed call-id.u.job 'run_js' body]]
  =^  cs2  state  (drive-put sid.u.job u.mses)
  [:(weld ~[stop] cs1 cs2) state]
::
++  wait-card
  |=  [sid=session-id:h name=@ta at=@da]
  ^-  card
  [%pass `wire`[%timer `@ta`sid name ~] %arvo %b %wait at]
::
++  rest-card
  |=  [sid=session-id:h name=@ta at=@da]
  ^-  card
  [%pass `wire`[%timer `@ta`sid name ~] %arvo %b %rest at]
::  +handle-timer-fire: a wakeup becomes ordinary admitted input
::
++  handle-timer-fire
  |=  [sid=session-id:h name=@ta err=(unit tang)]
  ^-  (quip card _state)
  =/  key  [sid name]
  =/  mt  (~(get by timers) key)
  ?~  mt  `state
  ?^  err
    ~&  [%harness-timer-error sid name]
    `state
  =/  mses  (~(get by sessions) sid)
  ?~  mses  `state(timers (~(del by timers) key))
  =/  ses  u.mses
  =/  event=event:h
    (input-event [%timer name] ~ ~ [%user (rap 3 '[timer %' name ' fired] ' prompt.u.mt ~)])
  =^  cs1  ses
    (record-all sid ses ~[event])
  =/  dr  (drive sid ses)
  =.  skills  sk.dr
  =.  staged  stg.dr
  =.  ses  ses.dr
  =/  rearm=[cs=(list card) nt=_timers]
    ?~  every.u.mt
      [~ (~(del by timers) key)]
    =/  at2=@da  (add now.bowl u.every.u.mt)
    :-  ~[(wait-card sid name at2)]
    (~(put by timers) key [at2 every.u.mt prompt.u.mt])
  :-  :(weld cs1 cards.dr cs.rearm)
  state(sessions (~(put by sessions) sid ses), timers nt.rearm)
::
++  need-session
  |=  sid=session-id:h
  ^-  session:h
  ~|  [%no-such-session sid]
  (~(got by sessions) sid)
::  +drive: replay, decide, act; loop until idle or pending.
::  skill-writing tools mutate the agent-level library, so drive
::  mutates the subject's skills as it loops (later iterations see
::  the update) and returns the final map for the caller to persist
::
++  drive
  |=  [sid=session-id:h ses=session:h]
  ^-  [cards=(list card) ses=session:h sk=(map @t skill:h) stg=(map @t skill:h)]
  =|  cards=(list card)
  |-  ^-  [cards=(list card) ses=session:h sk=(map @t skill:h) stg=(map @t skill:h)]
  =/  v=view:h  (play:hl log.ses)
  =/  stp  (decide:hl v (skills-visible sid skills))
  ?~  stp  [cards ses skills staged]
  ?-  -.u.stp
      %tools
    ::  sync tools run on-ship now; async tools (iris) record a
    ::  request marker and their results re-enter as events.
    ::  skill mutations fold through the accumulator so a write is
    ::  visible to a read later in the same batch; only the event
    ::  enters the log (skill content lives in state, that's the point)
    ::
    =/  acc
      %+  roll  calls.u.stp
      |:  [c=*tool-call:h acc=[evs=*(list event:h) tcards=*(list card) sk=skills stg=staged]]
      ^+  acc
      ?.  (tool-granted:hl name.c tools.config.v)
        %=  acc  evs
          %+  snoc  evs.acc
          `event:h`[%tool-completed id.c name.c 'rejected: tool is not granted for this session']
        ==
      ?:  =(name.c 'write_skill')
        =/  nam  (tool-str args.c 'name')
        =/  dsc  (tool-str args.c 'description')
        =/  bod  (tool-str args.c 'body')
        =/  bad
          %=  acc  evs
            %+  snoc  evs.acc
            `event:h`[%tool-completed id.c name.c 'error: need name, description, body']
          ==
        ?~  nam  bad
        ?~  dsc  bad
        ?~  bod  bad
        %=  acc
          sk   (~(put by sk.acc) u.nam [u.dsc u.bod])
          evs  %+  snoc  evs.acc
               `event:h`[%tool-completed id.c name.c (rap 3 'skill \'' u.nam '\' written' ~)]
        ==
      ?:  =(name.c 'delete_skill')
        =/  nam  (tool-str args.c 'name')
        ?~  nam
          %=  acc  evs
            %+  snoc  evs.acc
            `event:h`[%tool-completed id.c name.c 'error: bad name argument']
          ==
        ?.  (~(has by sk.acc) u.nam)
          %=  acc  evs
            %+  snoc  evs.acc
            `event:h`[%tool-completed id.c name.c (cat 3 'error: no such skill: ' u.nam)]
          ==
        %=  acc
          sk   (~(del by sk.acc) u.nam)
          evs  %+  snoc  evs.acc
               `event:h`[%tool-completed id.c name.c (rap 3 'skill \'' u.nam '\' deleted' ~)]
        ==
      ::  governed self-modification: propose stages a skill, commit
      ::  promotes staged->live, discard drops it. rehearse is async
      ::  (spawns a sandboxed child) and self-pokes below
      ::
      ?:  =(name.c 'propose_skill')
        =/  nam  (tool-str args.c 'name')
        =/  dsc  (tool-str args.c 'description')
        =/  bod  (tool-str args.c 'body')
        ?.  &(?=(^ nam) ?=(^ dsc) ?=(^ bod))
          acc(evs (snoc evs.acc [%tool-completed id.c name.c 'error: need name, description, body']))
        %=  acc
          stg  (~(put by stg.acc) u.nam [u.dsc u.bod])
          evs  %+  snoc  evs.acc
               `event:h`[%tool-completed id.c name.c (rap 3 'skill \'' u.nam '\' staged — rehearse it before committing' ~)]
        ==
      ?:  =(name.c 'commit_skill')
        =/  nam  (tool-str args.c 'name')
        ?~  nam
          acc(evs (snoc evs.acc [%tool-completed id.c name.c 'error: bad name argument']))
        ?.  (~(has by stg.acc) u.nam)
          acc(evs (snoc evs.acc [%tool-completed id.c name.c (cat 3 'error: nothing staged named ' u.nam)]))
        %=  acc
          sk   (~(put by sk.acc) u.nam (~(got by stg.acc) u.nam))
          stg  (~(del by stg.acc) u.nam)
          evs  %+  snoc  evs.acc
               `event:h`[%tool-completed id.c name.c (rap 3 'skill \'' u.nam '\' committed to the live library' ~)]
        ==
      ?:  =(name.c 'discard_skill')
        =/  nam  (tool-str args.c 'name')
        ?~  nam
          acc(evs (snoc evs.acc [%tool-completed id.c name.c 'error: bad name argument']))
        %=  acc
          stg  (~(del by stg.acc) u.nam)
          evs  %+  snoc  evs.acc
               `event:h`[%tool-completed id.c name.c (rap 3 'staged skill \'' u.nam '\' discarded' ~)]
        ==
      ?:  =(name.c 'rehearse_skill')
        =/  nam  (tool-str args.c 'name')
        =/  inp  (tool-str args.c 'input')
        ?.  &(?=(^ nam) ?=(^ inp))
          acc(evs (snoc evs.acc [%tool-completed id.c name.c 'error: need name and input']))
        %=  acc
          evs     (snoc evs.acc `event:h`[%tool-requested id.c name.c])
          tcards  (snoc tcards.acc (rehearse-poke sid id.c u.nam u.inp))
        ==
      ::  run_js: reject synchronously on the loop guard or bad args so
      ::  the model gets immediate feedback; otherwise self-poke to spawn
      ::  the thread (needs state access to record the tid)
      ::
      ?:  =(name.c 'run_js')
        =/  code  (tool-str args.c 'code')
        ?~  code
          acc(evs (snoc evs.acc [%tool-completed id.c name.c 'error: need code argument']))
        =/  reject  (js-loop-guard:hl u.code)
        ?^  reject
          acc(evs (snoc evs.acc [%tool-completed id.c name.c u.reject]))
        %=  acc
          evs     (snoc evs.acc `event:h`[%tool-requested id.c name.c])
          tcards  (snoc tcards.acc (run-js-poke sid id.c u.code))
        ==
      =/  async=(unit (unit card))
        ?:  =(name.c 'http_fetch')     `(fetch-card sid c)
        ?:  |(=(name.c 'list_mcp_tools') =(name.c 'call_mcp_tool'))
          `(mcp-card sid c)
        ?:  =(name.c 'run_subagent')   `(spawn-card sid c)
        ?:  =(name.c 'ask_peer')       `(ask-peer-card sid c)
        ~
      ?~  async
        acc(evs (snoc evs.acc (run-tool c (skills-visible sid sk.acc))))
      ?~  u.async
        %=  acc  evs
          %+  snoc  evs.acc
          `event:h`[%tool-completed id.c name.c 'error: bad tool arguments']
        ==
      %=  acc
        evs     (snoc evs.acc `event:h`[%tool-requested id.c name.c])
        tcards  (snoc tcards.acc u.u.async)
      ==
    =.  skills  sk.acc
    =.  staged  stg.acc
    =^  cs  ses  (record-all sid ses evs.acc)
    $(cards :(weld cards cs tcards.acc))
  ::
      %turn
    =^  cs  ses  (issue-llm sid ses %turn v)
    $(cards (weld cards cs))
  ::
      %compact
    =^  cs  ses  (issue-llm sid ses %compaction v)
    $(cards (weld cards cs))
  ::
      %halt
    ::  record the halt (sets err, stops the loop) and stop driving
    ::
    =^  cs  ses  (record-all sid ses ~[[%halted reason.u.stp]])
    [(weld cards cs) ses skills staged]
  ==
::  +issue-llm: record the request marker and pass to iris
::
++  issue-llm
  |=  [sid=session-id:h ses=session:h kind=request-kind:h v=view:h]
  ^-  [(list card) session:h]
  =/  req  next-req.ses
  =.  next-req.ses  +(req)
  =^  cs  ses  (record-all sid ses ~[[%llm-requested req kind]])
  [(snoc cs (llm-card sid req kind v)) ses]
::
++  provider-for-url
  |=  url=@t
  ^-  @t
  ?:  =('https://openrouter.ai/api/v1/chat/completions' url)  'openrouter'
  ?:  =('https://api.openai.com/v1/chat/completions' url)     'openai'
  ?:  =('https://chatgpt.com/backend-api/codex/responses' url)  'openai'
  ?:  =('https://api.anthropic.com/v1/chat/completions' url)  'anthropic'
  'custom'
++  provider-key
  |=  provider=@t
  ^-  @t
  =/  stored=@t  (fall (~(get by provider-keys) provider) '')
  ?:  !=('' stored)  stored
  ?:(=('openrouter' provider) api-key '')
++  model-list-card
  |=  [req=@ud provider=@t url=@t]
  ^-  card
  =/  key=@t  (provider-key provider)
  =/  hed=header-list:http  ~[['accept' 'application/json']]
  =?  hed  !=('' key)
    [['authorization' (cat 3 'Bearer ' key)] hed]
  =/  account  (provider-key 'openai-account')
  =?  hed  ?&  !=('' account)
                  =('openai' provider)
                  =('https://chatgpt.com/backend-api/codex/models?client_version=0.153.0' url)
              ==
    [['chatgpt-account-id' account] hed]
  :*  %pass  `wire`[%models (scot %ud req) ~]
      %arvo  %i  %request  [%'GET' url hed ~]  *outbound-config:iris
  ==
::
++  llm-card
  |=  [sid=session-id:h req=@ud kind=request-kind:h v=view:h]
  ^-  card
  =/  responses=?  =('https://chatgpt.com/backend-api/codex/responses' url.config.v)
  =/  payload=json
    ?:(responses (responses-body:hl v kind (skills-visible sid skills)) (request-body:hl v kind (skills-visible sid skills)))
  =/  body=@t  (en:json:html payload)
  ::  blank session key falls back to the agent-level default
  ::
  =/  eff-key=@t
    ?:(=('' key.config.v) (provider-key (provider-for-url url.config.v)) key.config.v)
  =/  =request:http
    :*  %'POST'
        url.config.v
        =/  hed=header-list:http
          [['content-type' 'application/json'] headers.config.v]
        =?  hed  !=('' eff-key)
          [['authorization' (cat 3 'Bearer ' eff-key)] hed]
        hed
        `(as-octs:mimes:html body)
    ==
  :*  %pass  `wire`[%llm `@ta`sid (scot %ud req) kind ~]
      %arvo  %i  %request  request  *outbound-config:iris
  ==
::  +handle-llm-response: digest an iris sign back into events
::
++  handle-llm-response
  |=  $:  sid=session-id:h
          req=@ud
          kind=request-kind:h
          res=client-response:iris
      ==
  ^-  (quip card _state)
  =/  mses  (~(get by sessions) sid)
  ?~  mses  `state
  =/  ses  u.mses
  =/  v  (play:hl log.ses)
  ::  ignore stale responses (cancelled or forked-away requests)
  ::
  ?~  pending.v  `state
  ?.  =(req.u.pending.v req)  `state
  ?:  ?=(%progress -.res)
    =/  incremental  incremental.res
    ?~  incremental  `state
    =/  key  [sid req]
    =/  prior=stream-progress  (fall (~(get by streams) key) ['' 0])
    =/  body=@t  (cat 3 body.prior q.u.incremental)
    =/  responses=?
      =('https://chatgpt.com/backend-api/codex/responses' url.config.v)
    =/  text=@t  (stream-text:hl body responses)
    =/  total=@ud  (met 3 text)
    =/  sent=@ud  sent.prior
    =.  streams  (~(put by streams) key [body total])
    ?.  (gth total sent)  `state
    =/  delta=@t  (cut 3 [sent (sub total sent)] text)
    =/  prompt  (~(get by acp-prompts) sid)
    ?~  prompt  `state
    [~[(acp-stream-card connection.u.prompt sid delta)] state]
  =.  streams  (~(del by streams) [sid req])
  =/  ev=event:h
    ?:  ?=(%cancel -.res)
      [%llm-failed req 'request cancelled by runtime']
    =/  status  status-code.response-header.res
    =/  body=(unit @t)
      ?~  full-file.res  ~
      `q.data.u.full-file.res
    ?.  &((gte status 200) (lth status 300))
      :+  %llm-failed  req
      %+  rap  3
      :~  'http error '
          (scot %ud status)
          ': '
          (fall body '')
      ==
    ?~  body  [%llm-failed req 'empty response body']
    =/  responses=?  =('https://chatgpt.com/backend-api/codex/responses' url.config.v)
    =/  digest
      ?:  responses
        (mule |.((parse-responses-sse:hl u.body)))
      =/  streamed  (mule |.((parse-chat-sse:hl u.body)))
      ?:  ?&  ?=(%& -.streamed)
              ?=(%& -.p.streamed)
          ==
        streamed
      =/  jon  (de:json:html u.body)
      ?~  jon  [%| 'invalid json in response']
      (mule |.((parse-response:hl u.jon)))
    ?:  ?=(%| -.digest)
      [%llm-failed req 'failed to digest response']
    =/  out  p.digest
    ?:  ?=(%| -.out)  [%llm-failed req p.out]
    ?:  ?=(%compaction kind)
      ?>  ?=(%assistant -.it.p.out)
      [%compaction-completed req body.it.p.out]
    [%llm-completed req stop.p.out u.p.out it.p.out]
  =^  cs1  ses  (record-all sid ses ~[ev])
  =^  cs2  state  (drive-put sid ses)
  [(weld cs1 cs2) state]
::
++  handle-model-response
  |=  [req=@ud res=client-response:iris]
  ^-  (quip card _state)
  ?:  ?=(%progress -.res)  `state
  =/  pending  (~(get by model-requests) req)
  ?~  pending  `state
  =.  model-requests  (~(del by model-requests) req)
  ?:  ?=(%cancel -.res)
    [~[(acp-error-card connection.u.pending request-id.u.pending '-32603' 'Model catalog request was cancelled')] state]
  =/  status  status-code.response-header.res
  =/  body=(unit @t)
    ?~  full-file.res  ~
    `q.data.u.full-file.res
  ?.  &((gte status 200) (lth status 300))
    [~[(acp-error-card connection.u.pending request-id.u.pending '-32603' (cat 3 'Model catalog returned HTTP ' (scot %ud status)))] state]
  ?~  body
    [~[(acp-error-card connection.u.pending request-id.u.pending '-32603' 'Model catalog returned an empty response')] state]
  =/  jon  (de:json:html u.body)
  ?~  jon
    [~[(acp-error-card connection.u.pending request-id.u.pending '-32603' 'Model catalog returned invalid JSON')] state]
  =/  parsed  (mole |.((parse-model-list u.jon)))
  ?~  parsed
    [~[(acp-error-card connection.u.pending request-id.u.pending '-32603' 'Model catalog has an unsupported shape')] state]
  =/  info=(list model-info)  u.parsed
  =/  result=json
    %-  pairs:enjs:format
    :~  ['models' %a (turn info |=(model=model-info `json`[%s id.model]))]
        ['modelInfo' %a (turn info model-info-json)]
    ==
  [~[(acp-result-card connection.u.pending request-id.u.pending result)] state]
::
++  model-info-json
  |=  model=model-info
  ^-  json
  %-  pairs:enjs:format
  :~  ['id' %s id.model]
      ['contextWindow' ?~(context.model ~ (numb:enjs:format u.context.model))]
  ==
::
++  parse-model-list
  |=  jon=json
  ^-  (list model-info)
  ?>  ?=([%o *] jon)
  =/  data  (~(get by p.jon) 'data')
  =/  models  (~(get by p.jon) 'models')
  =/  rows=(list json)
    ?:  ?=([~ %a *] data)  p.u.data
    ?:  ?=([~ %a *] models)  p.u.models
    ~
  ?>  ?=(^ rows)
  %+  murn  rows
  |=  item=json
  ^-  (unit model-info)
  ?.  ?=([%o *] item)  ~
  =/  id  (~(get by p.item) 'id')
  =/  slug  (~(get by p.item) 'slug')
  =/  name=(unit @t)
    ?:  ?=([~ %s *] id)  `p.u.id
    ?:(?=([~ %s *] slug) `p.u.slug ~)
  ?~  name  ~
  `[u.name (model-context p.item)]
::
++  model-context
  |=  row=(map @t json)
  ^-  (unit @ud)
  =/  direct
    %+  first-json  row
    :~  'context_length'  'context_window'  'contextWindow'
        'max_input_tokens'  'max_context_length'  'max_context_tokens'
    ==
  =/  parsed  (json-ud direct)
  ?^  parsed  parsed
  =/  top  (~(get by row) 'top_provider')
  ?.  ?=([~ %o *] top)  ~
  (json-ud (first-json p.u.top ~['context_length' 'context_window']))
::
++  first-json
  |=  [row=(map @t json) names=(list @t)]
  ^-  (unit json)
  |-
  ?~  names  ~
  =/  value  (~(get by row) i.names)
  ?^(value value $(names t.names))
::
++  json-ud
  |=  value=(unit json)
  ^-  (unit @ud)
  ?~  value  ~
  ?:  ?=(%n -.u.value)  (rush p.u.value dem)
  ?:  ?=(%s -.u.value)  (rush p.u.value dem)
  ~
::  +record-all: append events to the log, give facts to subscribers
::
++  record-all
  |=  [sid=session-id:h ses=session:h evs=(list event:h)]
  ^-  [(list card) session:h]
  =|  cs=(list card)
  |-  ^-  [(list card) session:h]
  ?~  evs  [(flop cs) ses]
  %=  $
    evs      t.evs
    log.ses  [i.evs log.ses]
    cs       :_  cs
             :*  %give  %fact  ~[`path`[%session `@ta`sid ~]]
                 %harness-update  !>(`update:h`[%event sid i.evs])
             ==
  ==
::  +input-event: stamp the common admission envelope at the boundary. The
::  identifier is stable data in the event, not an index inferred by a client.
::
++  input-event
  |=  $:  source=input-source:h
          actor=(unit @p)
          reply=(unit reply-target:h)
          item=item:h
      ==
  ^-  event:h
  =/  id=input-id:h
    `@uv`(end [3 16] (shas %harness-input (jam [eny.bowl now.bowl source actor reply item])))
  [%input-received [id source actor reply now.bowl item]]
::  +requested-tool / +authorized-call: internal self-pokes are still pokes,
::  so execution checks both a durable request marker and the current grant.
::
++  requested-tool
  |=  [ses=session:h call-id=@t]
  ^-  (unit @t)
  =/  events  log.ses
  |-  ^-  (unit @t)
  ?~  events  ~
  ?:  ?&  ?=(%tool-requested -.i.events)
           =(call-id call-id.i.events)
       ==
    `name.i.events
  $(events t.events)
++  authorized-call
  |=  [sid=session-id:h call-id=@t name=@t]
  ^-  ?
  =/  maybe  (~(get by sessions) sid)
  ?~  maybe  |
  =/  v  (play:hl log.u.maybe)
  ?.  (~(has in wait.v) call-id)  |
  ?.  (tool-granted:hl name tools.config.v)  |
  =/  requested  (requested-tool u.maybe call-id)
  ?~  requested  |
  =(name u.requested)
::  +run-tool: sync tools execute on-ship, immediately.
::  sk is the current skill library (possibly mutated earlier in the
::  same tool batch), so reads see fresh writes
::
++  run-tool
  |=  [c=tool-call:h sk=(map @t skill:h)]
  ^-  event:h
  =/  out=@t
    ?:  =(name.c 'get_ship_time')
      (scot %da now.bowl)
    ?:  =(name.c 'read_desk_file')
      (read-desk-file args.c)
    ?:  =(name.c 'list_desk_files')
      (list-desk-files args.c)
    ?:  =(name.c 'read_skill')
      (read-skill args.c sk)
    (cat 3 'unknown tool: ' name.c)
  [%tool-completed id.c name.c out]
::  +read-skill: fetch a skill body from the library
::
++  read-skill
  |=  [args=@t sk=(map @t skill:h)]
  ^-  @t
  =/  nam  (tool-str args 'name')
  ?~  nam  'error: bad name argument'
  =/  s  (~(get by sk) u.nam)
  ?~  s  (cat 3 'error: no such skill: ' u.nam)
  body.u.s
::  +tool-str: pull a string field out of tool-call arguments
::
++  tool-str
  |=  [args=@t key=@t]
  ^-  (unit @t)
  =/  jon  (de:json:html args)
  ?~  jon  ~
  ?.  ?=([%o *] u.jon)  ~
  =/  v  (~(get by p.u.jon) key)
  ?:(?=([~ %s *] v) `p.u.v ~)
::  +tool-path: pull a clay path out of tool-call arguments
::
++  tool-path
  |=  args=@t
  ^-  (unit path)
  =/  jon  (de:json:html args)
  ?~  jon  ~
  ?.  ?=([%o *] u.jon)  ~
  =/  p  (~(get by p.u.jon) 'path')
  ?.  ?=([~ %s *] p)  ~
  (rush p.u.p stap)
::
++  read-desk-file
  |=  args=@t
  ^-  @t
  =/  pax  (tool-path args)
  ?~  pax  'error: bad path argument'
  ?.  ?=([@ @ *] u.pax)  'error: path must be /desk/spur/file/ext'
  =/  bas=path  /(scot %p our.bowl)/[i.u.pax]/(scot %da now.bowl)
  =/  spur=path  t.u.pax
  =/  res
    %-  mole  |.
    ?.  .^(? %cu (weld bas spur))  'error: no such file'
    =/  ext  (rear spur)
    =/  =tube:clay  .^(tube:clay %cc (weld bas /[ext]/mime))
    =/  =mime  !<(mime (tube .^(vase %cr (weld bas spur))))
    (clip:hl q.q.mime 50.000)
  ?~  res  'error: could not read file'
  u.res
::
++  list-desk-files
  |=  args=@t
  ^-  @t
  =/  pax  (tool-path args)
  ?~  pax  'error: bad path argument'
  ?~  u.pax  'error: need at least /desk'
  =/  bas=path  /(scot %p our.bowl)/[i.u.pax]/(scot %da now.bowl)
  =/  res
    %-  mole  |.
    =/  paths  .^((list path) %ct (weld bas t.u.pax))
    %+  clip:hl
      (crip (zing (turn paths |=(p=path (weld (spud p) "\0a")))))
    50.000
  ?~  res  'error: could not list directory'
  u.res
::  +mcp-card: a generic MCP discovery/call becomes an iris request.
::  This hand targets stateless Streamable HTTP servers: identity and
::  credentials remain agent configuration, while results enter the log.
::
++  mcp-card
  |=  [sid=session-id:h c=tool-call:h]
  ^-  (unit card)
  =/  server-id  (tool-str args.c 'server')
  ?~  server-id  ~
  =/  configured  (~(get by mcp-servers) u.server-id)
  ?~  configured  ~
  ?.  enabled.u.configured  ~
  =/  method=@t
    ?:(=('list_mcp_tools' name.c) 'tools/list' 'tools/call')
  =/  params=json
    ?:  =('list_mcp_tools' name.c)
      (pairs:enjs:format ~)
    =/  tool-name  (tool-str args.c 'name')
    =/  arguments  (tool-str args.c 'arguments')
    ?~  tool-name  ~
    =/  parsed=(unit json)
      ?~(arguments `(pairs:enjs:format ~) (de:json:html u.arguments))
    ?~  parsed  ~
    %-  pairs:enjs:format
    :~  ['name' %s u.tool-name]
        ['arguments' u.parsed]
    ==
  =/  payload=json
    %-  pairs:enjs:format
    :~  ['jsonrpc' %s '2.0']
        ['id' (numb:enjs:format 1)]
        ['method' %s method]
        ['params' params]
    ==
  =/  hed=header-list:http
    :~  ['content-type' 'application/json']
        ['accept' 'application/json, text/event-stream']
    ==
  =.  hed  (weld headers.u.configured hed)
  =/  =request:http
    [%'POST' url.u.configured hed `(as-octs:mimes:html (en:json:html payload))]
  :-  ~
  :*  %pass  `wire`[%tool `@ta`sid `@ta`id.c ~]
      %arvo  %i  %request  request  *outbound-config:iris
  ==
::  +fetch-card: an http_fetch tool call becomes an iris request
::
++  fetch-card
  |=  [sid=session-id:h c=tool-call:h]
  ^-  (unit card)
  =/  jon  (de:json:html args.c)
  ?~  jon  ~
  ?.  ?=([%o *] u.jon)  ~
  =/  url  (~(get by p.u.jon) 'url')
  ?.  ?=([~ %s *] url)  ~
  =/  method=method:http
    =/  m  (~(get by p.u.jon) 'method')
    ?:(&(?=([~ %s *] m) =('POST' p.u.m)) %'POST' %'GET')
  =/  body=(unit octs)
    =/  b  (~(get by p.u.jon) 'body')
    ?.  ?=([~ %s *] b)  ~
    `(as-octs:mimes:html p.u.b)
  =/  hdrs=header-list:http
    ?~(body ~ ~[['content-type' 'application/json']])
  =/  =request:http  [method p.u.url hdrs body]
  :-  ~
  :*  %pass  `wire`[%tool `@ta`sid `@ta`id.c ~]
      %arvo  %i  %request  request  *outbound-config:iris
  ==
::  +handle-tool-response: an async tool result re-enters as an event
::
++  handle-tool-response
  |=  [sid=session-id:h call-id=@t res=client-response:iris]
  ^-  (quip card _state)
  ?:  ?=(%progress -.res)  `state
  =/  mses  (~(get by sessions) sid)
  ?~  mses  `state
  =/  ses  u.mses
  =/  v  (play:hl log.ses)
  ::  ignore stale results (cancelled or forked-away requests)
  ::
  ?.  (~(has in wait.v) call-id)  `state
  =/  body=@t
    ?:  ?=(%cancel -.res)  'error: request cancelled by runtime'
    =/  status  status-code.response-header.res
    =/  txt=@t
      ?~  full-file.res  ''
      (clip:hl q.data.u.full-file.res 8.000)
    (rap 3 'HTTP ' (scot %ud status) '\0a\0a' txt ~)
  =/  tname=@t
    |-  ^-  @t
    ?~  log.ses  'http_fetch'
    ?:  ?&(?=(%tool-requested -.i.log.ses) =(call-id call-id.i.log.ses))
      name.i.log.ses
    $(log.ses t.log.ses)
  =^  cs1  ses  (record-all sid ses ~[[%tool-completed call-id tname body]])
  =^  cs2  state  (drive-put sid ses)
  [(weld cs1 cs2) state]
::  +drive-put: drive a session, store it, then settle subagent links
::
++  drive-put
  |=  [sid=session-id:h ses=session:h]
  ^-  (quip card _state)
  =/  dr  (drive sid ses)
  =.  skills  sk.dr
  =.  staged  stg.dr
  =.  sessions  (~(put by sessions) sid ses.dr)
  =^  cs2  state  (settle sid)
  [:(weld cards.dr ~[(shadow-put-card sid ses.dr)] cs2) state]
::  +settle: when a session goes idle, deliver what it owes:
::  a finished subagent's answer to its parent, and answers for
::  any peer asks queued against it
::
++  settle
  |=  sid=session-id:h
  ^-  (quip card _state)
  =^  cs1  state  (settle-sub sid)
  =^  cs2  state  (settle-asks sid)
  =^  cs3  state  (settle-acp sid)
  [:(weld cs1 cs2 cs3) state]
::
++  settle-acp
  |=  sid=session-id:h
  ^-  (quip card _state)
  =/  prompt  (~(get by acp-prompts) sid)
  ?~  prompt  `state
  =/  mses  (~(get by sessions) sid)
  ?~  mses  `state(acp-prompts (~(del by acp-prompts) sid))
  =/  v  (play:hl log.u.mses)
  =/  updates  (acp-item-cards connection.u.prompt sid cursor.u.prompt items.v)
  =.  acp-prompts
    (~(put by acp-prompts) sid [connection.u.prompt request-id.u.prompt (lent items.v)])
  ?^  pending.v  [updates state]
  ?.  =(~ wait.v)  [updates state]
  =.  acp-prompts  (~(del by acp-prompts) sid)
  ?^  err.v
    [(weld updates ~[(acp-error-card connection.u.prompt request-id.u.prompt '-32603' u.err.v)]) state]
  ?~  items.v
    [(weld updates ~[(acp-error-card connection.u.prompt request-id.u.prompt '-32603' 'Prompt ended without a response')]) state]
  =/  last  (rear items.v)
  ?.  ?=([%assistant * ~] last)
    [(weld updates ~[(acp-error-card connection.u.prompt request-id.u.prompt '-32603' 'Prompt ended without a response')]) state]
  =/  stop=@t  (acp-stop-reason log.u.mses)
  =/  result=json  (pairs:enjs:format ~[['stopReason' %s stop]])
  =/  finish=card  (acp-result-card connection.u.prompt request-id.u.prompt result)
  [(weld updates ~[finish]) state]
::
++  acp-stop-reason
  |=  log=(list event:h)
  ^-  @t
  ?~  log  'end_turn'
  ?:  ?=(%llm-completed -.i.log)
    ?:(=(%length stop.i.log) 'max_tokens' 'end_turn')
  $(log t.log)
::
++  settle-sub
  |=  sid=session-id:h
  ^-  (quip card _state)
  =/  link  (~(get by subs) sid)
  ?~  link  `state
  =/  mses  (~(get by sessions) sid)
  ?~  mses  `state
  =/  v  (play:hl log.u.mses)
  ?^  pending.v  `state
  ?.  =(~ wait.v)  `state
  =/  result=(unit @t)
    ?^  err.v  `(cat 3 'subagent error: ' u.err.v)
    ?~  items.v  ~
    =/  last  (rear items.v)
    ?:  &(?=(%assistant -.last) =(~ calls.last))
      `body.last
    ~
  ?~  result  `state
  ::  a rehearsal child answers a rehearse_skill call and is disposable;
  ::  an ordinary subagent answers run_subagent and is kept
  ::
  =/  reh  (~(get by rehearsals) sid)
  =/  tool-name=@t  ?~(reh 'run_subagent' 'rehearse_skill')
  =.  subs  (~(del by subs) sid)
  =?  rehearsals  ?=(^ reh)  (~(del by rehearsals) sid)
  =?  sessions    ?=(^ reh)  (~(del by sessions) sid)
  =/  mp  (~(get by sessions) parent.u.link)
  ?~  mp  `state
  ?.  (authorized-call parent.u.link call-id.u.link tool-name)  `state
  =^  cs1  u.mp
    %^  record-all  parent.u.link  u.mp
    ~[[%tool-completed call-id.u.link tool-name u.result]]
  =^  cs2  state  (drive-put parent.u.link u.mp)
  ::  kick the disposed rehearsal child's ui subscription
  =/  kick=(list card)
    ?~  reh  ~
    ~[[%give %kick ~[`path`[%session `@ta`sid ~]] ~]]
  [:(weld kick cs1 cs2) state]
::  +settle-asks: answer every peer ask queued against an idle session
::
++  settle-asks
  |=  sid=session-id:h
  ^-  (quip card _state)
  =/  q  (~(get by serving) sid)
  ?~  q  `state
  ?~  u.q  `state(serving (~(del by serving) sid))
  =/  mses  (~(get by sessions) sid)
  ?~  mses  `state
  =/  v  (play:hl log.u.mses)
  ?^  pending.v  `state
  ?.  =(~ wait.v)  `state
  =/  result=(unit (each @t @t))
    ?^  err.v  `[%| (cat 3 'error: ' u.err.v)]
    ?~  items.v  ~
    =/  last  (rear items.v)
    ?:  &(?=(%assistant -.last) =(~ calls.last))
      `[%& body.last]
    ~
  ?~  result  `state
  :_  state(serving (~(del by serving) sid))
  %+  turn  u.q
  |=  [=ship id=ask-id:h]
  (answer-card ship id u.result)
::  +handle-a2a: the wire protocol, both directions
::
++  handle-a2a
  |=  [src=ship msg=a2a:h]
  ^-  (quip card _state)
  ?-  -.msg
      %answer
    =/  ma  (~(get by asks) id.msg)
    ?~  ma  `state
    ?.  =(src ship.u.ma)  `state
    =.  asks  (~(del by asks) id.msg)
    =/  mses  (~(get by sessions) sid.u.ma)
    ?~  mses  `state
    ?.  (authorized-call sid.u.ma call-id.u.ma 'ask_peer')  `state
    =/  body=@t
      ?:  ?=(%& -.result.msg)  p.result.msg
      (cat 3 'peer error: ' p.result.msg)
    =^  cs1  u.mses
      %^  record-all  sid.u.ma  u.mses
      ~[[%tool-completed call-id.u.ma 'ask_peer' body]]
    =^  cs2  state  (drive-put sid.u.ma u.mses)
    [(weld cs1 cs2) state]
  ::
      %ask
    ::  identity is the permission: no grant, no service
    ::
    =/  g  (~(get by peers) src)
    ?~  g
      [~[(answer-card src id.msg [%| 'no grant for your ship'])] state]
    =/  mbase  peer-base
    ?~  mbase
      [~[(answer-card src id.msg [%| 'peer serving not configured'])] state]
    =/  base  u.mbase
    =/  sid=session-id:h  (cat 3 'peer--' (scot %p src))
    =/  mses  (~(get by sessions) sid)
    ?:  ?&  !=(0 budget.u.g)
            ?=(^ mses)
            =/  v  (play:hl log.u.mses)
            (gte (add prompt.total.v completion.total.v) budget.u.g)
        ==
      [~[(answer-card src id.msg [%| 'budget exhausted'])] state]
    ::  the durable per-peer session runs under the grant, refreshed
    ::  each ask so grant changes take effect
    ::
    =/  cfg=config:h
      %=  base
        model   (fall model.u.g model.base)
        tools   tools.u.g
        system  %+  rap  3
                :~  system.base
                    ' You are answering an ask from the agent of '
                    (scot %p src)
                ==
      ==
    =/  ses=session:h  (fall mses [~[[%config-replaced cfg]] 0])
    =/  event=event:h
      (input-event [%peer src id.msg] `src `[%peer src id.msg] [%user prompt.msg])
    =^  cs1  ses
      %^  record-all  sid  ses
      ?~  mses
        ~[event]
      :~  [%config-replaced cfg]
          event
      ==
    =.  serving
      %+  ~(put by serving)  sid
      [[src id.msg] (fall (~(get by serving) sid) ~)]
    =^  cs2  state  (drive-put sid ses)
    [(weld cs1 cs2) state]
  ==
::  +answer-card: send a typed answer back over ames
::
++  answer-card
  |=  [=ship id=ask-id:h result=(each @t @t)]
  ^-  card
  :*  %pass  `wire`[%a2a %answer (scot %uv id) ~]
      %agent  [ship dap.bowl]  %poke
      %harness-a2a-0  !>(`a2a:h`[%answer id result])
  ==
::  +fail-ask: a nack or timeout becomes an error tool result
::
++  fail-ask
  |=  [id=ask-id:h why=@t]
  ^-  (quip card _state)
  =/  ma  (~(get by asks) id)
  ?~  ma  `state
  =.  asks  (~(del by asks) id)
  =/  mses  (~(get by sessions) sid.u.ma)
  ?~  mses  `state
  ?.  (authorized-call sid.u.ma call-id.u.ma 'ask_peer')  `state
  =^  cs1  u.mses
    %^  record-all  sid.u.ma  u.mses
    ~[[%tool-completed call-id.u.ma 'ask_peer' (cat 3 'error: ' why)]]
  =^  cs2  state  (drive-put sid.u.ma u.mses)
  [(weld cs1 cs2) state]
::  +ask-peer-card: an ask_peer tool call becomes a poke to ourselves
::
++  ask-peer-card
  |=  [sid=session-id:h c=tool-call:h]
  ^-  (unit card)
  =/  shp  (tool-str args.c 'ship')
  =/  prm  (tool-str args.c 'prompt')
  ?~  shp  ~
  ?~  prm  ~
  =/  who=(unit @p)
    %+  slaw  %p
    ?:(=('~' (end [3 1] u.shp)) u.shp (cat 3 '~' u.shp))
  ?~  who  ~
  :-  ~
  :*  %pass  `wire`[%aski `@ta`sid `@ta`id.c ~]
      %agent  [our.bowl dap.bowl]  %poke
      %harness-action  !>(`action:h`[%ask-peer sid id.c u.who u.prm])
  ==
::  +skills-visible: what skills a session may see.
::  - a rehearsal child additionally sees the one staged skill it tests
::  - a peer session sees only its grant's inflows
::  - any other session sees the full live library
::
++  skills-visible
  |=  [sid=session-id:h sk=(map @t skill:h)]
  ^-  (map @t skill:h)
  =/  reh  (~(get by rehearsals) sid)
  ?^  reh
    =/  staged-one  (~(get by staged) u.reh)
    ?~  staged-one  sk
    (~(put by sk) u.reh u.staged-one)
  ?.  =('peer--' (end [3 6] sid))  sk
  =/  pship  (slaw %p (rsh [3 6] sid))
  ?~  pship  ~
  =/  g  (~(get by peers) u.pship)
  ?~  g  ~
  %-  malt
  %+  skim  ~(tap by sk)
  |=  [n=@t s=skill:h]
  (~(has in inflows.u.g) n)
::  +spawn-card: a run_subagent tool call becomes a poke to ourselves
::
++  spawn-card
  |=  [sid=session-id:h c=tool-call:h]
  ^-  (unit card)
  =/  jon  (de:json:html args.c)
  ?~  jon  ~
  ?.  ?=([%o *] u.jon)  ~
  =/  p  (~(get by p.u.jon) 'prompt')
  ?.  ?=([~ %s *] p)  ~
  =/  sys=(unit @t)
    =/  s  (~(get by p.u.jon) 'system')
    ?:(?=([~ %s *] s) `p.u.s ~)
  :-  ~
  :*  %pass  `wire`[%spawn `@ta`sid `@ta`id.c ~]
      %agent  [our.bowl dap.bowl]  %poke
      %harness-action  !>(`action:h`[%spawn sid id.c p.u.p sys])
  ==
::  eyre: webhooks admit input from the outside world
::
++  serve
  |=  [eyre-id=@ta req=inbound-request:eyre]
  ^-  (quip card _state)
  =/  bad
    |=  [code=@ud msg=@t]
    ^-  (quip card _state)
    [(give-http eyre-id [code ~] `(as-octs:mimes:html msg)) state]
  ?.  =(%'POST' method.request.req)  (bad 405 'POST only')
  =/  parsed=(unit [[ext=(unit @ta) site=(list @t)] args=(list [@t @t])])
    %+  rush  url.request.req
    ;~(plug apat:de-purl:html yque:de-purl:html)
  ?~  parsed  (bad 400 'bad url')
  =/  site=(list @t)  site.u.parsed
  ?.  ?=([%'harness-api' %webhook @ ~] site)
    (bad 404 'not found')
  =/  sid=session-id:h  i.t.t.site
  =/  mses  (~(get by sessions) sid)
  ?~  mses  (bad 404 'no such session')
  =/  txt=(unit @t)
    ?~  body.request.req  ~
    =/  jon  (de:json:html q.u.body.request.req)
    ?~  jon  ~
    ?.  ?=([%o *] u.jon)  ~
    =/  t  (~(get by p.u.jon) 'text')
    ?:(?=([~ %s *] t) `p.u.t ~)
  ?~  txt  (bad 400 'body must be json with a "text" field')
  =/  ses  u.mses
  =/  event=event:h
    (input-event [%webhook url.request.req] ~ `[%http eyre-id] [%user u.txt])
  =^  cs1  ses
    (record-all sid ses ~[event])
  =^  cs2  state  (drive-put sid ses)
  :_  state
  %+  weld  (weld cs1 cs2)
  %^  give-http  eyre-id
    [200 ~[['content-type' 'application/json']]]
  `(as-octs:mimes:html '{"ok":true}')
::
++  give-http
  |=  [eyre-id=@ta [status=@ud headers=header-list:http] body=(unit octs)]
  ^-  (list card)
  =/  pax=path  /http-response/[eyre-id]
  :~  :*  %give  %fact  ~[pax]
          %http-response-header  !>(`response-header:http`[status headers])
      ==
      [%give %fact ~[pax] %http-response-data !>(body)]
      [%give %kick ~[pax] ~]
  ==
--
