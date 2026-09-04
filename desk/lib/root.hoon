::  Minimal root nexus for the Harness distribution.
::
/+  nexus, tarball, loader, io=fiberio, ball-api, http-utils, server
^=  nexus:nexus
|%
++  on-load
  |=  =ball:tarball
  ^-  bole:tarball
  %+  spin:loader  ball
  :~  (manifest:loader 0)
      [%load %| / / same-fold:loader]
      [%fall %| /apps [`[~ ~ %.n ~] ~]]
      [%fall %| /port [`[`[/ %port] ~ %.n ~] ~]]
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
      [[%sys %eyre %requests ~] @]
    ;<  ~  bind:m  (rise-wait:io prod "%eyre /requests: failed")
    =/  eyre-id=@ta  name.rail
    ;<  [src=@p req=inbound-request:eyre]  bind:m
      (get-state-as:io ,[src=@p inbound-request:eyre])
    =/  [site=path args=quay:eyre]  (parse-url:http-utils url.request.req)
    (dispatch:ball-api eyre-id src req site args)
  ==
--
