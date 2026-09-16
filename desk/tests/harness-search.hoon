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
++  test-search-errors-never-echo-arbitrary-uppercase-codes
  =/  out  (response:search (reply 500 '{"error":{"code":"FIXTURE_SECRET"}}'))
  (expect-eq !>('Brave Search returned HTTP 500') !>(out))
++  test-search-recognizes-token-errors-on-validation-status
  =/  invalid  (response:search (reply 422 '{"error":{"code":"SUBSCRIPTION_TOKEN_INVALID"}}'))
  =/  missing  (response:search (reply 422 '{"error":{"code":"SUBSCRIPTION_TOKEN_MISSING"}}'))
  (expect !>(&((find-sub:ht 'API key' invalid) =(invalid missing))))
++  test-search-unreadable-and-empty-results
  =/  invalid  (response:search (reply 200 'not-json'))
  =/  empty  (response:search (reply 200 '{"web":{"results":[]}}'))
  =/  failure  (response:search (reply 502 'not-json'))
  (expect !>(&(=('Brave Search returned an unreadable response.' invalid) =('No web results found.' empty) =('Brave Search returned HTTP 502' failure))))
++  test-search-and-discovery-use-existing-permissions
  (expect !>(&((tool-granted:ht 'web_search' ~[%web]) !(tool-granted:ht 'web_search' ~[%mcp]) (tool-granted:ht 'list_mcp_servers' ~[[%mcp 'visible']]) !(tool-granted:ht 'list_mcp_servers' ~[%web]))))
++  test-mcp-discovery-only-exposes-enabled-names-and-ids
  =/  servers=(map mcp-server-id:h mcp-server:h)
    (my ~[['visible' ['Friendly name' 'https://private.example' ~[['authorization' 'secret']] &]] ['disabled' ['Hidden' 'https://hidden.example' ~ |]]])
  =/  run  ~(. effects [*bowl:gall servers])
  =/  out  (run-tool:run ['call' 'list_mcp_servers' '{}'] ~ ~[[%mcp 'visible'] [%mcp 'disabled']])
  ?>  ?=(%tool-completed -.out)
  (expect !>(&(=('list_mcp_servers' name.out) (find-sub:ht 'visible' body.out) !(find-sub:ht 'secret' body.out) !(find-sub:ht 'private.example' body.out) !(find-sub:ht 'disabled' body.out))))
++  test-searxng-keeps-query-out-of-url-and-ignores-model-endpoint
  =/  out  (configured-request:search '{"query":"a & + % café","url":"https://evil.example"}' 'not-sent' [%searxng 'http://localhost:8080/prefix/'])
  ?>  ?=(%& -.out)
  ?>  ?=(^ body.p.out)
  (expect !>(&(=('http://localhost:8080/prefix/search' url.p.out) =(%'POST' method.p.out) !(find-sub:ht 'not-sent' (en:json:html (pairs:enjs:format (turn header-list.p.out |=([k=@t v=@t] [k %s v]))))) (find-sub:ht 'format=json' q.u.body.p.out))))
++  test-searxng-missing-instance-fails-before-dispatch
  =/  out  (configured-request:search '{"query":"hello"}' '' [%searxng ''])
  (expect !>(?=(%| -.out)))
++  test-searxng-config-validates-provider-and-url
  =/  good  (json-config:search (need (de:json:html '{"provider":"searxng","instance-url":"https://search.example/prefix"}')))
  =/  bad  (mule |.((json-config:search (need (de:json:html '{"provider":"searxng","instance-url":""}')))))
  (expect !>(&(=(%searxng provider.good) ?=(%| -.bad) !(valid-instance:search 'file:///private') !(valid-instance:search 'https://search.example?q=secret'))))
++  test-searxng-results-use-shared-output-contract
  =/  out  (configured-response:search (reply 200 '{"results":[{"title":"A","url":"https://a.example","content":"An excerpt","secret":"do-not-copy"}]}') %searxng)
  (expect !>(&((find-sub:ht '"description":"An excerpt"' out) (find-sub:ht 'https://a.example' out) !(find-sub:ht 'do-not-copy' out))))
++  test-searxng-json-disabled-is-actionable-without-echoing-body
  =/  out  (configured-response:search (reply 403 'fixture-secret') %searxng)
  (expect !>(&((find-sub:ht 'search.formats' out) !(find-sub:ht 'fixture-secret' out))))
++  test-searxng-unreadable-and-empty-responses
  =/  empty  (configured-response:search (reply 200 '{"results":[]}') %searxng)
  =/  broken  (configured-response:search (reply 200 '<html>fixture-secret</html>') %searxng)
  (expect !>(&(=('No web results found.' empty) (find-sub:ht 'unreadable' broken) !(find-sub:ht 'fixture-secret' broken))))
--
