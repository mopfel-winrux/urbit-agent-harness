::  Full-agent persistence and timer checks; emitted cards are never executed.
::  -test /=harness=/tests-integration/harness-schedule
/-  c=harness-cron, hh=harness-hand, h=harness, ac=acp, renew=harness-oauth, adapter=harness-adapter, *harness-store
/+  *test, schedule=harness-schedule, defaults=harness-defaults, hl=harness, tools=harness-tools, auth=harness-auth
/=  head  /app/harness
|%
++  bowl
  ^-  bowl:gall
  =/  b=bowl:gall  *bowl:gall
  b(our ~zod, src ~zod, now ~2026.9.9)
++  job
  ^-  schedule:c
  =/  act=action:c
    [%add 0v1 'source-binding' 'alice' %prompt (pairs:enjs:format ~[['schedule' %s '* * * * *'] ['timezone' %s 'UTC'] ['prompt' %s 'Check status'] ['runs' %s '2']])]
  (create:schedule act ['fixture-chat' 'room' 'source' ~['alice'] &] ~ ~2026.9.9)
++  fixture
  ^-  state-0
  =/  s=state-0  *state-0
  =/  cfg  builtin-config:defaults
  =.  defaults.s  cfg(tools ~)
  =.  sessions.s
    (my ~[['source' [~[[%config-replaced defaults.s]] 1]] ['schedule-0v1' [~[[%config-replaced defaults.s]] 2]]])
  =.  bindings.hands.s
    (my ~[['source-binding' ['fixture-chat' 'room' 'source' ~['alice'] &]] ['schedule-0v1' ['fixture-chat' 'room' 'schedule-0v1' ~['alice'] &]]])
  s
++  isolated
  |=  attempt=$-(* tang)
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  ;;(tang product.out)
++  test-delete-detaches-hands-and-cancels-source-and-run-schedules
  %-  isolated  |=  ignored=*
  %-  zing
  %+  turn  `(list @t)`~['source' 'schedule-0v1']
  |=  sid=@t
  =/  s  fixture
  =.  schedules.s  (my ~[[0v1 job]])
  =/  loaded  (~(on-load head bowl) !>(s))
  =/  payload
    %-  en:json:html
    (pairs:enjs:format ~[['jsonrpc' %s '2.0'] ['id' %n '1'] ['method' %s 'session/delete'] ['params' (pairs:enjs:format ~[['sessionId' %s sid]])]])
  =/  update=update:v1:ac  [%messages 'fixture' %agent ~[[1 ~2026.9.9 payload]]]
  =/  out  (~(on-agent +.loaded bowl) /acp/watch [%fact %acp-update-1 !>(update)])
  =/  next  !<(state-0 ~(on-save +.out bowl))
  ;:  weld
    (expect !>(!(~(has by sessions.next) sid)))
    (expect-eq !>(%cancelled) !>(state:(~(got by schedules.next) 0v1)))
    (expect !>(!enabled:(~(got by bindings.hands.next) 'schedule-0v1')))
    (expect !>(!(lien ~(val by bindings.hands.next) |=(b=binding:hh &(=(sid sid.b) enabled.b)))))
    (expect-eq !>(~) !>((requests -.out)))
  ==
++  test-reload-replaces-one-timer-without-spending-budget
  (isolated |=(ignored=* reload-timer))
++  test-delete-cancels-running-and-queued-input-without-publishing
  %-  isolated  |=  ignored=*
  =/  s  fixture
  =.  sessions.s
    (~(put by sessions.s) 'source' [~[[%llm-requested 0 %turn] [%input-admitted [%user 'Running input']] [%config-replaced defaults.s]] 1])
  =.  observations.hands.s
    (my ~[[0v1 ['source-binding' 'running' 'alice' 'Running input' ~2026.9.9 %running]] [0v2 ['source-binding' 'queued' 'alice' 'Queued input' ~2026.9.9 %queued]]])
  =.  active.hands.s  (my ~[['source' 0v1]])
  =.  queue.hands.s  ~[0v2]
  =/  loaded  (~(on-load head bowl) !>(s))
  =/  out  (~(on-poke +.loaded bowl) %harness-action !>(`action:h`[%delete 'source']))
  =/  next  !<(state-0 ~(on-save +.out bowl))
  ;:  weld
    (expect !>(!(~(has by sessions.next) 'source')))
    (expect-eq !>(~) !>(active.hands.next))
    (expect-eq !>(~) !>(queue.hands.next))
    (expect-eq !>(%cancelled) !>(phase:(~(got by observations.hands.next) 0v1)))
    (expect-eq !>(%cancelled) !>(phase:(~(got by observations.hands.next) 0v2)))
    (expect-eq !>(%abandoned) !>(status:(~(got by outbox.hands.next) 0v1)))
    (expect-eq !>(~) !>((requests -.out)))
  ==
