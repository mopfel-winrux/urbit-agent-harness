::  Full head execution with fixture HTTP responses; emitted network cards
::  are inspected, never delivered to providers or the installed agent.
/-  *harness-store, hosted=harness-hosted, ac=acp, renew=harness-oauth
/+  *test, auth=harness-auth, ha=harness-hosted-auth, defaults=harness-defaults, ht=harness-tools, j=harness-workspace-json
/=  head  /app/harness
|%
++  test-credential-cleanup-survives-reload
  (isolated |=(ignored=* cleanup-reload))
++  cleanup-reload
  =/  bowl=bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~zod, now ~2026.9.17)
  =/  saved=state-30  *state-30
  =.  api-key.saved  'private'
  =.  provider-keys.saved  (my ~[['openai-device' 'subscription'] ['xai-refresh' 'refresh'] ['hosted-openrouter' 'managed']])
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  args  (pairs:enjs:format ~[['provider' %s 'openai'] ['requestId' %s 'pending-cleanup']])
  =/  started  (~(on-poke +.loaded bowl) %harness-hosted !>(`request:hosted`['login' 'start' args]))
  =/  cleared  (~(on-poke +.started bowl) %harness-hosted !>(`request:hosted`['cleanup' 'clear-credentials' [%o ~]]))
  =/  after  !<(state-30 ~(on-save +.cleared bowl))
  =/  reloaded  (~(on-load head bowl) !>(after))
  =/  retained  !<(state-30 ~(on-save +.reloaded bowl))
  =/  reply=client-response:iris
    [%finished [200 ~] `['application/json' (as-octs:mimes:html '{"device_auth_id":"PRIVATE_DEVICE","user_code":"VISIBLE_CODE","interval":5}')]]
  =/  late  (~(on-arvo +.reloaded bowl) /hosted-auth/pending-cleanup/1 [%iris %http-response reply])
  =/  late-state  !<(state-30 ~(on-save +.late bowl))
  ;:  weld
    (expect-eq !>(~) !>(provider-keys.retained))
    (expect-eq !>('') !>(api-key.retained))
    (expect-eq !>(~) !>(flows.hosted.retained))
    (expect-eq !>(~) !>(active.openai-auth.retained))
    (expect-eq !>(~) !>(active.xai-auth.retained))
    (expect-eq !>(~) !>(flows.hosted.late-state))
    (expect-eq !>(~) !>(provider-keys.late-state))
  ==
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
  =/  loaded  (~(on-load head bowl) !>(*state-30))
  =/  args  (pairs:enjs:format ~[['provider' %s 'openai'] ['requestId' %s 'integration-login']])
  =/  started  (~(on-poke +.loaded bowl) %harness-hosted !>(`request:hosted`['start' 'start' args]))
  =/  saved  !<(state-30 ~(on-save +.started bowl))
  =/  reloaded  (~(on-load head bowl) !>(saved))
  =/  retained  !<(state-30 ~(on-save +.reloaded bowl))
  =/  reply=client-response:iris
    [%finished [200 ~] `['application/json' (as-octs:mimes:html '{"device_auth_id":"PRIVATE_DEVICE","user_code":"VISIBLE_CODE","interval":5}')]]
  =/  responded  (~(on-arvo +.reloaded bowl) /hosted-auth/integration-login/1 [%iris %http-response reply])
  =/  polled  !<(state-30 ~(on-save +.responded bowl))
  =/  wake  (~(on-arvo +.responded bowl(now (add now.bowl ~s5))) /hosted-auth-poll/integration-login/1 [%behn %wake ~])
  =/  polling  !<(state-30 ~(on-save +.wake bowl))
  =/  disconnected  (~(on-poke +.wake bowl) %harness-hosted !>(`request:hosted`['disconnect' 'disconnect' args]))
  =/  cleared  !<(state-30 ~(on-save +.disconnected bowl))
  =/  late  (~(on-arvo +.disconnected bowl) /hosted-auth/integration-login/2 [%iris %http-response reply])
  =/  after  !<(state-30 ~(on-save +.late bowl))
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
  =/  loaded  (~(on-load head bowl) !>(*state-30))
  =.  src.bowl  ~nec
  =/  poke  (mule |.((~(on-poke +.loaded bowl) %harness-hosted !>(`request:hosted`['foreign' 'status' [%o ~]]))))
  =/  watch  (mule |.((~(on-watch +.loaded bowl) /hosted/foreign)))
  ;:  weld
    (expect !>(?=(%| -.poke)))
    (expect !>(?=(%| -.watch)))
  ==
++  test-provision-survives-reload-and-preserves-owner-configuration
  (isolated |=(ignored=* provision-reload))
