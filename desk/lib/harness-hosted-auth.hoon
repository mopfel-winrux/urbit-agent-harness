::  Concrete provider flows with bounded work and secret-free projections.
::  No provider response body is published as an error or transcript event.
/-  *harness-hosted, renew=harness-oauth
/+  auth=harness-auth, oauth=harness-oauth, j=harness-workspace-json
|%
+$  card  card:agent:gall
+$  result  [db=state keys=(map @t @t) cards=(list card) response=json]
++  envelope
  |=  [status=@ud body=json]
  (pairs:enjs:format ~[['status' (numb:enjs:format status)] ['body' body]])
++  error
  |=  [status=@ud message=@t]
  (envelope status (pairs:enjs:format ~[['error' %s message]]))
++  slot
  |=  provider=@t
  ?:(=('openai' provider) 'openai-device' 'anthropic-device')
++  identity
  |=  [keys=(map @t @t) provider=@t]
  (sham [(key:auth keys (slot provider)) (key:auth keys (cat 3 provider '-refresh')) (key:auth keys (cat 3 provider '-account'))])
++  supported
  |=(provider=@t |(=('openai' provider) =('anthropic' provider)))
++  public-flow
  |=  [id=@t f=flow now=@da]
  ^-  json
  =/  expired  (gte now expires.f)
  =/  status=@t
    ?:  expired  'error'
    ?-  phase.f
      %code      'authenticating'
      %poll      'awaiting_browser'
      %exchange  'authenticating'
      %verify    'authenticating'
      %token     'awaiting_token'
      %done      'complete'
      %error     'error'
    ==
  %-  pairs:enjs:format
  :~  ['id' %s id]
      ['provider' %s provider.f]
      ['status' %s status]
      ['expiresAt' (stamp:j expires.f)]
      ['verificationUrl' %s verification.f]
      ['userCode' %s user-code.f]
      ['error' %s ?:(expired 'Login expired. Start a new login.' error.f)]
  ==
++  flow-response
  |=  [status=@ud id=@t f=flow now=@da]
  (envelope status (pairs:enjs:format ~[['flow' (public-flow id f now)]]))
++  status
  |=  [db=state keys=(map @t @t) renewal=state:renew now=@da]
  ^-  json
  =/  providers
    %+  turn  `(list @t)`~['openai' 'anthropic']
    |=  provider=@t
    =/  token  (key:auth keys (slot provider))
    =/  expires  (expiry:oauth token)
    =/  state=@t
      ?:  =('' token)  'missing'
      ?:  &(=('openai' provider) terminal.renewal)  'expired'
      ?~  expires  'static'
      ?:  (gte now u.expires)  'expired'
      ?:  (gte (add now ~m5) u.expires)  'expiring'
      'ok'
    (pairs:enjs:format ~[['provider' %s provider] ['status' %s state]])
  =/  models
    %+  turn  `(list @t)`~['openai' 'anthropic']
    |=  provider=@t
    =/  saved  (~(get by catalogs.db) provider)
    [provider ?~(saved [%a ~] ?:(=(identity.u.saved (identity keys provider)) models.u.saved [%a ~]))]
  %-  envelope  :-  200
  (pairs:enjs:format ~[['ts' (stamp:j now)] ['providers' %a providers] ['subscriptionModels' (pairs:enjs:format models)]])
++  capabilities
  %-  envelope  :-  200
  %-  pairs:enjs:format
  :~  ['runtime' %s 'harness']
      ['providers' %a ~[[%s 'openai'] [%s 'anthropic']]]
      ['apiKeyProviders' %a ~[[%s 'openai'] [%s 'anthropic'] [%s 'openrouter']]]
      ['modelFallbacks' %b |]
  ==
++  prune
  |=  [db=state now=@da]
  db(flows (malt (skim ~(tap by flows.db) |=([id=@t f=flow] (lth now expires.f)))))
++  invalidate
  |=  [db=state provider=@t]
  db(flows (malt (skip ~(tap by flows.db) |=([id=@t f=flow] =(provider provider.f)))), catalogs (~(del by catalogs.db) provider))
