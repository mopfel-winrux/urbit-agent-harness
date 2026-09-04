/-  h=harness
/+  *test, hl=harness, hs=harness-session
|%
++  history
  ^-  (list event:h)
  %-  flop
  ^-  (list event:h)
  :~  [%config-replaced *config:h]
      [%input-admitted [%user 'one']]
      [%llm-completed 0 %stop [10 2] [%assistant 'first' ~]]
      [%input-admitted [%user 'two']]
      [%llm-completed 1 %stop [20 3] [%assistant 'second' ~]]
      [%input-admitted [%user 'three']]
      [%llm-completed 2 %stop [30 4] [%assistant 'third' ~]]
      [%input-admitted [%user 'four']]
      [%compaction-completed 3 'summary']
  ==
++  test-transcript-survives-compaction
  =/  context  items:(play:hl history)
  =/  transcript  (transcript-items:hl history)
  (expect !>(&(=(7 (lent transcript)) (lth (lent context) (lent transcript)))))
++  test-replay-order-and-usage
  =/  view  (play:hl history)
  =/  before  (play:hl (slag 1 history))
  =/  expected=(list item:h)
    ~[[%assistant 'first' ~] [%user 'two'] [%assistant 'second' ~] [%user 'three'] [%assistant 'third' ~] [%user 'four']]
  (expect !>(&(=(expected items.view) =(items.before (transcript-items:hl (slag 1 history))) =([60 9] total.view) =(`'summary' summary.view))))
++  test-stable-event-addresses
  (expect-eq !>(`(list @ud)`~[2 3 4 5 6 7 8]) !>((turn (transcript:hl history) |=([at=@ud (unit input-id:h) item:h] at))))
++  test-branch-keeps-prefix
  =/  result  (branch:hs 'parent' [history 4] 3)
  ?>  ?=(%& -.result)
  =/  view  (play:hl log.p.result)
  (expect !>(&(=(`[from='parent' at=3] origin.view) =(2 (lent items.view)) =(~ pending.view) =(~ (decide:hl view ~)))))
++  test-branch-rejects-invalid-point
  =/  out-of-range  (branch:hs 'parent' [history 4] 100)
  =/  user-message  (branch:hs 'parent' [history 4] 4)
  (expect !>(&(?=(%| -.out-of-range) ?=(%| -.user-message))))
++  test-branch-rejects-open-tool-exchange
  =/  log=(list event:h)
    ~[[%llm-completed 0 %tool-calls [1 1] [%assistant '' ~[['call' 'get_ship_time' '{}']]]]]
  =/  result  (branch:hs 'parent' [log 1] 1)
  (expect !>(?=(%| -.result)))
++  test-stream-rejects-unfinished-text
  =/  wire=@t  'data: {"choices":[{"delta":{"content":"partial"},"finish_reason":null}]}\0a\0a'
  =/  result  (parse-chat-sse:hl wire)
  (expect !>(?=(%| -.result)))
++  test-stream-joins-fragmented-tools
  =/  wire=@t
    %+  rap  3
    :~  'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"call","function":{"name":"get_ship_time","arguments":"{"}}]},"finish_reason":null}]}\0a\0a'
        'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"function":{"arguments":"}"}}]},"finish_reason":"tool_calls"}]}\0a\0a'
    ==
  =/  result  (parse-chat-sse:hl wire)
  ?>  ?=(%& -.result)
  (expect-eq !>(`item:h`[%assistant '' ~[['call' 'get_ship_time' '{}']]]) !>(it.p.result))
--
