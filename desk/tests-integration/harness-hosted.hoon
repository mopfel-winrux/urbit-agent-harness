::  Full head execution with fixture HTTP responses; emitted network cards
::  are inspected, never delivered to providers or the installed agent.
/-  *harness-store, hosted=harness-hosted, ac=acp, renew=harness-oauth
/+  *test, auth=harness-auth, ha=harness-hosted-auth
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
  =/  loaded  (~(on-load head bowl) !>(*state-29))
  =/  args  (pairs:enjs:format ~[['provider' %s 'openai'] ['requestId' %s 'integration-login']])
  =/  started  (~(on-poke +.loaded bowl) %harness-hosted !>(`request:hosted`['start' 'start' args]))
  =/  saved  !<(state-29 ~(on-save +.started bowl))
  =/  reloaded  (~(on-load head bowl) !>(saved))
  =/  retained  !<(state-29 ~(on-save +.reloaded bowl))
  =/  reply=client-response:iris
    [%finished [200 ~] `['application/json' (as-octs:mimes:html '{"device_auth_id":"PRIVATE_DEVICE","user_code":"VISIBLE_CODE","interval":5}')]]
  =/  responded  (~(on-arvo +.reloaded bowl) /hosted-auth/integration-login/1 [%iris %http-response reply])
  =/  polled  !<(state-29 ~(on-save +.responded bowl))
  =/  wake  (~(on-arvo +.responded bowl(now (add now.bowl ~s5))) /hosted-auth-poll/integration-login/1 [%behn %wake ~])
  =/  polling  !<(state-29 ~(on-save +.wake bowl))
  =/  disconnected  (~(on-poke +.wake bowl) %harness-hosted !>(`request:hosted`['disconnect' 'disconnect' args]))
  =/  cleared  !<(state-29 ~(on-save +.disconnected bowl))
  =/  late  (~(on-arvo +.disconnected bowl) /hosted-auth/integration-login/2 [%iris %http-response reply])
  =/  after  !<(state-29 ~(on-save +.late bowl))
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
  =/  loaded  (~(on-load head bowl) !>(*state-29))
  =.  src.bowl  ~nec
  =/  poke  (mule |.((~(on-poke +.loaded bowl) %harness-hosted !>(`request:hosted`['foreign' 'status' [%o ~]]))))
  =/  watch  (mule |.((~(on-watch +.loaded bowl) /hosted/foreign)))
  ;:  weld
    (expect !>(?=(%| -.poke)))
    (expect !>(?=(%| -.watch)))
  ==
++  test-xai-native-login-and-renewal-survive-head-reload
  (isolated |=(ignored=* xai-login))
++  reply
  |=  body=@t
  ^-  client-response:iris
  [%finished [200 ~] `['application/json' (as-octs:mimes:html body)]]
++  xai-login
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =.  src.bowl  ~zod
  =.  now.bowl  ~2026.9.17
  =/  loaded  (~(on-load head bowl) !>(*state-29))
  =/  payload  '{"jsonrpc":"2.0","id":1,"method":"harness/provider/login","params":{"action":"start","provider":"xai","requestId":"xai-integration"}}'
  =/  update=update:v1:ac  [%messages 'xai-fixture' %agent ~[[1 now.bowl payload]]]
  =/  started  (~(on-agent +.loaded bowl) /acp/watch [%fact %acp-update-1 !>(update)])
  =/  code  (~(on-arvo +.started bowl) /hosted-auth/xai-integration/1 [%iris %http-response (reply '{"device_code":"PRIVATE","user_code":"ABCD-1234","verification_uri":"https://accounts.x.ai/oauth2/device","expires_in":1800,"interval":5}')])
  =.  now.bowl  (add now.bowl ~s5)
  =/  polling  (~(on-arvo +.code bowl) /hosted-auth-poll/xai-integration/1 [%behn %wake ~])
  =/  tokens  (~(on-arvo +.polling bowl) /hosted-auth/xai-integration/2 [%iris %http-response (reply '{"access_token":"ACCESS","refresh_token":"REFRESH","expires_in":3600}')])
  =/  verified  (~(on-arvo +.tokens bowl) /hosted-auth/xai-integration/3 [%iris %http-response (reply '{"data":[{"id":"grok-build"}]}')])
  =/  saved  !<(state-29 ~(on-save +.verified bowl))
  =.  now.bowl  (add now.bowl ~h1)
  =/  reloaded  (~(on-load head bowl) !>(saved))
  =/  payload  '{"jsonrpc":"2.0","id":2,"method":"harness/provider/models","params":{"provider":"xai","url":"https://cli-chat-proxy.grok.com/v1/models"}}'
  =/  update=update:v1:ac  [%messages 'xai-fixture' %agent ~[[2 now.bowl payload]]]
  =/  requested  (~(on-agent +.reloaded bowl) /acp/watch [%fact %acp-update-1 !>(update)])
  =/  pending  !<(state-29 ~(on-save +.requested bowl))
  =/  during  (~(on-load head bowl) !>(pending))
  =/  renewed  (~(on-arvo +.during bowl) /xai-renew/1 [%iris %http-response (reply '{"access_token":"ROTATED_ACCESS","refresh_token":"ROTATED_REFRESH","expires_in":3600}')])
  =/  after  !<(state-29 ~(on-save +.renewed bowl))
  =/  requests
    %+  murn  -.renewed
    |=  c=card:agent:gall
    ^-  (unit http-card:renew)
    ?.  ?=([%pass [%models *] %arvo %i %request *] c)  ~
    `c
  =/  sent  (snag 0 requests)
  ;:  weld
    (expect-eq !>('ACCESS') !>((key:auth provider-keys.saved 'xai-device')))
    (expect-eq !>(1) !>(~(wyt by waiting.xai-auth.pending)))
    (expect-eq !>(~) !>(active.openai-auth.pending))
    (expect-eq !>('ROTATED_ACCESS') !>((key:auth provider-keys.after 'xai-device')))
    (expect-eq !>('ROTATED_REFRESH') !>((key:auth provider-keys.after 'xai-refresh')))
    (expect-eq !>(xai-models:auth) !>(url.request.sent))
    (expect !>((lien header-list.request.sent |=([name=@t value=@t] &(=('authorization' name) =('Bearer ROTATED_ACCESS' value))))))
    (expect-eq !>((identity:ha provider-keys.after 'xai')) !>(identity:(~(got by catalogs.hosted.after) 'xai')))
  ==
--
