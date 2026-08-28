::  harness: the head of an on-ship agent harness
::
::    a gall agent that owns sessions (event logs), drives the pure
::    core in /lib/harness, and speaks to the provider through iris.
::    surfaces: pokes (%harness-action), facts on /session/[sid],
::    scries at /x/sessions and /x/session/[sid]. the chat ui is
::    served from /web by %harness-fileserver.
::
/-  h=harness, spider
/+  hl=harness, default-agent, dbug, tbjs=thread-builder-js
|%
::  no state versioning during prototyping: on a schema change,
::  |nuke %harness and |revive to start fresh
::
+$  state-0
  $:  %0
      sessions=(map session-id:h session:h)
      timers=(map [session-id:h @ta] timer:h)
      ::  child session -> the parent tool call awaiting its answer
      ::
      subs=(map session-id:h [parent=session-id:h call-id=@t])
      ::  agent-level skill library, shared by all sessions
      ::
      skills=(map @t skill:h)
      ::  a2a: identity-based grants, outgoing asks, incoming queues
      ::
      peers=(map ship peer-grant:h)
      peer-base=(unit config:h)
      asks=(map ask-id:h [sid=session-id:h call-id=@t =ship])
      serving=(map session-id:h (list [=ship id=ask-id:h]))
      ::  in-flight run_js threads, keyed by spider tid
      ::
      jobs=(map @ta [sid=session-id:h call-id=@t deadline=@da])
      ::  agent-level default api key; a session whose config key is
      ::  blank falls back to this, resolved at send time so the key
      ::  need never enter a session log
      ::
      api-key=@t
  ==
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
  :_  this
  ~[[%pass /eyre/connect %arvo %e %connect [~ /harness-api] dap.bowl]]
