::  harness: the head of an on-ship agent harness
::
::    a gall agent that owns sessions (event logs), drives the pure
::    core in /lib/harness, and speaks to the provider through iris.
::    surfaces: pokes (%harness-action), facts on /session/[sid],
::    scries at /x/sessions and /x/session/[sid]. the chat ui is
::    served from /web by %harness-fileserver.
::
/-  h=harness
/+  hl=harness, default-agent, dbug
|%
+$  versioned-state
  $%  state-0
  ==
+$  state-0  [%0 sessions=(map session-id:h session:h)]
+$  card  card:agent:gall
--
%-  agent:dbug
=|  state-0
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
  [~ this]
::
++  on-save  !>(state)
::
++  on-load
  |=  old-vase=vase
  ^-  (quip card _this)
  =/  old  !<(versioned-state old-vase)
  ?-  -.old
    %0  `this(state old)
  ==
::
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
  ==
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+  path  (on-watch:def path)
    [%session @ ~]  `this
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
  ==
::
++  on-agent  |=([wire sign:agent:gall] (on-agent:def +<))
::
++  on-arvo
  |=  [=wire sign=sign-arvo]
  ^-  (quip card _this)
  ?+  wire  (on-arvo:def wire sign)
      [%llm @ @ @ ~]
    =/  sid=session-id:h  i.t.wire
    =/  req=@ud  (slav %ud i.t.t.wire)
    =/  kind=request-kind:h  ;;(request-kind:h i.t.t.t.wire)
    ?.  ?=([%iris %http-response *] sign)  (on-arvo:def wire sign)
    =^  cards  state
      (handle-llm-response:hc sid req kind client-response.sign)
    [cards this]
  ==
::
++  on-fail  |=([term tang] `this)
--
::  helper core: everything stateful lives here
::
|_  =bowl:gall
+*  hl-lib  hl
::  +handle-action: admit a command, then drive the session
::
++  handle-action
  |=  act=action:h
  ^-  (quip card _state)
  ?-  -.act
      %new
    =/  ses=session:h  [~[[%config-replaced config.act]] 0]
    =^  cards  ses  (drive sid.act ses)
    :-  cards
    state(sessions (~(put by sessions) sid.act ses))
  ::
      %send
    =/  ses  (need-session sid.act)
    =^  cs1  ses
      (record-all sid.act ses ~[[%input-admitted [%user text.act]]])
    =^  cs2  ses  (drive sid.act ses)
    :-  (weld cs1 cs2)
    state(sessions (~(put by sessions) sid.act ses))
  ::
      %fork
    =/  ses  (need-session from.act)
    ::  drop request markers so the fork is not stuck pending;
    ::  everything else is shared structure, copied for free
    ::
    =/  clean=(list event:h)
      (skip log.ses |=(e=event:h ?=(%llm-requested -.e)))
    :-  ~
    state(sessions (~(put by sessions) to.act [clean next-req.ses]))
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
    ::  a late response will mismatch the (now absent) pending marker
    ::
    =/  clean=(list event:h)
      (skip log.ses |=(e=event:h ?=(%llm-requested -.e)))
    :-  ~
    state(sessions (~(put by sessions) sid.act [clean next-req.ses]))
  ::
      %config
    =/  ses  (need-session sid.act)
    =^  cards  ses
      (record-all sid.act ses ~[[%config-replaced config.act]])
    :-  cards
    state(sessions (~(put by sessions) sid.act ses))
  ==
::
++  need-session
  |=  sid=session-id:h
  ^-  session:h
  ~|  [%no-such-session sid]
  (~(got by sessions) sid)
::  +drive: replay, decide, act; loop until idle or pending
::
++  drive
  |=  [sid=session-id:h ses=session:h]
  ^-  [(list card) session:h]
  =|  cards=(list card)
  |-  ^-  [(list card) session:h]
  =/  v=view:h  (play:hl log.ses)
  =/  stp  (decide:hl v)
  ?~  stp  [cards ses]
  ?-  -.u.stp
      %tools
    =/  evs=(list event:h)  (turn calls.u.stp run-tool)
    =^  cs  ses  (record-all sid ses evs)
    $(cards (weld cards cs))
  ::
      %turn
    =^  cs  ses  (issue-llm sid ses %turn v)
    $(cards (weld cards cs))
  ::
      %compact
    =^  cs  ses  (issue-llm sid ses %compaction v)
    $(cards (weld cards cs))
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
++  llm-card
  |=  [sid=session-id:h req=@ud kind=request-kind:h v=view:h]
  ^-  card
  =/  body=@t  (en:json:html (request-body:hl v kind))
  =/  =request:http
    :*  %'POST'
        url.config.v
        :~  ['content-type' 'application/json']
            ['authorization' (cat 3 'Bearer ' key.config.v)]
        ==
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
  ?:  ?=(%progress -.res)  `state
  =/  mses  (~(get by sessions) sid)
  ?~  mses  `state
  =/  ses  u.mses
  =/  v  (play:hl log.ses)
  ::  ignore stale responses (cancelled or forked-away requests)
  ::
  ?~  pending.v  `state
  ?.  =(req.u.pending.v req)  `state
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
    =/  jon  (de:json:html u.body)
    ?~  jon  [%llm-failed req 'invalid json in response']
    =/  digest  (mule |.((parse-response:hl u.jon)))
    ?:  ?=(%| -.digest)
      [%llm-failed req 'failed to digest response']
    =/  out  p.digest
    ?:  ?=(%| -.out)  [%llm-failed req p.out]
    ?:  ?=(%compaction kind)
      ?>  ?=(%assistant -.it.p.out)
      [%compaction-completed req body.it.p.out]
    [%llm-completed req stop.p.out u.p.out it.p.out]
  =^  cs1  ses  (record-all sid ses ~[ev])
  =^  cs2  ses  (drive sid ses)
  :-  (weld cs1 cs2)
  state(sessions (~(put by sessions) sid ses))
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
::  +run-tool: phase-0 tools execute on-ship, synchronously
::
++  run-tool
  |=  c=tool-call:h
  ^-  event:h
  ?:  =(name.c 'get_ship_time')
    [%tool-completed id.c name.c (scot %da now.bowl)]
  [%tool-completed id.c name.c (cat 3 'unknown tool: ' name.c)]
--
