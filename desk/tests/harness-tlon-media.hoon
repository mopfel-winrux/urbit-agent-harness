/-  t=harness-tlon
/+  *test, m=harness-tlon-media, p=harness-tlon-policy
/=  adapter  /app/harness-tlon
|%
++  test-native-download-has-no-secret-or-body
  =/  url  'https://www.python.org/static/img/python-logo.png'
  =/  req  (download-request:m url)
  (expect-eq !>(`request:http`[%'GET' url ~[['Accept' 'image/png,image/jpeg,image/gif,image/webp'] ['Accept-Encoding' 'identity']] ~]) !>(req))
++  test-native-download-rejects-local-addresses-and-url-credentials
  =/  urls=(list @t)
    :~  'http://www.python.org/image.png'
        'https://127.0.0.1/image.png'
        'https://[::1]/image.png'
        'https://localhost/image.png'
        'https://service.local/image.png'
        'https://service.internal/image.png'
        'https://user:password@example.com/image.png'
        'https://example.com:8443/image.png'
        'https://example.com/image.png#fragment'
        'https://example.com/\0aimage.png'
    ==
  (expect !>((levy urls rejected-url)))
++  rejected-url
  |=  url=@t
  ^-  ?
  =(~ (mole |.((download-request:m url))))
++  test-native-migration-drops-worker-config-preserves-evidence
  =/  old=state-8:t  *state-8:t
  =.  media.old  ['http://localhost:8789' 'old-secret']
  =.  last-sent.old  ~2026.9.6
  =.  epoch.old  31
  =.  uploads.old  (my ~[[0v1 `upload:t`[%put 0v2 'key' 'image/png' 'url' [2 1]]]])
  =/  next  (upgrade-native-media:p old)
  (expect-eq !>(+.+.old) !>(+.next))
++  test-media-migration-preserves-delivery-evidence
  =/  old=state-6:t  *state-6:t
  =.  last-sent.old  ~2026.9.6
  =.  epoch.old  31
  =.  wake.old  `~2026.9.7
  =/  next  (upgrade-media:p old)
  (expect !>(&(=(['' ''] media.next) =(~ uploads.next) =(+.old +.+.+.next))))
++  test-image-rejects-svg-and-oversized-payloads
  (expect !>(&(=(~ (image-type:m [12 '<svg></svg>'])) =(~ (image-type:m [8.388.609 0xa1a.0a0d.474e.5089])))))
++  test-hosted-toggle-needs-no-static-credentials
  =/  config  (need (de:json:html '{"storage-update":{"configuration":{"service":"presigned-url"}}}'))
  (expect !>((hosted:m config)))
++  test-hosted-request-uses-fixed-broker-and-exact-file-metadata
  =/  req  (hosted-request:m ~nec 'identity-fixture' 'nec/a.png' 'image/png' 123)
  ?>  ?=(^ body.req)
  =/  payload  (need (de:json:html q.u.body.req))
  =/  want  (need (de:json:html '{"token":"identity-fixture","contentLength":123,"contentType":"image/png","fileName":"nec/a.png"}'))
  (expect !>(?&(=('https://memex.tlon.network/v1/nec/upload' url.req) =(%'PUT' method.req) =(want payload) =(~[['Content-Type' 'application/json']] header-list.req))))
++  response
  |=  [url=@t public=@t]
  ^-  client-response:iris
  =/  body  (en:json:html (pairs:enjs:format ~[['url' %s url] ['filePath' %s public]]))
  [%finished [200 ~] `['application/json' (as-octs:mimes:html body)]]
++  test-hosted-response-keeps-signed-url-exactly
  =/  url  'https://storage.googleapis.com/bucket/nec/a.png?X-Goog-Credential=signer%40example.com%2Fscope&X-Goog-Signature=123'
  =/  public  'https://storage.googleapis.com/bucket/nec/a.png'
  (expect-eq !>([url public]) !>((hosted-response:m (response url public))))
