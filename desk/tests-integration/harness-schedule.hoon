::  Full-agent persistence and timer checks; emitted cards are never executed.
::  -test /=harness=/tests-integration/harness-schedule
/-  c=harness-cron, hh=harness-hand, h=harness, ac=acp, *harness-store
/+  *test, schedule=harness-schedule, defaults=harness-defaults, hl=harness, tools=harness-tools
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
  ^-  state-30
  =/  s=state-30  *state-30
  =.  tlon-cron-imported.s  |
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
++  test-reload-replaces-one-timer-without-spending-budget
  (isolated |=(ignored=* reload-timer))
++  test-scheduled-work-keeps-bookkeeping-and-human-reply-context
  %-  isolated  |=  ignored=*
  =/  s  fixture
  =/  cfg  defaults.s(tools ~[%workspace])
  =.  tlon-cron-imported.s  &
  =.  sessions.s  (~(put by sessions.s) 'source' [~[[%config-replaced cfg]] 1])
  =/  loaded  (~(on-load head bowl) !>(s))
  =/  act=action:c
    [%add 0v2 'source-binding' 'alice' %prompt (pairs:enjs:format ~[['at' %s '2026-09-09T00:01:17Z'] ['prompt' %s 'Finish the task and report the result']])]
  =/  out  (~(on-poke +.loaded bowl) %harness-cron !>(`request:c`['fixture' act]))
  =/  next  !<(state-30 ~(on-save +.out bowl))
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
  =.  tlon-cron-imported.s  &
  =.  schedules.s  (my ~[[0v1 job]])
  =.  schedule-wake.s  `next.job
  =/  out  (~(on-load head bowl) !>(s))
  =/  next  !<(state-30 ~(on-save +.out bowl))
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
  =.  tlon-cron-imported.s  &
  =.  schedules.s  (my ~[[0v1 job]])
  ::  A real actor makes live grant evaluation consult the identity boundary.
  ::  Loading may validate it; the subsequent read and ACK must not do so.
  =.  sessions.s
    (~(put by sessions.s) 'source' [~[[%input-received [0v9 [%acp 'fixture'] `~zod ~ ~2026.9.9 [%user 'fixture']]] [%config-replaced defaults.s]] 1])
  =/  loaded  (~(on-load head bowl) !>(s))
  =/  ready  !<(state-30 ~(on-save +.loaded bowl))
  =/  step
    |.
    =/  ack  (~(on-agent +.loaded bowl) /acp/ack [%poke-ack ~])
    =/  update=update:v1:ac
      [%messages 'fixture' %agent ~[[1 ~2026.9.9 '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}']]]
    =/  read  (~(on-agent +.ack bowl) /acp/watch [%fact %acp-update-1 !>(update)])
    =/  next  !<(state-30 ~(on-save +.read bowl))
    &(=(schedules.ready schedules.next) =(schedule-wake.ready schedule-wake.next) =(2 (lent -.read)) =(~ -.ack))
  ::  Any attempted authority scry blocks this isolated evaluation.
  =/  checked  (mink [step %9 2 %0 1] |=([* *] ~))
  ;:  weld
    (expect-eq !>(%active) !>(state:(~(got by schedules.ready) 0v1)))
    (expect !>(?=(%0 -.checked)))
    (expect !>(?:(?=(%0 -.checked) ;;(? product.checked) |)))
  ==
++  test-legacy-handoff-preserves-receipts-and-cannot-resurrect-cleared-jobs
  (isolated |=(ignored=* legacy-handoff))
++  test-added-tools-preserve-schedule-ceilings-and-revocation-pauses
  %-  isolated  |=  ignored=*
  =/  s  fixture
  =.  tlon-cron-imported.s  &
  =/  cfg  defaults.s(tools ~[%web %workspace])
  =.  sessions.s  (~(put by sessions.s) 'source' [~[[%config-replaced cfg]] 1])
  =/  j  job
  =.  tools.j  ~[%web]
  =.  schedules.s  (my ~[[0v1 j]])
  =/  loaded  (~(on-load head bowl) !>(s))
  =/  next  !<(state-30 ~(on-save +.loaded bowl))
  =.  sessions.next  (~(put by sessions.next) 'source' [~[[%config-replaced cfg(tools ~[%workspace])]] 1])
  =/  reloaded  (~(on-load head bowl) !>(next))
  =/  revoked  !<(state-30 ~(on-save +.reloaded bowl))
  ;:  weld
    (expect-eq !>(%active) !>(state:(~(got by schedules.next) 0v1)))
    (expect-eq !>(~[%web]) !>(tools:(~(got by schedules.next) 0v1)))
    (expect-eq !>(%paused) !>(state:(~(got by schedules.revoked) 0v1)))
  ==
++  legacy-handoff
  =/  s  fixture
  =.  bindings.hands.s  ~
  =/  job  job
  =/  old  (job-value:schedule job(state %complete, remaining 0, last `0v7))
  =.  observations.hands.s  (my ~[[0v7 [run-sid.job 'event' 'alice' 'body' ~2026.9.9 %completed]]])
  =.  outbox.hands.s  (my ~[[0v7 [0v7 run-sid.job 'tlon' 'room' run-sid.job %reply 'answer' %uncertain 'worker' '' ~]]])
  =/  transfer=transfer:c  [(my ~[[0v1 old]]) (my ~[[0v1 ['missing-source' 'alice']]])]
  =/  loaded  (~(on-load head bowl) !>(s))
  =/  out  (~(on-poke +.loaded bowl) %harness-cron-import !>(transfer))
  =/  next  !<(state-30 ~(on-save +.out bowl))
  =/  imported  (need (~(get by schedules.next) 0v1))
  ::  Simulate removal of settled metadata; the durable import fence survives.
  =/  cleared  next(schedules ~)
  =/  reloaded  (~(on-load head bowl) !>(cleared))
  =/  repeat  (~(on-poke +.reloaded bowl) %harness-cron-import !>(transfer))
  =/  final  !<(state-30 ~(on-save +.repeat bowl))
  ;:  weld
    (expect !>(tlon-cron-imported.next))
    (expect-eq !>(run-sid.old) !>(run-sid.imported))
    (expect-eq !>(last.old) !>(last.imported))
    (expect-eq !>(remaining.old) !>(remaining.imported))
    (expect-eq !>(observations.hands.s) !>(observations.hands.next))
    (expect-eq !>(outbox.hands.s) !>(outbox.hands.next))
    (expect !>(!(clearable:schedule (job-value:schedule imported) hands.next)))
    (expect-eq !>(`(map @uv schedule:c)`~) !>(schedules.final))
  ==
--
