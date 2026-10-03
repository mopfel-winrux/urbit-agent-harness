::  Run the complete head against fixture Iris responses; no network effects
::  are delivered. Assert the actual emitted requests, not just configuration.
/-  h=harness, *harness-store, renew=harness-oauth, ac=acp
/+  *test, policy=harness-defaults, hl=harness, j=harness-workspace-json
/=  head  /app/harness
|%
++  isolated
  |=  attempt=$-(* tang)
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  ;;(tang product.out)
++  bowl
  ^-  bowl:gall
  =/  b  *bowl:gall
  b(our ~zod, src ~zod, now ~2026.9.17)
++  requests
  |=  cards=(list card:agent:gall)
  ^-  (list http-card:renew)
  %+  murn
    cards
  |=  c=card:agent:gall
  ^-((unit http-card:renew) ?:(?=([%pass [%llm *] %arvo %i %request *] c) `c ~))
++  body
  |=  c=http-card:renew
  =/  octs  (need body.request.c)
  (need (de:json:html q.octs))
++  fixture
  ^-  state-0
  =/  s  *state-0
  =/  cfg  builtin-config:policy
  =.  cfg
    %=  cfg  url  'https://openrouter.ai/api/v1/chat/completions'  model  'primary'  zdr  &
      fallbacks  ~[['openrouter' 'backup']]  tools  ~
    ==
  %=  s  defaults  cfg  local-mcp-seen  1  provider-keys  (my ~[['openrouter' 'fixture-key']])
    sessions  (my ~[['fixture' [~[[%config-replaced cfg]] 0]]])
  ==
++  failed
  ^-  client-response:iris
  [%finished [429 ~] `['application/json' (as-octs:mimes:html '{"error":"limited"}')]]
++  test-failover-is-ordered-fenced-and-does-not-replace-the-primary
  (isolated |=(ignored=* failover))
++  failover
  =/  loaded  (~(on-load head bowl) !>(fixture))
  =/  sent
    %+  ~(on-poke +.loaded bowl)
      %harness-action
    !>(`action:h`[%send 'fixture' 'Reply with hello'])
  =/  primary  (snag 0 (requests -.sent))
  =/  retried  (~(on-arvo +.sent bowl) wire.primary [%iris %http-response failed])
  =/  backup  (snag 0 (requests -.retried))
  =/  saved  !<(state-0 ~(on-save +.retried bowl))
  =/  late  (~(on-arvo +.retried bowl) wire.primary [%iris %http-response failed])
  =/  success=client-response:iris
    :*  %finished  [200 ~]
        :-  ~
        :*  'application/json'
            %-  as-octs:mimes:html
            '{"choices":[{"message":{"role":"assistant","content":"hello"},"finish_reason":"stop"}],"usage":{"prompt_tokens":4,"completion_tokens":1}}'
        ==
    ==
  =/  done  (~(on-arvo +.late bowl) wire.backup [%iris %http-response success])
  =/  finished  !<(state-0 ~(on-save +.done bowl))
  =/  view  (play:hl log:(~(got by sessions.finished) 'fixture'))
  =/  repeated  (~(on-poke +.done bowl) %harness-action !>(`action:h`[%send 'fixture' 'Again']))
  ;:  weld
      (expect-eq !>('primary') !>((string:j (body primary) 'model')))
      (expect-eq !>('backup') !>((string:j (body backup) 'model')))
      (expect !>(!=(wire.primary wire.backup)))
      (expect-eq !>(~) !>((requests -.late)))
      %+  expect-eq
        !>(`(need (de:json:html '{"zdr":true,"data_collection":"deny"}')))
      !>((get:j (body backup) 'provider'))
      (expect-eq !>('primary') !>(model.config.view))
      (expect-eq !>(`item:h`[%assistant 'hello' ~]) !>((rear items.view)))
      (expect-eq !>(~) !>(pending.view))
      (expect-eq !>('primary') !>((string:j (body (snag 0 (requests -.repeated))) 'model')))
  ==
++  test-fallback-exhaustion-stops-and-cancellation-never-retries
  (isolated |=(ignored=* exhausted))
++  exhausted
  =/  loaded  (~(on-load head bowl) !>(fixture))
  =/  sent  (~(on-poke +.loaded bowl) %harness-action !>(`action:h`[%send 'fixture' 'Reply']))
  =/  primary  (snag 0 (requests -.sent))
  =/  retried  (~(on-arvo +.sent bowl) wire.primary [%iris %http-response failed])
  =/  backup  (snag 0 (requests -.retried))
  =/  done  (~(on-arvo +.retried bowl) wire.backup [%iris %http-response failed])
  =/  saved  !<(state-0 ~(on-save +.done bowl))
  =/  view  (play:hl log:(~(got by sessions.saved) 'fixture'))
  =/  cancelled  (~(on-poke +.sent bowl) %harness-action !>(`action:h`[%cancel 'fixture']))
  =/  late  (~(on-arvo +.cancelled bowl) wire.primary [%iris %http-response failed])
  ;:  weld
      (expect-eq !>(~) !>((requests -.done)))
      (expect-eq !>(~) !>(pending.view))
      (expect !>(?=(^ err.view)))
      (expect-eq !>(~) !>((requests -.late)))
  ==
++  test-streamed-text-prevents-failover
  (isolated |=(ignored=* partial))
++  partial
  =/  loaded  (~(on-load head bowl) !>(fixture))
  =/  sent  (~(on-poke +.loaded bowl) %harness-action !>(`action:h`[%send 'fixture' 'Reply']))
  =/  primary  (snag 0 (requests -.sent))
  =/  chunk  (as-octs:mimes:html 'data: {"choices":[{"delta":{"content":"hello"}}]}\0a\0a')
  =/  progress=client-response:iris  [%progress [200 ~] p.chunk ~ `chunk]
  =/  waiting  !<(state-0 ~(on-save +.sent bowl))
  =.  acp-prompts.waiting  (my ~[['fixture' ['client' [%n '1'] 0]]])
  =/  watched  (~(on-load head bowl) !>(waiting))
  =/  streamed  (~(on-arvo +.watched bowl) wire.primary [%iris %http-response progress])
  =/  frames
    %+  murn  -.streamed
    |=  card=card:agent:gall
    ^-  (unit json)
    ?.  ?=([%pass [%acp %send ~] %agent * %poke %acp-action-1 *] card)  ~
    =/  [pass=* wire=* agent=* target=* poke=* mark=* data=vase]  card
    =/  action  !<(action:v1:ac data)
    ?>  ?=(%send -.action)
    (de:json:html payload.action)
  =/  update  (need (get:j (need (get:j (snag 0 frames) 'params')) 'update'))
  =/  saved  !<(state-0 ~(on-save +.streamed bowl))
  =/  view  (play:hl log:(~(got by sessions.saved) 'fixture'))
  ?>  ?=(^ pending.view)
  ?>  =(5 sent:(~(got by streams.saved) ['fixture' req.u.pending.view]))
  =/  done  (~(on-arvo +.streamed bowl) wire.primary [%iris %http-response failed])
  =/  finished  !<(state-0 ~(on-save +.done bowl))
  =/  cancelled  (~(on-poke +.streamed bowl) %harness-action !>(`action:h`[%cancel 'fixture']))
  =/  stopped  !<(state-0 ~(on-save +.cancelled bowl))
  ;:  weld
      (expect-eq !>(~) !>((requests -.done)))
      (expect-eq !>('harness_agent_stream_chunk') !>((string:j update 'sessionUpdate')))
      %+  expect-eq
        !>((lent log:(~(got by sessions.saved) 'fixture')))
      !>((number:j update 'revision' 0))
      (expect-eq !>(0) !>((number:j update 'offset' 999)))
      (expect-eq !>('hello') !>((string:j (need (get:j update 'content')) 'text')))
      (expect-eq !>(0) !>(~(wyt by streams.finished)))
      (expect-eq !>(0) !>(~(wyt by streams.stopped)))
  ==
++  test-failover-uses-persisted-catalog-capacity-and-skips-small-models
  (isolated |=(ignored=* (catalog-failover |)))
++  test-missing-primary-credentials-use-the-same-fallback-budget
  (isolated |=(ignored=* (catalog-failover &)))
++  catalog-failover
  |=  missing=?
  =/  initial  fixture
  =/  cfg  defaults.initial
  =.  cfg  cfg(fallbacks ~[['openrouter' 'small'] ['openrouter' 'backup']])
  =?  cfg  missing
    cfg(url 'https://api.openai.com/v1/responses', zdr |)
  =.  initial  initial(defaults cfg, sessions (my ~[['fixture' [~[[%config-replaced cfg]] 0]]]))
  =/  loaded  (~(on-load head bowl) !>(initial))
  =/  catalogs
    %+  murn  -.loaded
    |=  c=card:agent:gall
    ^-  (unit http-card:renew)
    ?:(?=([%pass [%model-context *] %arvo %i %request *] c) `c ~)
  ?>  =(1 (lent catalogs))
  =/  catalog  (snag 0 catalogs)
  =/  response=client-response:iris
    :*  %finished  [200 ~]
        :-  ~
        :*  'application/json'
            %-  as-octs:mimes:html
            '{"data":[{"id":"small","context_length":32000},{"id":"backup","context_length":128000}]}'
        ==
    ==
  =/  learned  (~(on-arvo +.loaded bowl) wire.catalog [%iris %http-response response])
  =/  cached  !<(state-0 ~(on-save +.learned bowl))
  =/  reloaded  (~(on-load head bowl) !>(cached))
  ::  This prompt requires the larger fallback's advertised window.
  =/  prompt  (rap 3 (reap 380.000 'x'))
  =/  sent  (~(on-poke +.reloaded bowl) %harness-action !>(`action:h`[%send 'fixture' prompt]))
  =/  first  (snag 0 (requests -.sent))
  =/  routed
    ?:  missing  sent
    (~(on-arvo +.sent bowl) wire.first [%iris %http-response failed])
  =/  backup  (snag 0 (requests -.routed))
  =/  saved  !<(state-0 ~(on-save +.routed bowl))
  =/  view  (play:hl log:(~(got by sessions.saved) 'fixture'))
  ?>  ?=(^ route.view)
  ;:  weld
      (expect-eq !>('https://openrouter.ai/api/v1/models') !>(url.request.catalog))
      (expect-eq !>('backup') !>((string:j (body backup) 'model')))
      (expect-eq !>(128.000) !>(max-context.config.u.route.view))
      (expect-eq !>(800.000) !>(max-context.config.view))
      (expect-eq !>(model-contexts.cached) !>(model-contexts.saved))
      (expect-eq !>(zdr.cfg) !>(zdr.config.u.route.view))
      (expect-eq !>(1) !>((lent (requests -.routed))))
  ==
--
