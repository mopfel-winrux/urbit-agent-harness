::  Two isolated heads; emitted provider/network cards never leave the fixture.
/-  h=harness, w=harness-workspace, adapter=harness-adapter, *harness-store
/+  *test, rpc=harness-peer-rpc, defaults=harness-defaults, work=harness-workspace, hl=harness, effects=harness-effects
/=  head  /app/harness
|%
++  isolated
  |=  run=$-(* tang)
  =/  attempt  |.((run ~))
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  ;;(tang product.out)
++  fixture
  |=  other=@p
  ^-  state-0
  =/  saved=state-0  *state-0
  =.  saved  saved(defaults builtin-config:defaults, local-mcp-seen 1, welcome-seen 1)
  =.  peers.saved  (my ~[[other [~[%workspace %peers] ~ 0 ~]]])
  =/  created  (apply:work workspace.saved [& [0v0 'Owner'] 0v0] [%task-create 'task' '' 'A bounded part of the goal' 'Return a checked result.'] ~2026.9.14)
  ?>  ?=(%& -.created)
  saved(workspace p.created)
++  test-peer-context-identifies-the-authenticated-home-and-local-boundary
  %-  isolated  |=  ignored=*
  =/  bowl=bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~nec, now ~2026.9.14)
  =/  saved  (fixture ~nec)
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  received  (~(on-poke +.loaded bowl) %harness-a2a-0 !>(`a2a:h`[%ask 0v1 %text 'Complete the supplied home task.']))
  =/  next  !<(state-0 ~(on-save +.received bowl))
  =/  v  (play:hl log:(~(got by sessions.next) 'peer--~nec'))
  %-  zing
  %+  turn  ~['running on ~zod' 'authenticated request from ~nec' 'Workspace records are ship-local' 'call_peer_tool' 'current id and version' 'without changing trust']
  |=  part=@t
  (expect !>(?=(^ (find (trip part) (trip system.config.v)))))
++  test-active-peer-work-rejects-overlap-and-deduplicates-the-request
  %-  isolated  |=  ignored=*
  =/  bowl=bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~nec, now ~2026.9.14)
  =/  loaded  (~(on-load head bowl) !>((fixture ~nec)))
  =/  first  (~(on-poke +.loaded bowl) %harness-a2a-0 !>(`a2a:h`[%ask 0v1 %text 'Finish this task.']))
  =/  before  !<(state-0 ~(on-save +.first bowl))
  =/  duplicate  (~(on-poke +.first bowl) %harness-a2a-0 !>(`a2a:h`[%ask 0v1 %text 'Finish this task.']))
  =/  repeated  !<(state-0 ~(on-save +.duplicate bowl))
  =/  overlap  (~(on-poke +.duplicate bowl) %harness-a2a-0 !>(`a2a:h`[%ask 0v2 %text 'Another assignment must not replace active work.']))
  =/  rejected  !<(state-0 ~(on-save +.overlap bowl))
  ;:  weld
    (expect-eq !>(sessions.before) !>(sessions.repeated))
    (expect-eq !>(sessions.before) !>(sessions.rejected))
    (expect-eq !>(serving.before) !>(serving.rejected))
    (expect-eq !>(~) !>(-.duplicate))
    (expect-eq !>(1) !>((lent -.overlap)))
  ==
