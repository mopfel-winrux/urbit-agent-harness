::  Drive real head arms with fixture Iris responses; cards stay local.
/-  h=harness, *harness-store, renew=harness-oauth
/+  *test, policy=harness-defaults, hl=harness, j=harness-provider-wire
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
  b(our ~zod, src ~zod, now ~2026.10.7)
++  requests
  |=  cards=(list card:agent:gall)
  ^-  (list http-card:renew)
  %+  murn  cards
  |=  c=card:agent:gall
  ^-((unit http-card:renew) ?:(?=([%pass [%llm *] %arvo %i %request *] c) `c ~))
++  fixture
  ^-  state-0
  =/  s  *state-0
  =/  cfg  builtin-config:policy
  =.  cfg
    cfg(url 'https://openrouter.ai/api/v1/chat/completions', model 'fixture', zdr &, tools ~)
  %=  s
    defaults  cfg
    summary-models  [`cfg(model 'compaction-fixture') `cfg(model 'lcm-fixture')]
    local-mcp-seen  1
    provider-keys  (my ~[['openrouter' 'fixture-key']])
    sessions  %-  my
              ~[['first' [~[[%config-replaced cfg]] 0]] ['second' [~[[%config-replaced cfg]] 0]]]
  ==
++  response
  |=  text=@t
  ^-  client-response:iris
  =/  message  (pairs:enjs:format ~[['role' %s 'assistant'] ['content' %s text]])
  =/  choice  (pairs:enjs:format ~[['message' message] ['finish_reason' %s 'stop']])
  =/  body  (en:json:html (pairs:enjs:format ~[['choices' %a ~[choice]]]))
  [%finished [200 ~] `['application/json' (as-octs:mimes:html body)]]
++  test-background-capture-is-independent-of-active-turn-and-shared-on-admission
  (isolated |=(ignored=* independent))
++  independent
  =/  loaded  (~(on-load head bowl) !>(fixture))
  =/  sent
    %+  ~(on-poke +.loaded bowl)
      %harness-action
    !>(`action:h`[%send 'first' 'Provisioning requires privacy.'])
  =/  request  (snag 0 (requests -.sent))
  =/  completed
    %+  ~(on-arvo +.sent bowl)
      wire.request
    [%iris %http-response (response 'Understood.')]
  =/  saved  !<(state-0 ~(on-save +.completed bowl))
  =/  at  (need wake.knowledge.saved)
  =/  tick  bowl
  =.  tick  tick(now at)
  =/  working  (~(on-arvo +.completed tick) /memory-work/(scot %da at) [%behn %wake ~])
  =/  extraction  (snag 0 (requests -.working))
  =/  work-state  !<(state-0 ~(on-save +.working tick))
  =/  concurrent
    %+  ~(on-poke +.working tick)
      %harness-action
    !>(`action:h`[%send 'first' 'Now continue the conversation.'])
  =/  before  !<(state-0 ~(on-save +.concurrent tick))
  =/  fact=@t
    '[{"name":"provisioning","revision":0,"text":"Provisioning requires privacy.","aliases":[],"general":false,"event":2,"quote":"requires privacy"}]'
  =/  captured
    (~(on-arvo +.concurrent tick) wire.extraction [%iris %http-response (response fact)])
  =/  after  !<(state-0 ~(on-save +.captured tick))
  =/  fenced  (~(on-poke +.captured tick) %harness-action !>(`action:h`[%fence 'first']))
  =/  fence-state  !<(state-0 ~(on-save +.fenced tick))
  =/  peek  (need (need (~(on-peek +.captured tick) /x/memory/provisioning)))
  =/  record  !<(json q.peek)
  =/  cross
    %+  ~(on-poke +.captured tick)
      %harness-action
    !>(`action:h`[%send 'second' 'What does provisioning require?'])
  =/  recalled  (snag 0 (requests -.cross))
  =/  text  q:(need body.request.recalled)
  =/  found  (find "Provisioning requires privacy." (trip text))
  ;:  weld
      (expect-eq !>(1) !>((lent (requests -.sent))))
      (expect-eq !>(~) !>((requests -.completed)))
      (expect-eq !>(1) !>(next.knowledge.saved))
      (expect-eq !>('lcm-fixture') !>(model.config:(need pending.knowledge.work-state)))
      (expect-eq !>(%memory) !>((snag 3 wire.extraction)))
      (expect-eq !>(~) !>((requests -.captured)))
      (expect-eq !>(sessions.before) !>(sessions.after))
      %+  expect-eq
        !>(log:(~(got by sessions.after) 'first'))
      !>((~(got by cursors.knowledge.fence-state) 'first'))
      (expect !>((~(has by records.knowledge.after) 'provisioning')))
      (expect-eq !>('Provisioning requires privacy.') !>((str:j record 'text')))
      (expect !>(?=(^ found)))
  ==
++  test-reload-timeout-and-late-responses-preserve-the-conversation
  (isolated |=(ignored=* timeout))
++  timeout
  =/  loaded  (~(on-load head bowl) !>(fixture))
  =/  sent
    %+  ~(on-poke +.loaded bowl)
      %harness-action
    !>(`action:h`[%send 'first' 'Provisioning requires privacy.'])
  =/  request  (snag 0 (requests -.sent))
  =/  completed
    %+  ~(on-arvo +.sent bowl)
      wire.request
    [%iris %http-response (response 'Understood.')]
  =/  saved  !<(state-0 ~(on-save +.completed bowl))
  =/  at  (need wake.knowledge.saved)
  =/  tick  bowl
  =.  tick  tick(now at)
  =/  working  (~(on-arvo +.completed tick) /memory-work/(scot %da at) [%behn %wake ~])
  =/  extraction  (snag 0 (requests -.working))
  =/  pending  !<(state-0 ~(on-save +.working tick))
  =/  reloaded  (~(on-load head tick) !>(pending))
  =/  restored  !<(state-0 ~(on-save +.reloaded tick))
  =.  at  (need wake.knowledge.restored)
  =.  tick  tick(now at)
  =/  expired  (~(on-arvo +.reloaded tick) /memory-work/(scot %da at) [%behn %wake ~])
  =/  retry  !<(state-0 ~(on-save +.expired tick))
  =/  late  (~(on-arvo +.expired tick) wire.extraction [%iris %http-response (response '[]')])
  =/  after  !<(state-0 ~(on-save +.late tick))
  ;:  weld
      (expect-eq !>(sessions.pending) !>(sessions.after))
      (expect-eq !>(pending.knowledge.pending) !>(pending.knowledge.restored))
      (expect-eq !>(~) !>(pending.knowledge.after))
      (expect-eq !>(1) !>(head.knowledge.after))
      (expect-eq !>(2) !>(next.knowledge.after))
      (expect-eq !>(knowledge.retry) !>(knowledge.after))
      (expect-eq !>(~) !>((requests -.reloaded)))
      (expect-eq !>(~) !>((requests -.expired)))
      (expect-eq !>(~) !>((requests -.late)))
  ==
++  test-optout-excludes-cancelled-turns-after-reenabling
  (isolated |=(ignored=* optout))
++  optout
  =/  loaded  (~(on-load head bowl) !>(fixture))
  =/  off  (~(on-poke +.loaded bowl) %harness-action !>(`action:h`[%send 'first' '/memory off']))
  =/  private
    (~(on-poke +.off bowl) %harness-action !>(`action:h`[%send 'first' 'PRIVATE_OPT_OUT_EVIDENCE']))
  =/  cancelled  (~(on-poke +.private bowl) %harness-action !>(`action:h`[%cancel 'first']))
  =/  on  (~(on-poke +.cancelled bowl) %harness-action !>(`action:h`[%send 'first' '/memory on']))
  =/  sent
    %+  ~(on-poke +.on bowl)
      %harness-action
    !>(`action:h`[%send 'first' 'Provisioning requires privacy.'])
  =/  request  (snag 0 (requests -.sent))
  =/  completed
    %+  ~(on-arvo +.sent bowl)
      wire.request
    [%iris %http-response (response 'Understood.')]
  =/  saved  !<(state-0 ~(on-save +.completed bowl))
  =/  at  (need wake.knowledge.saved)
  =/  tick  bowl
  =.  tick  tick(now at)
  =/  working  (~(on-arvo +.completed tick) /memory-work/(scot %da at) [%behn %wake ~])
  =/  extraction  (snag 0 (requests -.working))
  =/  text  q:(need body.request.extraction)
  =/  private-found  (find "PRIVATE_OPT_OUT_EVIDENCE" (trip text))
  =/  public-found  (find "Provisioning requires privacy." (trip text))
  ;:  weld
      (expect-eq !>(~) !>(private-found))
      (expect !>(?=(^ public-found)))
  ==
--
