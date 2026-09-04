::  Concrete effect bindings: ship reads, HTTP/MCP, timers and peer/self pokes.
::  This door receives a bowl and the MCP registry, never the session store.
::  Callers must authorize tools and record intent before emitting these cards;
::  result handlers in the agent fence late receipts before appending events.
::  Sync reads return a result noun; async helpers describe cards, not a loop.
/-  h=harness
/+  ht=harness-tools
|_  [=bowl:gall mcp-servers=(map mcp-server-id:h mcp-server:h)]
+$  card  card:agent:gall
::  +run-js-poke: a run_js tool call becomes a poke to ourselves
::
++  run-js-poke
  |=  [sid=session-id:h call-id=@t code=@t]
  ^-  card
  :*  %pass  `wire`[%runjs `@ta`sid `@ta`call-id ~]
      %agent  [our.bowl dap.bowl]  %poke
      %harness-action  !>(`action:h`[%run-js sid call-id code])
  ==
::  +rehearse-poke: a rehearse_skill tool call becomes a poke to ourselves
::
++  rehearse-poke
  |=  [sid=session-id:h call-id=@t name=@t input=@t]
  ^-  card
  :*  %pass  `wire`[%reh `@ta`sid `@ta`call-id ~]
      %agent  [our.bowl dap.bowl]  %poke
      %harness-action  !>(`action:h`[%rehearse sid call-id name input])
  ==
::
++  wait-card
  |=  [sid=session-id:h name=@ta at=@da]
  ^-  card
  [%pass `wire`[%timer `@ta`sid name ~] %arvo %b %wait at]
::
++  rest-card
  |=  [sid=session-id:h name=@ta at=@da]
  ^-  card
  [%pass `wire`[%timer `@ta`sid name ~] %arvo %b %rest at]
::  +run-tool: sync tools execute on-ship, immediately.
::  sk is the current skill library (possibly mutated earlier in the
::  same tool batch), so reads see fresh writes
::
++  run-tool
  |=  [c=tool-call:h sk=(map @t skill:h)]
  ^-  event:h
  =/  out=@t
    ?:  =(name.c 'get_ship_time')
      (scot %da now.bowl)
    ?:  =(name.c 'read_desk_file')
      (read-desk-file args.c)
    ?:  =(name.c 'list_desk_files')
      (list-desk-files args.c)
    ?:  =(name.c 'read_skill')
      (read-skill args.c sk)
    (cat 3 'unknown tool: ' name.c)
  [%tool-completed id.c name.c out]
::  +read-skill: fetch a skill body from the library
::
++  read-skill
  |=  [args=@t sk=(map @t skill:h)]
  ^-  @t
  =/  nam  (tool-str args 'name')
  ?~  nam  'error: bad name argument'
  =/  s  (~(get by sk) u.nam)
  ?~  s  (cat 3 'error: no such skill: ' u.nam)
  body.u.s