++  test-scheduled-work-keeps-bookkeeping-and-human-reply-context
  %-  isolated  |=  ignored=*
  =/  s  fixture
  =/  cfg  defaults.s(tools ~[%workspace])
  =.  sessions.s  (~(put by sessions.s) 'source' [~[[%config-replaced cfg]] 1])
  =/  loaded  (~(on-load head bowl) !>(s))
  =/  act=action:c
    [%add 0v2 'source-binding' 'alice' %prompt (pairs:enjs:format ~[['at' %s '2026-09-09T00:01:17Z'] ['prompt' %s 'Finish the task and report the result']])]
  =/  out  (~(on-poke +.loaded bowl) %harness-cron !>(`request:c`['fixture' act]))
  =/  next  !<(state-0 ~(on-save +.out bowl))
  =/  v  (play:hl log:(~(got by sessions.next) 'schedule-0v2'))
  ;:  weld
    (expect !>((tool-granted:tools 'workspace' tools.config.v)))
    (expect-eq !>(~2026.9.9..00.01.17) !>(next:(~(got by schedules.next) 0v2)))
    (expect !>((tool-granted:tools 'calculate' tools.config.v)))
    (expect !>(!(tool-granted:tools 'schedule_once' tools.config.v)))
    (expect !>(!(tool-granted:tools 'harness_admin' tools.config.v)))
    (expect !>(?=(^ (find "Your final message goes directly to the human" (trip system.config.v)))))
    (expect !>(?=(^ (find "maintain its records silently" (trip system.config.v)))))
    (expect !>(?=(^ (find "Internal task references in the brief are for tools only" (trip system.config.v)))))
    (expect !>(?=(^ (find "both work records and the reply" (trip system.config.v)))))
    (expect-eq !>(~) !>(items.v))
  ==
++  reload-timer
  =/  s  fixture
  =/  job  job
  =.  schedules.s  (my ~[[0v1 job]])
  =.  schedule-wake.s  `next.job
  =/  out  (~(on-load head bowl) !>(s))
  =/  next  !<(state-0 ~(on-save +.out bowl))
  =/  timers
    (skim -.out |=(card=card:agent:gall ?=([%pass [%schedules *] %arvo %b *] card)))
  ;:  weld
    (expect-eq !>(2) !>((lent timers)))
    (expect-eq !>(schedules.s) !>(schedules.next))
    (expect-eq !>(schedule-wake.s) !>(schedule-wake.next))
  ==
++  test-reads-and-acks-with-an-active-schedule-do-not-read-authority
  (isolated |=(ignored=* read-cadence))
++  read-cadence
  =/  s  fixture
  =/  job  job
  =.  tools.job  ~[%admin]
  =.  schedules.s  (my ~[[0v1 job]])
  ::  A real actor makes live grant evaluation consult the identity boundary.
  ::  Loading may validate it; the subsequent read and ACK must not do so.
  =.  sessions.s
    (~(put by sessions.s) 'source' [~[[%input-received [0v9 [%acp 'fixture'] `~zod ~ ~2026.9.9 [%user 'fixture']]] [%config-replaced defaults.s]] 1])
  =/  loaded  (~(on-load head bowl) !>(s))
  =/  ready  !<(state-0 ~(on-save +.loaded bowl))
  =/  step
    |.
    =/  ack  (~(on-agent +.loaded bowl) /acp/ack [%poke-ack ~])
    =/  update=update:v1:ac
      [%messages 'fixture' %agent ~[[1 ~2026.9.9 '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}']]]
    =/  read  (~(on-agent +.ack bowl) /acp/watch [%fact %acp-update-1 !>(update)])
    =/  next  !<(state-0 ~(on-save +.read bowl))
    &(=(schedules.ready schedules.next) =(schedule-wake.ready schedule-wake.next) =(2 (lent -.read)) =(~ -.ack))
  ::  Any attempted authority scry blocks this isolated evaluation.
  =/  checked  (mink [step %9 2 %0 1] |=([* *] ~))
  ;:  weld
    (expect-eq !>(%active) !>(state:(~(got by schedules.ready) 0v1)))
    (expect !>(?=(%0 -.checked)))
    (expect !>(?:(?=(%0 -.checked) ;;(? product.checked) |)))
  ==
