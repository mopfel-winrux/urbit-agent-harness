::  Opt-in full agent: -test /=harness=/tests-integration/harness-peer-sync
/-  h=harness, *harness-store
/+  *test
/=  head  /app/harness
|%
++  poke
  |=  [saved=state-20 act=action:h no-scries=?]
  ^-  [(list card:agent:gall) state-20]
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =.  src.bowl  ~zod
  =.  now.bowl  ~2026.9.8
  =.  local-mcp-seen.saved  1
  =/  attempt
    |.
    =/  loaded  (~(on-load head bowl) !>(saved))
    =/  step
      |.
      =/  out  (~(on-poke +.loaded bowl) %harness-action !>(act))
      [-.out !<(state-20 ~(on-save +.out bowl))]
    =/  out  (mink [step %9 2 %0 1] |=([* *] ?:(no-scries ~ ``%.n)))
    ?>  ?=(%0 -.out)
    product.out
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  ;;([(list card:agent:gall) state-20] product.out)
++  test-local-grant-and-revocation-announce-once
  =/  first  (poke *state-20 [%grant ~nec [~[%web] ~ 0 ~]] |)
  =/  same  (poke +.first [%grant ~nec [~[%web] ~ 0 ~]] &)
  =/  removed  (poke +.same [%revoke ~nec] |)
  ;:  weld
    (expect-eq !>(1) !>((lent -.first)))
    (expect-eq !>(~) !>(-.same))
    (expect-eq !>(1) !>((lent -.removed)))
    (expect-eq !>(~) !>(announced-access:+.removed))
  ==
++  test-routine-acknowledgements-do-not-read-other-agents
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =.  now.bowl  ~2026.9.8
  =/  saved=state-20  *state-20
  ::  Even an undiscovered/absent MCP agent must not add callback scries.
  =.  local-mcp-seen.saved  0
  =/  attempt
    |.
    =/  loaded  (~(on-load head bowl) !>(saved))
    =/  step  |.((~(on-agent +.loaded bowl) /acp/ack [%poke-ack ~]))
    ::  An attempted scry blocks evaluation. Ordinary callbacks need none.
    =/  out  (mink [step %9 2 %0 1] |=([* *] ~))
    ?=(%0 -.out)
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  (expect !>(;;(? product.out)))
++  test-existing-remote-report-does-not-refresh-local-permissions
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =.  src.bowl  ~nec
  =.  now.bowl  ~2026.9.8
  =/  saved=state-20  *state-20
  =.  local-mcp-seen.saved  1
  =.  remote-access.saved  (my ~[[~nec [~ ~2026.9.7]]])
  =/  attempt
    |.
    =/  loaded  (~(on-load head bowl) !>(saved))
    =/  step
      |.
      (~(on-poke +.loaded bowl) %harness-access-0 !>(`peer-access-message:h`[%status ~ ~]))
    =/  out  (mink [step %9 2 %0 1] |=([* *] ~))
    ?=(%0 -.out)
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  (expect !>(;;(? product.out)))
--