++  fail
  |=  [out=result id=@t message=@t]
  =/  f  (~(get by flows.db.out) id)
  ?~  f  out
  out(flows.db (~(put by flows.db.out) id u.f(phase %error, pending |, device '', token '', refresh '', account '', error message)))
++  request
  |=  [out=result id=@t now=@da method=?(%'GET' %'POST') url=@t headers=header-list:http body=(unit @t)]
  ^-  result
  =/  f  (~(got by flows.db.out) id)
  =.  f  f(serial +(serial.f), pending &, deadline (add now ~s30))
  =/  http=request:http  [method url headers ?~(body ~ `(as-octs:mimes:html u.body))]
  =/  cards=(list card)
    :~  [%pass /hosted-auth/[id]/(scot %ud serial.f) %arvo %i %request http [0 0]]
        [%pass /hosted-auth-timeout/[id]/(scot %ud serial.f) %arvo %b %wait deadline.f]
    ==
  out(flows.db (~(put by flows.db.out) id f), cards (weld cards.out cards))
++  poll-later
  |=  [out=result id=@t now=@da]
  =/  f  (~(got by flows.db.out) id)
  =.  f  f(pending |)
  out(flows.db (~(put by flows.db.out) id f), cards (snoc cards.out [%pass /hosted-auth-poll/[id]/(scot %ud serial.f) %arvo %b %wait (add now (mul interval.f ~s1))]))
++  verify
  |=  [out=result id=@t now=@da]
  =/  f  (~(got by flows.db.out) id)
  =.  out  out(flows.db (~(put by flows.db.out) id f(phase %verify)))
  =/  headers=header-list:http  ~[['authorization' (cat 3 'Bearer ' token.f)] ['accept' 'application/json']]
  ?:  =('openai' provider.f)
    =?  headers  !=('' account.f)  [['chatgpt-account-id' account.f] headers]
    (request out id now %'GET' device-models:auth headers ~)
  (request out id now %'GET' 'https://api.anthropic.com/v1/models?limit=1000' (weld headers ~[['anthropic-version' '2023-06-01'] ['anthropic-beta' 'oauth-2025-04-20']]) ~)
++  run
  |=  [db=state keys=(map @t @t) action=@t args=json now=@da]
  ^-  result
  =/  out=result  [(prune db now) keys ~ (error 400 'Invalid authentication request.')]
  ?:  =('capabilities' action)  out(response capabilities)
  ?:  =('flow' action)
    =/  id  (string:j args 'flowId')
    =/  f  (~(get by flows.db.out) id)
    ?~  f  out(response (error 404 'Login not found or expired.'))
    out(response (flow-response 200 id u.f now))
  ?:  =('complete' action)
    =/  id  (string:j args 'flowId')
    =/  f  (~(get by flows.db.out) id)
    ?~  f  out(response (error 404 'Login not found or expired.'))
    ?:  &(=('anthropic' provider.u.f) =(%done phase.u.f))
      out(response (flow-response 200 id u.f now))
    ?:  &(=('anthropic' provider.u.f) =(%verify phase.u.f) =((string:j args 'token') token.u.f))
      out(response (flow-response 202 id u.f now))
    ?.  &(=('anthropic' provider.u.f) =(%token phase.u.f))
      out(response (error 409 'This login is not awaiting a token.'))
    =/  token  (string:j args 'token')
    ?.  &((gte (met 3 token) 80) (lte (met 3 token) 8.192) =('sk-ant-oat01-' (cut 3 [0 13] token)))
      out(response (error 400 'Enter a valid Anthropic setup token.'))
    =.  out  out(flows.db (~(put by flows.db.out) id u.f(token token)))
    =.  out  (verify out id now)
    out(response (flow-response 202 id (~(got by flows.db.out) id) now))
  =/  provider  (string:j args 'provider')
  ?.  (supported provider)  out(response (error 400 'Unsupported provider. Read hosted capabilities.'))
  ?:  =('disconnect' action)
    =.  db.out  (invalidate db.out provider)
    =.  keys.out  (~(put by keys.out) (slot provider) '')
    =.  keys.out  (~(put by keys.out) (cat 3 provider '-refresh') '')
    =.  keys.out  (~(put by keys.out) (cat 3 provider '-account') '')
    out(response (envelope 200 (pairs:enjs:format ~[['provider' %s provider]])))
  ?.  =('start' action)  out
  =/  id  (string:j args 'requestId')
  ?.  &((gth (met 3 id) 0) (lte (met 3 id) 128) (levy (trip id) |=(c=@ |(&((gte c 'a') (lte c 'z')) &((gte c '0') (lte c '9')) =('-' c) =('.' c)))))
    out(response (error 400 'Expected a bounded requestId containing lowercase letters, digits, dots or hyphens.'))
  =/  existing  (~(get by flows.db.out) id)
  ?^  existing
    ?.  =(provider provider.u.existing)  out(response (error 409 'Request ID belongs to another provider.'))
    out(response (flow-response 200 id u.existing now))
  ?:  (gte ~(wyt by flows.db.out) 32)  out(response (error 429 'Too many pending logins.'))
  ::  One login per provider; replacing it fences every outstanding response.
  =.  db.out  (invalidate db.out provider)
  =/  f=flow  [provider ?:(=('openai' provider) %code %token) (add now ~m15) (identity keys provider) 0 | *@da 5 '' '' '' '' '' '' '']
  =.  flows.db.out  (~(put by flows.db.out) id f)
  =?  out  =('openai' provider)
    (request out id now %'POST' 'https://auth.openai.com/api/accounts/deviceauth/usercode' ~[['content-type' 'application/json']] `'{"client_id":"app_EMoamEEZ73f0CkXaXp7hrann"}')
  out(response (flow-response 202 id (~(got by flows.db.out) id) now))
++  wake
  |=  [db=state keys=(map @t @t) id=@t serial=@ud timeout=? now=@da]
  ^-  result
  =/  out=result  [db keys ~ ~]
  =/  f  (~(get by flows.db) id)
  ?~  f  out
  ?.  =(serial serial.u.f)  out
  ?:  (gte now expires.u.f)  (fail out id 'Login expired. Start a new login.')
  ?:  timeout
    ?:  &(pending.u.f (gte now deadline.u.f))  (fail out id 'Provider request timed out. Start a new login.')
    out
  ?.  &(=(%poll phase.u.f) !pending.u.f)  out
  =/  body  (en:json:html (pairs:enjs:format ~[['device_auth_id' %s device.u.f] ['user_code' %s user-code.u.f]]))
  (request out id now %'POST' 'https://auth.openai.com/api/accounts/deviceauth/token' ~[['content-type' 'application/json']] `body)
++  claims
  |=  token=@t
  ^-  json
  =/  parts  (rush token (more dot (cook crip (plus ;~(pose hig low nud hep cab)))))
  ?~  parts  ~
  ?.  =(3 (lent u.parts))  ~
  =/  decoded  (~(de base64:mimes:html | &) (snag 1 u.parts))
  ?~  decoded  ~
  (fall (de:json:html q.u.decoded) ~)
++  receive
  |=  [db=state keys=(map @t @t) id=@t serial=@ud res=client-response:iris now=@da]
  ^-  result
  =/  out=result  [db keys ~ ~]
  =/  found  (~(get by flows.db) id)
  ?~  found  out
  =/  f  u.found
  ?.  &(pending.f =(serial serial.f))  out
  ?:  (gte now deadline.f)
    (fail out id 'Provider request timed out. Start a new login.')
  ?:  |((gte now expires.f) !=(base.f (identity keys provider.f)))
    (fail out id 'Login expired or credentials changed. Start a new login.')
  ?:  ?=(%progress -.res)  out
  ?:  ?=(%cancel -.res)  (fail out id 'Provider request interrupted. Start a new login.')
  =.  out  out(flows.db (~(put by flows.db.out) id f(pending |)))
  =/  status  status-code.response-header.res
  ?:  &(=(%poll phase.f) |(=(403 status) =(404 status)))
    (poll-later out id now)
  ?.  =(200 status)  (fail out id 'Provider rejected authentication. Check your login and try again.')
  =/  parsed
    %-  mole  |.
    ?>  ?=(^ full-file.res)
    ?>  (lte p.data.u.full-file.res 262.144)
    =/  value  (need (de:json:html q.data.u.full-file.res))
    ?>  ?=(%o -.value)
    value
  ?~  parsed  (fail out id 'Provider returned an invalid authentication response.')
  =/  body  u.parsed
  =/  decoded  (mule |.((advance out id f body now)))
  ?:  ?=(%| -.decoded)  (fail out id 'Provider returned an invalid authentication response.')
  p.decoded
++  advance
  |=  [out=result id=@t f=flow body=json now=@da]
  ^-  result
  ?:  =(%code phase.f)
    =/  device  (string:j body 'device_auth_id')
    =/  code  (string:j body 'user_code')
    ?>  &(!=('' device) !=('' code) (lte (met 3 device) 4.096) (lte (met 3 code) 64))
    =/  raw  (get:j body 'interval')
    =/  interval=@ud
      ?~  raw  5
      ?:  ?=(%s -.u.raw)  (fall (rush p.u.raw dem) 5)
      (number:j body 'interval' 5)
    =.  f  f(phase %poll, pending |, device device, user-code code, verification 'https://auth.openai.com/codex/device', interval (min 60 (max 2 interval)))
    (poll-later out(flows.db (~(put by flows.db.out) id f)) id now)
  ?:  =(%poll phase.f)
    =/  code  (string:j body 'authorization_code')
    =/  verifier  (string:j body 'code_verifier')
    ?>  &(!=('' code) !=('' verifier))
    =/  form  (rap 3 'grant_type=authorization_code&client_id=app_EMoamEEZ73f0CkXaXp7hrann&redirect_uri=https%3A%2F%2Fauth.openai.com%2Fdeviceauth%2Fcallback&code=' (crip (en-urlt:html (trip code))) '&code_verifier=' (crip (en-urlt:html (trip verifier))) ~)
    =.  out  out(flows.db (~(put by flows.db.out) id f(phase %exchange, pending |)))
    (request out id now %'POST' 'https://auth.openai.com/oauth/token' ~[['content-type' 'application/x-www-form-urlencoded']] `form)
  ?:  =(%exchange phase.f)
    =/  token  (string:j body 'access_token')
    =/  refresh  (fall (optional:j body 'refresh_token') '')
    ?>  &(!=('' token) (lte (met 3 token) 16.384) (lte (met 3 refresh) 16.384))
    =/  claims  (claims (fall (optional:j body 'id_token') token))
    =/  nested  ?~(claims ~ (get:j claims 'https://api.openai.com/auth'))
    =/  account  ?~(nested '' (fall (optional:j u.nested 'chatgpt_account_id') ''))
    =.  f  f(token token, refresh refresh, account account, pending |)
    (verify out(flows.db (~(put by flows.db.out) id f)) id now)
  ?>  =(%verify phase.f)
  =/  rows  (need (get:j body ?:(=('openai' provider.f) 'models' 'data')))
  ?>  ?=(%a -.rows)
  =/  models
    %+  murn  (scag 512 p.rows)
    |=  row=json
    ^-  (unit json)
    =/  id  (fall (optional:j row ?:(=('openai' provider.f) 'slug' 'id')) '')
    ?:  =('' id)  ~
    =/  name  (fall (optional:j row ?:(=('openai' provider.f) 'display_name' 'display_name')) id)
    `(pairs:enjs:format ~[['id' %s id] ['name' %s name]])
  =.  keys.out  (~(put by keys.out) (slot provider.f) token.f)
  =.  keys.out  (~(put by keys.out) (cat 3 provider.f '-refresh') refresh.f)
  =.  keys.out  (~(put by keys.out) (cat 3 provider.f '-account') account.f)
  =.  catalogs.db.out  (~(put by catalogs.db.out) provider.f [(identity keys.out provider.f) [%a models]])
  =.  f  f(phase %done, pending |, device '', token '', refresh '', account '')
  out(flows.db (~(put by flows.db.out) id f))
--
