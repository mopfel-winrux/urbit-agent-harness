/+  *test, kernel=harness-kernel
|%
++  test-reload-renews-clay-read
  =/  bowl  *bowl:gall
  =/  key=arvo-resource:gall  [/clay/next/web %clay %warp ~]
  =.  ras.bowl  (~(put in ras.bowl) key)
  =.  rad.bowl
    (~(put by rad.bowl) key [%clay %warp ~zod %harness %next %z da+~2026.1.1 /web])
  =/  next=card:agent:gall
    [%pass /clay/next/web %arvo %clay %read ~ ~zod %harness %next %z da+~2026.1.2 /web]
  %+  expect-eq
    !>(~[[%pass /clay/next/web %arvo %clay %rest ~] next])
  !>((prepare:kernel bowl ~[next]))
++  test-rebind-keeps-live-handler
  =/  bowl  *bowl:gall
  =/  key=arvo-resource:gall  [/eyre/connect %eyre %binding /harness-api]
  =.  ras.bowl  (~(put in ras.bowl) key)
  =.  rad.bowl  (~(put by rad.bowl) key [%eyre %binding %harness])
  =/  =card:agent:gall
    [%pass /eyre/connect %arvo %eyre %connect /harness-api %harness]
  (expect-eq !>(~) !>((prepare:kernel bowl ~[card])))
++  test-rebind-replaces-handler
  =/  bowl  *bowl:gall
  =/  key=arvo-resource:gall  [/eyre/connect %eyre %binding /harness-api]
  =.  ras.bowl  (~(put in ras.bowl) key)
  =.  rad.bowl  (~(put by rad.bowl) key [%eyre %binding %harness])
  =/  =card:agent:gall
    [%pass /eyre/connect %arvo %eyre %connect /harness-api %harness-fileserver]
  %+  expect-eq
    !>(~[[%pass /eyre/connect %arvo %eyre %disconnect /harness-api] card])
  !>((prepare:kernel bowl ~[card]))
++  test-retry-cancels-request-on-its-own-wire
  =/  bowl  *bowl:gall
  =.  ras.bowl  (silt ~[[/request/one %iris %request] [/request/two %iris %request]])
  =/  request=card:agent:gall
    [%pass /request/one %arvo %iris %request [%'GET' 'https://example.com' ~ ~] [0 0]]
  %+  expect-eq
    !>(~[[%pass /request/one %arvo %iris %cancel-request ~] request])
  !>((prepare:kernel bowl ~[request]))
++  test-cancellation-and-creation-share-event-tracking
  =/  wait=card:agent:gall  [%pass /timer %arvo %behn %wait ~2026.1.1]
  =/  rest=card:agent:gall  [%pass /timer %arvo %behn %rest ~2026.1.1]
  %+  expect-eq
    !>(~[wait rest wait rest wait])
  !>((prepare:kernel *bowl:gall ~[wait wait rest wait]))
++  test-distinct-timers-and-agent-cards-keep-order
  =/  cards=(list card:agent:gall)
    :~  [%pass /timer %arvo %behn %wait ~2026.1.1]
        [%pass /timer %arvo %behn %wait ~2026.1.2]
        [%pass /self %agent [~zod %harness] %poke %noun !>(~)]
    ==
  (expect-eq !>(cards) !>((prepare:kernel *bowl:gall cards)))
++  test-clearing-absent-cache-is-idempotent
  =/  =card:agent:gall  [%pass /eyre/cache %arvo %eyre %set-response '/apps/harness' ~]
  (expect-eq !>(~) !>((prepare:kernel *bowl:gall ~[card])))
--
