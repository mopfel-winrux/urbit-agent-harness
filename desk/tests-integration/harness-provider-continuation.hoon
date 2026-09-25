::  Real local tool execution through the head, with provider-wire fixtures.
/-  h=harness, *harness-store, renew=harness-oauth
/+  *test, policy=harness-defaults, hl=harness, w=harness-provider-wire, hp=harness-provider, hj=harness-json
/=  head  /app/harness
/=  fixture  /tests/harness-provider-continuation
|%
++  test-chat-and-native-tools-preserve-continuations-through-reload
  %-  zing
  %+  turn  `(list @t)`~[native:fixture router:fixture 'https://example.test/v1/chat/completions']
  |=  url=@t
  =/  attempt  |.((exchange url))
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  ;;(tang product.out)
++  requests
  |=  cards=(list card:agent:gall)
  ^-  (list http-card:renew)
  (murn cards |=(c=card:agent:gall ^-((unit http-card:renew) ?:(?=([%pass [%llm *] %arvo %i %request *] c) `c ~))))
++  body
  |=  c=http-card:renew
  (need (de:json:html q:(need body.request.c)))
++  exchange
  |=  url=@t
  =/  native=?  =(url native:fixture)
  =/  bowl=bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~zod, now ~2026.9.24)
  =/  saved=state-0  *state-0
  =/  cfg  builtin-config:policy
  =.  cfg  cfg(url url, model 'fixture-model', tools ~, key 'fixture-key')
  =.  saved
    saved(defaults cfg, local-mcp-seen 1, sessions (my ~[['fixture' [~[[%config-replaced cfg]] 0]]]))
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  sent  (~(on-poke +.loaded bowl) %harness-action !>(`action:h`[%send 'fixture' 'What time is it?']))
  =/  first  (snag 0 (requests -.sent))
  =/  raw  ?:(native native-stream:fixture chat-stream:fixture)
  =/  response=client-response:iris
    [%finished [200 ~] `['text/event-stream' (as-octs:mimes:html raw)]]
  =/  executed  (~(on-arvo +.sent bowl) wire.first [%iris %http-response response])
  =/  next  (snag 0 (requests -.executed))
  =/  messages  (need (get:w (body next) 'messages'))
  ?>  ?=(%a -.messages)
  =/  assistant  (snag ?:(native 1 2) p.messages)
  =/  fields  (need (de:json:html (continuation:hp url raw)))
  ?>  ?=(%o -.fields)
  =/  state  !<(state-0 ~(on-save +.executed bowl))
  =/  reloaded  (~(on-load head bowl) !>(state))
  =/  restored  !<(state-0 ~(on-save +.reloaded bowl))
  =/  view  (play:hl log:(~(got by sessions.restored) 'fixture'))
  =/  final-text
    ?:  native
      '{"type":"message","role":"assistant","content":[{"type":"text","text":"Done."}],"stop_reason":"end_turn","usage":{"input_tokens":4,"output_tokens":2}}'
    '{"choices":[{"finish_reason":"stop","message":{"role":"assistant","content":"Done."}}],"usage":{"prompt_tokens":4,"completion_tokens":2}}'
  =/  final=client-response:iris
    [%finished [200 ~] `['application/json' (as-octs:mimes:html final-text)]]
  =/  done  (~(on-arvo +.reloaded bowl) wire.next [%iris %http-response final])
  =/  retained  !<(state-0 ~(on-save +.done bowl))
  =/  v  (play:hl log:(~(got by sessions.retained) 'fixture'))
  =/  display  (need (get:w (view-json:hj view ~s30) 'items'))
  ?>  ?=(%a -.display)
  ;:  weld
    (expect-eq !>(url) !>(url.request.next))
    (expect !>((levy ~(tap by p.fields) |=([key=@t value=json] =(`value (get:w assistant key))))))
    (expect-eq !>((get:w (body next) 'messages')) !>((get:w (payload:hp view %turn ~) 'messages')))
    (expect-eq !>(3) !>((lent p.display)))
    (expect !>((lien items.view |=(it=item:h ?&(?=(%tool -.it) !=('' body.it))))))
    (expect-eq !>(`item:h`[%assistant 'Done.' ~]) !>((rear items.v)))
    (expect-eq !>(~) !>(pending.v))
    (expect-eq !>(?:(native [37 7] [4 2])) !>(total.v))
  ==
--
