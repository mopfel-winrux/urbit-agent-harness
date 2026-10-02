::  Catalog metadata updates capacity without admitting or retrying model work.
/-  h=harness, *harness-store, renew=harness-oauth
/+  *test, policy=harness-defaults, hl=harness, auth=harness-auth, mc=harness-model-context
/=  head  /app/harness
|%
++  isolated
  |=  attempt=$-(* tang)
  =/  result  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.result)
  ;;(tang product.result)
++  bowl
  ^-  bowl:gall
  =/  value  *bowl:gall
  value(our ~zod, src ~zod, now ~2026.10.2)
++  fixture
  ^-  state-0
  =/  saved  *state-0
  =/  cfg  builtin-config:policy
  =.  cfg  cfg(url device-url:auth, model 'gpt-6-luna', max-context 80.000)
  =/  failed=(list event:h)
    :~  [%llm-failed 0 'context budget exhausted']
        [%llm-requested 0 %turn]
        [%input-admitted [%user 'Keep the current request']]
        [%config-replaced cfg]
    ==
  =/  waiting=(list event:h)
    :~  [%llm-routed 0 cfg]
        [%llm-requested 0 %turn]
        [%input-admitted [%user 'Wait for my response']]
        [%config-replaced cfg]
    ==
  %=  saved
    defaults  cfg(model 'gpt-6-astra', max-context 272.000)
    peer-base  `cfg
    summary-models  [`cfg `cfg]
    local-mcp-seen  1
    provider-keys  (my ~[['openai-device' 'fixture-token'] ['openai-account' 'fixture-account']])
    sessions
      %-  my
      :~  ['failed' [failed 1]]
          ['pending' [waiting 1]]
          ['unknown' [~[[%config-replaced cfg(model 'unknown', max-context 123.456)]] 0]]
          ['custom' [~[[%config-replaced cfg(url 'https://example.test/responses')]] 0]]
      ==
  ==
++  requests
  |=  cards=(list card:agent:gall)
  ^-  (list http-card:renew)
  (murn cards |=(c=card:agent:gall ^-((unit http-card:renew) ?:(?=([%pass [%model-context *] %arvo %i %request *] c) `c ~))))
++  reply
  |=  raw=@t
  ^-  client-response:iris
  [%finished [200 ~] `['application/json' (as-octs:mimes:html raw)]]
++  catalog
  (reply '{"models":[{"slug":"gpt-6-luna","context_window":272000,"max_context_window":872000},{"slug":"gpt-6-astra","context_window":272000,"max_context_window":872000}]}')
++  test-reload-refreshes-every-known-route-without-retrying-work
  %-  isolated  |=  ignored=*
  =/  loaded  (~(on-load head bowl) !>(fixture))
  =/  initial  !<(state-0 ~(on-save +.loaded bowl))
  =/  sent  (requests -.loaded)
  =/  request  (snag 0 sent)
  =/  updated  (~(on-arvo +.loaded bowl) wire.request [%iris %http-response catalog])
  =/  saved  !<(state-0 ~(on-save +.updated bowl))
  =/  again  (~(on-arvo +.updated bowl) wire.request [%iris %http-response catalog])
  =/  repeated  !<(state-0 ~(on-save +.again bowl))
  =/  failed  (play:hl log:(~(got by sessions.saved) 'failed'))
  =/  pending  (play:hl log:(~(got by sessions.saved) 'pending'))
  ?>  ?&(?=(^ peer-base.saved) ?=(^ compaction.summary-models.saved) ?=(^ lcm.summary-models.saved) ?=(^ route.pending))
  ;:  weld
    (expect-eq !>(1) !>((lent sent)))
    (expect-eq !>(%'GET') !>(method.request.request))
    (expect-eq !>(device-models:auth) !>(url.request.request))
    (expect !>((lien header-list.request.request |=([name=@t value=@t] &(=('chatgpt-account-id' name) =(value 'fixture-account'))))))
    (expect-eq !>(872.000) !>(max-context.defaults.saved))
    (expect-eq !>(872.000) !>(max-context.u.peer-base.saved))
    (expect-eq !>(872.000) !>(max-context.u.compaction.summary-models.saved))
    (expect-eq !>(872.000) !>(max-context.u.lcm.summary-models.saved))
    (expect-eq !>(872.000) !>(max-context.config.failed))
    (expect-eq !>(`'context budget exhausted') !>(err.failed))
    (expect-eq !>(~[[%user 'Keep the current request']]) !>(items.failed))
    (expect-eq !>(`[0 %turn]) !>(pending.pending))
    (expect-eq !>(80.000) !>(max-context.config.u.route.pending))
    (expect-eq !>((~(got by sessions.initial) 'unknown')) !>((~(got by sessions.saved) 'unknown')))
    (expect-eq !>((~(got by sessions.initial) 'custom')) !>((~(got by sessions.saved) 'custom')))
    (expect-eq !>(saved) !>(repeated))
    (expect !>(!(lien -.updated |=(c=card:agent:gall ?=([%pass * %arvo %i %request *] c)))))
  ==
++  test-unavailable-or-invalid-metadata-preserves-saved-capacity
  %-  isolated  |=  ignored=*
  =/  loaded  (~(on-load head bowl) !>(fixture))
  =/  initial  !<(state-0 ~(on-save +.loaded bowl))
  =/  request  (snag 0 (requests -.loaded))
  %-  zing
  %+  turn
    `(list client-response:iris)`~[[%finished [401 ~] ~] (reply 'invalid JSON') (reply '{"models":[{"slug":"gpt-6-luna","max_context_window":0}]}')]
  |=  response=client-response:iris
  =/  updated  (~(on-arvo +.loaded bowl) wire.request [%iris %http-response response])
  (expect-eq !>(initial) !>(!<(state-0 ~(on-save +.updated bowl))))
++  test-credential-identity-fences-late-catalog-responses
  %-  isolated  |=  ignored=*
  =/  loaded  (~(on-load head bowl) !>(fixture))
  =/  request  (snag 0 (requests -.loaded))
  =/  initial  !<(state-0 ~(on-save +.loaded bowl))
  =.  provider-keys.initial  (~(put by provider-keys.initial) 'openai-device' 'replacement-token')
  =/  reloaded  (~(on-load +.loaded bowl) !>(initial))
  =/  current  !<(state-0 ~(on-save +.reloaded bowl))
  =/  updated  (~(on-arvo +.reloaded bowl) wire.request [%iris %http-response catalog])
  (expect-eq !>(current) !>(!<(state-0 ~(on-save +.updated bowl))))
--
