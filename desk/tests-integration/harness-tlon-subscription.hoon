::  Full adapter with synthetic scries; emitted effects never execute.
::  -test /=harness=/tests-integration/harness-tlon-subscription
/-  t=harness-tlon, hh=harness-hand, ad=harness-adapter
/+  *test, policy=harness-tlon-policy
/=  adapter  /app/harness-tlon
|%
++  fixture
  ^-  state-1:t
  =/  s=state-1:t  *state-1:t
  s(owner-initialized 1, policy [& `~zod ~ %mentions ~ ~], activity-through ~2026.10.1, error 'Activity recovery failed')
++  run
  |=  [saved=state-1:t sub=(unit [acked=? path=path]) event=?(%load %wake %kick %enable %disable)]
  ^-  [cards=(list card:agent:gall) saved=state-1:t]
  =/  bowl=bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~zod, now ~2026.10.1..00.00.10)
  =.  wex.bowl  (~(put by wex.bowl) [/head ~zod %harness] [& /hand-events])
  =?  wex.bowl  ?=(^ sub)
    (~(put by wex.bowl) [/activity ~zod %activity] u.sub)
  =/  attempt
    |.
    ::  A retry wake receives Gall's acknowledged watch while the saved
    ::  adapter still has watching=false, as after an acknowledgement crash.
    =/  before  ?:  =(%wake event)
      bowl(wex (~(del by wex.bowl) [/activity ~zod %activity]))
    bowl
    =/  loaded  (~(on-load adapter before) !>(saved))
    =/  out
      ?-  event
        %load  loaded
        %wake  (~(on-arvo +.loaded bowl) /poll [%behn %wake ~])
        %kick  (~(on-agent +.loaded bowl) /activity [%kick ~])
        ?(%enable %disable)
          =/  params  (policy-json:policy policy.saved(enabled =(%enable event)))
          (~(on-poke +.loaded bowl) %noun !>(`request:ad`['fixture' [%n '1'] 'harness/tlon/configure' `params]))
      ==
    ::  Project before validating the result: other effects contain large
    ::  typed payloads unrelated to subscription recovery.
    [(activity-cards -.out) !<(state-1:t ~(on-save +.out bowl))]
  =/  checked
    %+  mink  [attempt %9 2 %0 1]
    |=  [ref=* raw=*]
    ^-  (unit (unit noun))
    =/  path  ;;(path raw)
    ?:  =(%$ (rear path))  ``&
    ?:  (lien path |=(part=@ta =(%hand-state part)))  ``*state:hh
    ::  The current Activity feed is empty; its cursor remains untouched.
    ?:  (lien path |=(part=@ta =(%activity part)))  ``~
    ~
  ?>  ?=(%0 -.checked)
  ;;([cards=(list card:agent:gall) saved=state-1:t] product.checked)
++  activity-cards
  |=  cards=(list card:agent:gall)
  (skim cards |=(c=card:agent:gall ?=([%pass [%activity ~] %agent *] c)))
++  test-acknowledged-watch-repairs-local-flag-on-reload-and-retry
  =/  s  fixture
  =/  reloaded  (run fixture `[& /v4] %load)
  =/  retried  (run fixture `[& /v4] %wake)
  ;:  weld
    (expect !>(watching.saved.reloaded))
    (expect !>(watching.saved.retried))
    (expect !>(=(~ (activity-cards cards.reloaded))))
    (expect !>(=(~ (activity-cards cards.retried))))
    (expect !>(=('' error.saved.reloaded)))
    (expect !>(=(activity-through.s activity-through.saved.retried)))
  ==
++  test-pending-watch-is-not-duplicated-or-treated-as-connected
  =/  s  fixture
  =/  out  (run s(watching &) `[| /v4] %load)
  (expect !>(&(!watching.saved.out =(~ (activity-cards cards.out)) ?=(^ wake.saved.out))))
++  test-missing-watch-and-kick-create-one-watch
  =/  s  fixture
  =/  loaded  (run s(watching &) ~ %load)
  =/  kicked  (run fixture ~ %kick)
  =/  expected=(list card:agent:gall)  ~[[%pass /activity %agent [~zod %activity] %watch /v4]]
  (expect !>(&(!watching.saved.loaded =(expected (activity-cards cards.loaded)) =(expected (activity-cards cards.kicked)))))
++  test-enable-reuses-watch-and-disable-only-leaves
  =/  s  fixture
  =/  enabled  (run s(enabled.policy |) `[& /v4] %enable)
  =/  disabled  (run fixture `[& /v4] %disable)
  =/  expected=(list card:agent:gall)  ~[[%pass /activity %agent [~zod %activity] %leave ~]]
  (expect !>(&(watching.saved.enabled =(~ (activity-cards cards.enabled)) !watching.saved.disabled =(expected (activity-cards cards.disabled)))))
++  test-disabled-reload-never-subscribes
  =/  s  fixture
  =/  out  (run s(enabled.policy |, watching &) `[& /v4] %load)
  (expect !>(&(!watching.saved.out =(~ (activity-cards cards.out)))))
--
