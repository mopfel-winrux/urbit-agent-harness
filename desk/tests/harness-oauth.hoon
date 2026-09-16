/-  *harness-oauth
/+  *test, oa=harness-oauth, auth=harness-auth
|%
++  token
  |=  exp=@ud
  =/  body  (as-octs:mimes:html (en:json:html (pairs:enjs:format ~[['exp' (numb:enjs:format exp)]])))
  (rap 3 'eyJ.' (~(en base64:mimes:html | &) body) '.sig' ~)
++  keys
  (my ~[['openai-device' (token 1)] ['openai-refresh' 'fixture-refresh'] ['openai-account' 'fixture-account']])
++  req
  ^-  http-card
  [%pass /llm/fixture/0/turn %arvo %i %request [%'POST' device-url:auth ~[['authorization' 'Bearer stale']] `(as-octs:mimes:html '{}')] *outbound-config:iris]
++  reply
  |=  [status=@ud body=@t]
  ^-  client-response:iris
  [%finished [status ~] `['application/json' (as-octs:mimes:html body)]]
++  test-expiry-hint-is-defensive
  (expect !>(&(=(`~1970.1.1..00.00.01 (expiry:oa (token 1))) =(~ (expiry:oa 'not-a-jwt')))))
++  test-concurrent-requests-share-refresh
  =/  request=http-card  req
  =/  out  (filter:oa ~[request request(wire /llm/other/0/turn)] *state keys ~2026.1.1)
  =/  held  (need (~(get by waiting.oauth.out) wire.request))
  (expect !>(&(=(2 (lent cards.out)) =(2 (lent ~(tap by waiting.oauth.out))) ?=(^ active.oauth.out) =(~ header-list.request.held))))
++  test-cancellation-removes-waiter
  =/  request=http-card  req
  =/  first  (filter:oa ~[req] *state keys ~2026.1.1)
  =/  next  (filter:oa ~[[%pass wire.request %arvo %i %cancel-request ~]] oauth.first keys ~2026.1.1)
  (expect-eq !>(~) !>(waiting.oauth.next))
++  test-new-login-fences-refresh-response
  =/  first  (filter:oa ~[req] *state keys ~2026.1.1)
  =/  changed  (~(put by keys) 'openai-device' 'different-login')
  =/  out  (receive:oa oauth.first changed ~2026.1.1 1 (reply 200 '{"access_token":"wrong"}'))
  (expect !>(&(=(changed keys.out) =(~ cards.out))))
++  test-rotation-releases-waiters-atomically
  =/  first  (filter:oa ~[req] *state keys ~2026.1.1)
  =/  out  (receive:oa oauth.first keys ~2026.1.1 1 (reply 200 '{"access_token":"fresh-token","refresh_token":"rotated","expires_in":3600}'))
  (expect !>(&(=(~ active.oauth.out) =(~ waiting.oauth.out) =(1 (lent cards.out)) =('fresh-token' (key:auth keys.out 'openai-device')) =('rotated' (key:auth keys.out 'openai-refresh')))))
++  test-missing-rotation-preserves-refresh-token
  =/  first  (filter:oa ~[req] *state keys ~2026.1.1)
  =/  out  (receive:oa oauth.first keys ~2026.1.1 1 (reply 200 '{"access_token":"fresh-token","expires_in":3600}'))
  (expect-eq !>('fixture-refresh') !>((key:auth keys.out 'openai-refresh')))
++  test-terminal-error-is-sanitized-and-does-not-loop
  =/  first  (filter:oa ~[req] *state keys ~2026.1.1)
  =/  failed  (receive:oa oauth.first keys ~2026.1.1 1 (reply 401 'secret body never enters conversation'))
  =/  next  (filter:oa ~[req] oauth.failed keys ~2026.1.2)
  (expect !>(&(terminal.oauth.next =(~ cards.next) =(1 (lent failed.next)) =(keys keys.next))))
++  test-timeout-releases-and-fences-waiters
  =/  first  (filter:oa ~[req] *state keys ~2026.1.1)
  =/  out  (filter:oa ~ oauth.first keys (add ~2026.1.1 ~s31))
  (expect !>(&(=(~ active.oauth.out) =(~ waiting.oauth.out) =(1 (lent failed.out)) (gth retry-at.oauth.out ~2026.1.1))))
++  test-fresh-token-and-api-cards-do-not-refresh
  =/  request=http-card  req
  =/  fresh  (~(put by keys) 'openai-device' (token 2.000.000.000))
  =/  out  (filter:oa ~[request request(url.request 'https://api.openai.com/v1/chat/completions')] *state fresh ~2026.1.1)
  (expect !>(&(=(2 (lent cards.out)) =(~ active.oauth.out) =(~ waiting.oauth.out))))
++  test-cleared-login-cannot-be-resurrected-by-refresh-token
  =/  cleared  (~(put by keys) 'openai-device' '')
  =/  out  (filter:oa ~[req] *state cleared ~2026.1.1)
  (expect !>(&(=(~ cards.out) =(1 (lent failed.out)) =(~ waiting.oauth.out))))
++  test-temporary-failure-has-a-cooldown
  =/  first  (filter:oa ~[req] *state keys ~2026.1.1)
  =/  failed  (receive:oa oauth.first keys ~2026.1.1 1 (reply 429 'private quota response'))
  =/  early  (filter:oa ~[req] oauth.failed keys (add ~2026.1.1 ~s1))
  =/  later  (filter:oa ~[req] oauth.early keys (add ~2026.1.1 ~s61))
  (expect !>(&(=(~ cards.early) =(1 (lent failed.early)) =(2 (lent cards.later)) !terminal.oauth.later)))
++  test-waiting-is-bounded
  =/  request=http-card  req
  =/  incoming=(list card:oa)
    (turn (gulf 0 64) |=(n=@ud `card:oa`request(wire /models/(scot %ud n))))
  =/  out  (filter:oa incoming *state keys ~2026.1.1)
  (expect !>(&(=(64 (lent ~(tap by waiting.oauth.out))) =(1 (lent failed.out)) =(2 (lent cards.out)))))
--
