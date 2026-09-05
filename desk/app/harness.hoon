::  Gall composition root and authoritative orchestrator.
::  Accept input -> record event -> replay/decide -> authorize -> emit cards.
::  Result handlers verify outstanding identities before recording completion.
::  Codecs and effect bindings cannot mutate this store or start a second loop.
::  Persistence layouts/conversion, provider formats and client presentation
::  live in named modules so this file can concentrate on lifecycle ownership.
::
/-  h=harness, hh=harness-hand, sh=harness-shadow, adapter=harness-adapter, spider, ac=acp, *harness-store
/+  hl=harness, hs=harness-session, hd=harness-hand, hg=harness-grub, shadow=harness-shadow, hp=harness-provider, auth=harness-auth, ht=harness-tools, hj=harness-json, command=harness-command, context=harness-context, failure=harness-failure, policy=harness-defaults, storage=harness-store, transport=harness-acp, bindings=harness-effects, default-agent, dbug
|%
+$  card  card:agent:gall
--
%-  agent:dbug
=|  state-8
=*  state  -
^-  agent:gall
=<
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)
    hc    ~(. +> bowl)
    wire-codec  ~(. transport our.bowl)
    effects  ~(. bindings [bowl mcp-servers])
::
++  on-init
  ^-  (quip card _this)
  :_  this(defaults builtin-config:policy)
  :~  [%pass /eyre/connect %arvo %e %connect [~ /harness-api] dap.bowl]
      acp-open-card:wire-codec
      acp-watch-card:wire-codec
      (watch:hg our.bowl shadow-channel:hc)
  ==
::
++  on-save  !>(state)
::
++  on-load
  |=  old-vase=vase
  ^-  (quip card _this)
  =/  new=state-8  (load:storage old-vase)
  :_  this(state new)
  =/  base=(list card)
    :~  [%pass /eyre/connect %arvo %e %connect [~ /harness-api] dap.bowl]
        acp-open-card:wire-codec
        acp-watch-card:wire-codec
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
    ?>  =(src.bowl our.bowl)
    =^  cards  state  (handle-action:hc !<(action:h vase))
    [cards this]
  ::
      %noun
    ?>  =(src.bowl our.bowl)
    =^  cards  state  (handle-action:hc ;;(action:h q.vase))
    [cards this]
  ::
      %harness-hand
    ?>  =(src.bowl our.bowl)
    =/  req  !<(request:hh vase)
    =/  out  (hand-call:hc act.req)
    :_  this(state new.out)
    %+  snoc  cards.out
    [%give %fact ~[/hands/[id.req]] %noun !>(result.out)]
  ::
      %handle-http-request
    ?>  =(src.bowl our.bowl)
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
  ?>  =(src.bowl our.bowl)
  ?+  path  (on-watch:def path)
    [%session @ ~]       `this
    [%hands @ ~]         `this
    [%http-response *]   `this
  ==
::
++  on-leave  |=(path `this)
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?>  =(src.bowl our.bowl)
  ?+  path  (on-peek:def path)
      [%x %hands @ ~]
    ``json+!>((status-json:hd hands i.t.t.path))
  ::
      [%x %hand-outbox @ ~]
    ``json+!>((outbox-json:hd hands i.t.t.path))
  ::
      [%x %hand-state ~]
    ``noun+!>(hands)
  ::
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
    ``json+!>((view-json:hj (play:hl log.u.ses)))
  ::
      [%x %events @ ~]
    =/  sid=session-id:h  i.t.t.path
    =/  ses  (~(get by sessions) sid)
    ?~  ses  [~ ~]
    :^  ~  ~  %json
    !>  ^-  json
    [%a (turn (flop log.u.ses) event-json:hj)]
  ::
      [%x %snapshot @ ~]
    =/  ses  (~(get by sessions) `session-id:h`i.t.t.path)
    ?~  ses  [~ ~]
    ``json+!>((snapshot:hs u.ses ~))
  ::
      [%x %head @ ~]
    =/  sid=session-id:h  i.t.t.path
    =/  ses  (~(get by sessions) sid)
    ?~  ses  [~ ~]
    ``noun+!>((inspect:hs u.ses (skills-visible:hc sid skills)))
  ::
      [%x %verification @ ~]
    ``json+!>((shadow-status:hc i.t.t.path))
  ::
      [%x %status ~]
    :^  ~  ~  %json
    !>  ^-  json
    (pairs:enjs:format ~[['has-key' %b !=('' api-key)]])
  ::
      [%x %tools ~]
    :^  ~  ~  %json
    !>  ^-  json
    [%a (turn all-tools:ht |=(t=term `json`[%s t]))]
  ::
      [%x %defaults ~]
    ``json+!>((config-json:hj defaults))
  ::
      [%x %mcp ~]
    :^  ~  ~  %json
    !>  ^-  json
    [%a (turn ~(tap by mcp-servers) mcp-server-json:hj)]
  ::
      [%x %skills ~]
    ``json+!>((skills-json:hj skills))
  ::
      [%x %staged ~]
    ``json+!>((skills-json:hj staged))
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
      [%adapter %tlon @ @ ~]
    ?.  ?=(%poke-ack -.sign)  `this
    ?~  p.sign  `this
    =/  id=json  ;;(json (cue (slav %uv i.t.t.t.wire)))
    [~[(acp-error-card:wire-codec i.t.t.wire id '-32603' 'Tlon hand unavailable; inspect adapter status on the ship')] this]
  ::
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
      [~[acp-watch-card:wire-codec] this]
    ::
        %watch-ack
      ?~  p.sign  `this
      [~[acp-watch-card:wire-codec] this]
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
          ?:  ?=(%& -.out.u.parsed)  (clip:ht p.out.u.parsed 8.000)
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
  ::  Bounded summary lifetime; request identity makes a late wake harmless.
      [%compact-timeout @ @ @ ~]
    ?.  ?=([%behn %wake *] sign)  (on-arvo:def wire sign)
    =^  cards  state
      (compact-timeout:hc i.t.wire (slav %ud i.t.t.wire) (slav %uv i.t.t.t.wire))
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
::  Stateful lifecycle. Keep state replacement and emitted cards together:
::  splitting this into independently driving adapters would create two owners.
::
|_  =bowl:gall
+*  wire-codec  ~(. transport our.bowl)
    effects  ~(. bindings [bowl mcp-servers])
::  Supervision: publish evidence, never delegate authority to the mirror.
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
  =/  visible  (skills-visible sid skills)
  =/  input=input:sh  [%0 ses visible (digest:shadow ses visible)]
  (send:hg our.bowl shadow-channel [%make-file /agents/main/shadow-inputs name %noun input %.y])
++  shadow-del-card
  |=  sid=session-id:h
  ^-  (list card)
  =/  name=@ta  sid
  %+  turn  ~[/agents/main/shadow-inputs /agents/main/sessions /agents/main/checks]
  |=  path=path
  (send:hg our.bowl shadow-channel [%cull path `name])
