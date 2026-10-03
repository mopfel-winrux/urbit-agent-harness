::  ACP admission and response ordering through the full head. Cards are
::  inspected inside the sandbox and never delivered to other agents.
/-  *harness-store, h=harness, ac=acp
/+  *test, policy=harness-defaults, hl=harness, j=harness-workspace-json
/=  head  /app/harness
|%
++  isolated
  |=  attempt=$-(* tang)
  =/  result  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.result)
  ;;(tang product.result)
::
++  bowl
  ^-  bowl:gall
  =/  value  *bowl:gall
  value(our ~zod, src ~zod, now ~2026.10.1)
::
++  fixture
  ^-  state-0
  =/  saved  *state-0
  saved(defaults builtin-config:policy, local-mcp-seen 1)
::
++  frames
  |=  cards=(list card:agent:gall)
  ^-  (list json)
  %+  murn  cards
  |=  card=card:agent:gall
  ^-  (unit json)
  ?.  ?=([%pass [%acp %send ~] %agent * %poke %acp-action-1 *] card)  ~
  =/  [pass=* wire=* agent=* target=* poke=* mark=* data=vase]  card
  =/  action  !<(action:v1:ac data)
  ?>  ?=(%send -.action)
  (de:json:html payload.action)
::
++  test-batch-admits-requests-in-order-and-ignores-replay
  %-  isolated
  |=  ignored=*
  =/  loaded  (~(on-load head bowl) !>(fixture))
  =/  =update:v1:ac
    :*  %messages  'fixture'  %agent
        :~  [1 ~2026.10.1 '{']
            [2 ~2026.10.1 '{"jsonrpc":"2.0","method":"session/new","params":{"name":"ignored"}}']
            :*  3  ~2026.10.1
                '{"jsonrpc":"2.0","id":1,"method":"session/new","params":{"name":"alpha"}}'
            ==
            [4 ~2026.10.1 '{"jsonrpc":"2.0","id":2,"method":"unknown"}']
            [5 ~2026.10.1 '{"jsonrpc":"2.0","id":3,"method":"session/list"}']
        ==
    ==
  =/  admitted
    %+  ~(on-agent +.loaded bowl)
      /acp/watch
    [%fact %acp-update-1 !>(update)]
  =/  saved  !<(state-0 ~(on-save +.admitted bowl))
  =/  replies  (frames -.admitted)
  ?>  =(4 (lent replies))
  =/  replayed
    %+  ~(on-agent +.admitted bowl)
      /acp/watch
    [%fact %acp-update-1 !>(update)]
  =/  acknowledgements
    %+  skim  -.admitted
    |=(card=card:agent:gall ?=([%pass [%acp %ack ~] %agent * %poke %acp-action-1 *] card))
  ;:  weld
      (expect-eq !>(1) !>(~(wyt by sessions.saved)))
      (expect !>((~(has by sessions.saved) 'alpha')))
      (expect-eq !>(5) !>((~(got by acp-through.saved) 'fixture')))
      (expect-eq !>(5) !>((lent acknowledgements)))
      (expect-eq !>(`json`[%n '1']) !>((need (get:j (snag 0 replies) 'id'))))
      %+  expect-eq
        !>('alpha')
      !>((string:j (need (get:j (snag 0 replies) 'result')) 'sessionId'))
      (expect-eq !>('session/update') !>((string:j (snag 1 replies) 'method')))
      %+  expect-eq
        !>(`json`[%n '-32601'])
      !>((need (get:j (need (get:j (snag 2 replies) 'error')) 'code')))
      (expect-eq !>(`json`[%n '3']) !>((need (get:j (snag 3 replies) 'id'))))
      (expect-eq !>(~) !>(-.replayed))
  ==
::
++  test-cancel-notification-needs-no-id-and-null-id-gets-a-reply
  %-  isolated
  |=  ignored=*
  =/  saved  fixture
  =/  events=(list event:h)
    :~  [%llm-requested 0 %turn]
        [%input-admitted [%user 'Pending']]
        [%config-replaced defaults.saved]
    ==
  =.  sessions.saved  (~(put by sessions.saved) 'alpha' [events 1])
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  =update:v1:ac
    :*  %messages  'fixture'  %agent
        :~  :*  1  ~2026.10.1
                '{"jsonrpc":"2.0","method":"session/cancel","params":{"sessionId":"alpha"}}'
            ==
            [2 ~2026.10.1 '{"jsonrpc":"2.0","id":null,"method":"initialize"}']
        ==
    ==
  =/  cancelled
    %+  ~(on-agent +.loaded bowl)
      /acp/watch
    [%fact %acp-update-1 !>(update)]
  =/  after  !<(state-0 ~(on-save +.cancelled bowl))
  =/  replies  (frames -.cancelled)
  ?>  =(1 (lent replies))
  =/  view  (play:hl log:(~(got by sessions.after) 'alpha'))
  ;:  weld
      (expect !>(?=(^ cancelled.view)))
      (expect-eq !>(~) !>(pending.view))
      (expect-eq !>(`json`~) !>((need (get:j (snag 0 replies) 'id'))))
      (expect !>(?=(^ (get:j (snag 0 replies) 'result'))))
  ==
--
