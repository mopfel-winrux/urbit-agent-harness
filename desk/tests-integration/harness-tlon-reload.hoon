::  Opt-in: -test /=harness=/tests-integration/harness-tlon-reload
::  Keep full-agent construction out of the default 2 GB loom unit suite.
/-  t=harness-tlon
/+  *test
/=  adapter  /app/harness-tlon
|%
++  load
  |=  saved=vase
  ^-  [(list card:agent:gall) state:t]
  =/  attempt
    |.
    =/  bowl=bowl:gall  *bowl:gall
    =.  now.bowl  ~2026.9.6
    =/  out  (~(on-load adapter bowl) saved)
    [-.out !<(state:t ~(on-save +.out bowl))]
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  ;;([(list card:agent:gall) state:t] product.out)
++  test-reload-does-not-export-or-reconfigure-steward
  =/  old=state-13:t  *state-13:t
  =.  lenses.old  (my ~[[0v1 `lens-export:t`[~zod 3 0v2 %sending ~2026.9.6 ~]]])
  =/  out  (load !>(old))
  (expect !>(!(lien -.out |=(c=card:agent:gall ?=([%pass * %agent [* %steward] *] c)))))
++  reload
  |=  phase=?(%fetch %put %grant %hosted-put)
  ^-  state:t
  =/  state=state:t  *state:t
  =.  uploads.state  (my ~[[0v1 `upload:t`[phase 0v2 'key' 'image/png' 'https://storage.googleapis.com/bucket/key' [2 1]]]])
  =.  tool-receipts.state  (my ~[[0v1 `tool-receipt:t`[['s' 1 ['call' 'tlon_upload_image' '{}']] %sending '' ~2026.9.6]]])
  =/  out  (load !>(state))
  ::  Reload may cancel the old duct and publish a result, never request HTTP.
  ?>  !(lien -.out |=(c=card:agent:gall ?=([%pass * %arvo %i %request *] c)))
  +.out
++  test-native-download-reload-is-known-not-uploaded
  =/  state  (reload %fetch)
  =/  receipt  (~(got by tool-receipts.state) 0v1)
  (expect !>(&(=(~ uploads.state) =(%done stage.receipt) ?=(^ (find "before any upload" (trip body.receipt))))))
++  test-legacy-worker-reload-drops-settings-and-retires-fetch
  =/  old=state-8:t  *state-8:t
  =.  media.old  ['http://localhost:8789' 'retired-secret']
  =.  uploads.old  (my ~[[0v1 `upload:t`[%fetch 0v2 '' '' '' [0 0]]]])
  =.  tool-receipts.old  (my ~[[0v1 `tool-receipt:t`[['s' 1 ['call' 'tlon_upload_image' '{}']] %sending '' ~2026.9.6]]])
  =/  out  (load !>(old))
  ?>  !(lien -.out |=(c=card:agent:gall ?=([%pass * %arvo %i %request *] c)))
  =/  next  +.out
  (expect !>(&(=(%16 -.next) =(~ uploads.next) =(%done stage:(~(got by tool-receipts.next) 0v1)))))
++  test-hosted-grant-reload-is-uncertain-without-claiming-a-put
  =/  state  (reload %grant)
  =/  receipt  (~(got by tool-receipts.state) 0v1)
  (expect !>(&(=(~ uploads.state) =(%uncertain stage.receipt) ?=(^ (find "no image PUT was sent" (trip body.receipt))))))
++  test-hosted-put-reload-discards-bytes-without-retrying
  =/  state  (reload %hosted-put)
  (expect !>(&(=(~ uploads.state) =(%uncertain stage:(~(got by tool-receipts.state) 0v1)))))
--