::  +tool-str: pull a string field out of tool-call arguments
::
++  tool-str
  |=  [args=@t key=@t]
  ^-  (unit @t)
  =/  jon  (de:json:html args)
  ?~  jon  ~
  ?.  ?=([%o *] u.jon)  ~
  =/  v  (~(get by p.u.jon) key)
  ?:(?=([~ %s *] v) `p.u.v ~)
::  +tool-path: pull a clay path out of tool-call arguments
::
++  tool-path
  |=  args=@t
  ^-  (unit path)
  =/  jon  (de:json:html args)
  ?~  jon  ~
  ?.  ?=([%o *] u.jon)  ~
  =/  p  (~(get by p.u.jon) 'path')
  ?.  ?=([~ %s *] p)  ~
  (rush p.u.p stap)
::
++  read-desk-file
  |=  args=@t
  ^-  @t
  =/  pax  (tool-path args)
  ?~  pax  'error: bad path argument'
  ?.  ?=([@ @ *] u.pax)  'error: path must be /desk/spur/file/ext'
  =/  bas=path  /(scot %p our.bowl)/[i.u.pax]/(scot %da now.bowl)
  =/  spur=path  t.u.pax
  =/  res
    %-  mole  |.
    ?.  .^(? %cu (weld bas spur))  'error: no such file'
    =/  ext  (rear spur)
    =/  =tube:clay  .^(tube:clay %cc (weld bas /[ext]/mime))
    =/  =mime  !<(mime (tube .^(vase %cr (weld bas spur))))
    (clip:ht q.q.mime 50.000)
  ?~  res  'error: could not read file'
  u.res
::
++  list-desk-files
  |=  args=@t
  ^-  @t
  =/  pax  (tool-path args)
  ?~  pax  'error: bad path argument'
  ?~  u.pax  'error: need at least /desk'
  =/  bas=path  /(scot %p our.bowl)/[i.u.pax]/(scot %da now.bowl)
  =/  res
    %-  mole  |.
    =/  paths  .^((list path) %ct (weld bas t.u.pax))
    %+  clip:ht
      (crip (zing (turn paths |=(p=path (weld (spud p) "\0a")))))
    50.000
  ?~  res  'error: could not list directory'
  u.res
::  +mcp-card: a generic MCP discovery/call becomes an iris request.
::  This hand targets stateless Streamable HTTP servers: identity and
::  credentials remain agent configuration, while results enter the log.
::
++  mcp-card
  |=  [sid=session-id:h c=tool-call:h]
  ^-  (unit card)
  =/  server-id  (tool-str args.c 'server')
  ?~  server-id  ~
  =/  configured  (~(get by mcp-servers) u.server-id)
  ?~  configured  ~
  ?.  enabled.u.configured  ~
  =/  method=@t
    ?:(=('list_mcp_tools' name.c) 'tools/list' 'tools/call')
  =/  params=json
    ?:  =('list_mcp_tools' name.c)
      (pairs:enjs:format ~)
    =/  tool-name  (tool-str args.c 'name')
    =/  arguments  (tool-str args.c 'arguments')
    ?~  tool-name  ~
    =/  parsed=(unit json)
      ?~(arguments `(pairs:enjs:format ~) (de:json:html u.arguments))
    ?~  parsed  ~
    %-  pairs:enjs:format
    :~  ['name' %s u.tool-name]
        ['arguments' u.parsed]
    ==
  =/  payload=json
    %-  pairs:enjs:format
    :~  ['jsonrpc' %s '2.0']
        ['id' (numb:enjs:format 1)]
        ['method' %s method]
        ['params' params]
    ==
  =/  hed=header-list:http
    :~  ['content-type' 'application/json']
        ['accept' 'application/json, text/event-stream']
    ==
  =.  hed  (weld headers.u.configured hed)
  =/  =request:http
    [%'POST' url.u.configured hed `(as-octs:mimes:html (en:json:html payload))]
  :-  ~
  :*  %pass  `wire`[%tool `@ta`sid `@ta`id.c ~]
      %arvo  %i  %request  request  *outbound-config:iris
  ==
::  +fetch-card: an http_fetch tool call becomes an iris request
::
++  fetch-card
  |=  [sid=session-id:h c=tool-call:h]
  ^-  (unit card)
  =/  jon  (de:json:html args.c)
  ?~  jon  ~
  ?.  ?=([%o *] u.jon)  ~
  =/  url  (~(get by p.u.jon) 'url')
  ?.  ?=([~ %s *] url)  ~
  =/  method=method:http
    =/  m  (~(get by p.u.jon) 'method')
    ?:(&(?=([~ %s *] m) =('POST' p.u.m)) %'POST' %'GET')
  =/  body=(unit octs)
    =/  b  (~(get by p.u.jon) 'body')
    ?.  ?=([~ %s *] b)  ~
    `(as-octs:mimes:html p.u.b)
  =/  hdrs=header-list:http
    ?~(body ~ ~[['content-type' 'application/json']])
  =/  =request:http  [method p.u.url hdrs body]
  :-  ~
  :*  %pass  `wire`[%tool `@ta`sid `@ta`id.c ~]
      %arvo  %i  %request  request  *outbound-config:iris
  ==
::  +answer-card: send a typed answer back over ames
::
++  answer-card
  |=  [=ship id=ask-id:h result=(each @t @t)]
  ^-  card
  :*  %pass  `wire`[%a2a %answer (scot %uv id) ~]
      %agent  [ship dap.bowl]  %poke
      %harness-a2a-0  !>(`a2a:h`[%answer id result])
  ==
::  +ask-peer-card: an ask_peer tool call becomes a poke to ourselves
::
++  ask-peer-card
  |=  [sid=session-id:h c=tool-call:h]
  ^-  (unit card)
  =/  shp  (tool-str args.c 'ship')
  =/  prm  (tool-str args.c 'prompt')
  ?~  shp  ~
  ?~  prm  ~
  =/  who=(unit @p)
    %+  slaw  %p
    ?:(=('~' (end [3 1] u.shp)) u.shp (cat 3 '~' u.shp))
  ?~  who  ~
  :-  ~
  :*  %pass  `wire`[%aski `@ta`sid `@ta`id.c ~]
      %agent  [our.bowl dap.bowl]  %poke
      %harness-action  !>(`action:h`[%ask-peer sid id.c u.who u.prm])
  ==
::  +spawn-card: a run_subagent tool call becomes a poke to ourselves
::
++  spawn-card
  |=  [sid=session-id:h c=tool-call:h]
  ^-  (unit card)
  =/  jon  (de:json:html args.c)
  ?~  jon  ~
  ?.  ?=([%o *] u.jon)  ~
  =/  p  (~(get by p.u.jon) 'prompt')
  ?.  ?=([~ %s *] p)  ~
  =/  sys=(unit @t)
    =/  s  (~(get by p.u.jon) 'system')
    ?:(?=([~ %s *] s) `p.u.s ~)
  :-  ~
  :*  %pass  `wire`[%spawn `@ta`sid `@ta`id.c ~]
      %agent  [our.bowl dap.bowl]  %poke
      %harness-action  !>(`action:h`[%spawn sid id.c p.u.p sys])
  ==
::
++  give-http
  |=  [eyre-id=@ta [status=@ud headers=header-list:http] body=(unit octs)]
  ^-  (list card)
  =/  pax=path  /http-response/[eyre-id]
  :~  :*  %give  %fact  ~[pax]
          %http-response-header  !>(`response-header:http`[status headers])
      ==
      [%give %fact ~[pax] %http-response-data !>(body)]
      [%give %kick ~[pax] ~]
  ==
--