++  shadow-status
  |=  sid=session-id:h
  ^-  json
  =/  ses  (~(get by sessions) sid)
  ?~  ses  ~
  =/  base=path  /(scot %p our.bowl)/harness-grub/(scot %da now.bowl)
  =/  info=(map @t json)
    (my ~[['authoritativeRevision' (numb:enjs:format (lent log.u.ses))] ['authoritativeDigest' %s (scot %uv (digest:shadow u.ses (skills-visible sid skills)))]])
  =/  empty=json
    [%o (~(put by info) 'check' ~)]
  ?.  .^(? %gu (weld base /$))  empty
  ::  Check membership before reading: a missing Gall scry is not a local
  ::  exception and must never be allowed to fail an ACP update.
  =/  sources  .^((list @ta) %gx (weld base /peek/kids/agents/main/shadow-inputs/noun))
  =/  source=(unit *)
    ?.  (lien sources |=(name=@ta =(name sid)))  ~
    %-  mole  |.
    .^(* %gx /(scot %p our.bowl)/harness-grub/(scot %da now.bowl)/peek/file/agents/main/shadow-inputs/[sid]/noun)
  ?:  ?&(?=(^ source) ?=([%failed * *] u.source))
    =/  failure  (mole |.(;;(failure:sh u.source)))
    ?~  failure  empty
    [%o (~(put by info) 'check' (pairs:enjs:format ~[['crashed' %b %.y] ['matched' %b %.n] ['evidence' %s (scot %uv (shas %shadow-crash (jam trace.u.failure)))]]))]
  =/  verdict=(unit json)
    =/  checks  .^((list @ta) %gx (weld base /peek/kids/agents/main/checks/noun))
    ?.  (lien checks |=(name=@ta =(name sid)))  ~
    %-  mole  |.
    ;;(json .^(* %gx /(scot %p our.bowl)/harness-grub/(scot %da now.bowl)/peek/file/agents/main/checks/[sid]/noun))
  [%o (~(put by info) 'check' ?~(verdict ~ u.verdict))]
