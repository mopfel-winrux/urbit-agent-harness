::  Supply Clay files inside a sandbox and inspect HTTP cards without delivery.
/+  *test
/=  server  /app/harness-fileserver
|%
+$  files  (map path mime)
++  bowl
  ^-  bowl:gall
  =/  value  *bowl:gall
  %=  value
    our  ~zod
    src  ~zod
    dap  %harness-fileserver
    now  ~2026.10.1
    byk  [~zod %harness da+~2026.10.1]
  ==
++  read
  |=  [files=files query=path]
  ^-  (unit (unit *))
  ?~  query  ~
  =/  file-path=path  (slag 4 `path`query)
  ?+  i.query  ~
    %cu  ``(~(has by files) file-path)
    %cr  ``!>((~(got by files) file-path))
    %cc
      ?>  ?=([@ %mime ~] file-path)
      ``|=(file=vase file)
  ==
++  check
  |=  $:  authenticated=?
          method=method:http
          url=@t
          files=files
          status=@ud
          headers=header-list:http
          body=@t
          cached=?
      ==
  ^-  tang
  ::  Keep typed agent values inside the sandbox; export only test failures.
  =/  attempt
    |.
    =/  inbound  *inbound-request:eyre
    =.  inbound
      %=  inbound
        authenticated  authenticated
        method.request  method
        url.request  url
      ==
    =/  started  ~(on-init server bowl)
    =/  response
      (~(on-poke +.started bowl) %handle-http-request !>([~.fixture inbound]))
    =/  cards  -.response
    =/  saved  ~(on-save +.response bowl)
    =/  payload=simple-payload:http  [[status headers] `(as-octs:mimes:html body)]
    =/  expected=(list card:agent:gall)
      :~  [%give %fact ~[/http-response/fixture] %http-response-header !>(response-header.payload)]
          [%give %fact ~[/http-response/fixture] %http-response-data !>(data.payload)]
          [%give %kick ~[/http-response/fixture] ~]
      ==
    =?  expected  cached
      (snoc expected [%pass /eyre/cache %arvo %e %set-response url ~ auth=| %payload payload])
    =/  state
      !<([%0 foot=path woot=path cash=(set @t)] saved)
    ;:  weld
      (expect-eq !>(expected) !>(cards))
      (expect-eq !>(?:(cached (silt ~[url]) *(set @t))) !>(cash.state))
    ==
  =/  result
    %+  mink  [attempt %9 2 %0 1]
    |=  [type=* query=*]
    (read files ;;(path query))
  ?>  ?=(%0 -.result)
  ;;(tang product.result)
++  test-authentication-precedes-method-and-route-validation
  ;:  weld
    (check | %'GET' '/apps/harness' ~ 403 ~ 'unauthenticated' |)
    (check | %'POST' '/apps/harness' ~ 403 ~ 'unauthenticated' |)
    (check & %'POST' '/apps/harness' ~ 405 ~ 'read-only resource' |)
    (check & %'GET' '/elsewhere' ~ 500 ~ 'bad route' |)
    (check | %'GET' '/apps/harness/app.js?v=1' ~ 403 ~ 'unauthenticated' |)
    (check | %'GET' '/apps/harness/publicity/repo' ~ 403 ~ 'unauthenticated' |)
  ==
++  test-public-shells-with-periods-use-the-index-without-caching
  =/  files=files  (my ~[[/web/index/html [/text/plain (as-octs:mimes:html 'Shell')]]])
  =/  headers=header-list:http  ~[['content-type' 'text/html'] ['cache-control' 'no-cache']]
  ;:  weld
    (check | %'GET' '/apps/harness/public/repo.name' files 200 headers 'Shell' |)
    (check | %'GET' '/harness' files 200 headers 'Shell' |)
    (check | %'GET' '/harness/' files 200 headers 'Shell' |)
    (check & %'GET' '/apps/harness/session/one' files 200 headers 'Shell' |)
    (check | %'POST' '/harness' files 405 ~ 'read-only resource' |)
  ==
++  test-asset-mime-cache-policy-and-request-url-are-preserved
  =/  files=files
    %-  my
    :~  [/web/app/js [/application/javascript (as-octs:mimes:html 'Script')]]
        [/web/sw/js [/application/javascript (as-octs:mimes:html 'Worker')]]
        [/web/harness/png [/image/png (as-octs:mimes:html 'Image')]]
    ==
  =/  script-headers=header-list:http
    ~[['content-type' 'application/javascript'] ['cache-control' 'max-age=3600']]
  ;:  weld
    (check | %'GET' '/apps/harness/app.js' files 200 script-headers 'Script' &)
    (check & %'GET' '/apps/harness/app.js?v=1' files 200 script-headers 'Script' &)
    (check & %'GET' '/harness/app.js' files 200 script-headers 'Script' &)
    (check & %'GET' '/apps/harness/sw.js' files 200 ~[['content-type' 'application/javascript'] ['cache-control' 'no-cache']] 'Worker' &)
    (check | %'GET' '/apps/harness/harness.png' files 200 ~[['content-type' 'image/png'] ['cache-control' 'max-age=86400']] 'Image' &)
  ==
++  test-missing-assets-are-cached-and-missing-shells-are-not
  ;:  weld
    (check | %'GET' '/apps/harness/manifest.json' ~ 404 ~ 'not found' &)
    (check | %'GET' '/apps/harness/harness.svg' ~ 404 ~ 'not found' &)
    (check | %'GET' '/apps/harness/app.css' ~ 404 ~ 'not found' &)
    (check & %'GET' '/apps/harness/session/one' ~ 404 ~ 'not found' |)
  ==
--
