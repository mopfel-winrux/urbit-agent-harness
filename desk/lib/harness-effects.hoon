::  Concrete effect bindings: ship reads, HTTP/MCP, timers and peer/self pokes.
::  This door receives a bowl and the MCP registry, never the session store.
::  Callers must authorize tools and record intent before emitting these cards;
::  result handlers in the agent fence late receipts before appending events.
::  Sync reads return a result noun; async helpers describe cards, not a loop.
/-  h=harness, spider
/+  ht=harness-tools, tbjs=thread-builder-js, local-mcp=harness-local-mcp
|_  [=bowl:gall mcp-servers=(map mcp-server-id:h mcp-server:h)]
+$  card  card:agent:gall
::  +run-js-poke: a run_js tool call becomes a poke to ourselves
::
++  run-js-poke
  |=  [sid=session-id:h generation=@ud call-id=@t code=@t]
  ^-  card
  :*  %pass  `wire`[%runjs `@ta`sid `@ta`call-id ~]
      %agent  [our.bowl dap.bowl]  %poke
      %harness-effect  !>(`effect:h`[generation [%run-js sid call-id code]])
  ==
::  QuickJS/WASM executor. The head owns the job record
::  and authorizes admission; this binding only builds the Spider effects.
++  js-cards
  |=  [tid=@ta code=@t deadline=@da]
  ^-  (list card)
  =/  =shed:khan  (tbjs code)
  =/  args=inline-args:spider  [~ `tid [our.bowl q.byk.bowl da+now.bowl] shed]
  :~  [%pass `wire`[%jswatch tid ~] %agent [our.bowl %spider] %watch /thread-result/[tid]]
      [%pass `wire`[%jspoke tid ~] %agent [our.bowl %spider] %poke %spider-inline !>(args)]
      [%pass `wire`[%jsdog tid ~] %arvo %b %wait deadline]
  ==
::  +rehearse-poke: a rehearse_skill tool call becomes a poke to ourselves
::
++  rehearse-poke
  |=  [sid=session-id:h generation=@ud call-id=@t name=@t input=@t]
  ^-  card
  :*  %pass  `wire`[%reh `@ta`sid `@ta`call-id ~]
      %agent  [our.bowl dap.bowl]  %poke
      %harness-effect  !>(`effect:h`[generation [%rehearse sid call-id name input]])
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
  |=  [c=tool-call:h sk=(map @t skill:h) tools=(list tool-grant:h)]
  ^-  event:h
  ?.  (call-granted:ht c tools)
    [%tool-completed id.c name.c 'rejected: tool or path is not granted for this session']
  =/  out=@t
    ?:  =(name.c 'current_time')
      (current-time now.bowl)
    ?:  =(name.c 'list_desk_scopes')
      (en:json:html [%a (turn (clay-scopes:ht tools) |=(p=path `json`[%s (crip (spud p))]))])
    ?:  =(name.c 'read_desk_file')
      (read-desk-file args.c)
    ?:  =(name.c 'list_desk_files')
      (list-desk-files args.c)
    ?:  =(name.c 'read_skill')
      (read-skill args.c sk)
    ?:  =(name.c 'list_mcp_servers')
      %-  en:json:html
      :-  %a
      %+  murn  ~(tap by mcp-servers)
      |=  [id=mcp-server-id:h server=mcp-server:h]
      ^-  (unit json)
      ?.  &(enabled.server (mcp-granted:ht id tools))  ~
      `(pairs:enjs:format ~[['id' %s id] ['name' %s name.server]])
    (cat 3 'unknown tool: ' name.c)
  [%tool-completed id.c name.c out]
++  current-time
  |=  now=@da
  ^-  @t
  =/  d=date  (yore now)
  =/  pad  |=(n=@ud ^-(tape ?:((lth n 10) "0{(a-co:co n)}" (a-co:co n))))
  =/  utc=@t
    (crip "{(a-co:co y.d)}-{(pad m.d)}-{(pad d.t.d)}T{(pad h.t.d)}:{(pad m.t.d)}:{(pad s.t.d)}Z")
  =/  seconds  (div (sub now ~1970.1.1) ~s1)
  =/  weekday  (snag (mod (add (div seconds 86.400) 4) 7) `(list @t)`~['Sunday' 'Monday' 'Tuesday' 'Wednesday' 'Thursday' 'Friday' 'Saturday'])
  %-  en:json:html
  (pairs:enjs:format ~[['utc' %s utc] ['timezone' %s 'UTC'] ['unixSeconds' (numb:enjs:format seconds)] ['weekday' %s weekday]])
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
  =/  p  (tool-str args 'path')
  ?~  p  ~
  (rush u.p stap)
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
    ::  %q reads the stored noun without invoking desk-defined marks. Scoped
    ::  reads must not gain authority through a mark's conversion/import code.
    (clay-text:ht ext .^(noun %cq (weld bas spur)))
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
++  mcp-payload
  |=  c=tool-call:h
  ^-  (unit json)
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
  :-  ~
  ^-  json
    %-  pairs:enjs:format
    :~  ['jsonrpc' %s '2.0']
        ['id' (numb:enjs:format 1)]
        ['method' %s method]
        ['params' params]
    ==
++  mcp-card
  |=  [sid=session-id:h generation=@ud c=tool-call:h tools=(list tool-grant:h)]
  ^-  (unit card)
  ?.  (call-granted:ht c tools)  ~
  =/  server-id  (tool-str args.c 'server')
  ?~  server-id  ~
  =/  configured  (~(get by mcp-servers) u.server-id)
  ?~  configured  ~
  ?.  enabled.u.configured  ~
  =/  payload  (mcp-payload c)
  ?~  payload  ~
  ?:  =((url:local-mcp our.bowl) url.u.configured)
    :-  ~
    :*  %pass  /local-mcp-request/[sid]/(scot %ud generation)/[id.c]
        %agent  [our.bowl dap.bowl]  %poke  %harness-effect
        !>(`effect:h`[generation [%local-mcp sid id.c]])
    ==
  =/  hed=header-list:http
    :~  ['content-type' 'application/json']
        ['accept' 'application/json, text/event-stream']
    ==
  =.  hed  (weld headers.u.configured hed)
  =/  =request:http
    [%'POST' url.u.configured hed `(as-octs:mimes:html (en:json:html u.payload))]
  :-  ~
  :*  %pass  `wire`[%tool-2 `@ta`sid (scot %ud generation) `@ta`id.c ~]
      %arvo  %i  %request  request  *outbound-config:iris
  ==
::  +fetch-card: an http_fetch tool call becomes an iris request
::
++  fetch-card
  |=  [sid=session-id:h generation=@ud c=tool-call:h]
  ^-  (unit card)
  =/  jon  (de:json:html args.c)
  ?~  jon  ~
  ?.  ?=([%o *] u.jon)  ~
  =/  url  (~(get by p.u.jon) 'url')
  ?.  ?=([~ %s *] url)  ~
  ?.  &((lte (met 3 p.u.url) 8.192) |(=('http://' (end [3 7] p.u.url)) =('https://' (end [3 8] p.u.url))))  ~
  ?:  (lien (trip p.u.url) |=(c=@t |((lte c 32) (gte c 127) =(c '#') =(c '@') =(c 92))))  ~
  ?~  (de-purl:html p.u.url)  ~
  =/  method  (~(get by p.u.jon) 'method')
  ?:  ?&(?=(^ method) !=([%s 'GET'] u.method))  ~
  ?:  (~(has by p.u.jon) 'body')  ~
  =/  =request:http  [%'GET' p.u.url ~ ~]
  :-  ~
  :*  %pass  `wire`[%tool-2 `@ta`sid (scot %ud generation) `@ta`id.c ~]
      %arvo  %i  %request  request  [0 0]
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
  |=  [sid=session-id:h generation=@ud c=tool-call:h]
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
      %harness-effect  !>(`effect:h`[generation [%ask-peer sid id.c u.who u.prm]])
  ==
++  check-peer-card
  |=  [sid=session-id:h generation=@ud c=tool-call:h]
  ^-  (unit card)
  =/  shp  (tool-str args.c 'ship')
  ?~  shp  ~
  =/  who  (slaw %p u.shp)
  ?~  who  ~
  :-  ~
  :*  %pass  /peer-check/[sid]/[id.c]
      %agent  [our.bowl dap.bowl]  %poke  %harness-effect
      !>(`effect:h`[generation [%check-peer sid id.c u.who]])
  ==
++  peer-rpc-card
  |=  [sid=session-id:h generation=@ud c=tool-call:h]
  ^-  (unit card)
  =/  ship  (tool-str args.c 'ship')
  ?~  ship  ~
  =/  who  (slaw %p u.ship)
  ?~  who  ~
  =/  name  (tool-str args.c 'name')
  ?:  &(=('call_peer_tool' name.c) ?=(~ name))  ~
  =/  args  (fall (tool-str args.c 'arguments') '{}')
  :-  ~
  :*  %pass  /peer-rpc-request/[sid]/(scot %ud generation)/[id.c]
      %agent  [our.bowl dap.bowl]  %poke  %harness-effect
      !>(`effect:h`[generation [%peer-rpc sid id.c u.who ?:(=('list_peer_tools' name.c) ~ name) args]])
  ==
++  admin-card
  |=  [sid=session-id:h generation=@ud c=tool-call:h]
  ^-  (unit card)
  =/  method  (tool-str args.c 'method')
  ?~  method  ~
  =/  raw  (fall (tool-str args.c 'params') '{}')
  ?:  (gth (met 3 raw) 65.536)  ~
  =/  params  (de:json:html raw)
  ?.  ?&(?=(^ params) ?=(%o -.u.params))  ~
  :-  ~
  :*  %pass  /admin-request/[sid]/(scot %ud generation)/[id.c]
      %agent  [our.bowl dap.bowl]  %poke  %harness-effect
      !>(`effect:h`[generation [%admin-call sid id.c u.method u.params]])
  ==
::  +spawn-card: a run_subagent tool call becomes a poke to ourselves
::
++  spawn-card
  |=  [sid=session-id:h generation=@ud c=tool-call:h]
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
      %harness-effect  !>(`effect:h`[generation [%spawn sid id.c p.u.p sys]])
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