::
::  Client ingress: ordered admission belongs here; frame encoding does not.
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
    cards      :(weld cards admitted ~[(acp-ack-card:wire-codec connection sequence)])
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
    [~[(acp-error-card:wire-codec connection u.id '-32601' 'Method not found')] state]
  ::
      %initialize
    ?~  id  `state
    [~[(acp-result-card:wire-codec connection u.id acp-initialize-result:wire-codec)] state]
  ::  Optional hands own their settings and social protocols. Forward the
  ::  authenticated request; the hand replies on the same ACP connection.
      ?(%'harness/tlon' %'harness/tlon/configure' %'harness/tlon/contacts' %'harness/tlon/watch' %'harness/tlon/profile' %'harness/tlon/profile/set')
    ?~  id  `state
    :_  state
    :~  [%pass /adapter/tlon/[connection]/(scot %uv (jam u.id)) %agent [our.bowl %harness-tlon] %poke %noun !>(`request:adapter`[connection u.id p.u.method params])]
    ==
  ::
      %'harness/hand'
    ?~  id  `state
    ?~  params
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Expected a hand action')] state]
    =/  parsed  (mule |.((json-action:hd u.params)))
    ?.  ?=(%& -.parsed)
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Invalid hand action')] state]
    =/  out  (hand-call p.parsed)
    =/  response=card
      ?:  ?=(%& -.result.out)  (acp-result-card:wire-codec connection u.id p.result.out)
      (acp-error-card:wire-codec connection u.id '-32602' p.result.out)
    [(snoc cards.out response) new.out]
  ::
      %'session/new'
    ?~  id  `state
    =/  requested  (acp-param-string:wire-codec params 'name')
    =/  sid=session-id:h
      ?~(requested (cat 3 'acp-' (scot %ud sequence.msg)) u.requested)
    ?:  (~(has by sessions) sid)
      [~[(acp-error-card:wire-codec connection u.id '-32603' 'Session id collision')] state]
    =^  made  state  (handle-action [%new sid defaults])
    =/  result=json
      (pairs:enjs:format ~[['sessionId' %s sid]])
    [:(weld made ~[(acp-result-card:wire-codec connection u.id result) (acp-session-update-card:wire-codec connection sid advertised:command)]) state]
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
    [~[(acp-result-card:wire-codec connection u.id result)] state]
  ::
      %'session/load'
    ?~  id  `state
    =/  sid  (acp-param-string:wire-codec params 'sessionId')
    ?~  sid
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Unknown session')] state]
    ?.  (~(has by sessions) u.sid)
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Unknown session')] state]
    =/  current=session:h  (need (~(get by sessions) u.sid))
    =/  replay=(list card)
      (acp-item-cards:wire-codec connection u.sid 0 (transcript-items:hl log.current))
    [:(weld replay ~[(acp-result-card:wire-codec connection u.id (pairs:enjs:format ~)) (acp-session-update-card:wire-codec connection u.sid advertised:command)]) state]
  ::
      %'session/resume'
    ?~  id  `state
    =/  sid  (acp-param-string:wire-codec params 'sessionId')
    ?~  sid
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Unknown session')] state]
    ?.  (~(has by sessions) u.sid)
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Unknown session')] state]
    [~[(acp-result-card:wire-codec connection u.id (pairs:enjs:format ~)) (acp-session-update-card:wire-codec connection u.sid advertised:command)] state]
  ::
      %'session/close'
    ?~  id  `state
    =/  sid  (acp-param-string:wire-codec params 'sessionId')
    ?~  sid
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Unknown session')] state]
    ?.  (~(has by sessions) u.sid)
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Unknown session')] state]
    ::  Closing a client's view does not cancel work owned by the ship.
    [~[(acp-result-card:wire-codec connection u.id (pairs:enjs:format ~))] state]
  ::
      %'session/delete'
    ?~  id  `state
    =/  sid  (acp-param-string:wire-codec params 'sessionId')
    ?~  sid
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Unknown session')] state]
    ?.  (~(has by sessions) u.sid)
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Unknown session')] state]
    ?:  (lien ~(val by bindings.hands) |=(b=binding:hh =(sid.b u.sid)))
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Remove hand bindings before deleting the session')] state]
    =^  deleted  state  (handle-action [%delete u.sid])
    [:(weld deleted ~[(acp-result-card:wire-codec connection u.id (pairs:enjs:format ~))]) state]
  ::
      %'harness/status'
    ?~  id  `state
    =/  provider=@t  (fall (acp-param-string:wire-codec params 'provider') 'openrouter')
    =/  stored=@t  (provider-key provider)
    =/  has=?
      ?|  !=('' stored)
          ?&  =('openrouter' provider)
              !=('' api-key)
          ==
      ==
    =/  result=json
      ?.  =('openai' provider)  (pairs:enjs:format ~[['has-key' %b has]])
      =/  device=?  !=('' (provider-key 'openai-device'))
      =/  method=@t
        ?:  &((device-route:auth url.defaults) device)  'device'
        ?:  &(=('openai' (provider-for-url:hp url.defaults)) has)  'api-key'
        ?:(device 'device' 'api-key')
      (pairs:enjs:format ~[['has-key' %b |(has device)] ['has-api-key' %b has] ['has-device-login' %b device] ['auth-method' %s method]])
    [~[(acp-result-card:wire-codec connection u.id result)] state]
  ::
      %'harness/tools'
    ?~  id  `state
    =/  result=json
      [%a (turn all-tools:ht |=(t=term `json`[%s t]))]
    [~[(acp-result-card:wire-codec connection u.id result)] state]
  ::
      %'harness/defaults'
    ?~  id  `state
    [~[(acp-result-card:wire-codec connection u.id (config-json:hj defaults))] state]
  ::
      %'harness/defaults/configure'
    ?~  id  `state
    =/  raw  (acp-param-json:wire-codec params 'config')
    ?~  raw
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Expected config')] state]
    =/  decoded  (mule |.((json-config:hj u.raw)))
    ?:  ?=(%| -.decoded)
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Invalid configuration')] state]
    =^  configured  state  (handle-action [%defaults p.decoded])
    [:(weld configured ~[(acp-result-card:wire-codec connection u.id (config-json:hj defaults))]) state]
  ::
      %'harness/mcp/servers'
    ?~  id  `state
    =/  result=json  [%a (turn ~(tap by mcp-servers) mcp-server-json:hj)]
    [~[(acp-result-card:wire-codec connection u.id result)] state]
  ::
      %'harness/mcp/configure'
    ?~  id  `state
    =/  raw  (acp-param-json:wire-codec params 'servers')
    ?~  raw
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Expected servers')] state]
    =/  decoded  (mule |.((json-mcp-servers:hj u.raw)))
    ?:  ?=(%| -.decoded)
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Invalid MCP configuration')] state]
    =^  configured  state  (handle-action [%mcp-config p.decoded])
    =/  result=json  [%a (turn ~(tap by mcp-servers) mcp-server-json:hj)]
    [:(weld configured ~[(acp-result-card:wire-codec connection u.id result)]) state]
  ::
      %'harness/session/config'
    ?~  id  `state
    =/  sid  (acp-param-string:wire-codec params 'sessionId')
    ?~  sid
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Expected sessionId')] state]
    =/  current  (~(get by sessions) u.sid)
    ?~  current
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Unknown session')] state]
    =/  result=json  (view-json:hj (play:hl log.u.current))
    [~[(acp-result-card:wire-codec connection u.id result)] state]
  ::
      %'harness/session/snapshot'
    ?~  id  `state
    =/  sid  (acp-param-string:wire-codec params 'sessionId')
    ?~  sid
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Expected sessionId')] state]
    =/  current  (~(get by sessions) u.sid)
    ?~  current
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Unknown session')] state]
    =/  since  (acp-param-number:wire-codec params 'since')
    =/  v  (play:hl log.u.current)
    =/  streaming=@t
      ?~  pending.v  ''
      ?.  =(%turn kind.u.pending.v)  ''
      =/  progress  (~(get by streams) [u.sid req.u.pending.v])
      ?~  progress  ''
      (stream-text:hp body.u.progress =('https://chatgpt.com/backend-api/codex/responses' url.config.v))
    =/  result  (snapshot:hs u.current since)
    ?>  ?=(%o -.result)
    =.  result  [%o (~(put by p.result) 'streaming' [%s streaming])]
    [~[(acp-result-card:wire-codec connection u.id result)] state]
  ::
      %'harness/session/verify'
    ?~  id  `state
    =/  sid  (acp-param-string:wire-codec params 'sessionId')
    ?~  sid  [~[(acp-error-card:wire-codec connection u.id '-32602' 'Expected sessionId')] state]
    ?.  (~(has by sessions) u.sid)
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Unknown session')] state]
    [~[(acp-result-card:wire-codec connection u.id (shadow-status u.sid))] state]
  ::
      %'harness/session/recheck'
    ?~  id  `state
    =/  sid  (acp-param-string:wire-codec params 'sessionId')
    ?~  sid  [~[(acp-error-card:wire-codec connection u.id '-32602' 'Expected sessionId')] state]
    =/  ses  (~(get by sessions) u.sid)
    ?~  ses  [~[(acp-error-card:wire-codec connection u.id '-32602' 'Unknown session')] state]
    =/  result  (pairs:enjs:format ~[['queued' %b %.y] ['revision' (numb:enjs:format (lent log.u.ses))]])
    [~[(shadow-put-card u.sid u.ses) (acp-result-card:wire-codec connection u.id result)] state]
  ::
      %'harness/session/fork'
    ?~  id  `state
    =/  sid  (acp-param-string:wire-codec params 'sessionId')
    =/  name  (acp-param-string:wire-codec params 'name')
    =/  at  (acp-param-number:wire-codec params 'eventCount')
    ?.  &(?=(^ sid) ?=(^ name) ?=(^ at))
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Expected sessionId, name, and eventCount')] state]
    =/  current  (~(get by sessions) u.sid)
    ?~  current
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Unknown session')] state]
    ?:  |(=('' u.name) (~(has by sessions) u.name))
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Choose an unused conversation name')] state]
    =/  fork  (branch:hs u.sid u.current u.at)
    ?:  ?=(%| -.fork)
      [~[(acp-error-card:wire-codec connection u.id '-32602' p.fork)] state]
    =^  made  state  (handle-action [%fork-at u.sid u.name u.at])
    =/  result=json  (pairs:enjs:format ~[['sessionId' %s u.name]])
    [:(weld made ~[(acp-result-card:wire-codec connection u.id result)]) state]
  ::
      %'harness/session/use-default-model'
    ?~  id  `state
    =/  sid  (acp-param-string:wire-codec params 'sessionId')
    ?~  sid
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Expected sessionId')] state]
    =/  current  (~(get by sessions) u.sid)
    ?~  current
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Unknown session')] state]
    ::  An explicit model-only update, atomic with respect to grant changes.
    ::  Keep this conversation's instructions, history and tool authority.
    =/  cfg  config:(play:hl log.u.current)
    =.  cfg  cfg(url url.defaults, model model.defaults, key '', headers headers.defaults, max-context max-context.defaults)
    =^  configured  state  (handle-action [%config u.sid cfg])
    [:(weld configured ~[(acp-result-card:wire-codec connection u.id (config-json:hj cfg))]) state]
  ::
      %'harness/session/configure'
    ?~  id  `state
    =/  sid  (acp-param-string:wire-codec params 'sessionId')
    =/  raw  (acp-param-json:wire-codec params 'config')
    ?.  &(?=(^ sid) ?=(^ raw))
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Expected sessionId and config')] state]
    ?.  (~(has by sessions) u.sid)
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Unknown session')] state]
    =/  decoded  (mule |.((json-config:hj u.raw)))
    ?:  ?=(%| -.decoded)
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Invalid configuration')] state]
    =^  configured  state  (handle-action [%config u.sid p.decoded])
    =/  current=session:h  (need (~(get by sessions) u.sid))
    =/  result=json  (view-json:hj (play:hl log.current))
    [:(weld configured ~[(acp-result-card:wire-codec connection u.id result)]) state]
  ::
      %'harness/credential/set'
    ?~  id  `state
    =/  key  (acp-param-string:wire-codec params 'key')
    =/  provider=@t  (fall (acp-param-string:wire-codec params 'provider') 'openrouter')
    ?~  key
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Expected key')] state]
    =.  provider-keys  (put-key:auth provider-keys provider u.key)
    =?  api-key  =('openrouter' provider)  u.key
    =/  result=json
      (pairs:enjs:format ~[['has-key' %b !=('' u.key)]])
    [~[(acp-result-card:wire-codec connection u.id result)] state]
  ::
      %'harness/provider/models'
    ?~  id  `state
    =/  provider  (acp-param-string:wire-codec params 'provider')
    =/  url  (acp-param-string:wire-codec params 'url')
    ?.  &(?=(^ provider) ?=(^ url))
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Expected provider and url')] state]
    =/  req=@ud  next-model-request
    =.  next-model-request  +(next-model-request)
    =.  model-requests  (~(put by model-requests) req [connection u.id])
    [~[(model-list-card req u.provider u.url)] state]
  ::
      %'harness/session/rename'
    ?~  id  `state
    =/  sid  (acp-param-string:wire-codec params 'sessionId')
    =/  name  (acp-param-string:wire-codec params 'name')
    ?.  &(?=(^ sid) ?=(^ name))
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Expected sessionId and name')] state]
    ?.  (~(has by sessions) u.sid)
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Unknown session')] state]
    ?:  (lien ~(val by bindings.hands) |=(b=binding:hh =(sid.b u.sid)))
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Remove hand bindings before renaming the session')] state]
    ?:  (~(has by sessions) u.name)
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Name already in use')] state]
    =/  current=session:h  (need (~(get by sessions) u.sid))
    =/  view=view:h  (play:hl log.current)
    ?:  |(?=(^ pending.view) !=(~ wait.view))
      [~[(acp-error-card:wire-codec connection u.id '-32600' 'Session is busy')] state]
    ::  A rename changes the address of the same record; it is not a fork and
    ::  therefore does not invent ancestry in the session history.
    ::
    =.  sessions  (~(put by sessions) u.name current)
    =^  deleted  state  (handle-action [%delete u.sid])
    :_  state
    %+  weld  ~[(shadow-put-card u.name current)]
    (weld deleted ~[(acp-result-card:wire-codec connection u.id (pairs:enjs:format ~))])
  ::
      %'session/prompt'
    ?~  id  `state
    =/  sid  (acp-param-string:wire-codec params 'sessionId')
    =/  text  (acp-prompt-text:wire-codec params)
    ?~  sid
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Expected sessionId and text prompt')] state]
    ?~  text
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Expected sessionId and text prompt')] state]
    ?.  (~(has by sessions) u.sid)
      [~[(acp-error-card:wire-codec connection u.id '-32602' 'Unknown session')] state]
    ::  /stop settles the prior prompt before reserving this command's reply.
    =^  stopped  state  (stop-command u.sid u.text)
    ?:  (~(has by acp-prompts) u.sid)
      [~[(acp-error-card:wire-codec connection u.id '-32600' 'A prompt is already running')] state]
    =/  current=session:h  (need (~(get by sessions) u.sid))
    =/  current-view  (play:hl log.current)
    ?:  |(?=(^ pending.current-view) !=(~ wait.current-view))
      [~[(acp-error-card:wire-codec connection u.id '-32600' 'A turn is already running')] state]
    =/  cursor=@ud  (lent (transcript-items:hl log.current))
    =.  acp-prompts  (~(put by acp-prompts) u.sid [connection u.id cursor])
    =/  event=event:h
      (input-event [%acp connection] `our.bowl `[%acp connection] [%user u.text])
    ?>  ?=(%input-received -.event)
    =/  client-id  (acp-param-string:wire-codec params 'clientMessageId')
    =/  admission=json
      (pairs:enjs:format ~[['sessionUpdate' %s 'harness_prompt_admitted'] ['clientMessageId' ?~(client-id ~ [%s u.client-id])] ['inputId' %s (scot %uv id.input.event)]])
    =^  driven  state  (admit u.sid current event)
    [:(weld stopped ~[(acp-session-update-card:wire-codec connection u.sid admission)] driven) state]
  ::
      %'session/cancel'
    =/  sid  (acp-param-string:wire-codec params 'sessionId')
    ?~  sid  `state
    ?.  (~(has by sessions) u.sid)  `state
    =^  cancelled  state  (handle-action [%cancel u.sid])
    ?~  id  [cancelled state]
    [:(weld cancelled ~[(acp-result-card:wire-codec connection u.id (pairs:enjs:format ~))]) state]
  ==
::  Hand ingress: the delivery ledger owns deduplication and publication;
::  this bridge admits observations only at a semantic session boundary.
::
++  hand-call
  |=  act=action:hh
  ^-  [result=(each json @t) cards=(list card) new=_state]
  =/  cfg=(unit binding:hh)
    ?+  -.act  ~
      %bind      `config.act
      %register  `config.act
    ==
  ?:  ?&(?=(^ cfg) !(~(has by sessions) sid.u.cfg))
    [[%| 'Create the session and configure its tool grants before binding it'] ~ state]
  =/  applied  (apply:hd hands act now.bowl)
  ?:  ?=(%| -.applied)  [[%| p.applied] ~ state]
  ::  Validate and deduplicate BEFORE interrupting. A replayed /stop cannot
  ::  cancel newer work. Cancel against the old ledger, then admit the stop
  ::  observation so it is not swept up with the work it just cancelled.
  =^  stopped  state
    ?.  ?&  ?=(%observe -.act)
        (stopping:command text.act)
        !(~(has by observations.hands) (input-id:hd binding.act event.act))
        ==
      `state
    =/  sid  sid:(need (~(get by bindings.hands) binding.act))
    (stop-command sid text.act)
  ::  Reapply to retain cancellation receipts and the other bindings' queues.
  =/  accepted  ?~(stopped applied (apply:hd hands act now.bowl))
  ?>  ?=(%& -.accepted)
  =.  hands  db.p.accepted
  =/  sid=(unit session-id:h)
    ?+  -.act  ~
      %observe  `sid:(need (~(get by bindings.hands) binding.act))
      %enable   `sid:(need (~(get by bindings.hands) id.act))
    ==
  ?~  sid  [[%& result.p.accepted] ~ state]
  =^  cards  state  (hand-pump u.sid)
  [[%& result.p.accepted] (weld stopped cards) state]
