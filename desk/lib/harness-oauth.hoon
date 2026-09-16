::  OpenAI device-token renewal at the HTTP boundary. The reducer and clients
::  never handle OAuth. Renew on use, five minutes before expiry: no idle polling.
::  Concurrent requests share a refresh; cancellation removes held work. A new
::  login invalidates old callbacks, and rotating both tokens is one state change.
/-  *harness-oauth
/+  auth=harness-auth
|%
+$  card  card:agent:gall
+$  result  [cards=(list card) oauth=state keys=(map @t @t) failed=(list [=wire error=@t])]
++  identity
  |=  keys=(map @t @t)
  (sham [(key:auth keys 'openai-device') (key:auth keys 'openai-refresh') (key:auth keys 'openai-account')])
++  expiry
  |=  token=@t
  ^-  (unit @da)
  ::  Decode only an untrusted expiry hint, never use JWT claims as authority.
  =/  parts  (rush token (more dot (cook crip (plus ;~(pose hig low nud hep cab)))))
  ?~  parts  ~
  ?.  =(3 (lent u.parts))  ~
  =/  decoded  (~(de base64:mimes:html | &) (snag 1 u.parts))
  ?~  decoded  ~
  =/  jon  (de:json:html q.u.decoded)
  ?.  ?=([~ %o *] jon)  ~
  =/  exp  (~(get by p.u.jon) 'exp')
  ?.  ?=([~ %n *] exp)  ~
  =/  seconds  (rush p.u.exp dem)
  ?~  seconds  ~
  ?.  (lte u.seconds 253.402.300.799)  ~
  `(add ~1970.1.1 (mul u.seconds ~s1))
++  clear-headers
  |=  headers=header-list:http
  %+  skim  headers
  |=  [name=@t value=@t]
  !(~(has in (silt ~['authorization' 'chatgpt-account-id'])) (crip (cass (trip name))))
++  authorize
  |=  [c=http-card keys=(map @t @t)]
  ^-  card
  =.  header-list.request.c
    (headers:auth keys url.request.c (clear-headers header-list.request.c))
  =.  header-list.request.c
    [['authorization' (cat 3 'Bearer ' (key:auth keys 'openai-device'))] header-list.request.c]
  c
++  fail-waiting
  |=  [out=result message=@t]
  =.  failed.out
    (weld failed.out (turn ~(tap by waiting.oauth.out) |=([w=wire http-card] [w message])))
  out(waiting.oauth ~)
++  filter
  |=  [incoming=(list card) oauth=state keys=(map @t @t) now=@da]
  ^-  result
  =/  out=result  [~ oauth keys ~]
  =/  id  (identity keys)
  =?  out  !=(id identity.oauth)
    =.  out  (fail-waiting out 'authentication_error: OpenAI login changed while waiting. Send the message again.')
    out(oauth [id serial.oauth ~ (expiry (key:auth keys 'openai-device')) *@da '' | ~])
  ::  Also check the deadline on ordinary events, so a missed wake cannot wedge
  ::  requests across reload. A timeout fences a late token response.
  =?  out  ?&(?=(^ active.oauth.out) (gte now deadline.u.active.oauth.out))
    (failed-refresh out now 'OpenAI login renewal timed out. Try again shortly.' |)
  =/  expired=?
    ?~(expires.oauth.out & (gte (add now ~m5) u.expires.oauth.out))
  =/  renewable=?  !=('' (key:auth keys 'openai-refresh'))
  |-  ^-  result
  ?~  incoming
    ?.  &(expired renewable !=(~ waiting.oauth.out) ?=(~ active.oauth.out))  out
    =/  nonce  +(serial.oauth.out)
    =/  deadline=@da  (add now ~s30)
    =/  started=state
      [identity.oauth.out nonce `[nonce deadline] expires.oauth.out retry-at.oauth.out error.oauth.out terminal.oauth.out waiting.oauth.out]
    =/  body  (cat 3 'grant_type=refresh_token&client_id=app_EMoamEEZ73f0CkXaXp7hrann&refresh_token=' (crip (en-urlt:html (trip (key:auth keys 'openai-refresh')))))
    =/  request=request:http
      [%'POST' 'https://auth.openai.com/oauth/token' ~[['content-type' 'application/x-www-form-urlencoded'] ['accept' 'application/json']] `(as-octs:mimes:html body)]
    ::  A rotating refresh token must not be retried by Iris or redirected.
    =/  fresh=(list card)
      ~[[%pass /openai-renew/(scot %ud nonce) %arvo %i %request request [0 0]] [%pass /openai-timeout/(scot %ud nonce) %arvo %b %wait deadline]]
    :*  (weld cards.out fresh)
        started
        keys.out
        failed.out
    ==
  =/  c  i.incoming
  ?:  ?=([%pass * %arvo %i %cancel-request *] c)
    $(incoming t.incoming, out out(waiting.oauth (~(del by waiting.oauth.out) p.c), cards (snoc cards.out c)))
  ?.  ?=([%pass * %arvo %i %request *] c)
    $(incoming t.incoming, out out(cards (snoc cards.out c)))
  =/  http=http-card  c
  ?.  &((device-route:auth url.request.http) |(?=([%llm *] wire.http) ?=([%models *] wire.http)))
    $(incoming t.incoming, out out(cards (snoc cards.out c)))
  ?:  =('' (key:auth keys 'openai-device'))
    $(incoming t.incoming, out out(failed (snoc failed.out [wire.http 'authentication_error: No OpenAI device login is saved. Sign in in OpenAI settings.'])))
  ?:  |(terminal.oauth.out (lth now retry-at.oauth.out))
    $(incoming t.incoming, out out(failed (snoc failed.out [wire.http error.oauth.out])))
  ?.  expired
    $(incoming t.incoming, out out(cards (snoc cards.out (authorize http keys))))
  ?.  renewable
    ::  An opaque imported token without a refresh token may still be usable.
    ?:  ?~(expires.oauth.out & (lth now u.expires.oauth.out))
      $(incoming t.incoming, out out(cards (snoc cards.out (authorize http keys))))
    $(incoming t.incoming, out out(failed (snoc failed.out [wire.http 'authentication_error: OpenAI device login expired. Sign in again to enable automatic renewal.'])))
  ?:  (gte (lent ~(tap by waiting.oauth.out)) 64)
    $(incoming t.incoming, out out(failed (snoc failed.out [wire.http 'OpenAI login renewal is busy. Try again shortly.'])))
  =.  header-list.request.http  (clear-headers header-list.request.http)
  $(incoming t.incoming, out out(waiting.oauth (~(put by waiting.oauth.out) wire.http http)))
++  failed-refresh
  |=  [out=result now=@da message=@t terminal=?]
  =.  out  (fail-waiting out message)
  out(active.oauth ~, retry-at.oauth `@da`(add now ~m1), error.oauth message, terminal.oauth terminal)
++  receive
  |=  [oauth=state keys=(map @t @t) now=@da nonce=@ud res=client-response:iris]
  ^-  result
  =/  out=result  [~ oauth keys ~]
  ?.  &(=(identity.oauth (identity keys)) ?=(^ active.oauth))  out
  ?.  =(nonce serial.u.active.oauth)  out
  ?:  ?=(%progress -.res)  out
  ?:  ?=(%cancel -.res)
    (failed-refresh out now 'OpenAI login renewal was interrupted. Try again shortly.' |)
  =/  status  status-code.response-header.res
  ?.  =(200 status)
    ::  Never publish the raw token response, even when the provider fails.
    =/  terminal=?  |(=(400 status) =(401 status) =(403 status))
    (failed-refresh out now ?:(terminal 'authentication_error: OpenAI device login can no longer be renewed. Sign in again in OpenAI settings.' 'OpenAI login renewal is temporarily unavailable. Try again shortly.') terminal)
  =/  parsed
    %-  mole  |.
    ?>  ?=(^ full-file.res)
    =/  jon  (need (de:json:html q.data.u.full-file.res))
    ?>  ?=([%o *] jon)
    =/  token  (need (~(get by p.jon) 'access_token'))
    ?>  ?=([%s *] token)
    ?>  !=('' p.token)
    =/  refresh  (~(get by p.jon) 'refresh_token')
    =/  lifetime  (~(get by p.jon) 'expires_in')
    =/  hint  (expiry p.token)
    =/  expires=(unit @da)
      ?^  hint  hint
      ?.  ?=([~ %n *] lifetime)  ~
      =/  seconds  (rush p.u.lifetime dem)
      ?~  seconds  ~
      ?.  &((gth u.seconds 300) (lte u.seconds 31.536.000))  ~
      `(add now (mul u.seconds ~s1))
    ?>  ?=(^ expires)
    ?>  (gth u.expires (add now ~m5))
    [p.token ?:(?=([~ %s *] refresh) p.u.refresh '') expires]
  ?~  parsed
    (failed-refresh out now 'OpenAI login renewal returned an invalid response. Try again shortly.' |)
  =/  data=[token=@t refresh=@t expires=(unit @da)]  u.parsed
  =.  keys.out  (~(put by keys) 'openai-device' token.data)
  =?  keys.out  !=('' refresh.data)  (~(put by keys.out) 'openai-refresh' refresh.data)
  =.  cards.out  (turn ~(val by waiting.oauth) |=(c=http-card (authorize c keys.out)))
  out(oauth [(identity keys.out) serial.oauth ~ expires.data *@da '' | ~])
--
