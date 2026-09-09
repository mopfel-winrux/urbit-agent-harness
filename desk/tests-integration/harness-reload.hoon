/-  *harness-store
::  Opt-in full-agent evaluation: -test /=harness=/tests-integration/harness-reload
/+  *test
/=  head  /app/harness
|%
++  reload
  |=  [bowl=bowl:gall saved=vase]
  ^-  (list card:agent:gall)
  ::  Synthetic bowls must never escape into the running ship's namespace.
  =/  attempt  |.(-:(~(on-load head bowl) saved))
  ::  Existing agents are live, but their new endpoints are not loaded yet.
  ::  A data scry during reload must fail rather than be silently stubbed.
  =/  out
    %+  mink  [attempt %9 2 %0 1]
    |=  [ref=* raw=*]
    =/  path  ;;(path raw)
    ?:(=(%gu (head path)) ``%.y ~)
  ?>  ?=(%0 -.out)
  ;;((list card:agent:gall) product.out)
++  watches
  |=  cards=(list card:agent:gall)
  (skim cards |=(c=card:agent:gall ?=([%pass * %agent * %watch *] c)))
++  test-reload-opens-missing-subscriptions
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =/  cards  (reload bowl !>(*state-13))
  (expect-eq !>(2) !>((lent (watches cards))))
++  test-reload-keeps-surviving-subscriptions
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =.  wex.bowl  (~(put by wex.bowl) [/acp/watch ~zod %acp] [& /v1/agent])
  =.  wex.bowl  (~(put by wex.bowl) [/harness-grub/sessions ~zod %harness-grub] [& /client/sessions])
  =/  saved=state-13  *state-13
  =.  sessions.saved  (my ~[['peer--~nec' [~ 1]]])
  =/  cards  (reload bowl !>(saved))
  ;:  weld
    (expect-eq !>(~) !>((watches cards)))
    (expect-eq !>(3) !>((lent cards)))
  ==
++  test-pending-mirror-waits-for-acknowledgement
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =.  wex.bowl  (~(put by wex.bowl) [/acp/watch ~zod %acp] [& /v1/agent])
  =.  wex.bowl  (~(put by wex.bowl) [/harness-grub/sessions ~zod %harness-grub] [| /client/sessions])
  =/  saved=state-13  *state-13
  =.  sessions.saved  (my ~[['fixture' [~ 1]]])
  =/  cards  (reload bowl !>(saved))
  (expect-eq !>(3) !>((lent cards)))
--