::  Admit queued work only at a session boundary. Immediate admission and
::  pumping share one event; its state commits before external effects run.
++  hand-pump
  |=  sid=session-id:h
  ^-  (quip card _state)
  =/  current  (~(get by sessions) sid)
  ?~  current  `state
  =/  v  (play:hl log.u.current)
  ?:  |(?=(^ pending.v) !=(~ wait.v))  `state
  =/  id  (next:hd hands sid)
  ?~  id  `state
  =/  obs  (need (~(get by observations.hands) u.id))
  =/  cfg  (need (~(get by bindings.hands) binding.obs))
  =.  hands  (start:hd hands sid u.id)
  =/  event=event:h
    [%input-received [u.id [%hand binding.obs hand.cfg address.cfg event.obs actor.obs] ~ `[%hand binding.obs] at.obs [%user text.obs]]]
  (admit sid u.current event)
::  Shared human ingress. Commands produce an ordinary terminal assistant
::  item and their own audit event. /compact alone admits a summary request.
++  admit
  |=  [sid=session-id:h ses=session:h event=event:h]
  ^-  (quip card _state)
  ?>  ?=(%input-received -.event)
  ?>  ?=(%user -.item.input.event)
  =/  cmd  (parse:command body.item.input.event)
  ?:  =(`['compact' ''] cmd)
    =^  recorded  ses  (record-all sid ses ~[event])
    =^  started  ses  (start-compaction sid ses `id.input.event)
    =^  driven  state  (drive-put sid ses)
    [:(weld recorded started driven) state]
  =/  events=(list event:h)  ~[event]
  =?  events  ?=(^ cmd)
    =/  v  (play:hl log.ses)
    =/  result  (evaluate:command u.cmd v defaults (skills-visible sid skills))
    %+  snoc
      (weld events events.result)
    [%command-completed id.input.event name.u.cmd body.result]
  =^  recorded  ses  (record-all sid ses events)
  =^  driven  state  (drive-put sid ses)
  [(weld recorded driven) state]
