/-  h=harness
/+  *test, search=harness-search, ht=harness-tools, effects=harness-effects
|%
++  reply
  |=  [status=@ud body=@t]
  ^-  client-response:iris
  [%finished [status ~] `['application/json' (as-octs:mimes:html body)]]
++  test-search-validates-before-dispatch
  =/  missing  (request:search '{"query":"hello"}' '')
  =/  invalid  (request:search '{}' 'fixture')
  =/  empty  (request:search '{"query":""}' 'fixture')
  (expect !>(&(?=(%| -.missing) ?=(%| -.invalid) ?=(%| -.empty))))
++  test-search-url-cannot-be-overridden-by-arguments
  =/  out  (request:search '{"query":"site:openai.com Astra OpenAI & + % café", "url":"https://evil.example"}' 'fixture-key')
  ?>  ?=(%& -.out)
  ?>  ?=(^ body.p.out)
  =/  jon  (need (de:json:html q.u.body.p.out))
  ?>  ?=([%o *] jon)
  (expect !>(&(=(%'POST' method.p.out) =('https://api.search.brave.com/res/v1/web/search' url.p.out) =(`[%s 'site:openai.com Astra OpenAI & + % café'] (~(get by p.jon) 'q')))))
++  test-search-results-are-small-and-attributed
  =/  out  (response:search (reply 200 '{"web":{"results":[{"title":"A","url":"https://a.example","description":"An excerpt","secret":"not included"}]}}'))
  (expect !>(&((find-sub:ht 'https://a.example' out) !(find-sub:ht 'not included' out))))
++  test-search-errors-never-echo-provider-body
  =/  out  (response:search (reply 401 'fixture-secret'))
  (expect !>(&((find-sub:ht 'API key' out) !(find-sub:ht 'fixture-secret' out))))
++  test-search-and-discovery-use-existing-permissions
  (expect !>(&((tool-granted:ht 'web_search' ~[%web]) !(tool-granted:ht 'web_search' ~[%mcp]) (tool-granted:ht 'list_mcp_servers' ~[%mcp]) !(tool-granted:ht 'list_mcp_servers' ~[%web]))))
++  test-mcp-discovery-only-exposes-enabled-names-and-ids
  =/  servers=(map mcp-server-id:h mcp-server:h)
    (my ~[['visible' ['Friendly name' 'https://private.example' ~[['authorization' 'secret']] &]] ['disabled' ['Hidden' 'https://hidden.example' ~ |]]])
  =/  run  ~(. effects [*bowl:gall servers])
  =/  out  (run-tool:run ['call' 'list_mcp_servers' '{}'] ~)
  ?>  ?=(%tool-completed -.out)
  (expect !>(&(=('list_mcp_servers' name.out) (find-sub:ht 'visible' body.out) !(find-sub:ht 'secret' body.out) !(find-sub:ht 'private.example' body.out) !(find-sub:ht 'disabled' body.out))))
--
