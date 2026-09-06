/-  h=harness
/+  *test, r=harness-run-report
|%
++  input
  |=  id=@uv
  ^-  event:h
  [%input-received [id [%acp 'fixture'] ~ ~ ~2026.9.6 [%user 'PRIVATE_PROMPT']]]
++  fixture
  ^-  (list event:h)
  %-  flop
  :~  (input 0v1)
      [%llm-completed 1 %tool-calls [3 4] [%assistant 'PRIVATE_THOUGHT' ~[['PRIVATE_CALL_ID' 'current_time' 'PRIVATE_ARGS']]]]
      [%tool-completed 'PRIVATE_CALL_ID' 'current_time' 'PRIVATE_RESULT']
      [%llm-completed 2 %stop [1 2] [%assistant 'PRIVATE_REPLY' ~]]
      (input 0v2)
      [%llm-completed 3 %tool-calls [3 4] [%assistant '' ~[['id' 'SECRET_TOOL_NAME' 'PRIVATE_ARGS']]]]
      [%tool-completed 'id' 'SECRET_TOOL_NAME' 'error: PRIVATE_ERROR']
  ==
++  test-report-is-scoped-to-the-admitted-input
  =/  got  (need (collect:r fixture 0v1))
  (expect-eq !>(`report:r`[~[['PRIVATE_CALL_ID' 'current_time' %completed]] 1 |]) !>(got))
++  test-report-masks-unknown-tool-names-and-classifies-errors
  =/  got  (need (collect:r fixture 0v2))
  (expect-eq !>(`report:r`[~[['id' 'other_tool' %error]] 1 |]) !>(got))
++  test-report-missing-input-is-not-a-whole-session-report
  (expect-eq !>(`(unit report:r)`~) !>((collect:r fixture 0v3)))
++  test-report-bounds-log-traversal
  =/  log  (weld (reap 4.096 `event:h`[%retried ~]) fixture)
  (expect-eq !>(`(unit report:r)`~) !>((collect:r log 0v1)))
++  test-report-bounds-tool-detail-but-keeps-count
  =/  calls  (reap 70 `tool-call:h`['id' 'current_time' 'PRIVATE_ARGS'])
  =/  log=(list event:h)  ~[[%llm-completed 1 %tool-calls [1 2] [%assistant '' calls]] (input 0v1)]
  =/  got  (need (collect:r log 0v1))
  (expect !>(&(=(70 count.got) =(64 (lent calls.got)) truncated.got)))
++  test-report-does-not-turn-uncertainty-into-success
  (expect-eq !>(`call-state:r`%uncertain) !>((result-status:r 'uncertain: may have uploaded PRIVATE_URL')))
--