::  A stop is out of band, not another queued request. Idle sessions need no
::  synthetic cancellation; their command acknowledgement is sufficient.
++  stop-command
  |=  [sid=session-id:h text=@t]
  ^-  (quip card _state)
  ?.  (stopping:command text)  `state
  =/  v  (play:hl log:(need-session sid))
  ?.  |(?=(^ pending.v) !=(~ wait.v) (~(has by active.hands) sid) (~(has by acp-prompts) sid))  `state
  (handle-action [%cancel sid])
++  settle-hands
  |=  sid=session-id:h
  ^-  (quip card _state)
  =/  id  (~(get by active.hands) sid)
  ?~  id  (hand-pump sid)
  =/  current  (~(get by sessions) sid)
  ?~  current  `state
  =/  result  (outcome:hl (play:hl log.u.current))
  ?~  result  `state
  ::  Public hands receive a safe failure description, not private diagnostics.
  =/  body=@t
    ?-  -.u.result
      %cancelled  'Work was cancelled.'
      %failure    (public-message:failure reason.u.result)
      %reply      body.u.result
    ==
  =.  hands  (finish:hd hands sid -.u.result body)
  (hand-pump sid)
::
::  Native commands converge here, including commands decoded from ACP.
::  Changes to a session and its runtime bookkeeping commit in one Gall event.
++  handle-action
  |=  act=action:h
  ^-  (quip card _state)
  ?-  -.act
      %new
    ?>  !(~(has by sessions) sid.act)
    =/  cfg=config:h  config.act
    =?  provider-keys  !=('' key.cfg)
      (put-key:auth provider-keys (credential-for-url:auth url.cfg) key.cfg)
    =.  cfg  cfg(key '')
    =/  ses=session:h  [~[[%config-replaced cfg]] 0]
    =^  cards  state  (drive-put sid.act ses)
    [cards state]
  ::
      %send
    =^  stopped  state  (stop-command sid.act text.act)
    =/  ses  (need-session sid.act)
    ?>  !(~(has by active.hands) sid.act)
    =/  v  (play:hl log.ses)
    ?>  |(?=(~ (parse:command text.act)) &(?=(~ pending.v) =(~ wait.v)))
    =/  event=event:h
      (input-event [%poke src.bowl] `src.bowl ~ [%user text.act])
    =^  driven  state  (admit sid.act ses event)
    [(weld stopped driven) state]
  ::
      %fork
    ?>  !(~(has by sessions) to.act)
    =/  ses  (need-session from.act)
    =/  v  (play:hl log.ses)
    =/  req=(unit @ud)  ?~(pending.v ~ `req.u.pending.v)
    =/  event=event:h
      [%forked from.act (lent log.ses) req wait.v]
    =^  cards  ses  (record-all to.act ses ~[event])
    :-  (snoc cards (shadow-put-card to.act ses))
    state(sessions (~(put by sessions) to.act ses))
  ::
      %fork-at
    ?>  !(~(has by sessions) to.act)
    =/  fork  (branch:hs from.act (need-session from.act) at.act)
    ?>  ?=(%& -.fork)
    =/  ses  p.fork
    ?>  ?=(^ log.ses)
    =/  recorded
      (record-all to.act [t.log.ses next-req.ses] ~[i.log.ses])
    =/  child  +.recorded
    =.  sessions  (~(put by sessions) to.act child)
    [(snoc -.recorded (shadow-put-card to.act child)) state]
  ::
      %compact
    =/  ses  (need-session sid.act)
    =/  v  (play:hl log.ses)
    ?:  |(?=(^ pending.v) !=(~ wait.v))  `state
    =^  cards  ses  (start-compaction sid.act ses ~)
    =^  driven  state  (drive-put sid.act ses)
    [(weld cards driven) state]
  ::
      %cancel
    =/  ses  (need-session sid.act)
    =/  v  (play:hl log.ses)
    ::  Withdraw local HTTP waits as well as fencing their results. This
    ::  cannot undo an operation the external service has already accepted.
    =/  withdrawn=(list card)
      %+  murn  ~(tap in wait.v)
      |=  call-id=@t
      ^-  (unit card)
      =/  name  (requested-tool ses call-id)
      ?~  name  ~
      ?.  |(=(u.name 'http_fetch') =(u.name 'list_mcp_tools') =(u.name 'call_mcp_tool'))  ~
      `[%pass `wire`[%tool `@ta`sid.act `@ta`call-id ~] %arvo %i %cancel-request ~]
    =?  withdrawn  ?=(^ pending.v)
      :_  withdrawn
      :*  %pass  `wire`[%llm `@ta`sid.act (scot %ud req.u.pending.v) kind.u.pending.v ~]
          %arvo  %i  %cancel-request  ~
      ==
    =/  req=(unit @ud)  ?~(pending.v ~ `req.u.pending.v)
    =/  event=event:h
      [%cancelled req wait.v 'cancelled by client']
    =.  streams
      %-  ~(gas by *(map [session-id:h @ud] stream-progress))
      (skip ~(tap by streams) |=([[s=session-id:h @ud] stream-progress] =(s sid.act)))
    =^  cards  ses  (record-all sid.act ses ~[event])
    =.  sessions  (~(put by sessions) sid.act ses)
    =.  hands  (cancel-queued:hd hands sid.act)
    ::  Cancellation owes a terminal result to every kind of waiter, including
    ::  a parent session or peer. Use the same boundary as normal completion.
    =^  settled  state  (settle sid.act)
    [:(weld cards withdrawn ~[(shadow-put-card sid.act ses)] settled) state]
  ::
      %delete
    ?>  !(lien ~(val by bindings.hands) |=(b=binding:hh =(sid.b sid.act)))
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
      (rest-card:effects s name at:(~(got by timers) [s name]))
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
    =.  cards  (weld cards (shadow-del-card sid))
    =.  sessions  (~(del by sessions) sid)
    =/  prompt  (~(get by acp-prompts) sid)
    =?  cards  ?=(^ prompt)
      (snoc cards (acp-error-card:wire-codec connection.u.prompt request-id.u.prompt '-32603' 'Session deleted'))
    =.  acp-prompts  (~(del by acp-prompts) sid)
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
      (put-key:auth provider-keys (credential-for-url:auth url.cfg) key.cfg)
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
        ~[(rest-card:effects sid.act name.act at.u.old)]
      ::
        ~[(wait-card:effects sid.act name.act at)]
    ==
  ::
      %timer-cancel
    =/  key  [sid.act name.act]
    =/  old  (~(get by timers) key)
    ?~  old  `state
    :-  ~[(rest-card:effects sid.act name.act at.u.old)]
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
      (put-key:auth provider-keys (credential-for-url:auth url.cfg) key.cfg)
    `state(peer-base `cfg(key ''))
  ::
      %defaults
    =/  cfg=config:h  config.act
    =?  provider-keys  !=('' key.cfg)
      (put-key:auth provider-keys (credential-for-url:auth url.cfg) key.cfg)
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
  ::  A wakeup cannot splice input into a hand's active turn. Keep the timer
  ::  durable and reconsider at a session boundary without dropping the wake.
  ?:  (~(has by active.hands) sid)
    =/  at=@da  (add now.bowl ~s5)
    [~[(wait-card:effects sid name at)] state(timers (~(put by timers) key u.mt(at at)))]
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
    :-  ~[(wait-card:effects sid name at2)]
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
  =/  stp  (next:hs v (skills-visible sid skills))
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
      ?.  (tool-granted:ht name.c tools.config.v)
        %=  acc  evs
          %+  snoc  evs.acc
          `event:h`[%tool-completed id.c name.c 'rejected: tool is not granted for this session']
        ==
      ?:  =(name.c 'write_skill')
        =/  nam  (tool-str:effects args.c 'name')
        =/  dsc  (tool-str:effects args.c 'description')
        =/  bod  (tool-str:effects args.c 'body')
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
        =/  nam  (tool-str:effects args.c 'name')
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
        =/  nam  (tool-str:effects args.c 'name')
        =/  dsc  (tool-str:effects args.c 'description')
        =/  bod  (tool-str:effects args.c 'body')
        ?.  &(?=(^ nam) ?=(^ dsc) ?=(^ bod))
          acc(evs (snoc evs.acc [%tool-completed id.c name.c 'error: need name, description, body']))
        %=  acc
          stg  (~(put by stg.acc) u.nam [u.dsc u.bod])
          evs  %+  snoc  evs.acc
               `event:h`[%tool-completed id.c name.c (rap 3 'skill \'' u.nam '\' staged — rehearse it before committing' ~)]
        ==
      ?:  =(name.c 'commit_skill')
        =/  nam  (tool-str:effects args.c 'name')
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
        =/  nam  (tool-str:effects args.c 'name')
        ?~  nam
          acc(evs (snoc evs.acc [%tool-completed id.c name.c 'error: bad name argument']))
        %=  acc
          stg  (~(del by stg.acc) u.nam)
          evs  %+  snoc  evs.acc
               `event:h`[%tool-completed id.c name.c (rap 3 'staged skill \'' u.nam '\' discarded' ~)]
        ==
      ?:  =(name.c 'rehearse_skill')
        =/  nam  (tool-str:effects args.c 'name')
        =/  inp  (tool-str:effects args.c 'input')
        ?.  &(?=(^ nam) ?=(^ inp))
          acc(evs (snoc evs.acc [%tool-completed id.c name.c 'error: need name and input']))
        %=  acc
          evs     (snoc evs.acc `event:h`[%tool-requested id.c name.c])
          tcards  (snoc tcards.acc (rehearse-poke:effects sid id.c u.nam u.inp))
        ==
      ::  run_js: reject synchronously on the loop guard or bad args so
      ::  the model gets immediate feedback; otherwise self-poke to spawn
      ::  the thread (needs state access to record the tid)
      ::
      ?:  =(name.c 'run_js')
        =/  code  (tool-str:effects args.c 'code')
        ?~  code
          acc(evs (snoc evs.acc [%tool-completed id.c name.c 'error: need code argument']))
        =/  reject  (js-loop-guard:ht u.code)
        ?^  reject
          acc(evs (snoc evs.acc [%tool-completed id.c name.c u.reject]))
        %=  acc
          evs     (snoc evs.acc `event:h`[%tool-requested id.c name.c])
          tcards  (snoc tcards.acc (run-js-poke:effects sid id.c u.code))
        ==
      =/  async=(unit (unit card))
        ?:  =(name.c 'http_fetch')     `(fetch-card:effects sid c)
        ?:  |(=(name.c 'list_mcp_tools') =(name.c 'call_mcp_tool'))
          `(mcp-card:effects sid c)
        ?:  =(name.c 'run_subagent')   `(spawn-card:effects sid c)
        ?:  =(name.c 'ask_peer')       `(ask-peer-card:effects sid c)
        ~
      ?~  async
        acc(evs (snoc evs.acc (run-tool:effects c (skills-visible sid sk.acc))))
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
    =^  cs  ses  (start-compaction sid ses ~)
    $(cards (weld cards cs))
  ::
      %halt
    ::  record the halt (sets err, stops the loop) and stop driving
    ::
    =^  cs  ses  (record-all sid ses ~[[%halted reason.u.stp]])
    [(weld cards cs) ses skills staged]
  ==
