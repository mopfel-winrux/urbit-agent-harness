::  Opt-in: -test /=harness=/tests-integration/harness-drive
::  Execute one batch against a saved fixture. Inspect cards inside the
::  sandbox and never deliver them to agents or network services.
/-  h=harness, *harness-store
/+  *test, hl=harness, defaults=harness-defaults
/=  head  /app/harness
|%
++  test-tool-batch-shares-edits-and-preserves-deferred-identities
  =/  attempt  |.(tool-batch)
  =/  result  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.result)
  ;;(tang product.result)
::
++  tool-batch
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =.  src.bowl  ~zod
  =.  dap.bowl  %harness
  =.  now.bowl  ~2026.10.1
  =/  saved=state-0  *state-0
  =/  config  builtin-config:defaults
  =.  tools.config  ~[%skills %skill-write %author %web %code]
  =/  calls=(list tool-call:h)
    :~  ['write' 'write_skill' '{"name":"sample","description":"Sample","body":"First body"}']
        ['read-first' 'read_skill' '{"name":"sample"}']
        ['propose' 'propose_skill' '{"name":"sample","description":"Sample","body":"Second body"}']
        ['commit' 'commit_skill' '{"name":"sample"}']
        ['read-second' 'read_skill' '{"name":"sample"}']
        ['delete' 'delete_skill' '{"name":"sample"}']
        ['read-deleted' 'read_skill' '{"name":"sample"}']
        ['stage' 'propose_skill' '{"name":"draft","description":"Draft","body":"Unpublished"}']
        ['discard' 'discard_skill' '{"name":"draft"}']
        ['rejected' 'curl' '{"url":"https://example.com/"}']
        ['fetch' 'http_fetch' '{"url":"https://example.com/"}']
        ['script' 'run_js' '{"code":"return 1;"}']
    ==
  =/  log=(list event:h)
    :~  [%llm-completed 6 %tool-calls [0 0] [%assistant '' calls]]
        [%config-replaced config]
    ==
  =.  sessions.saved  (~(put by sessions.saved) 'batch' [log 7])
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  result
    (~(on-poke +.loaded bowl) %harness-action !>(`action:h`[%retry 'batch']))
  =/  after  !<(state-0 ~(on-save +.result bowl))
  =/  session  (~(got by sessions.after) 'batch')
  =/  completed
    %+  murn  (flop log.session)
    |=  event=event:h
    ^-  (unit [id=@t body=@t])
    ?.  ?=(%tool-completed -.event)  ~
    `[call-id.event body.event]
  =/  expected=(list [id=@t body=@t])
    :~  ['write' 'skill \'sample\' written']
        ['read-first' 'First body']
        ['propose' 'skill \'sample\' staged — rehearse it before committing']
        ['commit' 'skill \'sample\' committed to the live library']
        ['read-second' 'Second body']
        ['delete' 'skill \'sample\' deleted']
        ['read-deleted' 'error: no such skill: sample']
        ['stage' 'skill \'draft\' staged — rehearse it before committing']
        ['discard' 'staged skill \'draft\' discarded']
        ['rejected' 'rejected: tool is not granted for this session']
    ==
  =/  requested
    %+  skim  (flop log.session)
    |=(event=event:h ?=(%tool-requested-2 -.event))
  =/  expected-requests=(list event:h)
    :~  [%tool-requested-2 7 'fetch' 'http_fetch']
        [%tool-requested-2 7 'script' 'run_js']
    ==
  =/  deferred
    %+  murn  -.result
    |=  card=card:agent:gall
    ^-  (unit wire)
    ?.  ?=([%pass * *] card)  ~
    ?.  |(?=([%tool-2 *] p.card) ?=([%runjs *] p.card))  ~
    `p.card
  ;:  weld
    (expect-eq !>(expected) !>(completed))
    (expect-eq !>(expected-requests) !>(requested))
    (expect-eq !>(~) !>(skills.after))
    (expect-eq !>(~) !>(staged.after))
    (expect-eq !>(7) !>(next-req.session))
    (expect-eq !>(~[/tool-2/batch/7/fetch /runjs/batch/script]) !>(deferred))
  ==
--
