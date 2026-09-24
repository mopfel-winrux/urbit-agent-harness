::  Execute a real local tool through the full head using fixture provider
::  responses. Inspect outbound cards; never send them to a provider.
/-  h=harness, *harness-store, renew=harness-oauth
/+  *test, policy=harness-defaults, hl=harness, j=harness-workspace-json, auth=harness-auth
/=  head  /app/harness
|%
++  test-api-and-subscription-preserve-reasoning-through-a-tool-and-reload
  %-  zing
  %+  turn  `(list @t)`~['https://api.openai.com/v1/responses' device-url:auth]
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
  =/  bowl=bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~zod, now ~2026.9.24)
  =/  saved=state-0  *state-0
  =/  cfg  builtin-config:policy
  =.  cfg  cfg(url url, model 'gpt-6-luna', tools ~)
  =.  saved
    saved(defaults cfg, local-mcp-seen 1, provider-keys (my ~[['openai' 'fixture-api-key'] ['openai-device' 'fixture-device-token']]), sessions (my ~[['fixture' [~[[%config-replaced cfg]] 0]]]))
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  sent  (~(on-poke +.loaded bowl) %harness-action !>(`action:h`[%send 'fixture' 'What time is it?']))
  =/  first  (snag 0 (requests -.sent))
  =/  response=client-response:iris
    [%finished [200 ~] `['text/event-stream' (as-octs:mimes:html 'data: {"type":"response.output_item.done","item":{"id":"rs_time","type":"reasoning","summary":[],"encrypted_content":"ENCRYPTED_TIME"}}\0a\0adata: {"type":"response.output_item.done","item":{"type":"function_call","id":"fc_time","call_id":"call_time","name":"current_time","arguments":"{}"}}\0a\0adata: {"type":"response.completed","response":{"usage":{"input_tokens":10,"output_tokens":20}}}\0a\0a')]]
  =/  executed  (~(on-arvo +.sent bowl) wire.first [%iris %http-response response])
  =/  next  (snag 0 (requests -.executed))
  =/  input  (need (get:j (body next) 'input'))
  ?>  ?=(%a -.input)
  =/  state  !<(state-0 ~(on-save +.executed bowl))
  =/  reloaded  (~(on-load head bowl) !>(state))
  =/  final=client-response:iris
    [%finished [200 ~] `['text/event-stream' (as-octs:mimes:html 'data: {"type":"response.output_item.done","item":{"type":"message","role":"assistant","content":[{"type":"output_text","text":"It is midnight UTC."}]}}\0a\0adata: {"type":"response.completed","response":{"usage":{"input_tokens":30,"output_tokens":5}}}\0a\0a')]]
  =/  done  (~(on-arvo +.reloaded bowl) wire.next [%iris %http-response final])
  =/  retained  !<(state-0 ~(on-save +.done bowl))
  =/  v  (play:hl log:(~(got by sessions.retained) 'fixture'))
  =/  authorization
    (skim header-list.request.first |=([name=@t value=@t] =('authorization' name)))
  ;:  weld
    (expect-eq !>(url) !>(url.request.first))
    (expect-eq !>(url) !>(url.request.next))
    (expect-eq !>(~[['authorization' ?:(=(url device-url:auth) 'Bearer fixture-device-token' 'Bearer fixture-api-key')]]) !>(authorization))
    (expect-eq !>('ENCRYPTED_TIME') !>((string:j (snag 1 p.input) 'encrypted_content')))
    (expect-eq !>('function_call') !>((string:j (snag 2 p.input) 'type')))
    (expect-eq !>('function_call_output') !>((string:j (snag 3 p.input) 'type')))
    (expect-eq !>('call_time') !>((string:j (snag 3 p.input) 'call_id')))
    (expect !>(!=('' (string:j (snag 3 p.input) 'output'))))
    (expect-eq !>(`item:h`[%assistant 'It is midnight UTC.' ~]) !>((rear items.v)))
    (expect-eq !>(~) !>(pending.v))
    (expect-eq !>([40 25]) !>(total.v))
  ==
--
