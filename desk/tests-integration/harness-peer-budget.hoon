::  Exercise the owner reset endpoint against saved fixture logs, without
::  executing emitted inference/network cards or touching a running session.
::  Opt-in: -test /=harness=/tests-integration/harness-peer-budget
::  Full-agent virtual evaluation is slow; keep it out of the fast suite.
/-  h=harness, ac=acp, *harness-store
/+  *test, peers=harness-peer-policy, defaults=harness-defaults, hl=harness
/=  head  /app/harness
|%
++  fixture
  ^-  state-19
  =/  saved=state-19  *state-19
  =.  defaults.saved  builtin-config:defaults
  =.  peers.saved  (my ~[[~nec [~ ~ 100 ~]]])
  =.  sessions.saved
    %-  my
    ~[['peer--~nec' [~[[%llm-completed 0 %stop [100 20] [%assistant 'Retain this reply' ~]] [%config-replaced defaults.saved]] 1]]]
  saved
++  invoke
  |=  [saved=state-19 method=@t params=json]
  ^-  [(list card:agent:gall) state-19]
  ::  Optional live bindings are absent in this fixture. Never forward its
  ::  synthetic bowl scries to the ship running the tests.
  =/  attempt  |.((invoke-raw saved method params))
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  ;;([(list card:agent:gall) state-19] product.out)
++  invoke-raw
  |=  [saved=state-19 method=@t params=json]
  ^-  [(list card:agent:gall) state-19]
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =.  src.bowl  ~zod
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  payload
    %-  en:json:html
    (pairs:enjs:format ~[['jsonrpc' %s '2.0'] ['id' %n '1'] ['method' %s method] ['params' params]])
  =/  update=update:v1:ac  [%messages 'budget-fixture' %agent ~[[1 now.bowl payload]]]
  =/  out  (~(on-agent +.loaded bowl) /acp/watch [%fact %acp-update-1 !>(update)])
  [-.out !<(state-19 ~(on-save +.out bowl))]
++  reset-params
  |=  [saved=state-19 ship=@p]
  (pairs:enjs:format ~[['ship' %s (scot %p ship)] ['revision' %s (revision:peers peers.saved ~ peer-base.saved peer-limits.saved)]])
++  test-reset-keeps-history-grants-and-limit-and-survives-reload
  =/  saved  fixture
  =/  out  (invoke saved 'harness/peers/reset' (reset-params saved ~nec))
  =/  next  +.out
  =/  baseline  (fall (~(get by peer-budget-resets.next) ~nec) 0)
  =/  v  (play:hl log:(need (~(get by sessions.next) 'peer--~nec')))
  =/  reloaded  (invoke next(acp-through ~) 'harness/peers' ~)
  ;:  weld
    (expect-eq !>(120) !>(baseline))
    (expect-eq !>(0) !>((used:peers (add prompt.total.v completion.total.v) baseline)))
    (expect-eq !>(sessions.saved) !>(sessions.next))
    (expect-eq !>(peers.saved) !>(peers.next))
    (expect-eq !>(peer-limits.saved) !>(peer-limits.next))
    (expect-eq !>(peer-budget-resets.next) !>(peer-budget-resets:+.reloaded))
  ==
++  test-invalid-and-stale-resets-do-not-change-counts
  =/  saved  fixture
  =/  invalid  (invoke saved 'harness/peers/reset' (reset-params saved ~bud))
  =/  stale  (invoke saved 'harness/peers/reset' (pairs:enjs:format ~[['ship' %s '~nec'] ['revision' %s 'stale']]))
  (expect !>(&(=(~ peer-budget-resets:+.invalid) =(~ peer-budget-resets:+.stale))))
++  test-deleting-peer-session-clears-only-its-reset-baseline
  =/  attempt  |.(delete-fixture)
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  ;;(tang product.out)
++  delete-fixture
  =/  saved  fixture
  =.  peer-budget-resets.saved  (my ~[[~nec 120] [~bud 7]])
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =.  src.bowl  ~zod
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  out  (~(on-poke +.loaded bowl) %harness-action !>(`action:h`[%delete 'peer--~nec']))
  =/  next  !<(state-19 ~(on-save +.out bowl))
  (expect !>(&(!(~(has by sessions.next) 'peer--~nec') =((my ~[[~bud 7]]) peer-budget-resets.next))))
--
