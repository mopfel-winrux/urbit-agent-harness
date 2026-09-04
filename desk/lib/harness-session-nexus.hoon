::  A supervised verifier, not an executor. Source and result are separate grubs.
/-  sh=harness-shadow
/+  nexus, tarball, io=fiberio, check=harness-shadow
=/  write
  |=  [road=road:tarball value=bask:tarball]
  =/  m  (fiber:fiber:nexus ,~)
  ^-  form:m
  ::  Snapshot writes are idempotent. Identity comes from destination+content,
  ::  not entropy; no read-before-write or system-service capability is needed.
  =/  wire=path  /snapshot/(scot %uv (shas %shadow-write (jam [road value])))
  ;<  ~  bind:m  (send-dart:io %node wire road %make %.y %.n %| value ~)
  (take-made:io wire)
^-  nexus:nexus
|%
++  on-load
  |=  ball=ball:tarball
  ^-  bole:tarball
  (ball-to-bole:tarball ball)
++  on-file
  |=  [rail=rail:tarball blot=blot:tarball]
  ^-  spool:fiber:nexus
  |=  prod=prod:fiber:nexus
  =/  m  (fiber:fiber:nexus ,~)
  ^-  process:fiber:nexus
  ?.  =([/ %noun] blot)  stay:m
  =/  result=road:tarball  [%& %& /agents/main/checks name.rail]
  ?^  prod
    ::  Failure reporting must not itself require the capability that failed.
    ::  Persist evidence in our own noun grub, with no darts or retry loop.
    ;<  raw=*  bind:m  (get-state-as:io ,*)
    ;<  ~  bind:m  (replace:io [%failed raw u.prod])
    ;<  ignored=sage:tarball  bind:m  take-poke:io
    ;<  ~  bind:m  (replace:io raw)
    $(prod ~)
  ;<  data=state:sh  bind:m  (get-state-as:io ,state:sh)
  ?:  ?=(%failed -.data)
    ;<  ignored=sage:tarball  bind:m  take-poke:io
    ;<  ~  bind:m  (replace:io source.data)
    $(prod ~)
  =/  verdict  (check:check data)
  ;<  ~  bind:m  (write [%& %& /agents/main/sessions name.rail] [[/ %noun] session.data])
  ::  Keep the stored mark total; readers validate the JSON noun locally.
  ::  A malformed diagnostic must not turn into a failed cross-agent scry.
  ;<  ~  bind:m  (write result [[/ %noun] verdict])
  ::  Keep the source alive. An explicit poke rechecks the current source;
  ::  content changes and runtime reloads also rebuild this process.
  ;<  ignored=sage:tarball  bind:m  take-poke:io
  $(prod ~)
--