++  test-peer-failure-replies-do-not-forward-private-provider-details
  %-  isolated  |=  ignored=*
  =/  saved  (fixture ~nec)
  =/  cfg  defaults.saved
  =.  sessions.saved
    (my ~[['peer--~nec' [~[[%llm-failed 0 'provider error: overloaded_error SYNTHETIC_SECRET'] [%llm-requested 0 %turn] [%input-received [0v1 [%peer ~nec 0v1] `~nec `[%peer ~nec 0v1] ~2026.9.14 [%user 'Check the assigned work']]] [%config-replaced cfg]] 1]]])
  =.  serving.saved  (my ~[['peer--~nec' ~[[~nec 0v1]]]])
  =/  bowl=bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~zod, now ~2026.9.14)
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  out  (~(on-poke +.loaded bowl) %harness-action !>(`action:h`[%config 'peer--~nec' cfg ~s30]))
  =/  replies
    %+  murn  -.out
    |=  card=card:agent:gall
    ^-  (unit @t)
    ?.  ?=([%pass * %agent * %poke %harness-a2a-0 *] card)  ~
    =/  msg  !<(a2a:h +.+.+.+.+.+.card)
    ?.  ?=([%answer * [%| *]] msg)  ~
    `p.result.msg
  ?>  ?=(^ replies)
  ;:  weld
    (expect !>(=(~ (find "SYNTHETIC_SECRET" (trip i.replies)))))
    (expect !>(?=(^ (find "temporarily unavailable" (trip i.replies)))))
  ==
++  call
  |=  [action=@t args=@t]
  (en:json:html (pairs:enjs:format ~[['action' %s action] ['args' (need (de:json:html args))]]))
++  test-peer-call-encodes-an-object-once-and-rejects-invalid-shapes
  =/  bowl=bowl:gall  *bowl:gall
  =/  executor  ~(. effects [bowl ~])
  =/  invoke  |=  raw=@t
    (peer-rpc-card:executor 'source' 1 ['call' 'call_peer_tool' raw])
  =/  valid  (invoke '{"ship":"~nec","name":"workspace","arguments":{"action":"help","args":{}}}')
  ?>  ?=(^ valid)
  ?>  ?=([%pass * %agent * %poke * *] u.valid)
  =/  effect  !<(effect:h +.+.+.+.+.+.u.valid)
  ?>  ?=(%peer-rpc -.act.effect)
  ;:  weld
    (expect-eq !>((need (de:json:html '{"action":"help","args":{}}'))) !>((need (de:json:html args.act.effect))))
    (expect-eq !>(~) !>((invoke 'not-json')))
    (expect-eq !>(~) !>((invoke '{"ship":"~nec","name":"workspace"}')))
    (expect-eq !>(~) !>((invoke '{"ship":"~nec","name":"workspace","arguments":"{}"}')))
    (expect-eq !>(~) !>((invoke '{"ship":"~nec","name":"workspace","arguments":[]}')))
  ==
++  test-tracked-ask-carries-the-authenticated-home-reference
  =/  bowl=bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod)
  =/  executor  ~(. effects [bowl ~])
  =/  invoke  |=  raw=@t
    (ask-peer-card:executor 'source' 1 ['call' 'ask_peer' raw])
  =/  linked  (invoke '{"ship":"~nec","prompt":"Verify the result","task":"task-1"}')
  ?>  ?=(^ linked)
  ?>  ?=([%pass * %agent * %poke * *] u.linked)
  =/  effect  !<(effect:h +.+.+.+.+.+.u.linked)
  ?>  ?=(%ask-peer -.act.effect)
  =/  plain  (invoke '{"ship":"~nec","prompt":"Check the weather"}')
  ?>  ?=(^ plain)
  ?>  ?=([%pass * %agent * %poke * *] u.plain)
  =/  plain-effect  !<(effect:h +.+.+.+.+.+.u.plain)
  ?>  ?=(%ask-peer -.act.plain-effect)
  ;:  weld
    (expect-eq !>(~nec) !>(ship.act.effect))
    (expect !>(?=(^ (find (trip '"home":"~zod"') (trip prompt.act.effect)))))
    (expect !>(?=(^ (find (trip '"id":"task-1"') (trip prompt.act.effect)))))
    (expect !>(?=(^ (find "Verify the result" (trip prompt.act.effect)))))
    (expect-eq !>('Check the weather') !>(prompt.act.plain-effect))
    (expect-eq !>(~) !>((invoke '{"ship":"~nec","prompt":"Check","task":null}')))
    (expect-eq !>(~) !>((invoke '{"ship":"~nec","prompt":"Check","task":42}')))
    (expect-eq !>(~) !>((invoke '{"ship":"~nec","prompt":"Check","task":""}')))
  ==
++  receive
  |=  [saved=state-0 our=@p source=@p id=@uv action=@t args=@t revoke=?]
  ^-  state-0
  =/  bowl=bowl:gall  *bowl:gall
  =.  bowl  bowl(our our, src source, now ~2026.9.14)
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  arguments  (call action args)
  =/  admitted  (~(on-poke +.loaded bowl) %harness-rpc-0 !>(`peer-rpc:h`[%invoke id now.bowl 'workspace' arguments]))
  =/  pending  !<(state-0 ~(on-save +.admitted bowl))
  =/  sid  (cat 3 'peer-tool--' (scot %p source))
  ?.  (~(has by peer-active.pending) sid)  pending
  =?  pending  revoke  pending(peers ~)
  =/  resumed  (~(on-load head bowl(src our)) !>(pending))
  =/  req=tool-request:adapter  [sid next-req:(~(got by sessions.pending) sid) [(call-id:rpc id now.bowl) 'workspace' arguments]]
  =/  executed  (~(on-poke +.resumed bowl(src our)) %harness-tool !>(req))
  !<(state-0 ~(on-save +.executed bowl))
++  test-trusted-peers-claim-and-complete-home-tasks-in-both-directions
  %-  isolated  |=  ignored=*
  =/  a  (receive (fixture ~nec) ~zod ~nec 0v1 'task-claim' '{"id":"task","version":1}' |)
  =/  b  (receive (fixture ~zod) ~nec ~zod 0v2 'task-claim' '{"id":"task","version":1}' |)
  =/  done  (receive a ~zod ~nec 0v3 'task-update' '{"id":"task","version":2,"status":"done","outcome":"Checked result"}' |)
  =/  denied  (receive b ~nec ~zod 0v4 'task-update' '{"id":"task","version":2,"status":"done"}' &)
  =/  first  (~(got by tasks.workspace.a) 'task')
  =/  second  (~(got by tasks.workspace.b) 'task')
  ;:  weld
    (expect-eq !>(%claimed) !>(status.first))
    (expect-eq !>(%claimed) !>(status.second))
    (expect-eq !>('Agent on ~nec') !>(label:(need claimant.first)))
    (expect-eq !>('Agent on ~zod') !>(label:(need claimant.second)))
    (expect-eq !>(%done) !>(status:(~(got by tasks.workspace.done) 'task')))
    (expect-eq !>('Checked result') !>(outcome:(~(got by tasks.workspace.done) 'task')))
    (expect-eq !>(tasks.workspace.b) !>(tasks.workspace.denied))
    (expect-eq !>(~) !>(projects.workspace.done))
    (expect-eq !>(~) !>(requests.work-controls.done))
  ==
++  test-malformed-work-arguments-give-an-actionable-shape-without-writing
  %-  isolated  |=  ignored=*
  =/  saved  (fixture ~nec)
  =/  next  (receive saved ~zod ~nec 0v1 'task' '"not-an-object"' |)
  =/  replies  (murn log:(~(got by sessions.next) 'peer-tool--~nec') |=(e=event:h ?:(?=(%tool-completed -.e) `body.e ~)))
  ?>  ?=(^ replies)
  ;:  weld
    (expect-eq !>(workspace.saved) !>(workspace.next))
    (expect !>(?=(^ (find "top-level action" (trip i.replies)))))
    (expect !>(?=(^ (find (trip '{"action":"help","args":{}}') (trip i.replies)))))
  ==
