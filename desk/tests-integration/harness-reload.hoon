/-  *harness-store, hn=harness-notes
::  Opt-in full-agent evaluation: -test /=harness=/tests-integration/harness-reload
/+  *test, notes=harness-notes
/=  head  /app/harness
|%
++  isolated
  |=  attempt=$-(* tang)
  ::  Assert inside the sandbox and return only a small test result. Coercing
  ::  emitted cards outside it traverses every embedded vase's complete type.
  ::  Existing agents are live, but their new endpoints are not loaded yet.
  ::  A data scry during reload must fail rather than be silently stubbed.
  =/  out
    %+  mink  [attempt %9 2 %0 1]
    |=  [ref=* raw=*]
    =/  path  ;;(path raw)
    ?:(?=([%gu *] path) ``%.y ~)
  ?>  ?=(%0 -.out)
  ;;(tang product.out)
++  reload
  |=  [bowl=bowl:gall saved=vase]
  ^-  (list card:agent:gall)
  -:(~(on-load head bowl) saved)
++  watches
  |=  cards=(list card:agent:gall)
  (skim cards |=(c=card:agent:gall ?=([%pass * %agent * %watch *] c)))
++  test-reload-opens-missing-subscriptions
  (isolated |=(ignored=* missing-subscriptions))
++  missing-subscriptions
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =/  cards  (reload bowl !>(*state-30))
  (expect-eq !>(2) !>((lent (watches cards))))
++  test-reload-reopens-acp-but-keeps-surviving-mirror
  (isolated |=(ignored=* surviving-subscriptions))
++  surviving-subscriptions
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =.  wex.bowl  (~(put by wex.bowl) [/acp/watch ~zod %acp] [& /v1/agent])
  =.  wex.bowl  (~(put by wex.bowl) [/harness-grub/sessions ~zod %harness-grub] [& /client/sessions])
  =/  saved=state-30  *state-30
  =.  sessions.saved  (my ~[['peer--~nec' [~ 1]]])
  =/  cards  (reload bowl !>(saved))
  ;:  weld
    (expect-eq !>(1) !>((lent (watches cards))))
    (expect !>((lien cards |=(c=card:agent:gall ?=([%pass [%acp %watch ~] %agent * %leave ~] c)))))
    (expect !>((lien cards |=(c=card:agent:gall ?=([%pass [%acp %watch ~] %agent * %watch *] c)))))
    (expect !>(!(lien cards |=(c=card:agent:gall ?=([%pass [%harness-grub %sessions ~] %agent * %watch *] c)))))
  ==
++  test-pending-mirror-waits-for-acknowledgement
  (isolated |=(ignored=* pending-mirror))
++  pending-mirror
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =.  wex.bowl  (~(put by wex.bowl) [/acp/watch ~zod %acp] [& /v1/agent])
  =.  wex.bowl  (~(put by wex.bowl) [/harness-grub/sessions ~zod %harness-grub] [| /client/sessions])
  =/  saved=state-30  *state-30
  =.  sessions.saved  (my ~[['fixture' [~ 1]]])
  =/  cards  (reload bowl !>(saved))
  ;:  weld
    (expect-eq !>(1) !>((lent (watches cards))))
    (expect !>(!(lien cards |=(c=card:agent:gall ?=([%pass [%harness-grub %sessions ~] %agent * %watch *] c)))))
  ==
++  test-reload-reobserves-sent-notes-write-without-dispatching-it-again
  =/  attempt
    |.
    =/  bowl=bowl:gall  *bowl:gall
    =.  our.bowl  ~zod
    =.  src.bowl  ~zod
    =.  now.bowl  ~2026.9.12
    =/  saved=state-30  *state-30
    =.  tlon-cron-imported.saved  &
    =/  args=json  (pairs:enjs:format ~[['title' %s 'Reload fixture'] ['body' %s 'Already dispatched']])
    =/  prepared  (prepare:notes workspace.saved workspace-notes.saved [%native 'reload'] 'artifact-create' args 'doc' now.bowl 0v42)
    ?>  ?=(%& -.prepared)
    =.  pending.workspace-notes.saved  `p.prepared(sent &)
    =/  rid  (request-id:notes p.prepared)
    =/  loaded  (~(on-load head bowl) !>(saved))
    =/  after-load  !<(state-30 ~(on-save +.loaded bowl))
    =/  ack  (~(on-agent +.loaded bowl) /artifact-notes/request/(scot %uv rid) [%watch-ack ~])
    =/  after-ack  !<(state-30 ~(on-save +.ack bowl))
    =/  emitted=(list card:agent:gall)  (weld -.loaded -.ack)
    ;:  weld
      (expect-eq !>(pending.workspace-notes.saved) !>(pending.workspace-notes.after-load))
      (expect-eq !>(pending.workspace-notes.saved) !>(pending.workspace-notes.after-ack))
      (expect !>((lien -.loaded |=(c=card:agent:gall ?=([%pass [%artifact-notes %request *] %agent * %watch *] c)))))
      (expect !>(!(lien emitted |=(c=card:agent:gall ?=([%pass * %agent * %poke %notes-action-1 *] c)))))
    ==
  ::  These cards are inspected, never delivered to the installed Notes agent.
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  ;;(tang product.out)
--