++  test-added-tools-preserve-schedule-ceilings-and-revocation-pauses
  %-  isolated  |=  ignored=*
  =/  s  fixture
  =/  cfg  defaults.s(tools ~[%web %workspace])
  =.  sessions.s  (~(put by sessions.s) 'source' [~[[%config-replaced cfg]] 1])
  =/  j  job
  =.  tools.j  ~[%web]
  =.  schedules.s  (my ~[[0v1 j]])
  =/  loaded  (~(on-load head bowl) !>(s))
  =/  next  !<(state-0 ~(on-save +.loaded bowl))
  =.  sessions.next  (~(put by sessions.next) 'source' [~[[%config-replaced cfg(tools ~[%workspace])]] 1])
  =/  reloaded  (~(on-load head bowl) !>(next))
  =/  revoked  !<(state-0 ~(on-save +.reloaded bowl))
  ;:  weld
    (expect-eq !>(%active) !>(state:(~(got by schedules.next) 0v1)))
    (expect-eq !>(~[%web]) !>(tools:(~(got by schedules.next) 0v1)))
    (expect-eq !>(%paused) !>(state:(~(got by schedules.revoked) 0v1)))
  ==
++  test-edit-is-versioned-and-delete-retains-history
  %-  isolated  |=  ignored=*
  =/  s  fixture
  =.  schedules.s  (my ~[[0v1 job]])
  =/  loaded  (~(on-load head bowl) !>(s))
  =/  args  (pairs:enjs:format ~[['schedule' %s '0 9 * * *'] ['timezone' %s 'UTC'] ['prompt' %s 'Check deployment status'] ['runs' %s '5']])
  =/  request=request:c  ['edit' [%edit 0v1 (sham job) args]]
  =/  edited  (~(on-poke +.loaded bowl) %harness-cron !>(request))
  =/  next  !<(state-0 ~(on-save +.edited bowl))
  =/  stale  (~(on-poke +.edited bowl) %harness-cron !>(request))
  =/  unchanged  !<(state-0 ~(on-save +.stale bowl))
  =/  deleted  (~(on-poke +.stale bowl) %harness-cron !>(`request:c`['delete' [%delete 0v1]]))
  =/  final  !<(state-0 ~(on-save +.deleted bowl))
  ;:  weld
    (expect-eq !>('Check deployment status') !>(prompt:(~(got by schedules.next) 0v1)))
    (expect-eq !>(5) !>(remaining:(~(got by schedules.next) 0v1)))
    (expect-eq !>(schedules.next) !>(schedules.unchanged))
    (expect-eq !>(~) !>(schedules.final))
    (expect !>((~(has by sessions.final) 'schedule-0v1')))
    (expect !>(!enabled:(~(got by bindings.hands.final) 'schedule-0v1')))
  ==
