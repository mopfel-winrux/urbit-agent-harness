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
      state-1
  ==
+$  state-0  [%0 sessions=(map session-id:h session:h)]
+$  state-1
  $:  %1
      sessions=(map session-id:h session:h)
      timers=(map [session-id:h @ta] timer:h)
  ==
+$  card  card:agent:gall
--
%-  agent:dbug
=|  state-1
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
    %0  `this(state [%1 sessions.old ~])
    %1  `this(state old)
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
      %+  skip  log.ses
      |=(e=event:h ?=(?(%llm-requested %tool-requested) -.e))
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
      %+  skip  log.ses
      |=(e=event:h ?=(?(%llm-requested %tool-requested) -.e))
    :-  ~
    state(sessions (~(put by sessions) sid.act [clean next-req.ses]))
  ::
      %retry
    =/  ses  (need-session sid.act)
    =^  cs1  ses  (record-all sid.act ses ~[[%retried ~]])
    =^  cs2  ses  (drive sid.act ses)
    :-  (weld cs1 cs2)
    state(sessions (~(put by sessions) sid.act ses))
  ::
      %config
    =/  ses  (need-session sid.act)
    =^  cs1  ses
      (record-all sid.act ses ~[[%config-replaced config.act]])
    =^  cs2  ses  (drive sid.act ses)
    :-  (weld cs1 cs2)
    state(sessions (~(put by sessions) sid.act ses))
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
  ==
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
  =^  cs1  ses
    %^  record-all  sid  ses
    ~[[%input-admitted [%user (rap 3 '[timer %' name ' fired] ' prompt.u.mt ~)]]]
  =^  cs2  ses  (drive sid ses)
  =/  rearm=[cs=(list card) nt=_timers]
    ?~  every.u.mt
      [~ (~(del by timers) key)]
    =/  at2=@da  (add now.bowl u.every.u.mt)
    :-  ~[(wait-card sid name at2)]
    (~(put by timers) key [at2 every.u.mt prompt.u.mt])
  :-  :(weld cs1 cs2 cs.rearm)
  state(sessions (~(put by sessions) sid ses), timers nt.rearm)
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
    ::  sync tools run on-ship now; async tools (iris) record a
    ::  request marker and their results re-enter as events
    ::
    =/  acc
      %+  roll  calls.u.stp
      |=  [c=tool-call:h acc=[evs=(list event:h) tcards=(list card)]]
      ?.  =(name.c 'http_fetch')
        acc(evs (snoc evs.acc (run-tool c)))
      =/  fc  (fetch-card sid c)
      ?~  fc
        %=  acc  evs
          %+  snoc  evs.acc
          `event:h`[%tool-completed id.c name.c 'error: bad http_fetch arguments']
        ==
      %=  acc
        evs     (snoc evs.acc `event:h`[%tool-requested id.c name.c])
        tcards  (snoc tcards.acc u.fc)
      ==
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
::  +run-tool: sync tools execute on-ship, immediately
::
++  run-tool
  |=  c=tool-call:h
  ^-  event:h
  =/  out=@t
    ?:  =(name.c 'get_ship_time')
      (scot %da now.bowl)
    ?:  =(name.c 'read_desk_file')
      (read-desk-file args.c)
    ?:  =(name.c 'list_desk_files')
      (list-desk-files args.c)
    (cat 3 'unknown tool: ' name.c)
  [%tool-completed id.c name.c out]
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
      (clip:hl q.data.u.full-file.res 30.000)
    (rap 3 'HTTP ' (scot %ud status) '\0a\0a' txt ~)
  =^  cs1  ses  (record-all sid ses ~[[%tool-completed call-id 'http_fetch' body]])
  =^  cs2  ses  (drive sid ses)
  :-  (weld cs1 cs2)
  state(sessions (~(put by sessions) sid ses))
--
