::  Pending tool replies retain their generation and live authority boundaries.
/-  h=harness, *harness-store
/+  *test, policy=harness-defaults, hl=harness
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
  =/  config  builtin-config:policy
  =.  config  config(tools ~[[%mcp 'fixture']])
  =/  server=mcp-server:h  ['Fixture' 'urbit://~zod/mcp-proxy' ~ &]
  =/  events=(list event:h)
    :~  [%tool-requested-2 2 'call' 'call_mcp_tool']
        [%llm-completed 1 %tool-calls [1 1] [%assistant '' ~[['call' 'call_mcp_tool' '{"server":"fixture","name":"read","arguments":{}}']]]]
        [%llm-requested 1 %turn]
        [%input-admitted [%user 'Read the result']]
        [%config-replaced config]
    ==
  %*  .  saved
    defaults       config
    local-mcp-seen  1
    sessions       (my ~[['source' [events 2]]])
    mcp-servers    (my ~[['fixture' server]])
    local-mcp      (my ~[[['source' 'call'] [2 'fixture' (sham server) 200 'Completed']]])
  ==
::
++  test-stale-mcp-sign-cannot-consume-a-current-request
  %-  isolated  |=  ignored=*
  =/  loaded  (~(on-load head bowl) !>(fixture))
  =/  before  !<(state-0 ~(on-save +.loaded bowl))
  =/  stale  (~(on-agent +.loaded bowl) /local-mcp/source/1/call [%kick ~])
  =/  after  !<(state-0 ~(on-save +.stale bowl))
  ;:  weld
    (expect-eq !>(sessions.before) !>(sessions.after))
    (expect-eq !>(local-mcp.before) !>(local-mcp.after))
    (expect-eq !>(~) !>(-.stale))
  ==
::
++  test-mcp-completion-rechecks-grants-and-server-identity
  %-  isolated  |=  ignored=*
  %-  zing
  %+  turn  `(list term)`~[%grant %disabled %configuration]
  |=  change=term
  =/  initial  fixture
  =/  session  (~(got by sessions.initial) 'source')
  =/  config  config:(play:hl log.session)
  =?  sessions.initial  =(%grant change)
    (~(put by sessions.initial) 'source' session(log [[%config-replaced config(tools ~)] log.session]))
  =/  server  (~(got by mcp-servers.initial) 'fixture')
  =?  mcp-servers.initial  =(%disabled change)
    (~(put by mcp-servers.initial) 'fixture' server(enabled |))
  =?  mcp-servers.initial  =(%configuration change)
    (~(put by mcp-servers.initial) 'fixture' server(url 'urbit://~nec/mcp-proxy'))
  =/  loaded  (~(on-load head bowl) !>(initial))
  =/  completed  (~(on-agent +.loaded bowl) /local-mcp/source/2/call [%kick ~])
  =/  saved  !<(state-0 ~(on-save +.completed bowl))
  =/  view  (play:hl log:(~(got by sessions.saved) 'source'))
  =/  receipt  (rear items.view)
  ?>  ?=(%tool -.receipt)
  =/  repeated  (~(on-agent +.completed bowl) /local-mcp/source/2/call [%kick ~])
  =/  after-repeat  !<(state-0 ~(on-save +.repeated bowl))
  ;:  weld
    (expect-eq !>('rejected: local MCP access or server configuration changed') !>(body.receipt))
    (expect-eq !>(~) !>(local-mcp.saved))
    (expect-eq !>(sessions.saved) !>(sessions.after-repeat))
    (expect-eq !>(~) !>(-.repeated))
  ==
--