++  requests
  |=  cards=(list card:agent:gall)
  ^-  (list http-card:renew)
  (murn cards |=(c=card:agent:gall ^-((unit http-card:renew) ?:(?=([%pass [%llm *] %arvo %i %request *] c) `c ~))))
++  failed-fixture
  ^-  state-0
  =/  s  fixture
  =/  j  job
  =.  last.j  `0v9
  =.  schedules.s  (my ~[[0v1 j]])
  =/  cfg  defaults.s(url device-url:auth, model 'fixture-model')
  =/  input=admitted-input:h  [0v9 [%hand run-sid.j hand.j destination.j 'tick' actor.j] ~ `[%hand run-sid.j] ~2026.9.9 [%user prompt.j]]
  =/  log=(list event:h)
    :~  [%llm-failed 2 'http error 401: token_expired']
        [%llm-requested 2 %turn]
        [%tool-completed 'status' 'current_time' '2026-09-09T00:00:00Z']
        [%tool-requested 'status' 'current_time']
        [%llm-completed 1 %tool-calls [0 0] [%assistant '' ~[['status' 'current_time' '{}']]]]
        [%llm-requested 1 %turn]
        [%input-received input]
        [%config-replaced cfg]
    ==
  =.  sessions.s  (~(put by sessions.s) run-sid.j [log 3])
  =.  provider-keys.s  (my ~[['openai-device' 'current-subscription-token']])
  =.  observations.hands.s  (my ~[[0v9 [run-sid.j 'tick' actor.j prompt.j ~2026.9.9 %failed]]])
  =.  outbox.hands.s  (my ~[[0v9 [0v9 run-sid.j hand.j destination.j run-sid.j %failure 'Authentication failed' %delivered 'worker' 'failure-post' ~]]])
  s
++  test-retry-uses-shared-login-preserves-budget-and-publishes-once
  %-  isolated  |=  ignored=*
  =/  s  failed-fixture
  =/  loaded  (~(on-load head bowl) !>(s))
  =/  request=request:c  ['retry' [%retry 0v1 0v9]]
  =/  retried  (~(on-poke +.loaded bowl) %harness-cron !>(request))
  =/  next  !<(state-0 ~(on-save +.retried bowl))
  =/  http  (snag 0 (requests -.retried))
  =/  duplicate  (~(on-poke +.retried bowl) %harness-cron !>(request))
  =/  success=client-response:iris
    [%finished [200 ~] `['text/event-stream' (as-octs:mimes:html 'data: {"type":"response.output_item.done","item":{"type":"message","role":"assistant","content":[{"type":"output_text","text":"Deployment is healthy."}]}}\0a\0adata: {"type":"response.completed","response":{"usage":{"input_tokens":30,"output_tokens":5}}}\0a\0a')]]
  =/  completed  (~(on-arvo +.duplicate bowl) wire.http [%iris %http-response success])
  =/  final  !<(state-0 ~(on-save +.completed bowl))
  =/  j  (~(got by schedules.final) 0v1)
  =/  publication  (~(got by outbox.hands.final) (need last.j))
  =/  late  (~(on-arvo +.completed bowl) wire.http [%iris %http-response success])
  =/  repeated  !<(state-0 ~(on-save +.late bowl))
  ;:  weld
    (expect-eq !>(1) !>((lent (requests -.retried))))
    (expect !>((lien header-list.request.http |=([key=@t value=@t] &(=('authorization' key) =('Bearer current-subscription-token' value))))))
    (expect-eq !>(2) !>(remaining.j))
    (expect-eq !>(next:(~(got by schedules.s) 0v1)) !>(next.j))
    (expect-eq !>(~) !>((requests -.duplicate)))
    (expect-eq !>(items:(play:hl log:(~(got by sessions.s) run-sid.j))) !>(items:(play:hl log:(~(got by sessions.next) run-sid.j))))
    (expect-eq !>(%reply) !>(kind.publication))
    (expect-eq !>('Deployment is healthy.') !>(body.publication))
    (expect-eq !>(%pending) !>(status.publication))
    (expect-eq !>(2) !>(~(wyt by outbox.hands.final)))
    (expect-eq !>(outbox.hands.final) !>(outbox.hands.repeated))
  ==
++  test-retry-refuses-uncertain-delivery-and-revoked-authority
  %-  isolated  |=  ignored=*
  %-  zing
  %+  turn  `(list ?)`~[%.y %.n]
  |=  uncertain=?
  ^-  tang
  =/  s  failed-fixture
  =/  pub  (~(got by outbox.hands.s) 0v9)
  =?  outbox.hands.s  uncertain  (my ~[[0v9 pub(status %uncertain)]])
  =?  bindings.hands.s  !uncertain
    (~(put by bindings.hands.s) 'source-binding' ['fixture-chat' 'room' 'source' ~['alice'] |])
  =/  loaded  (~(on-load head bowl) !>(s))
  =/  retried  (~(on-poke +.loaded bowl) %harness-cron !>(`request:c`['retry' [%retry 0v1 0v9]]))
  =/  final  !<(state-0 ~(on-save +.retried bowl))
  ;:  weld
    (expect-eq !>(~) !>((requests -.retried)))
    (expect-eq !>(`0v9) !>(last:(~(got by schedules.final) 0v1)))
  ==
++  tool-fixture
  |=  [name=@t args=@t actor=@t]
  ^-  state-0
  =/  s  fixture
  =/  job  job
  =/  cfg  defaults.s
  =/  call=tool-call:h  ['control' name args]
  =/  input=admitted-input:h  [0v8 [%hand 'source-binding' 'fixture-chat' 'room' 'human-request' actor] ~ `[%hand 'source-binding'] ~2026.9.9 [%user 'Manage my schedule']]
  =/  log=(list event:h)
    ~[[%tool-requested-2 4 'control' name] [%llm-completed 3 %tool-calls [0 0] [%assistant '' ~[call]]] [%llm-requested 3 %turn] [%input-received input] [%config-replaced cfg]]
  =.  sessions.s  (~(put by sessions.s) 'source' [log 4])
  =.  observations.hands.s  (my ~[[0v8 ['source-binding' 'human-request' actor 'Manage my schedule' ~2026.9.9 %running]]])
  =.  active.hands.s  (my ~[['source' 0v8]])
  =.  schedules.s  (my ~[[0v1 job] [0v2 job(actor 'bob', run-sid 'schedule-0v2', prompt 'PRIVATE-BOB')] [0v3 job(binding 'elsewhere', run-sid 'schedule-0v3', prompt 'PRIVATE-ROOM')]])
  s
++  test-tool-list-hides-other-users-and-other-conversations
  %-  isolated  |=  ignored=*
  =/  loaded  (~(on-load head bowl) !>((tool-fixture 'cron_list' '{}' 'alice')))
  =/  req=tool-request:adapter  ['source' 4 ['control' 'cron_list' '{}']]
  =/  out  (~(on-poke +.loaded bowl) %harness-tool !>(req))
  =/  body=@t
    =/  fact  (need (lien-card -.out))
    !<(@t q.cage.sign.fact)
  ;:  weld
    (expect !>(?=(^ (find "Check status" (trip body)))))
    (expect !>(?=(~ (find "PRIVATE" (trip body)))))
  ==
++  lien-card
  |=  cards=(list card:agent:gall)
  ^-  (unit [dt=%give sign=[tag=%fact paths=(list path) cage=cage]])
  ?~  cards  ~
  ?:  ?=([%give %fact * *] i.cards)  `i.cards
  $(cards t.cards)
++  test-tools-refuse-other-actors-cross-binding-and-revoked-callers
  %-  isolated  |=  ignored=*
  %-  zing
  %+  turn  `(list @t)`~['alice' 'mallory']
  |=  actor=@t
  ^-  tang
  %-  zing
  %+  turn  `(list @t)`~['cron_remove' 'cron_delete' 'cron_update' 'cron_retry']
  |=  name=@t
  ^-  tang
  =/  args  '{"id":"0v2","revision":"0v0","input":"0v9","args":{}}'
  =/  initial  (tool-fixture name args actor)
  =/  loaded  (~(on-load head bowl) !>(initial))
  =/  before  !<(state-0 ~(on-save +.loaded bowl))
  =/  req=tool-request:adapter  ['source' 4 ['control' name args]]
  =/  out  (~(on-poke +.loaded bowl) %harness-tool !>(req))
  =/  next  !<(state-0 ~(on-save +.out bowl))
  ;:  weld
    (expect-eq !>(schedules.before) !>(schedules.next))
    (expect-eq !>(~) !>((requests -.out)))
  ==
++  test-permissioned-human-can-delete-own-schedule
  %-  isolated  |=  ignored=*
  =/  args  '{"id":"0v1"}'
  =/  initial  (tool-fixture 'cron_delete' args 'alice')
  =/  loaded  (~(on-load head bowl) !>(initial))
  =/  req=tool-request:adapter  ['source' 4 ['control' 'cron_delete' args]]
  =/  out  (~(on-poke +.loaded bowl) %harness-tool !>(req))
  =/  next  !<(state-0 ~(on-save +.out bowl))
  ;:  weld
    (expect !>(!(~(has by schedules.next) 0v1)))
    (expect !>((~(has by schedules.next) 0v2)))
    (expect !>((~(has by schedules.next) 0v3)))
  ==
--
