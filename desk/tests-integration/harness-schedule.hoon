::  Full-agent persistence and timer checks; emitted cards are never executed.
::  -test /=harness=/tests-integration/harness-schedule
/-  c=harness-cron, hh=harness-hand, *harness-store
/+  *test, schedule=harness-schedule, defaults=harness-defaults
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
  ^-  state-20
  =/  s=state-20  *state-20
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
++  reload-timer
  =/  s  fixture
  =/  job  job
  =.  tlon-cron-imported.s  &
  =.  schedules.s  (my ~[[0v1 job]])
  =.  schedule-wake.s  `next.job
  =/  out  (~(on-load head bowl) !>(s))
  =/  next  !<(state-20 ~(on-save +.out bowl))
  =/  timers
    (skim -.out |=(card=card:agent:gall ?=([%pass [%schedules *] %arvo %b *] card)))
  ;:  weld
    (expect-eq !>(2) !>((lent timers)))
    (expect-eq !>(schedules.s) !>(schedules.next))
    (expect-eq !>(schedule-wake.s) !>(schedule-wake.next))
  ==
++  test-legacy-handoff-preserves-receipts-and-cannot-resurrect-cleared-jobs
  (isolated |=(ignored=* legacy-handoff))
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
  =/  next  !<(state-20 ~(on-save +.out bowl))
  =/  imported  (need (~(get by schedules.next) 0v1))
  ::  Simulate removal of settled metadata; the durable import fence survives.
  =/  cleared  next(schedules ~)
  =/  reloaded  (~(on-load head bowl) !>(cleared))
  =/  repeat  (~(on-poke +.reloaded bowl) %harness-cron-import !>(transfer))
  =/  final  !<(state-20 ~(on-save +.repeat bowl))
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
