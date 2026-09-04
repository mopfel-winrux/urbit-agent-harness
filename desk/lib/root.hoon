::  Minimal root nexus for the Harness distribution.
::
/+  nexus, tarball, loader, io=fiberio, ball-api, http-utils, server, session-nexus=harness-session-nexus
^-  nexus:nexus
|%
++  on-load
  |=  =ball:tarball
  ^-  bole:tarball
  =/  roads=(set road:tarball)
    %-  ~(gas in *(set road:tarball))
    :~  [%& %| /agents/main/sessions]
        [%& %| /agents/main/checks]
    ==
  =/  shadow-weir=weir:tarball  [roads ~ ~]
  =/  keep-shadow=fold-load:loader
    |=  old=bole:tarball
    =/  fil=pulp:tarball  (fall fil.old *pulp:tarball)
    old(fil `fil(neck ~, weir `shadow-weir))
  %+  spin:loader  ball
  :~  (manifest:loader 0)
      [%load %| / / same-fold:loader]
      [%fall %| /apps [`[~ ~ %.n ~] ~]]
      ::  Harness's durable namespace. Each conversation is a typed noun grub;
      ::  no desktop or bundled application catalog is mounted.
      [%fall %| /agents [`[~ ~ %.n ~] ~]]
      [%fall %| /agents/main [`[~ ~ %.n ~] ~]]
      [%fall %| /agents/main/profile empty-dir:loader]
      [%fall %| /agents/main/policies empty-dir:loader]
      [%fall %| /agents/main/skills empty-dir:loader]
      [%fall %| /agents/main/tools empty-dir:loader]
      [%fall %| /agents/main/sessions empty-dir:loader]
      [%fall %| /agents/main/checks empty-dir:loader]
      ::  The verifier can only write result namespaces. No cross-grub reads,
      ::  service pokes or raw Gall syscalls: no provider/network power.
      [%load %| /agents/main/shadow-inputs /agents/main/shadow-inputs keep-shadow]
      [%fall %| /agents/main/channels empty-dir:loader]
      [%fall %| /agents/main/executors empty-dir:loader]
      ::  Services required by Fibers used by the Harness tree.
      [%fall %| /sys/eyre [`[~ ~ %.n ~] ~]]
      [%fall %& [/sys/eyre %'main.server-state'] [[/ %server-state] *server-state:nexus]]
      [%fall %| /sys/eyre/requests [`[~ ~ %.n ~] ~]]
      [%fall %| /sys/behn [`[~ ~ %.n ~] ~]]
      [%fall %& [/sys/behn %'main.behn-state'] [[/ %behn-state] *behn-state:nexus]]
      [%fall %| /sys/iris [`[~ ~ %.n ~] ~]]
      [%fall %& [/sys/iris %'main.iris-state'] [[/ %iris-state] *iris-state:nexus]]
      [%fall %& [/sys/clay %'main.clay-state'] [[/ %clay-state] *clay-state:nexus]]
      [%fall %| /sys/clay/desks [`[~ ~ %.n ~] ~]]
      [%fall %| /sys/scry [`[~ ~ %.n ~] ~]]
      [%fall %& [/sys/scry %'main.sig'] [[/ %sig] ~]]
      [%fall %& [/sys/scry %'main.scry-state'] [[/ %scry-state] *scry-state:nexus]]
  ==
::
++  on-file
  |=  [=rail:tarball =blot:tarball]
  ^-  spool:fiber:nexus
  |=  =prod:fiber:nexus
  =/  m  (fiber:fiber:nexus ,~)
  ^-  process:fiber:nexus
  ?+    rail  stay:m
      [[%agents %main %shadow-inputs ~] @]
    ((on-file:session-nexus rail blot) prod)
      [[%sys %eyre %requests ~] @]
    ;<  ~  bind:m  (rise-wait:io prod "%eyre /requests: failed")
    =/  eyre-id=@ta  name.rail
    ;<  [src=@p req=inbound-request:eyre]  bind:m
      (get-state-as:io ,[src=@p inbound-request:eyre])
    =/  [site=path args=quay:eyre]  (parse-url:http-utils url.request.req)
    (dispatch:ball-api eyre-id src req site args)
  ==
--