::
++  on-save  !>(state)
::
++  on-load
  |=  old-vase=vase
  ^-  (quip card _this)
  ::  no state versioning while prototyping: an incompatible saved
  ::  state is dropped and we start fresh (the log is on the ship,
  ::  not in this agent's future). rebinding every load is idempotent.
  ::
  =/  old  (mole |.(!<(state-0 old-vase)))
  ~?  =(~ old)  [dap.bowl %incompatible-state-dropped]
  :_  this(state (fall old *state-0))
  ~[[%pass /eyre/connect %arvo %e %connect [~ /harness-api] dap.bowl]]
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
      [%x %status ~]
    :^  ~  ~  %json
    !>  ^-  json
    (pairs:enjs:format ~[['has-key' %b !=('' api-key)]])
  ::
      [%x %skills ~]
    ``json+!>((skills-json:hl skills))
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
::  +handle-action: admit a command, then drive the session
::
++  handle-action
  |=  act=action:h
  ^-  (quip card _state)
  ?-  -.act
      %new
    =/  ses=session:h  [~[[%config-replaced config.act]] 0]
    =^  cards  state  (drive-put sid.act ses)
    [cards state]
  ::
      %send
    =/  ses  (need-session sid.act)
    =^  cs1  ses
      (record-all sid.act ses ~[[%input-admitted [%user text.act]]])
    =^  cs2  state  (drive-put sid.act ses)
    [(weld cs1 cs2) state]
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
    =^  cs1  ses
      (record-all sid.act ses ~[[%config-replaced config.act]])
    =^  cs2  state  (drive-put sid.act ses)
    [(weld cs1 cs2) state]
  ::
      %spawn
    ::  internal, from our own drive loop: create the child session
    ::  from the parent's current config, sans %subagents (depth 1)
    ::
    ?>  =(our.bowl src.bowl)
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
      :~  [%input-admitted [%user prompt.act]]
          [%config-replaced ccfg]
      ==
    =.  subs  (~(put by subs) csid [parent.act call-id.act])
    =^  cards  state  (drive-put csid cses)
    [cards state]
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
    `state(peer-base `config.act)
  ::
      %ask-peer
    ::  internal, from our own drive loop: send a typed ask over ames
    ::  and start the timeout clock
    ::
    ?>  =(our.bowl src.bowl)
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
    ::  internal, from our own drive loop: build the js thread and run it
    ::  through spider under a tid we own, with a behn watchdog for the
    ::  (yielding) hang case. tight non-yielding loops are caught earlier
    ::  by the static guard; a computed one that slips through blocks a
    ::  single event and is the documented residual risk
    ::
    ?>  =(our.bowl src.bowl)
    =/  tid=@ta  (cat 3 'harness_js_' (scot %uv (end [3 16] (shas %js eny.bowl))))
    =/  deadline=@da  (add now.bowl js-timeout)
    =.  jobs  (~(put by jobs) tid [sid.act call-id.act deadline])
    =/  =shed:khan  (tbjs code.act)
    =/  args=inline-args:spider  [~ `tid [our.bowl q.byk.bowl da+now.bowl] shed]
    :_  state
    :~  :*  %pass  `wire`[%jswatch tid ~]
            %agent  [our.bowl %spider]  %watch  /thread-result/[tid]
        ==
        :*  %pass  `wire`[%jspoke tid ~]
            %agent  [our.bowl %spider]  %poke
            %spider-inline  !>(args)
        ==
        [%pass `wire`[%jsdog tid ~] %arvo %b %wait deadline]
    ==
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
  =^  cs1  ses
    %^  record-all  sid  ses
    ~[[%input-admitted [%user (rap 3 '[timer %' name ' fired] ' prompt.u.mt ~)]]]
  =/  dr  (drive sid ses)
  =.  skills  sk.dr
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
  ^-  [cards=(list card) ses=session:h sk=(map @t skill:h)]
  =|  cards=(list card)
  |-  ^-  [cards=(list card) ses=session:h sk=(map @t skill:h)]
  =/  v=view:h  (play:hl log.ses)
  =/  stp  (decide:hl v (skills-visible sid skills))
  ?~  stp  [cards ses skills]
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
      |:  [c=*tool-call:h acc=[evs=*(list event:h) tcards=*(list card) sk=skills]]
      ^+  acc
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
    [(weld cards cs) ses skills]
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
  =/  body=@t  (en:json:html (request-body:hl v kind (skills-visible sid skills)))
  ::  blank session key falls back to the agent-level default
  ::
  =/  eff-key=@t  ?:(=('' key.config.v) api-key key.config.v)
  =/  =request:http
    :*  %'POST'
        url.config.v
        :~  ['content-type' 'application/json']
            ['authorization' (cat 3 'Bearer ' eff-key)]
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
  =^  cs2  state  (drive-put sid ses)
  [(weld cs1 cs2) state]
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
  =.  sessions  (~(put by sessions) sid ses.dr)
  =^  cs2  state  (settle sid)
  [(weld cards.dr cs2) state]
::  +settle: when a session goes idle, deliver what it owes:
::  a finished subagent's answer to its parent, and answers for
::  any peer asks queued against it
::
++  settle
  |=  sid=session-id:h
  ^-  (quip card _state)
  =^  cs1  state  (settle-sub sid)
  =^  cs2  state  (settle-asks sid)
  [(weld cs1 cs2) state]
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
  =.  subs  (~(del by subs) sid)
  =/  mp  (~(get by sessions) parent.u.link)
  ?~  mp  `state
  =^  cs1  u.mp
    %^  record-all  parent.u.link  u.mp
    ~[[%tool-completed call-id.u.link 'run_subagent' u.result]]
  =^  cs2  state  (drive-put parent.u.link u.mp)
  [(weld cs1 cs2) state]
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
    =^  cs1  ses
      %^  record-all  sid  ses
      ?~  mses
        ~[[%input-admitted [%user prompt.msg]]]
      :~  [%config-replaced cfg]
          [%input-admitted [%user prompt.msg]]
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
::  +skills-visible: a peer session sees only its grant's inflows
::
++  skills-visible
  |=  [sid=session-id:h sk=(map @t skill:h)]
  ^-  (map @t skill:h)
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
  =^  cs1  ses
    %^  record-all  sid  ses
    ~[[%input-admitted [%user (cat 3 '[webhook] ' u.txt)]]]
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