::  The plan event and request are emitted atomically. Coverage refers to the
::  pre-dispatch log and active prefix, not whatever happens to be current when
::  Iris finishes. A command is acknowledged only after completion (or refusal).
++  start-compaction
  |=  [sid=session-id:h ses=session:h input=(unit input-id:h)]
  ^-  [(list card) session:h]
  =/  v  (play:hl log.ses)
  =/  missing  (missing:auth provider-keys config.v)
  ?^  missing  (record-all sid ses ~[[%halted u.missing]])
  =/  visible  (skills-visible sid skills)
  =/  planned
    (plan:context v (lent log.ses) input |=(candidate=view:h (estimate:hp candidate %compaction visible)))
  ?:  ?=(%| -.planned)
    =/  event=event:h
      ?~  input  [%halted (cat 3 'context budget: ' p.planned)]
      [%command-completed u.input 'compact' p.planned]
    (record-all sid ses ~[event])
  =/  req  next-req.ses
  =.  next-req.ses  +(req)
  =^  cs  ses  (record-all sid ses ~[[%compaction-planned req p.planned]])
  :-  :+  (llm-card sid req %compaction v(items (scag count.p.planned items.v)))
          [%pass `wire`[%compact-timeout `@ta`sid (scot %ud req) (scot %uv (sham log.ses)) ~] %arvo %b %wait (add now.bowl ~m3)]
          cs
  ses
