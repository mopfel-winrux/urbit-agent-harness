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
  :*  |  |  [%ipv4 .127.0.0.1]
      :*  %'POST'  '/harness/runners/laptop/events'
          ~[['authorization' (cat 3 'Bearer ' key:seed)] ['content-type' 'application/json']]
          `(as-octs:mimes:html body)
      ==
  ==
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
  %-  isolated
  |=  ignored=*
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
  %-  isolated
  |=  ignored=*
  =/  cfg  builtin-config:policy
  =.  cfg  cfg(url 'connected://laptop', model '', tools ~[%web])
  =/  initial  saved
  =.  initial
    initial(defaults cfg, sessions (my ~[['channel' [~[[%config-replaced cfg]] 0]]]))
  =/  loaded  (~(on-load head bowl) !>(initial))
  =/  sent
    %+  ~(on-poke +.loaded bowl)
      %harness-action
    !>(`action:h`[%send 'channel' 'Hello'])
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
  =/  claimed
    %+  ~(on-poke +.queued bowl)
      %handle-http-request
    !>([`@ta`%fixture claim])
  =/  again
    %+  ~(on-poke +.claimed bowl)
      %handle-http-request
    !>([`@ta`%fixture claim])
  =/  delta  (put:j (event 2 'delta') 'text' [%s 'Hello 🙂'])
  =/  streamed
    %+  ~(on-poke +.again bowl)
      %handle-http-request
    !>([`@ta`%fixture (request (en:json:html delta))])
  =/  streaming  !<(state-0 ~(on-save +.streamed bowl))
  =/  complete
    %^  put:j
      (event 3 'complete')
      'response'
    %-  need
    %-  de:json:html
    '{"choices":[{"finish_reason":"stop","message":{"role":"assistant","content":"Hello back"}}]}'
  =/  done
    %+  ~(on-poke +.streamed bowl)
      %handle-http-request
    !>([`@ta`%fixture (request (en:json:html complete))])
  =/  repeated
    %+  ~(on-poke +.done bowl)
      %handle-http-request
    !>([`@ta`%fixture (request (en:json:html complete))])
  =/  final  !<(state-0 ~(on-save +.repeated bowl))
  =/  tool-complete
    %^  put:j
      (event 2 'complete')
      'response'
    %-  need
    %-  de:json:html
    '{"choices":[{"finish_reason":"tool_calls","message":{"role":"assistant","content":"","tool_calls":[{"id":"fetch","type":"function","function":{"name":"http_fetch","arguments":"{\\"url\\":\\"https://example.test\\"}"}}]}}]}'
  =/  parked
    %+  ~(on-poke +.claimed bowl)
      %handle-http-request
    !>([`@ta`%fixture (request (en:json:html tool-complete))])
  =/  parked-state  !<(state-0 ~(on-save +.parked bowl))
  =/  parked-stop
    %+  ~(on-poke +.parked bowl)
      %harness-action
    !>(`action:h`[%cancel 'channel'])
  =/  parked-stopped  !<(state-0 ~(on-save +.parked-stop bowl))
  =/  stopped
    %+  ~(on-poke +.queued bowl)
      %harness-action
    !>(`action:h`[%cancel 'channel'])
  =/  stopped-state  !<(state-0 ~(on-save +.stopped bowl))
  =/  revoked  (owner:runner runners.queue-state 'revoke' args:seed ~2026.10.1)
  ?>  ?=(%& -.revoked)
  =/  disconnected  (~(on-load head bowl) !>(queue-state(runners db.p.revoked)))
  =/  revoke-state  !<(state-0 ~(on-save +.disconnected bowl))
  ;:  weld
      (expect-eq !>('prompt') !>((str:j envelope 'type')))
      (expect-eq !>(200) !>((code -.claimed)))
      (expect-eq !>(200) !>((code -.again)))
      %+  expect-eq
        !>(`stream-progress`['Hello 🙂' 10])
      !>((~(got by streams.streaming) ['channel' req.job]))
      (expect-eq !>(0) !>(~(wyt by streams.final)))
      (expect-eq !>(200) !>((code -.done)))
      (expect-eq !>(200) !>((code -.repeated)))
      %+  expect-eq
        !>(`item:h`[%assistant 'Hello back' ~])
      !>((rear items:(play:hl log:(~(got by sessions.final) 'channel'))))
      (expect-eq !>(0) !>(~(wyt by jobs.runners.final)))
      (expect !>(parked:(~(got by jobs.runners.parked-state) attempt.job)))
      (expect-eq !>(0) !>(~(wyt by jobs.runners.parked-stopped)))
      %+  expect-eq
        !>('cancel')
      !>((str:j (~(got by events:(~(got by registry.runners.parked-stopped) 'laptop')) 2) 'type'))
      (expect-eq !>(0) !>(~(wyt by jobs.runners.stopped-state)))
      %+  expect-eq
        !>('cancel')
      !>((str:j (~(got by events:(~(got by registry.runners.stopped-state) 'laptop')) 2) 'type'))
      (expect-eq !>(0) !>(~(wyt by jobs.runners.revoke-state)))
  ==
::
++  test-expired-job-notifies-hands-once
  %-  isolated
  |=  ignored=*
  =/  initial-bowl  bowl
  =/  config  builtin-config:policy
  =.  config  config(url 'connected://laptop', model '', tools ~)
  =/  events=(list event:h)
    :~  [%llm-routed 0 config]
        [%llm-requested 0 %turn]
        [%input-admitted [%user 'Hello']]
        [%config-replaced config]
    ==
  =/  job=request:r  ['laptop' 'timeout' 0 %turn 'attempt' (sham events) ~]
  =/  initial  saved
  =.  sessions.initial  (~(put by sessions.initial) 'timeout' [events 1])
  =.  jobs.runners.initial
    (~(put by jobs.runners.initial) 'attempt' [job (sub now.initial-bowl ~m31) | |])
  =/  loaded  (~(on-load head bowl) !>(initial))
  =/  running  !<(state-0 ~(on-save +.loaded bowl))
  ?>  ?=(^ wake.runners.running)
  =/  at  u.wake.runners.running
  =/  tick-bowl  initial-bowl(now at)
  =/  expired
    (~(on-arvo +.loaded tick-bowl) /runner-wake/(scot %da at) [%behn %wake ~])
  =/  final  !<(state-0 ~(on-save +.expired tick-bowl))
  =/  notifications
    %+  skim  -.expired
    |=  card=card:agent:gall
    ?=([%give %fact [[%hand-events ~] ~] %noun *] card)
  =/  view  (play:hl log:(~(got by sessions.final) 'timeout'))
  ;:  weld
      (expect-eq !>(1) !>((lent notifications)))
      (expect-eq !>(0) !>(~(wyt by jobs.runners.final)))
      (expect-eq !>(~) !>(pending.view))
      (expect !>(?=(^ err.view)))
  ==
::
++  test-reconnect-replays-after-cursor-and-closes-prior-stream
  %-  isolated
  |=  ignored=*
  =/  initial  saved
  =/  row  (~(got by registry.runners.initial) 'laptop')
  =.  row
    row(next 4, acknowledged 1, events (my ~[[2 [%s 'two']] [3 [%s 'three']]]))
  =.  registry.runners.initial  (~(put by registry.runners.initial) 'laptop' row)
  =/  loaded  (~(on-load head bowl) !>(initial))
  =/  connect
    |=  cursor=@t
    =/  inbound  (request '')
    %=  inbound  method.request  %'GET'  body.request  ~  header-list.request
        [['last-event-id' cursor] header-list.request.inbound]
    ==
  =/  first
    (~(on-poke +.loaded bowl) %handle-http-request !>([`@ta`%first (connect '1')]))
  =/  second
    (~(on-poke +.first bowl) %handle-http-request !>([`@ta`%second (connect '2')]))
  =/  final  !<(state-0 ~(on-save +.second bowl))
  =/  connected  (~(got by registry.runners.final) 'laptop')
  =/  transport
    %+  skim  -.second
    |=  card=card:agent:gall
    ?=(%give -.card)
  =/  data
    (as-octs:mimes:html (cat 3 ': connected\0a\0a' (frame:runner 3 [%s 'three'])))
  =/  expected=(list card:agent:gall)
    :~  [%give %fact ~[/http-response/first] %http-response-data !>(`(unit octs)`~)]
        [%give %kick ~[/http-response/first] ~]
        :*  %give  %fact  ~[/http-response/second]  %http-response-header
            !>  ^-  response-header:http
                :-  200
                :~  ['content-type' 'text/event-stream']
                    ['cache-control' 'no-store']
                    ['x-accel-buffering' 'no']
                ==
        ==
        [%give %fact ~[/http-response/second] %http-response-data !>(`(unit octs)`(some data))]
    ==
  =/  stale
    (~(on-poke +.second bowl) %handle-http-request !>([`@ta`%stale (connect '0')]))
  =/  future
    (~(on-poke +.second bowl) %handle-http-request !>([`@ta`%future (connect '4')]))
  =/  unchanged  !<(state-0 ~(on-save +.stale bowl))
  ;:  weld
      (expect-eq !>(expected) !>(transport))
      (expect-eq !>(`@ta`%second) !>((need stream.connected)))
      (expect-eq !>(events.row) !>(events.connected))
      (expect-eq !>(409) !>((code -.stale)))
      (expect-eq !>(409) !>((code -.future)))
      (expect-eq !>(runners.final) !>(runners.unchanged))
  ==
--
