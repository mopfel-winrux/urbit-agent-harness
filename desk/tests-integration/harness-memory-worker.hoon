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
    knowledge  knowledge.s(enabled.dreaming.maintenance &, due.dreaming.maintenance `~2026.10.8)
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
++  test-dreaming-is-off-by-default-and-reload-does-not-start-inference
  (isolated |=(ignored=* disabled))
++  test-conversation-events-do-not-postpone-the-memory-watchdog
  (isolated |=(ignored=* stable-wake))
++  stable-wake
  =/  loaded  (~(on-load head bowl) !>(fixture))
  =/  sent
    %+  ~(on-poke +.loaded bowl)
      %harness-action
    !>(`action:h`[%send 'first' 'Provisioning requires privacy.'])
  =/  request  (snag 0 (requests -.sent))
  =/  completed
    (~(on-arvo +.sent bowl) wire.request [%iris %http-response (response 'Understood.')])
  =/  saved  !<(state-0 ~(on-save +.completed bowl))
  =/  at  (need wake.knowledge.saved)
  =/  tick  bowl
  =.  tick  tick(now at)
  =/  working  (~(on-arvo +.completed tick) /memory-work/(scot %da at) [%behn %wake ~])
  =/  before  !<(state-0 ~(on-save +.working tick))
  =.  tick  tick(now (add (need wake.knowledge.before) ~s1))
  =/  concurrent
    (~(on-poke +.working tick) %harness-action !>(`action:h`[%send 'second' 'Continue.']))
  =/  after  !<(state-0 ~(on-save +.concurrent tick))
  ;:  weld
      (expect !>(?=(^ pending.knowledge.before)))
      (expect-eq !>(wake.knowledge.before) !>(wake.knowledge.after))
  ==
++  disabled
  =/  initial  fixture
  =.  enabled.dreaming.maintenance.knowledge.initial  |
  =.  due.dreaming.maintenance.knowledge.initial  ~
  =/  loaded  (~(on-load head bowl) !>(initial))
  =/  sent  (~(on-poke +.loaded bowl) %harness-action !>(`action:h`[%send 'first' 'Continue.']))
  =/  request  (snag 0 (requests -.sent))
  =/  completed
    (~(on-arvo +.sent bowl) wire.request [%iris %http-response (response 'Reply.')])
  =/  saved  !<(state-0 ~(on-save +.completed bowl))
  =/  reloaded  (~(on-load +.completed bowl) !>(saved))
  =/  after  !<(state-0 ~(on-save +.reloaded bowl))
  ;:  weld
      (expect-eq !>(~) !>((requests -.completed)))
      (expect-eq !>(~) !>((requests -.reloaded)))
      (expect-eq !>(~) !>(wake.knowledge.after))
      (expect-eq !>(0) !>(next.knowledge.after))
      (expect !>((~(has by buffered.dreaming.maintenance.knowledge.after) 'first')))
  ==
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
      (expect-eq !>(0) !>(next.knowledge.saved))
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
++  compaction-fixture
  ^-  state-0
  =/  initial  fixture
  =/  cfg  defaults.initial
  =/  log=(list event:h)
    :~  [%config-replaced cfg]
        :-  %input-received
        :*  0v1  [%poke ~zod]  `~zod  ~  ~2026.10.7
            [%user 'Provisioning requires privacy. Keep this constraint for future projects.']
        ==
        [%llm-requested 0 %turn]
        [%llm-routed 0 cfg]
        [%llm-completed 0 %stop [1 1] [%assistant 'Understood; I will respect that constraint.' ~]]
        [%input-received [0v2 [%poke ~zod] `~zod ~ ~2026.10.7 [%user 'Now review the plan.']]]
        [%llm-requested 1 %turn]
        [%llm-routed 1 cfg]
        [%llm-completed 1 %stop [1 1] [%assistant 'The plan is ready for review.' ~]]
    ==
  %=  initial
    sessions  (my ~[['first' [(flop log) 2]]])
    enabled.dreaming.maintenance.knowledge  |
    due.dreaming.maintenance.knowledge  ~
  ==
++  compact-answer
  |=  memories=json
  %-  en:json:html
  (pairs:enjs:format ~[['summary' %s 'Provision privately.'] ['memories' memories]])
++  compact-facts
  ^-  json
  %-  need
  %-  de:json:html
  '[{"name":"provisioning","revision":0,"text":"Provisioning requires privacy.","aliases":[],"general":false,"event":2,"quote":"requires privacy"}]'
++  compact-case
  |=  [mode=@t memories=json expected=@ud]
  ^-  tang
  =/  initial  compaction-fixture
  =?  disabled.knowledge.initial  =('off' mode)  (silt ~['first'])
  =/  loaded  (~(on-load head bowl) !>(initial))
  =/  started  (~(on-poke +.loaded bowl) %harness-action !>(`action:h`[%compact 'first']))
  =/  request  (snag 0 (requests -.started))
  =/  dispatched  !<(state-0 ~(on-save +.started bowl))
  =?  barrier.knowledge.dispatched  =('forgotten' mode)  +(barrier.knowledge.dispatched)
  =/  reloaded  (~(on-load +.started bowl) !>(dispatched))
  =/  completed
    %+  ~(on-arvo +.reloaded bowl)
      wire.request
    :*  %iris  %http-response
        (response ?:(=('off' mode) 'Provision privately.' (compact-answer memories)))
    ==
  =/  after  !<(state-0 ~(on-save +.completed bowl))
  =/  view  (play:hl log:(~(got by sessions.after) 'first'))
  =/  text  q:(need body.request.request)
  =/  extra  (find "Memory evidence:" (trip text))
  =/  checkpoint
    %+  skim  log:(~(got by sessions.after) 'first')
    |=(e=event:h ?=(%checkpoint-completed -.e))
  ?>  ?=(^ checkpoint)
  ;:  weld
      (expect-eq !>(1) !>((lent (requests -.started))))
      (expect-eq !>(~) !>((requests -.completed)))
      (expect-eq !>(~) !>(err.view))
      (expect-eq !>(~) !>(pending.view))
      (expect-eq !>(~) !>(compactions.maintenance.knowledge.after))
      (expect-eq !>(expected) !>(~(wyt by records.knowledge.after)))
      (expect-eq !>(!=('off' mode)) !>(?=(^ extra)))
      (expect-eq !>(|) !>(enabled.dreaming.maintenance.knowledge.after))
      (expect-eq !>(~) !>(wake.knowledge.after))
      %+  expect-eq  !>('Provision privately.')
      !>(?>(?=(%checkpoint-completed -.i.checkpoint) summary.i.checkpoint))
  ==
++  test-compaction-captures-original-evidence-in-one-request-with-dreaming-off
  (isolated |=(ignored=* (compact-case 'on' compact-facts 1)))
++  test-invalid-memory-proposals-do-not-discard-a-valid-checkpoint
  (isolated |=(ignored=* (compact-case 'on' [%s 'invalid'] 0)))
++  test-compaction-capture-survives-reload-and-respects-forgetting
  (isolated |=(ignored=* (compact-case 'forgotten' compact-facts 0)))
++  test-conversation-optout-keeps-compaction-tool-free-without-capture
  (isolated |=(ignored=* (compact-case 'off' compact-facts 0)))
--
