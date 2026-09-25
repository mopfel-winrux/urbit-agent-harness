::  Bounded MCP discovery. Catalogs contain summaries; a named lookup retains
::  the complete tool definition. No catalog cache or additional authority.
/+  w=harness-provider-wire, ht=harness-tools
|%
++  params
  |=  args=@t
  ^-  json
  =/  input  (need (de:json:html args))
  =/  cursor  (str:w input 'cursor')
  (pairs:enjs:format ?:(=('' cursor) ~ ~[['cursor' %s cursor]]))
++  receipt
  |=  [args=@t body=@t]
  ^-  @t
  ?.  =('HTTP 200\0a\0a' (end 3^10 body))  (clip:ht body 8.000)
  ?:  (gth (met 3 body) 262.154)
    'error: MCP catalog exceeds 256 KiB; the server must paginate tools/list'
  =/  projected  (mole |.((catalog args (rsh 3^10 body))))
  ?~  projected  'error: Invalid MCP catalog or discovery arguments'
  =/  encoded  (en:json:html u.projected)
  ?:  (gth (met 3 encoded) 47.000)
    'error: MCP tool definition exceeds 47 KB; ask the server to expose a smaller schema'
  (cat 3 'HTTP 200\0a\0a' encoded)
++  catalog
  |=  [args=@t body=@t]
  ^-  json
  =/  input  (need (de:json:html args))
  =/  decoded  (de:json:html body)
  =/  rpc=json
    ?^  decoded  u.decoded
    =/  replies
      (skim (events:w body) |=(event=json =(`[%n '1'] (get:w event 'id'))))
    ?>  =(1 (lent replies))
    (snag 0 replies)
  ?>  &(?=(%o -.rpc) =(`[%n '1'] (get:w rpc 'id')))
  ?^  (get:w rpc 'error')  rpc
  =/  result  (need (get:w rpc 'result'))
  =/  tools  (need (get:w result 'tools'))
  ?>  ?=(%a -.tools)
  =/  name  (str:w input 'name')
  =/  cursor  (str:w input 'cursor')
  =/  offset-text  (str:w input 'offset')
  =/  offset=@ud  ?:(=('' offset-text) 0 (need (rush offset-text dem)))
  ?>  (lte offset (lent p.tools))
  =/  selected=(list json)
    ?:  =('' name)  (page (slag offset p.tools))
    (skim p.tools |=(tool=json =(name (str:w tool 'name'))))
  =/  next=json  ~
  =/  following  (add offset (lent selected))
  =/  upstream  (str:w result 'nextCursor')
  =?  next  &(=('' name) (lth following (lent p.tools)))
    (pairs:enjs:format ~[['server' %s (str:w input 'server')] ['cursor' %s cursor] ['offset' %s (scot %ud following)]])
  =?  next  &(=(~ next) !=('' upstream) |(=('' name) =(~ selected)))
    (pairs:enjs:format ~[['server' %s (str:w input 'server')] ['cursor' %s upstream] ['offset' %s '0']])
  =?  next  &(!=('' name) ?=([%o *] next))
    (put:w next 'name' [%s name])
  =/  projected=json
    %-  pairs:enjs:format
    :~  ['tools' %a selected]
        ['cursor' %s cursor]
        ['next' next]
        ['hint' %s ?:(=('' name) 'Use list_mcp_tools with name and this cursor for the full description and inputSchema before calling. Use next as arguments for another page.' ?:(=(~ selected) 'No matching tool on this page; follow next if present.' 'Use this inputSchema with call_mcp_tool.'))]
    ==
  (put:w rpc 'result' projected)
::  Count and byte bounds keep JSON intact, including unusually long names.
++  page
  |=  tools=(list json)
  ^-  (list json)
  =/  out=(list json)  ~
  =/  size=@ud  0
  =/  count=@ud  0
  |-  ^-  (list json)
  ?~  tools  (flop out)
  ?:  =(50 count)  (flop out)
  =/  name  (str:w i.tools 'name')
  ?>  !=('' name)
  =/  row  (pairs:enjs:format ~[['name' %s name] ['description' %s (brief (str:w i.tools 'description'))]])
  =/  bytes  (add 1 (met 3 (en:json:html row)))
  ?:  (gth (add size bytes) 40.000)
    ?>  ?=(^ out)
    (flop out)
  $(tools t.tools, out [row out], size (add size bytes), count +(count))
++  brief
  |=  text=@t
  ^-  @t
  ?:  (lte (met 3 text) 160)  text
  =/  cap=@ud  160
  |-  ^-  @t
  =/  next  (cut 3 [cap 1] text)
  ::  Stop before an incomplete UTF-8 character, not inside its bytes.
  ?:  &((gte next 128) (lth next 192) (gth cap 0))  $(cap (dec cap))
  (cat 3 (end [3 cap] text) '...')
--