++  test-hosted-response-rejects-private-or-mismatched-destinations
  =/  public  'https://storage.googleapis.com/bucket/nec/a.png'
  =/  rejected
    |=  url=@t
    =(~ (mole |.((hosted-response:m (response url public)))))
  (expect !>(&((rejected 'http://127.0.0.1/a?sig=x') (rejected 'https://storage.googleapis.com.evil.example/a?sig=x') (rejected 'https://storage.googleapis.com/other?sig=x') (rejected 'https://storage.googleapis.com/bucket/nec/a.png'))))
++  test-hosted-response-rejects-oversized-body
  =/  res=client-response:iris  [%finished [200 ~] `['application/json' [16.385 0]]]
  (expect !>(=(~ (mole |.((hosted-response:m res))))))
++  test-hosted-migration-preserves-old-upload-evidence
  =/  old=state-7:t  *state-7:t
  =.  uploads.old  (my ~[[0v1 `upload-7:t`[%put 0v2 'key' 'image/png' 'url' [2 1]]]])
  =/  next  (upgrade-hosted-media:p old)
  (expect-eq !>(+.old) !>(+.next))
++  reload
  |=  phase=?(%fetch %put %grant %hosted-put)
  ^-  state:t
  =/  state=state:t  *state:t
  =.  uploads.state  (my ~[[0v1 `upload:t`[phase 0v2 'key' 'image/png' 'https://storage.googleapis.com/bucket/key' [2 1]]]])
  =.  tool-receipts.state  (my ~[[0v1 `tool-receipt:t`[['s' 1 ['call' 'tlon_upload_image' '{}']] %sending '' ~2026.9.6]]])
  =/  bowl=bowl:gall  *bowl:gall
  =.  now.bowl  ~2026.9.6
  =/  out  (~(on-load adapter bowl) !>(state))
  ::  Reload may cancel the old duct and publish a result, never request HTTP.
  ?>  !(lien -.out |=(c=card:agent:gall ?=([%pass * %arvo %i %request *] c)))
  !<(state:t ~(on-save +.out bowl))
++  test-native-download-reload-is-known-not-uploaded
  =/  state  (reload %fetch)
  =/  receipt  (~(got by tool-receipts.state) 0v1)
  (expect !>(&(=(~ uploads.state) =(%done stage.receipt) ?=(^ (find "before any upload" (trip body.receipt))))))
++  test-legacy-worker-reload-drops-settings-and-retires-fetch
  =/  old=state-8:t  *state-8:t
  =.  media.old  ['http://localhost:8789' 'retired-secret']
  =.  uploads.old  (my ~[[0v1 `upload:t`[%fetch 0v2 '' '' '' [0 0]]]])
  =.  tool-receipts.old  (my ~[[0v1 `tool-receipt:t`[['s' 1 ['call' 'tlon_upload_image' '{}']] %sending '' ~2026.9.6]]])
  =/  bowl=bowl:gall  *bowl:gall
  =.  now.bowl  ~2026.9.6
  =/  out  (~(on-load adapter bowl) !>(old))
  ?>  !(lien -.out |=(c=card:agent:gall ?=([%pass * %arvo %i %request *] c)))
  =/  next  !<(state:t ~(on-save +.out bowl))
  (expect !>(&(=(%9 -.next) =(~ uploads.next) =(%done stage:(~(got by tool-receipts.next) 0v1)))))
++  test-hosted-grant-reload-is-uncertain-without-claiming-a-put
  =/  state  (reload %grant)
  =/  receipt  (~(got by tool-receipts.state) 0v1)
  (expect !>(&(=(~ uploads.state) =(%uncertain stage.receipt) ?=(^ (find "no image PUT was sent" (trip body.receipt))))))
++  test-hosted-put-reload-discards-bytes-without-retrying
  =/  state  (reload %hosted-put)
  (expect !>(&(=(~ uploads.state) =(%uncertain stage:(~(got by tool-receipts.state) 0v1)))))
--
