::  General HTTP tool. Pure schema, request binding and receipt rendering.
::  The head owns grants, durable intent, cancellation and receipt fencing.
::  No shell, ambient credentials, destination policy or automatic retries.
/-  h=harness
|%
++  schema
  ^-  json
  %-  pairs:enjs:format
  :~  ['type' %s 'function']
      :-  'function'
      %-  pairs:enjs:format
      :~  ['name' %s 'curl']
          ['description' %s 'Make an HTTP(S) request with explicit method, headers and body. Can write to external services and reach private addresses. No credentials are supplied automatically. No automatic retries; an interrupted mutation may already have succeeded. Redirects are opt-in and forward the original method, headers and body, including credentials. Returns status, headers and bounded body text. Native HTTP client, not a shell command.']
          :-  'parameters'
          %-  pairs:enjs:format
          :~  ['type' %s 'object']
              ['required' %a ~[[%s 'url']]]
              :-  'properties'
              %-  pairs:enjs:format
              :~  ['url' (field 'string' 'HTTP(S) URL, up to 8192 bytes. No destination allowlist.')]
                  ['method' (field 'string' 'GET (default), HEAD, POST, PUT, PATCH, DELETE, OPTIONS, TRACE or CONNECT. These are the methods supported by the native runtime.')]
                  :-  'headers'
                  %-  pairs:enjs:format
                  :~  ['type' %s 'object']
                      ['description' %s 'Explicit HTTP header names mapped to string values, including Authorization if needed. Nothing is injected.']
                      ['additionalProperties' (pairs:enjs:format ~[['type' %s 'string']])]
                  ==
                  ['body' (field 'string' 'Optional request body, including an empty string; up to 4 MiB UTF-8. Set Content-Type explicitly when needed.')]
                  ['redirects' (field 'integer' 'Native redirect budget, 0 (default) through 20. The runtime follows 301/303/307 with absolute Location URLs, forwarding the original method, headers and body. Other redirects are returned for inspection.')]
              ==
          ==
      ==
  ==
++  field
  |=  [type=@t description=@t]
  (pairs:enjs:format ~[['type' %s type] ['description' %s description]])
++  token
  |=  value=@t
  ^-  ?
  ?&  !=('' value)
      (levy (trip value) |=(c=@t |(&((gte c 'a') (lte c 'z')) &((gte c 'A') (lte c 'Z')) &((gte c '0') (lte c '9')) (lien (trip '!#$%&\'*+-.^_`|~') |=(allowed=@t =(c allowed))))))
  ==
++  request-card
  |=  [sid=session-id:h generation=@ud call=tool-call:h]
  ^-  (unit card:agent:gall)
  =/  jon  (de:json:html args.call)
  ?.  ?=([~ %o *] jon)  ~
  =/  url  (~(get by p.u.jon) 'url')
  ?.  ?=([~ %s *] url)  ~
  ?.  &((lte (met 3 p.u.url) 8.192) |(=('http://' (end [3 7] p.u.url)) =('https://' (end [3 8] p.u.url))))  ~
  ?:  (lien (trip p.u.url) |=(c=@t |((lte c 32) (gte c 127) =(c 92))))  ~
  ?~  (de-purl:html p.u.url)  ~
  =/  method  (~(get by p.u.jon) 'method')
  ?:  ?&(?=(^ method) !?=([%s *] u.method))  ~
  =/  verb=@t
    ?~  method  'GET'
    ?>  ?=([%s *] u.method)
    p.u.method
  ?.  ?=(?(%'GET' %'HEAD' %'POST' %'PUT' %'PATCH' %'DELETE' %'OPTIONS' %'TRACE' %'CONNECT') verb)  ~
  =/  raw  (~(get by p.u.jon) 'headers')
  ?:  ?&(?=(^ raw) !?=([%o *] u.raw))  ~
  =/  headers=(list [@t json])
    ?~  raw  ~
    ?>  ?=([%o *] u.raw)
    ~(tap by p.u.raw)
  ?:  (gth (lent headers) 128)  ~
  ?.  (levy headers |=(entry=[key=@t value=json] ?&((token key.entry) ?=([%s *] value.entry) (lte (met 3 key.entry) 256) (lte (met 3 p.value.entry) 16.384) !(lien (trip p.value.entry) |=(c=@t |(=(c 0) =(c 10) =(c 13)))))))  ~
  =/  hed=header-list:http
    %+  turn  headers
    |=  [key=@t value=json]
    ^-  [@t @t]
    ?>  ?=([%s *] value)
    [key p.value]
  =/  body  (~(get by p.u.jon) 'body')
  ?:  ?&(?=(^ body) !?=([%s *] u.body))  ~
  =/  data=(unit octs)
    ?~  body  ~
    ?>  ?=([%s *] u.body)
    `(as-octs:mimes:html p.u.body)
  ?:  ?&(?=(^ data) (gth p.u.data 4.194.304))  ~
  =/  redirects  (~(get by p.u.jon) 'redirects')
  ?:  ?&(?=(^ redirects) !?=([%n *] u.redirects))  ~
  =/  count=(unit @ud)
    ?~  redirects  `0
    ?>  ?=([%n *] u.redirects)
    (slaw %ud p.u.redirects)
  ?~  count  ~
  ?:  (gth u.count 20)  ~
  =/  req=request:http  [verb p.u.url hed data]
  `[%pass `wire`[%tool-2 `@ta`sid (scot %ud generation) `@ta`id.call ~] %arvo %i %request req [u.count 0]]
++  response
  |=  res=client-response:iris
  ^-  @t
  ?:  ?=(%cancel -.res)  'error: request cancelled by runtime; an external mutation may already have succeeded'
  ?:  ?=(%progress -.res)  'error: incomplete HTTP response'
  =/  hed=@t
    %+  roll  headers.response-header.res
    |=  [[key=@t value=@t] out=@t]
    (bounded (rap 3 out key ': ' value '\0a' ~))
  =/  body=@t  ?~(full-file.res '' (bounded q.data.u.full-file.res))
  (rap 3 'HTTP ' (scot %ud status-code.response-header.res) '\0a' hed '\0a' body ~)
++  bounded
  |=  text=@t
  ^-  @t
  ?:  (lte (met 3 text) 8.000)  text
  (cat 3 (end [3 8.000] text) ' ...(truncated)')
--
