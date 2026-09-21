::  Run the complete head against fixture Iris responses; no network effects
::  are delivered. Assert the actual emitted requests, not just configuration.
/-  h=harness, *harness-store, renew=harness-oauth
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
  (murn cards |=(c=card:agent:gall ^-((unit http-card:renew) ?:(?=([%pass [%llm *] %arvo %i %request *] c) `c ~))))
++  body
  |=  c=http-card:renew
  =/  octs  (need body.request.c)
  (need (de:json:html q.octs))
++  fixture
  ^-  state-30
  =/  s  *state-30
  =/  cfg  builtin-config:policy
  =.  cfg  cfg(model 'primary', zdr &, fallbacks ~[['openrouter' 'backup']], tools ~)
  s(defaults cfg, local-mcp-seen 1, provider-keys (my ~[['openrouter' 'fixture-key']]), sessions (my ~[['fixture' [~[[%config-replaced cfg]] 0]]]))
++  failed
  ^-  client-response:iris
  [%finished [429 ~] `['application/json' (as-octs:mimes:html '{"error":"limited"}')]]
++  test-failover-is-ordered-fenced-and-does-not-replace-the-primary
  (isolated |=(ignored=* failover))
++  failover
  =/  loaded  (~(on-load head bowl) !>(fixture))
  =/  sent  (~(on-poke +.loaded bowl) %harness-action !>(`action:h`[%send 'fixture' 'Reply with hello']))
  =/  primary  (snag 0 (requests -.sent))
  =/  retried  (~(on-arvo +.sent bowl) wire.primary [%iris %http-response failed])
  =/  backup  (snag 0 (requests -.retried))
  =/  saved  !<(state-30 ~(on-save +.retried bowl))
  =/  late  (~(on-arvo +.retried bowl) wire.primary [%iris %http-response failed])
  =/  success=client-response:iris
    [%finished [200 ~] `['application/json' (as-octs:mimes:html '{"choices":[{"message":{"role":"assistant","content":"hello"},"finish_reason":"stop"}],"usage":{"prompt_tokens":4,"completion_tokens":1}}')]]
  =/  done  (~(on-arvo +.late bowl) wire.backup [%iris %http-response success])
  =/  finished  !<(state-30 ~(on-save +.done bowl))
  =/  view  (play:hl log:(~(got by sessions.finished) 'fixture'))
  =/  repeated  (~(on-poke +.done bowl) %harness-action !>(`action:h`[%send 'fixture' 'Again']))
  ;:  weld
    (expect-eq !>('primary') !>((string:j (body primary) 'model')))
    (expect-eq !>('backup') !>((string:j (body backup) 'model')))
    (expect !>(!=(wire.primary wire.backup)))
    (expect-eq !>(~) !>((requests -.late)))
    (expect-eq !>(`(need (de:json:html '{"zdr":true,"data_collection":"deny"}'))) !>((get:j (body backup) 'provider')))
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
  =/  saved  !<(state-30 ~(on-save +.done bowl))
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
  =/  streamed  (~(on-arvo +.sent bowl) wire.primary [%iris %http-response progress])
  =/  saved  !<(state-30 ~(on-save +.streamed bowl))
  =/  view  (play:hl log:(~(got by sessions.saved) 'fixture'))
  ?>  ?=(^ pending.view)
  ?>  =(5 sent:(~(got by streams.saved) ['fixture' req.u.pending.view]))
  =/  done  (~(on-arvo +.streamed bowl) wire.primary [%iris %http-response failed])
  (expect-eq !>(~) !>((requests -.done)))
--
