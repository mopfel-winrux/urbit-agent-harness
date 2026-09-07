/-  *harness-store
/+  *test
/=  head  /app/harness
|%
++  watches
  |=  cards=(list card:agent:gall)
  (skim cards |=(c=card:agent:gall ?=([%pass * %agent * %watch *] c)))
++  test-reload-opens-missing-subscriptions
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =/  out  (~(on-load head bowl) !>(*state-13))
  (expect-eq !>(2) !>((lent (watches -.out))))
++  test-reload-keeps-surviving-subscriptions
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =.  wex.bowl  (~(put by wex.bowl) [/acp/watch ~zod %acp] [& /v1/agent])
  =.  wex.bowl  (~(put by wex.bowl) [/harness-grub/sessions ~zod %harness-grub] [& /client/sessions])
  =/  saved=state-13  *state-13
  =.  sessions.saved  (my ~[['fixture' [~ 1]]])
  =/  out  (~(on-load head bowl) !>(saved))
  ;:  weld
    (expect-eq !>(~) !>((watches -.out)))
    (expect-eq !>(3) !>((lent -.out)))
  ==
++  test-pending-mirror-waits-for-acknowledgement
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =.  wex.bowl  (~(put by wex.bowl) [/acp/watch ~zod %acp] [& /v1/agent])
  =.  wex.bowl  (~(put by wex.bowl) [/harness-grub/sessions ~zod %harness-grub] [| /client/sessions])
  =/  saved=state-13  *state-13
  =.  sessions.saved  (my ~[['fixture' [~ 1]]])
  =/  out  (~(on-load head bowl) !>(saved))
  (expect-eq !>(2) !>((lent -.out)))
--
