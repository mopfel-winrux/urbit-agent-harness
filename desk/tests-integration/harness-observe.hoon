/-  h=harness, l=tlon-logs, *harness-store
/+  *test, policy=harness-defaults
/=  head  /app/harness
/=  routing  /tests-integration/harness-model-routing
|%
++  reports
  |=  cards=(list card:agent:gall)
  ^-  (list a-log:l)
  %+  murn
    cards
  |=  c=card:agent:gall
  ?:(?=([%pass [%telemetry ~] %agent * %poke %log-action-1 *] c) `!<(a-log:l +127.c) ~)
++  test-terminal-events-emit-once-and-sink-failure-is-inert
  =/  attempt  |.(exercise)
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  ;;(tang product.out)
++  exercise
  ^-  tang
  =/  =bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~zod, now ~2026.9.25)
  =/  cfg  builtin-config:policy
  =.  cfg  cfg(key 'PRIVATE_KEY')
  =/  log=(list event:h)
    ~[[%llm-requested 0 %turn] [%input-admitted [%user 'PRIVATE_PROMPT']] [%config-replaced cfg]]
  =/  saved=state-0  *state-0
  =.  saved  saved(local-mcp-seen 1, sessions (my ~[['private-session' [log 1]]]))
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  response=client-response:iris
    :*  %finished  [200 ~]
        :-  ~
        :*  'application/json'
            %-  as-octs:mimes:html
            '{"choices":[{"finish_reason":"stop","message":{"role":"assistant","content":"PRIVATE_REPLY"}}],"usage":{"prompt_tokens":10,"completion_tokens":5}}'
        ==
    ==
  =/  completed
    %+  ~(on-arvo +.loaded bowl)
      /llm/private-session/0/turn
    [%iris %http-response response]
  =/  again
    %+  ~(on-arvo +.completed bowl)
      /llm/private-session/0/turn
    [%iris %http-response response]
  =/  nack  (~(on-agent +.completed bowl) /telemetry [%poke-ack `~[leaf+"sink unavailable"]])
  =/  failed
    %+  ~(on-arvo +.loaded bowl)
      /llm/private-session/0/turn
    :*  %iris  %http-response
        [%finished [401 ~] `['application/json' (as-octs:mimes:html 'PRIVATE_ERROR')]]
    ==
  ;:  weld
      (expect-eq !>(1) !>((lent (reports -.completed))))
      (expect-eq !>(1) !>((lent (reports -.failed))))
      (expect-eq !>(~) !>((reports -.again)))
      (expect-eq !>(~) !>(-.nack))
      (expect-eq ~(on-save +.completed bowl) ~(on-save +.nack bowl))
  ==
++  test-fallback-logs-once-without-logging-stream-chunks
  =/  attempt  |.(fallback)
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  ;;(tang product.out)
++  fallback
  =/  bowl  bowl:routing
  =/  loaded  (~(on-load head bowl) !>(fixture:routing))
  =/  sent  (~(on-poke +.loaded bowl) %harness-action !>(`action:h`[%send 'fixture' 'private']))
  =/  request  (snag 0 (requests:routing -.sent))
  =/  retried  (~(on-arvo +.sent bowl) wire.request [%iris %http-response failed:routing])
  =/  late  (~(on-arvo +.retried bowl) wire.request [%iris %http-response failed:routing])
  =/  chunk  (as-octs:mimes:html 'data: {"choices":[{"delta":{"content":"private"}}]}\0a\0a')
  =/  progress=client-response:iris  [%progress [200 ~] p.chunk ~ `chunk]
  =/  streamed  (~(on-arvo +.sent bowl) wire.request [%iris %http-response progress])
  ;:  weld
      (expect-eq !>(~) !>((reports -.sent)))
      (expect-eq !>(1) !>((lent (reports -.retried))))
      (expect-eq !>(~) !>((reports -.late)))
      (expect-eq !>(~) !>((reports -.streamed)))
  ==
--
