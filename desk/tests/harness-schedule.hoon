/-  c=harness-cron, hh=harness-hand, h=harness, *harness-store
/+  *test, schedule=harness-schedule, hd=harness-hand, ht=harness-tools, storage=harness-store
|%
++  source
  ^-  binding:hh
  ['fixture-chat' 'room/launch' 'source' ~['alice'] &]
++  action
  ^-  $>(%add action:c)
  [%add 0v1 'source-binding' 'alice' %prompt (pairs:enjs:format ~[['schedule' %s '* * * * *'] ['timezone' %s 'UTC'] ['prompt' %s 'Check launch status'] ['runs' %s '2']])]
++  job
  ^-  schedule:c
  (create:schedule action source ~[%web] ~2026.9.9)
++  test-scheduler-has-no-tlon-dependency
  =/  job  job
  ;:  weld
    (expect-eq !>('fixture-chat') !>(hand.job))
    (expect-eq !>('room/launch') !>(destination.job))
    (expect-eq !>('source-binding') !>(binding.job))
    (expect-eq !>('alice') !>(actor.job))
    (expect-eq !>(`%harness) !>((tool-hand:ht 'cron_add')))
  ==
++  test-unknown-actor-and-disabled-binding-rejected
  =/  action  action
  =/  source  source
  =/  wrong  (mule |.((create:schedule action(actor 'mallory') source ~ ~2026.9.9)))
  =/  disabled  (mule |.((create:schedule action source(enabled |) ~ ~2026.9.9)))
  (expect !>(&(?=(%| -.wrong) ?=(%| -.disabled))))
++  test-reminder-cannot-change-hand-destination
  =/  action  action
  =/  args  (pairs:enjs:format ~[['at' %s '2026-09-10T10:00:00-05:00'] ['destination' %s 'another-room'] ['text' %s 'literal text']])
  =/  wrong  (mule |.((create:schedule action(kind %reminder, args args) source ~ ~2026.9.9)))
  (expect !>(?=(%| -.wrong)))
++  test-valid-reminder-keeps-timezone-and-literal-body
  =/  action  action
  =/  args  (pairs:enjs:format ~[['at' %s '2026-09-10T10:00:00-05:00'] ['destination' %s 'room/launch'] ['text' %s '/cancel is literal reminder text']])
  =/  out  (create:schedule action(kind %reminder, args args) source ~ ~2026.9.9)
  ;:  weld
    (expect-eq !>(%reminder) !>(kind.out))
    (expect-eq !>('UTC-05:00') !>(timezone.out))
    (expect-eq !>('/cancel is literal reminder text') !>(prompt.out))
    (expect-eq !>(1) !>(remaining.out))
  ==
++  test-downtime-coalesces-and-run-budget-terminates
  =/  once  (advance:schedule job 0v1 ~2026.9.10..12.00.30)
  =/  done  (advance:schedule once 0v2 ~2026.9.10..12.02.00)
  ;:  weld
    (expect-eq !>(1) !>(remaining.once))
    (expect-eq !>(~2026.9.10..12.01.00) !>(next.once))
    (expect-eq !>(%complete) !>(state.done))
    (expect-eq !>(0) !>(remaining.done))
  ==
++  test-pending-and-uncertain-work-prevent-overlap-and-clear
  =/  job  job
  =/  db=state:hh  *state:hh
  =.  observations.db  (my ~[[0v1 [run-sid.job 'event' 'alice' 'test' ~2026.9.9 %completed]]])
  =.  outbox.db  (my ~[[0v1 [0v1 run-sid.job hand.job destination.job run-sid.job %reply 'answer' %uncertain 'worker' '' ~]]])
  =/  done  (job-value:schedule job(state %complete, remaining 0, last `0v1))
  ;:  weld
    (expect !>((busy:schedule done db)))
    (expect !>(!(clearable:schedule done db)))
    (expect !>((clearable:schedule done db(outbox ~))))
  ==
++  test-clearing-unfired-cancelled-job-keeps-budget-unused
  =/  job  job
  (expect !>((clearable:schedule (job-value:schedule job(state %cancelled)) *state:hh)))
++  test-source-binding-scopes-list-results
  =/  job  job
  =/  jobs  (my ~[[0v1 job] [0v2 job(binding 'another-binding')]])
  =/  result  (list-json:schedule jobs *state:hh `'source-binding')
  ?>  ?=(%a -.result)
  (expect-eq !>(1) !>((lent p.result)))
++  test-schedules-strip-recursion-delegation-and-administration
  (expect-eq !>(`(list tool-grant:h)`~[%web]) !>((scheduled-tools:ht ~[%cron %subagents %code %admin %web])))
++  test-store-upgrade-preserves-prior-state-and-starts-one-empty-scheduler
  =/  old=state-19  *state-19
  =.  sessions.old  (my ~[['source' [~ 7]]])
  =.  provider-keys.old  (my ~[['fixture' 'synthetic-secret']])
  =/  loaded  (load:storage !>(old))
  ;:  weld
    (expect-eq !>(sessions.old) !>(sessions.loaded))
    (expect-eq !>(provider-keys.old) !>(provider-keys.loaded))
    (expect-eq !>(`(map @uv schedule:c)`~) !>(schedules.loaded))
    (expect !>(!tlon-cron-imported.loaded))
  ==
--
