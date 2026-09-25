::  Both MCP transports project catalogs before recording model-visible receipts.
/-  h=harness, *harness-store
/+  *test, policy=harness-defaults, hl=harness, w=harness-provider-wire
/=  head  /app/harness
/=  fixture  /tests/harness-mcp-discovery
|%
++  test-local-and-remote-discovery-retain-the-whole-catalog
  ^-  tang
  %-  zing
  %+  turn  `(list [? @t])`~[[& ''] [& 'tool-44'] [| ''] [| 'tool-44']]
  |=  [local=? name=@t]
  =/  attempt  |.((exchange local name))
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  ;;(tang product.out)
++  exchange
  |=  [local=? name=@t]
  ^-  tang
  =/  bowl=bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~zod, now ~2026.9.25)
  =/  cfg  builtin-config:policy
  =.  cfg  cfg(key 'fixture-key', url 'https://example.test/v1/chat/completions', tools ~[[%mcp 'fixture']])
  =/  server=mcp-server:h  ['Fixture' 'https://example.test/mcp' ~ &]
  =/  args  (en:json:html (pairs:enjs:format ~[['server' %s 'fixture'] ['name' %s name]]))
  =/  log=(list event:h)
    :~  [%tool-requested-2 1 'call' 'list_mcp_tools']
        [%llm-completed 0 %tool-calls [1 1] [%assistant '' ~[['call' 'list_mcp_tools' args]]]]
        [%llm-requested 0 %turn]
        [%input-admitted [%user 'Find a tool.']]
        [%config-replaced cfg]
    ==
  =/  raw  (en:json:html (source:fixture 45 ''))
  =/  saved=state-0  *state-0
  =.  saved
    saved(defaults cfg, local-mcp-seen 1, mcp-servers (my ~[['fixture' server]]), sessions (my ~[['fixture' [log 1]]]))
  =?  saved  local
    saved(local-mcp (my ~[[['fixture' 'call'] [1 'fixture' (sham server) 200 raw]]]))
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  completed
    ?:  local
      (~(on-agent +.loaded bowl) /local-mcp/fixture/1/call [%kick ~])
    =/  response=client-response:iris
      [%finished [200 ~] `['application/json' (as-octs:mimes:html raw)]]
    (~(on-arvo +.loaded bowl) /tool-2/fixture/1/call [%iris %http-response response])
  =/  retained  !<(state-0 ~(on-save +.completed bowl))
  =/  view  (play:hl log:(~(got by sessions.retained) 'fixture'))
  =/  receipt  (rear items.view)
  ?>  ?=(%tool -.receipt)
  =/  rpc  (need (de:json:html (rsh 3^10 body.receipt)))
  =/  result  (need (get:w rpc 'result'))
  =/  tools  (need (get:w result 'tools'))
  ?>  ?=(%a -.tools)
  ;:  weld
    (expect-eq !>(?:(=('' name) 45 1)) !>((lent p.tools)))
    (expect-eq !>('tool-44') !>((str:w (rear p.tools) 'name')))
    (expect-eq !>(!=('' name)) !>(?=(^ (get:w (rear p.tools) 'inputSchema'))))
    (expect-eq !>(0) !>(~(wyt by local-mcp.retained)))
  ==
--
