::  Full head execution with fixture HTTP responses; emitted network cards
::  are inspected, never delivered to providers or the installed agent.
/-  *harness-store, hosted=harness-hosted
/+  *test
/=  head  /app/harness
|%
++  isolated
  |=  attempt=$-(* tang)
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  ;;(tang product.out)
++  test-hosted-login-survives-reload-and-disconnect-fences-response
  (isolated |=(ignored=* reload-login))
++  reload-login
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =.  src.bowl  ~zod
  =.  now.bowl  ~2026.9.17
  =/  loaded  (~(on-load head bowl) !>(*state-28))
  =/  args  (pairs:enjs:format ~[['provider' %s 'openai'] ['requestId' %s 'integration-login']])
  =/  started  (~(on-poke +.loaded bowl) %harness-hosted !>(`request:hosted`['start' 'start' args]))
  =/  saved  !<(state-28 ~(on-save +.started bowl))
  =/  reloaded  (~(on-load head bowl) !>(saved))
  =/  retained  !<(state-28 ~(on-save +.reloaded bowl))
  =/  reply=client-response:iris
    [%finished [200 ~] `['application/json' (as-octs:mimes:html '{"device_auth_id":"PRIVATE_DEVICE","user_code":"VISIBLE_CODE","interval":5}')]]
  =/  responded  (~(on-arvo +.reloaded bowl) /hosted-auth/integration-login/1 [%iris %http-response reply])
  =/  polled  !<(state-28 ~(on-save +.responded bowl))
  =/  wake  (~(on-arvo +.responded bowl(now (add now.bowl ~s5))) /hosted-auth-poll/integration-login/1 [%behn %wake ~])
  =/  polling  !<(state-28 ~(on-save +.wake bowl))
  =/  disconnected  (~(on-poke +.wake bowl) %harness-hosted !>(`request:hosted`['disconnect' 'disconnect' args]))
  =/  cleared  !<(state-28 ~(on-save +.disconnected bowl))
  =/  late  (~(on-arvo +.disconnected bowl) /hosted-auth/integration-login/2 [%iris %http-response reply])
  =/  after  !<(state-28 ~(on-save +.late bowl))
  ;:  weld
    (expect-eq !>(hosted.saved) !>(hosted.retained))
    (expect-eq !>(%poll) !>(phase:(~(got by flows.hosted.polled) 'integration-login')))
    (expect-eq !>(~) !>(flows.hosted.after))
    (expect-eq !>(provider-keys.cleared) !>(provider-keys.after))
    (expect-eq !>(2) !>(serial:(~(got by flows.hosted.polling) 'integration-login')))
    (expect !>(pending:(~(got by flows.hosted.polling) 'integration-login')))
    (expect !>((lien -.wake |=(c=card:agent:gall ?=([%pass [%hosted-auth *] %arvo %i %request *] c)))))
  ==
++  test-hosted-access-rejects-remote-ships
  (isolated |=(ignored=* remote-access))
++  remote-access
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =.  src.bowl  ~zod
  =.  now.bowl  ~2026.9.17
  =/  loaded  (~(on-load head bowl) !>(*state-28))
  =.  src.bowl  ~nec
  =/  poke  (mule |.((~(on-poke +.loaded bowl) %harness-hosted !>(`request:hosted`['foreign' 'status' [%o ~]]))))
  =/  watch  (mule |.((~(on-watch +.loaded bowl) /hosted/foreign)))
  ;:  weld
    (expect !>(?=(%| -.poke)))
    (expect !>(?=(%| -.watch)))
  ==
--
