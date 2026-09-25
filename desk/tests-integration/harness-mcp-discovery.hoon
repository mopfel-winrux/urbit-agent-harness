::  Both MCP transports project catalogs before recording model-visible receipts.
/-  h=harness, *harness-store
/+  *test, policy=harness-defaults, hl=harness, w=harness-provider-wire, mcp=harness-mcp
/=  head  /app/harness
/=  fixture  /tests/harness-mcp-discovery
|%
++  test-peer-discovery-is-paged-and-does-not-create-transcript-events
  =/  attempt  |.(peer-discovery)
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  ;;(tang product.out)
++  peer-discovery
  ^-  tang
  =/  bowl=bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~nec, now ~2026.9.25)
  =/  saved=state-0  *state-0
  =.  saved  saved(local-mcp-seen 1, peers (my ~[[~nec [~[%skills] ~ 0 ~]]]))
  =/  loaded  (~(on-load head bowl) !>(saved))
  %-  zing
  %+  turn  `(list @t)`~['' 'read_skill' 'harness_admin']
  |=  name=@t
  ^-  tang
  =/  args  (en:json:html (pairs:enjs:format ~[['name' %s name]]))
  =/  response  (~(on-poke +.loaded bowl) %harness-rpc-0 !>(`peer-rpc:h`[%tools 0v1 args]))
  =/  replies
    (murn -.response |=(c=card:agent:gall ?:(?=([%pass * %agent * %poke %harness-rpc-0 *] c) `!<(peer-rpc:h +127.c) ~)))
  =/  reply  (snag 0 replies)
  ?>  ?=(%result -.reply)
  ?>  ?=(%& -.result.reply)
  =/  catalog  (need (de:json:html p.result.reply))
  =/  rows  (need (get:w catalog 'tools'))
  ?>  ?=(%a -.rows)
  =/  stored  !<(state-0 ~(on-save +.response bowl))
  =/  correct
    ?:  =('' name)
      (levy p.rows |=(row=json =(~ (get:w row 'inputSchema'))))
    ?:  =('harness_admin' name)  =(~ p.rows)
    &(=(1 (lent p.rows)) ?=(^ (get:w (snag 0 p.rows) 'inputSchema')))
  ;:  weld
    (expect-eq !>(sessions.saved) !>(sessions.stored))
    (expect !>(correct))
  ==
++  test-tool-transports-preserve-results-and-page-discovery
  ^-  tang
  %-  zing
  %+  turn  `(list [? @t])`~[[& ''] [& 'tool-44'] [| ''] [| 'tool-44'] [& 'large'] [| 'large'] [& 'schema'] [| 'schema'] [| 'peer']]
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
  =/  peer=?  =('peer' name)
  =?  bowl  peer  bowl(src ~nec)
  =/  cfg  builtin-config:policy
  =.  cfg  cfg(key 'fixture-key', url 'https://example.test/v1/chat/completions', tools ~[[%mcp 'fixture']])
  =?  cfg  peer  cfg(tools ~[%peers])
  =/  server=mcp-server:h  ['Fixture' 'https://example.test/mcp' ~ &]
  =/  large=?  |(peer =('large' name) =('schema' name))
  =/  tool  ?:(&(large !=('schema' name)) 'call_mcp_tool' 'list_mcp_tools')
  =?  tool  peer  'call_peer_tool'
  =/  args  (en:json:html (pairs:enjs:format ~[['server' %s 'fixture'] ['name' %s name]]))
  =?  args  peer  '{"ship":"~nec","name":"read_skill","arguments":{}}'
  =/  log=(list event:h)
    :~  [%tool-requested-2 1 'call' tool]
        [%llm-completed 0 %tool-calls [1 1] [%assistant '' ~[['call' tool args]]]]
        [%llm-requested 0 %turn]
        [%input-admitted [%user 'Find a tool.']]
        [%config-replaced cfg]
    ==
  =/  raw  (en:json:html (source:fixture 45 ''))
  =?  raw  =('schema' name)
    =/  def  (put:w (tool:fixture 0) 'name' [%s 'schema'])
    =.  def  (put:w def 'description' [%s (rap 3 (reap 60.000 'x'))])
    (en:json:html (pairs:enjs:format ~[['id' %n '1'] ['result' (pairs:enjs:format ~[['tools' %a ~[def]]])]]))
  =/  saved=state-0  *state-0
  =.  saved
    saved(defaults cfg, local-mcp-seen 1, mcp-servers (my ~[['fixture' server]]), sessions (my ~[['fixture' [log 1]]]))
  =?  saved  peer
    saved(peers (my ~[[~nec [~[%skills] ~ 0 ~]]]), asks (my ~[[0v1 ['fixture' 'call' ~nec]]]))
  =?  saved  local
    saved(local-mcp (my ~[[['fixture' 'call'] [1 'fixture' (sham server) 200 raw]]]))
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  completed
    ?:  peer
      (~(on-poke +.loaded bowl) %harness-rpc-0 !>(`peer-rpc:h`[%result 0v1 [%& raw]]))
    ?:  local
      (~(on-agent +.loaded bowl) /local-mcp/fixture/1/call [%kick ~])
    =/  response=client-response:iris
      [%finished [200 ~] `['application/json' (as-octs:mimes:html raw)]]
    (~(on-arvo +.loaded bowl) /tool-2/fixture/1/call [%iris %http-response response])
  =/  retained  !<(state-0 ~(on-save +.completed bowl))
  =/  view  (play:hl log:(~(got by sessions.retained) 'fixture'))
  =/  receipt  (rear items.view)
  ?>  ?=(%tool -.receipt)
  ?:  large
    =/  expected  (cat 3 'HTTP 200\0a\0a' raw)
    =?  expected  =('schema' name)  (receipt:mcp args expected)
    =?  expected  peer  raw
    ;:  weld
      (expect !>((gth (met 3 body.receipt) 48.000)))
      (expect-eq !>(expected) !>(body.receipt))
      (expect-eq !>(0) !>(~(wyt by local-mcp.retained)))
    ==
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