++  provision-reload
  =/  bowl=bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~zod, now ~2026.9.17)
  =/  saved=state-30  *state-30
  =.  local-mcp-seen.saved  1
  =.  defaults.saved  builtin-config:defaults
  =.  model.defaults.saved  'owner-choice'
  =.  provider-keys.saved  (my ~[['openai-device' 'subscription']])
  =.  mcp-servers.saved  (my ~[['local' ['Local' 'urbit://~zod/mcp-proxy' ~ &]]])
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  args  (need (de:json:html '{"providerKeys":{"openrouter":"platform","brave":"search"},"fallbacks":[{"provider":"openrouter","model":"z-ai/glm-5.3-flash:nitro"}]}'))
  =/  applied  (~(on-poke +.loaded bowl) %harness-hosted !>(`request:hosted`['provision' 'provision' args]))
  =/  next  !<(state-30 ~(on-save +.applied bowl))
  ?>  =(fallbacks.defaults.next ~[['openrouter' 'z-ai/glm-5.3-flash:nitro']])
  ::  An explicit empty chain survives subsequent platform provisioning.
  =.  fallbacks.defaults.next  ~
  =/  reloaded  (~(on-load head bowl) !>(next))
  =/  repeated  (~(on-poke +.reloaded bowl) %harness-hosted !>(`request:hosted`['again' 'provision' args]))
  =/  after  !<(state-30 ~(on-save +.repeated bowl))
  ::  A saved owner choice also takes precedence before initial provisioning.
  =/  chosen  (~(on-poke +.loaded bowl) %harness-action !>(`action:h`[%defaults defaults.saved]))
  =/  provisioned  (~(on-poke +.chosen bowl) %harness-hosted !>(`request:hosted`['owner-first' 'provision' args]))
  =/  owner-first  !<(state-30 ~(on-save +.provisioned bowl))
  ;:  weld
    (expect-eq !>(~) !>(fallbacks.defaults.owner-first))
    (expect-eq !>(provider-keys.next) !>(provider-keys.after))
    (expect-eq !>('owner-choice') !>(model.defaults.after))
    (expect-eq !>(~) !>(fallbacks.defaults.after))
    (expect-eq !>('subscription') !>((key:auth provider-keys.after 'openai-device')))
    (expect-eq !>('platform') !>((key:auth provider-keys.after 'openrouter')))
    (expect !>((mcp-granted:ht 'local' tools.defaults.after)))
    (expect-eq !>(sessions.saved) !>(sessions.after))
  ==
++  test-owner-first-turn-advertises-live-tools-despite-empty-session-grants
  (isolated |=(ignored=* owner-tools))
++  owner-tools
  =/  bowl=bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~zod, now ~2026.9.17)
  =/  saved=state-30  *state-30
  =.  local-mcp-seen.saved  1
  =.  mcp-servers.saved  (my ~[['local' ['Local' 'urbit://~zod/mcp-proxy' ~ &]]])
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  cfg  builtin-config:defaults
  =.  tools.cfg  ~
  =/  created  (~(on-poke +.loaded bowl) %harness-action !>(`action:h`[%new 'owner' cfg]))
  =/  sent  (~(on-poke +.created bowl) %harness-action !>(`action:h`[%send 'owner' 'What tools can you use?']))
  =/  requests
    %+  murn  -.sent
    |=  c=card:agent:gall
    ^-  (unit @t)
    ?.  ?=([%pass [%llm *] %arvo %i %request *] c)  ~
    =/  sent=http-card:renew  c
    ?~  body.request.sent  ~
    `q.u.body.request.sent
  ?>  =(1 (lent requests))
  =/  payload  (need (de:json:html (snag 0 requests)))
  =/  tools  (need (get:j payload 'tools'))
  ?>  ?=(%a -.tools)
  =/  names
    (turn p.tools |=(entry=json (string:j (need (get:j entry 'function')) 'name')))
  ;:  weld
    (expect !>((lien names |=(n=@t =('run_js' n)))))
    (expect !>((lien names |=(n=@t =('list_mcp_tools' n)))))
    (expect !>((lien names |=(n=@t =('harness_admin' n)))))
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
  =/  loaded  (~(on-load head bowl) !>(*state-30))
  =/  payload  '{"jsonrpc":"2.0","id":1,"method":"harness/provider/login","params":{"action":"start","provider":"xai","requestId":"xai-integration"}}'
  =/  update=update:v1:ac  [%messages 'xai-fixture' %agent ~[[1 now.bowl payload]]]
  =/  started  (~(on-agent +.loaded bowl) /acp/watch [%fact %acp-update-1 !>(update)])
  =/  code  (~(on-arvo +.started bowl) /hosted-auth/xai-integration/1 [%iris %http-response (reply '{"device_code":"PRIVATE","user_code":"ABCD-1234","verification_uri":"https://accounts.x.ai/oauth2/device","expires_in":1800,"interval":5}')])
  =.  now.bowl  (add now.bowl ~s5)
  =/  polling  (~(on-arvo +.code bowl) /hosted-auth-poll/xai-integration/1 [%behn %wake ~])
  =/  tokens  (~(on-arvo +.polling bowl) /hosted-auth/xai-integration/2 [%iris %http-response (reply '{"access_token":"ACCESS","refresh_token":"REFRESH","expires_in":3600}')])
  =/  verified  (~(on-arvo +.tokens bowl) /hosted-auth/xai-integration/3 [%iris %http-response (reply '{"data":[{"id":"grok-build"}]}')])
  =/  saved  !<(state-30 ~(on-save +.verified bowl))
  =.  now.bowl  (add now.bowl ~h1)
  =/  reloaded  (~(on-load head bowl) !>(saved))
  =/  payload  '{"jsonrpc":"2.0","id":2,"method":"harness/provider/models","params":{"provider":"xai","url":"https://cli-chat-proxy.grok.com/v1/models"}}'
  =/  update=update:v1:ac  [%messages 'xai-fixture' %agent ~[[2 now.bowl payload]]]
  =/  requested  (~(on-agent +.reloaded bowl) /acp/watch [%fact %acp-update-1 !>(update)])
  =/  pending  !<(state-30 ~(on-save +.requested bowl))
  =/  during  (~(on-load head bowl) !>(pending))
  =/  renewed  (~(on-arvo +.during bowl) /xai-renew/1 [%iris %http-response (reply '{"access_token":"ROTATED_ACCESS","refresh_token":"ROTATED_REFRESH","expires_in":3600}')])
  =/  after  !<(state-30 ~(on-save +.renewed bowl))
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
