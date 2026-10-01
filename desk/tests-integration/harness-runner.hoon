::  Public transport exercises the full head without executing outbound cards.
/-  *harness-store, r=harness-runner, h=harness
/+  *test, j=harness-provider-wire, hl=harness, policy=harness-defaults, runner=harness-runner
/=  head  /app/harness
/=  seed  /tests/harness-runner
|%
++  isolated
  |=  attempt=$-(* tang)
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  ;;(tang product.out)
++  bowl
  ^-  bowl:gall
  =/  b=bowl:gall  *bowl:gall
  b(our ~zod, src ~zod, now ~2026.10.1)
++  saved
  ^-  state-0
  =/  s=state-0  *state-0
  s(runners issued:seed, local-mcp-seen 1)
++  request
  |=  body=@t
  ^-  inbound-request:eyre
  [| | [%ipv4 .127.0.0.1] [%'POST' '/harness/runners/laptop/events' ~[['authorization' (cat 3 'Bearer ' key:seed)] ['content-type' 'application/json']] `(as-octs:mimes:html body)]]
++  code
  |=  cards=(list card:agent:gall)
  ^-  @ud
  =/  headers
    %+  murn  cards
    |=  c=card:agent:gall
    ?.  ?=([%give %fact * %http-response-header *] c)  ~
    =/  [give=* fact=* paths=* mark=* data=vase]  c
    `!<(response-header:http data)
  status-code:(snag 0 headers)
++  test-transport-key-origin-tls-path-version-and-sequence
  %-  isolated  |=  ignored=*
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  req  (request '{"version":1,"sequence":1,"type":"ack","through":0}')
  =/  cases=(list [inbound-request:eyre @ud])
    :~  [req 200]
        [req(header-list.request ~[['cookie' 'urbauth-~zod=not-a-key']]) 401]
        [req(header-list.request [['origin' 'null'] ['Origin' 'null'] header-list.request.req]) 403]
        [req(address [%ipv4 .10.0.0.1]) 403]
        [req(address [%ipv4 .10.0.0.1], secure &) 200]
        [req(url.request '/harness/runners/laptop/events?key=no') 404]
        [(request '{"version":2,"sequence":1,"type":"ack","through":0}') 400]
        [(request '{"version":1,"sequence":2,"type":"ack","through":0}') 409]
    ==
  %-  zing
  %+  turn  cases
  |=  [req=inbound-request:eyre expected=@ud]
  =/  result  (~(on-poke +.loaded bowl) %handle-http-request !>([`@ta`%fixture req]))
  (expect-eq !>(expected) !>((code -.result)))
++  test-native-dispatch-reply-replay-and-cancel
  %-  isolated  |=  ignored=*
  =/  cfg  builtin-config:policy
  =.  cfg  cfg(url 'connected://laptop', model '', tools ~[%web])
  =/  initial  saved
  =.  initial  initial(defaults cfg, sessions (my ~[['channel' [~[[%config-replaced cfg]] 0]]]))
  =/  loaded  (~(on-load head bowl) !>(initial))
  =/  sent  (~(on-poke +.loaded bowl) %harness-action !>(`action:h`[%send 'channel' 'Hello']))
  =/  submits
    %+  murn  -.sent
    |=  c=card:agent:gall
    ?.  ?=([%pass * %agent * %poke %harness-runner-request *] c)  ~
    =/  [pass=* wire=* agent=* who=* poke=* mark=* data=vase]  c
    `!<(request:r data)
  ?>  =(1 (lent submits))
  ?>  ?=(^ submits)
  =/  job  i.submits
  =/  queued  (~(on-poke +.sent bowl) %harness-runner-request !>(job))
  =/  queue-state  !<(state-0 ~(on-save +.queued bowl))
  =/  envelope  (~(got by events:(~(got by registry.runners.queue-state) 'laptop')) 1)
  =/  event
    |=  [sequence=@ud type=@t]
    %-  pairs:enjs:format
    :~  ['version' %n '1']
        ['sequence' (numb:enjs:format sequence)]
        ['type' %s type]
        ['attemptId' %s attempt.job]
        ['conversationId' %s 'channel']
        ['turnId' %s (scot %ud req.job)]
    ==
  =/  claim  (request (en:json:html (event 1 'claim')))
  =/  claimed  (~(on-poke +.queued bowl) %handle-http-request !>([`@ta`%fixture claim]))
  =/  again  (~(on-poke +.claimed bowl) %handle-http-request !>([`@ta`%fixture claim]))
  =/  complete  (put:j (event 2 'complete') 'response' (need (de:json:html '{"choices":[{"finish_reason":"stop","message":{"role":"assistant","content":"Hello back"}}]}')))
  =/  done  (~(on-poke +.again bowl) %handle-http-request !>([`@ta`%fixture (request (en:json:html complete))]))
  =/  repeated  (~(on-poke +.done bowl) %handle-http-request !>([`@ta`%fixture (request (en:json:html complete))]))
  =/  final  !<(state-0 ~(on-save +.repeated bowl))
  =/  tool-complete
    (put:j (event 2 'complete') 'response' (need (de:json:html '{"choices":[{"finish_reason":"tool_calls","message":{"role":"assistant","content":"","tool_calls":[{"id":"fetch","type":"function","function":{"name":"http_fetch","arguments":"{\\"url\\":\\"https://example.test\\"}"}}]}}]}')))
  =/  parked  (~(on-poke +.claimed bowl) %handle-http-request !>([`@ta`%fixture (request (en:json:html tool-complete))]))
  =/  parked-state  !<(state-0 ~(on-save +.parked bowl))
  =/  parked-stop  (~(on-poke +.parked bowl) %harness-action !>(`action:h`[%cancel 'channel']))
  =/  parked-stopped  !<(state-0 ~(on-save +.parked-stop bowl))
  =/  stopped  (~(on-poke +.queued bowl) %harness-action !>(`action:h`[%cancel 'channel']))
  =/  stopped-state  !<(state-0 ~(on-save +.stopped bowl))
  =/  revoked  (owner:runner runners.queue-state 'revoke' args:seed ~2026.10.1)
  ?>  ?=(%& -.revoked)
  =/  disconnected  (~(on-load head bowl) !>(queue-state(runners db.p.revoked)))
  =/  revoke-state  !<(state-0 ~(on-save +.disconnected bowl))
  ;:  weld
    (expect-eq !>('prompt') !>((str:j envelope 'type')))
    (expect-eq !>(200) !>((code -.claimed)))
    (expect-eq !>(200) !>((code -.again)))
    (expect-eq !>(200) !>((code -.done)))
    (expect-eq !>(200) !>((code -.repeated)))
    (expect-eq !>(`item:h`[%assistant 'Hello back' ~]) !>((rear items:(play:hl log:(~(got by sessions.final) 'channel')))))
    (expect-eq !>(0) !>(~(wyt by jobs.runners.final)))
    (expect !>(parked:(~(got by jobs.runners.parked-state) attempt.job)))
    (expect-eq !>(0) !>(~(wyt by jobs.runners.parked-stopped)))
    (expect-eq !>('cancel') !>((str:j (~(got by events:(~(got by registry.runners.parked-stopped) 'laptop')) 2) 'type')))
    (expect-eq !>(0) !>(~(wyt by jobs.runners.stopped-state)))
    (expect-eq !>('cancel') !>((str:j (~(got by events:(~(got by registry.runners.stopped-state) 'laptop')) 2) 'type')))
    (expect-eq !>(0) !>(~(wyt by jobs.runners.revoke-state)))
  ==
--