++  outgoing
  |=  [saved=state-0 name=@t args=@t act=action:h]
  ^-  state-0
  =/  bowl=bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~zod, now ~2026.9.14)
  =/  cfg  defaults.saved(tools ~[%peers])
  =/  call=tool-call:h  ['call' name args]
  =.  sessions.saved
    (my ~[['coordinator' [~[[%tool-requested-2 1 'call' name] [%llm-completed 0 %tool-calls [1 1] [%assistant '' ~[call]]] [%input-received [0v1 [%poke ~zod] `~zod ~ now.bowl [%user 'Pursue the goal']]] [%config-replaced cfg]] 1]]])
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  out  (~(on-poke +.loaded bowl) %harness-effect !>(`effect:h`[1 act]))
  !<(state-0 ~(on-save +.out bowl))
++  test-outgoing-work-needs-reciprocal-grants-but-discovery-does-not
  %-  isolated  |=  ignored=*
  =/  trusted  (fixture ~nec)
  =/  untrusted  trusted(peers ~)
  =/  plain  trusted(peers (my ~[[~nec [~ ~ 0 ~]]]))
  =/  args  '{"ship":"~nec","name":"workspace","arguments":{}}'
  =/  act=action:h  [%peer-rpc 'coordinator' 'call' ~nec `'workspace' '{}']
  =/  allowed  (outgoing trusted 'call_peer_tool' args act)
  =/  denied  (outgoing untrusted 'call_peer_tool' args act)
  =/  no-work  (outgoing plain 'call_peer_tool' args act)
  =/  discovered  (outgoing untrusted 'list_peer_tools' '{"ship":"~nec"}' [%peer-rpc 'coordinator' 'call' ~nec ~ '{}'])
  =/  no-ask  (outgoing untrusted 'ask_peer' '{"ship":"~nec","prompt":"Do this work"}' [%ask-peer 'coordinator' 'call' ~nec 'Do this work'])
  ;:  weld
    (expect-eq !>(1) !>(~(wyt by asks.allowed)))
    (expect-eq !>(~) !>(asks.denied))
    (expect-eq !>(~) !>(asks.no-work))
    (expect-eq !>(1) !>(~(wyt by asks.discovered)))
    (expect-eq !>(~) !>(asks.no-ask))
    (expect !>((lien log:(~(got by sessions.denied) 'coordinator') |=(e=event:h ?=(%tool-completed -.e)))))
  ==
++  test-revocation-rejects-peer-work-results-without-retrying
  %-  isolated  |=  ignored=*
  %-  zing
  %+  turn  ~['ask_peer' 'call_peer_tool' 'list_peer_tools']
  |=  name=@t
  =/  args  '{"ship":"~nec","name":"workspace","arguments":{},"prompt":"Do this work"}'
  =/  action=action:h
    ?:  =('ask_peer' name)  [%ask-peer 'coordinator' 'call' ~nec 'Do this work']
    [%peer-rpc 'coordinator' 'call' ~nec ?:(=('list_peer_tools' name) ~ `'workspace') '{}']
  =/  pending  (outgoing (fixture ~nec) name args action)
  =/  rows  ~(tap by asks.pending)
  ?>  ?=(^ rows)
  =/  id  p.i.rows
  =.  peers.pending  ~
  =/  bowl=bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~nec, now ~2026.9.14)
  =/  loaded  (~(on-load head bowl) !>(pending))
  =/  response
    ?:  =('ask_peer' name)
      (~(on-poke +.loaded bowl) %harness-a2a-0 !>(`a2a:h`[%answer id [%& 'Remote response']]))
    (~(on-poke +.loaded bowl) %harness-rpc-0 !>(`peer-rpc:h`[%result id [%& 'Remote response']]))
  =/  settled  !<(state-0 ~(on-save +.response bowl))
  =/  replies  (murn log:(~(got by sessions.settled) 'coordinator') |=(e=event:h ?:(?=(%tool-completed -.e) `body.e ~)))
  ?>  ?=(^ replies)
  ;:  weld
    (expect-eq !>(~) !>(asks.settled))
    (expect-eq !>(=('list_peer_tools' name)) !>(=('Remote response' i.replies)))
    (expect-eq !>(workspace.pending) !>(workspace.settled))
  ==
++  test-peer-timeout-preserves-uncertainty-and-never-resends
  %-  isolated  |=  ignored=*
  =/  pending  (outgoing (fixture ~nec) 'ask_peer' '{"ship":"~nec","prompt":"Do this work"}' [%ask-peer 'coordinator' 'call' ~nec 'Do this work'])
  =/  rows  ~(tap by asks.pending)
  ?>  ?=(^ rows)
  =/  id  p.i.rows
  =/  bowl=bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~zod, now ~2026.9.14..00.03.00)
  =/  loaded  (~(on-load head bowl) !>(pending))
  =/  out  (~(on-arvo +.loaded bowl) `wire`[%a2a-timeout (scot %uv id) ~] [%behn %wake ~])
  =/  next  !<(state-0 ~(on-save +.out bowl))
  =/  replies  (murn log:(~(got by sessions.next) 'coordinator') |=(e=event:h ?:(?=(%tool-completed -.e) `body.e ~)))
  ?>  ?=(^ replies)
  ;:  weld
    (expect-eq !>(~) !>(asks.next))
    (expect !>(?=(^ (find "may still be running" (trip i.replies)))))
    (expect !>(?=(^ (find "Do not resend or reassign" (trip i.replies)))))
    (expect !>(?=(^ (find "Read the home task" (trip i.replies)))))
  ==
--