++  compact-timeout
  |=  [sid=session-id:h req=@ud checkpoint=@uvH]
  ^-  (quip card _state)
  =/  current  (~(get by sessions) sid)
  ?~  current  `state
  =/  ses  u.current
  =/  v  (play:hl log.ses)
  ?.  =(pending.v `[req %compaction])  `state
  ?~  compaction.v  `state
  ::  Session titles can currently be reused after deletion. Include the exact
  ::  dispatch log (with admitted input identity/time), not just a small request
  ::  counter, so an old watchdog cannot cancel work in a recreated session.
  =/  at  +(through.u.compaction.v)
  ?.  =(checkpoint (sham (slag (sub (lent log.ses) at) log.ses)))  `state
  =^  recorded  ses
    (record-all sid ses ~[[%compaction-failed req 'Compaction timed out; the previous context was retained.' [0 0]]])
  =^  settled  state  (drive-put sid ses)
  :-  [[%pass `wire`[%llm `@ta`sid (scot %ud req) %compaction ~] %arvo %i %cancel-request ~] (weld recorded settled)]
  state
::  +issue-llm: record the request marker and pass to iris
::
::  Provider execution: reserve identity before dispatch. The codec never
::  sees credential storage; this boundary resolves the key at execution time.
++  issue-llm
  |=  [sid=session-id:h ses=session:h kind=request-kind:h v=view:h]
  ^-  [(list card) session:h]
  =/  missing  (missing:auth provider-keys config.v)
  ?^  missing  (record-all sid ses ~[[%halted u.missing]])
  =/  req  next-req.ses
  =.  next-req.ses  +(req)
  =^  cs  ses  (record-all sid ses ~[[%llm-requested req kind]])
  [(snoc cs (llm-card sid req kind v)) ses]
++  provider-key
  |=  provider=@t
  ^-  @t
  =/  stored=@t  (key:auth provider-keys provider)
  ?:  !=('' stored)  stored
  ?:(=('openrouter' provider) api-key '')
++  model-list-card
  |=  [req=@ud provider=@t url=@t]
  ^-  card
  =/  key=@t  (provider-key ?:(=('openai' provider) ?:((device-route:auth url) 'openai-device' 'openai') provider))
  =/  hed=header-list:http  ~[['accept' 'application/json']]
  =?  hed  !=('' key)
    [['authorization' (cat 3 'Bearer ' key)] hed]
  =/  account  (provider-key 'openai-account')
  =?  hed  &(!=('' account) =('openai' provider) (device-route:auth url))
    [['chatgpt-account-id' account] hed]
  :*  %pass  `wire`[%models (scot %ud req) ~]
      %arvo  %i  %request  [%'GET' url hed ~]  *outbound-config:iris
  ==
::
++  llm-card
  |=  [sid=session-id:h req=@ud kind=request-kind:h v=view:h]
  ^-  card
  =/  payload=json
    (payload:hp v kind (skills-visible sid skills))
  =/  body=@t  (en:json:html payload)
  ::  blank session key falls back to the agent-level default
  ::
  =/  eff-key=@t
    ?:(=('' key.config.v) (provider-key (credential-for-url:auth url.config.v)) key.config.v)
  =/  =request:http
    :*  %'POST'
        url.config.v
        =/  hed=header-list:http
          [['content-type' 'application/json'] (headers:auth provider-keys url.config.v headers.config.v)]
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
    ?.  =(%turn kind)  `state
    =/  incremental  incremental.res
    ?~  incremental  `state
    =/  key  [sid req]
    =/  prior=stream-progress  (fall (~(get by streams) key) ['' 0])
    =/  body=@t  (cat 3 body.prior q.u.incremental)
    =/  responses=?
      =('https://chatgpt.com/backend-api/codex/responses' url.config.v)
    =/  text=@t  (stream-text:hp body responses)
    =/  total=@ud  (met 3 text)
    =/  sent=@ud  sent.prior
    =.  streams  (~(put by streams) key [body total])
    ?.  (gth total sent)  `state
    =/  delta=@t  (cut 3 [sent (sub total sent)] text)
    =/  prompt  (~(get by acp-prompts) sid)
    ?~  prompt  `state
    [~[(acp-stream-card:wire-codec connection.u.prompt sid delta)] state]
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
    =/  request-url=@t
      ?~(compaction.v url.config.v url.u.compaction.v)
    =/  responses=?  =('https://chatgpt.com/backend-api/codex/responses' request-url)
    =/  digest
      ?:  responses
        (mule |.((parse-responses-sse:hp u.body)))
      =/  streamed  (mule |.((parse-chat-sse:hp u.body)))
      ?:  ?&  ?=(%& -.streamed)
              ?=(%& -.p.streamed)
          ==
        streamed
      =/  jon  (de:json:html u.body)
      ?~  jon  [%| 'invalid json in response']
      (mule |.((parse-response:hp u.jon)))
    ?:  ?=(%| -.digest)
      [%llm-failed req 'failed to digest response']
    =/  out  p.digest
    ?:  ?=(%| -.out)  [%llm-failed req p.out]
    ?:  ?=(%compaction kind)
      ?~  compaction.v
        [%compaction-failed req 'Compaction has no source plan; the previous context was retained. Retry explicitly.' u.p.out]
      =/  invalid  (validate:context v u.compaction.v stop.p.out it.p.out)
      ?^  invalid  [%compaction-failed req u.invalid u.p.out]
      ?>  ?=([%assistant * ~] it.p.out)
      =/  reply=(unit [input-id=input-id:h body=@t])
        ?~  command.u.compaction.v  ~
        `[u.command.u.compaction.v 'Context compacted. The recent turn and full source transcript were retained.']
      [%checkpoint-completed req body.it.p.out u.p.out reply]
    [%llm-completed req stop.p.out u.p.out it.p.out]
  =?  ev  &(?=(%llm-failed -.ev) =(%compaction kind))
    [%compaction-failed req err.ev [0 0]]
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
    [~[(acp-error-card:wire-codec connection.u.pending request-id.u.pending '-32603' 'Model catalog request was cancelled')] state]
  =/  status  status-code.response-header.res
  =/  body=(unit @t)
    ?~  full-file.res  ~
    `q.data.u.full-file.res
  ?.  &((gte status 200) (lth status 300))
    [~[(acp-error-card:wire-codec connection.u.pending request-id.u.pending '-32603' (cat 3 'Model catalog returned HTTP ' (scot %ud status)))] state]
  ?~  body
    [~[(acp-error-card:wire-codec connection.u.pending request-id.u.pending '-32603' 'Model catalog returned an empty response')] state]
  =/  jon  (de:json:html u.body)
  ?~  jon
    [~[(acp-error-card:wire-codec connection.u.pending request-id.u.pending '-32603' 'Model catalog returned invalid JSON')] state]
  =/  parsed  (mole |.((parse-model-list:hp u.jon)))
  ?~  parsed
    [~[(acp-error-card:wire-codec connection.u.pending request-id.u.pending '-32603' 'Model catalog has an unsupported shape')] state]
  =/  info=(list model-info:hp)  u.parsed
  =/  result=json
    %-  pairs:enjs:format
    :~  ['models' %a (turn info |=(model=model-info:hp `json`[%s id.model]))]
        ['modelInfo' %a (turn info model-info-json:hp)]
    ==
  [~[(acp-result-card:wire-codec connection.u.pending request-id.u.pending result)] state]
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
::  Self-pokes are not ambient authority: both a grant and an outstanding
::  request must still exist when the asynchronous operation starts/finishes.
++  authorized-call
  |=  [sid=session-id:h call-id=@t name=@t]
  ^-  ?
  =/  maybe  (~(get by sessions) sid)
  ?~  maybe  |
  =/  v  (play:hl log.u.maybe)
  ?.  (~(has in wait.v) call-id)  |
  ?.  (tool-granted:ht name tools.config.v)  |
  =/  requested  (requested-tool u.maybe call-id)
  ?~  requested  |
  =(name u.requested)
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
      (clip:ht q.data.u.full-file.res 8.000)
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
  =^  cs4  state  (settle-hands sid)
  [:(weld cs1 cs2 cs3 cs4) state]
::
++  settle-acp
  |=  sid=session-id:h
  ^-  (quip card _state)
  =/  prompt  (~(get by acp-prompts) sid)
  ?~  prompt  `state
  =/  mses  (~(get by sessions) sid)
  ?~  mses  `state(acp-prompts (~(del by acp-prompts) sid))
  =/  v  (play:hl log.u.mses)
  =/  transcript  (transcript-items:hl log.u.mses)
  =/  updates  (acp-item-cards:wire-codec connection.u.prompt sid cursor.u.prompt transcript)
  =.  acp-prompts
    (~(put by acp-prompts) sid [connection.u.prompt request-id.u.prompt (lent transcript)])
  =/  outcome  (outcome:hl v)
  ?~  outcome  [updates state]
  =.  acp-prompts  (~(del by acp-prompts) sid)
  ?:  ?=(%cancelled -.u.outcome)
    [:(weld updates ~[(acp-result-card:wire-codec connection.u.prompt request-id.u.prompt (pairs:enjs:format ~[['stopReason' %s 'cancelled']]))]) state]
  ?:  ?=(%failure -.u.outcome)
    [(weld updates ~[(acp-error-card:wire-codec connection.u.prompt request-id.u.prompt '-32603' reason.u.outcome)]) state]
  =/  stop=@t  (acp-stop-reason:wire-codec log.u.mses)
  =/  result=json  (pairs:enjs:format ~[['stopReason' %s stop]])
  =/  finish=card  (acp-result-card:wire-codec connection.u.prompt request-id.u.prompt result)
  [(weld updates ~[finish]) state]
::
++  settle-sub
  |=  sid=session-id:h
  ^-  (quip card _state)
  =/  link  (~(get by subs) sid)
  ?~  link  `state
  =/  mses  (~(get by sessions) sid)
  ?~  mses  `state
  =/  result  (outcome:hl (play:hl log.u.mses))
  ?~  result  `state
  =/  body=@t
    ?-  -.u.result
      %reply      body.u.result
      %failure    (cat 3 'error: subagent failed: ' reason.u.result)
      %cancelled  (cat 3 'error: subagent cancelled: ' reason.u.result)
    ==
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
    ~[[%tool-completed call-id.u.link tool-name body]]
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
  =/  outcome  (outcome:hl (play:hl log.u.mses))
  ?~  outcome  `state
  =/  result=(each @t @t)
    ?-  -.u.outcome
      %reply      [%& body.u.outcome]
      %failure    [%| (cat 3 'error: ' reason.u.outcome)]
      %cancelled  [%| (cat 3 'cancelled: ' reason.u.outcome)]
    ==
  :_  state(serving (~(del by serving) sid))
  %+  turn  u.q
  |=  [=ship id=ask-id:h]
  (answer-card:effects ship id result)
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
      [~[(answer-card:effects src id.msg [%| 'no grant for your ship'])] state]
    =/  mbase  peer-base
    ?~  mbase
      [~[(answer-card:effects src id.msg [%| 'peer serving not configured'])] state]
    =/  base  u.mbase
    =/  sid=session-id:h  (cat 3 'peer--' (scot %p src))
    ?:  (lien ~(val by bindings.hands) |=(b=binding:hh =(sid.b sid)))
      [~[(answer-card:effects src id.msg [%| 'Session reserved for hand bindings'])] state]
    =/  mses  (~(get by sessions) sid)
    ?:  ?&  !=(0 budget.u.g)
            ?=(^ mses)
            =/  v  (play:hl log.u.mses)
            (gte (add prompt.total.v completion.total.v) budget.u.g)
        ==
      [~[(answer-card:effects src id.msg [%| 'budget exhausted'])] state]
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
::  eyre: webhooks admit input from the outside world
::
++  serve
  |=  [eyre-id=@ta req=inbound-request:eyre]
  ^-  (quip card _state)
  =/  bad
    |=  [code=@ud msg=@t]
    ^-  (quip card _state)
    [(give-http:effects eyre-id [code ~] `(as-octs:mimes:html msg)) state]
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
  ?:  (lien ~(val by bindings.hands) |=(b=binding:hh =(sid.b sid)))
    (bad 409 'Use the authenticated hand observation queue for this bound session')
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
  %^  give-http:effects  eyre-id
    [200 ~[['content-type' 'application/json']]]
  `(as-octs:mimes:html '{"ok":true}')
--
