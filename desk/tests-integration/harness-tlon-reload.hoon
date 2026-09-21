::  Opt-in: -test /=harness=/tests-integration/harness-tlon-reload
::  Keep full-agent construction out of the default 2 GB loom unit suite.
/-  t=harness-tlon
/+  *test
/=  adapter  /app/harness-tlon
|%
++  load
  |=  saved=vase
  ^-  [(list card:agent:gall) state-0:t]
  =/  attempt
    |.
    =/  bowl=bowl:gall  *bowl:gall
    =.  now.bowl  ~2026.9.6
    =/  out  (~(on-load adapter bowl) saved)
    [-.out !<(state-0:t ~(on-save +.out bowl))]
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  ;;([(list card:agent:gall) state-0:t] product.out)
++  reload
  |=  phase=?(%fetch %put %grant %hosted-put)
  ^-  state-0:t
  =/  state=state-0:t  *state-0:t
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
++  test-hosted-grant-reload-is-uncertain-without-claiming-a-put
  =/  state  (reload %grant)
  =/  receipt  (~(got by tool-receipts.state) 0v1)
  (expect !>(&(=(~ uploads.state) =(%uncertain stage.receipt) ?=(^ (find "no image PUT was sent" (trip body.receipt))))))
++  test-hosted-put-reload-discards-bytes-without-retrying
  =/  state  (reload %hosted-put)
  (expect !>(&(=(~ uploads.state) =(%uncertain stage:(~(got by tool-receipts.state) 0v1)))))
--
