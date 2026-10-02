::  Serve the Harness shell and static assets from Clay.
::  The config core supplies +web-root (URL path) and +file-root (desk path).
::  Shells are read on every request; asset responses use Eyre's cache.
::
/+  dbug
/=  config  /app/harness-fileserver/config
::
|%
++  web-root   ^-  (list @t)  web-root:config
++  file-root  ^-  path  file-root:config
--
::
|%
++  starts-with
  |=  [prefix=@t value=@t]
  ^-  ?
  =/  prefix-chars=tape  (trip prefix)
  =/  value-chars=tape  (trip value)
  ?.  (lte (lent prefix-chars) (lent value-chars))  %.n
  =(prefix-chars (scag (lent prefix-chars) value-chars))
::
+$  state-0
  $:  %0
      foot=path
      woot=path
      cash=(set @t)
  ==
::
+$  card  card:agent:gall
::
++  store  ::  set cache entry
  |=  [url=@t entry=(unit cache-entry:eyre)]
  ^-  card
  [%pass /eyre/cache %arvo %e %set-response url entry]
::
++  read-next
  |=  [[our=@p =desk now=@da] foot=path]
  ^-  card
  =;  =task:clay
    [%pass [%clay %next foot] %arvo %c task]
  [%warp our desk ~ %next %z da+now foot]
::
++  set-norm
  |=  [[our=@p =desk] foot=path keep=?]
  ^-  card
  =;  =task:clay
    [%pass [%clay %norm foot] %arvo %c task]
  [%tomb %norm our desk (~(put of *norm:clay) foot keep)]
--
::
=|  state-0
=*  state  -
::
%-  agent:dbug
^-  agent:gall
|_  =bowl:gall
+*  this  .
::
++  on-init
  ^-  (quip card _this)
  =.  foot  file-root
  =.  woot  web-root
  :_  this
  ::  set up the binding,
  ::  the relevant tombstoning policy,
  ::  and await next file change
  ::
  :~  [%pass /eyre/connect %arvo %e %connect [~ woot] dap.bowl]
      [%pass /eyre/connect %arvo %e %connect [~ /harness] dap.bowl]
      (set-norm [our q.byk]:bowl foot |)
      (read-next [our q.byk now]:bowl foot)
      (store '/apps/harness' ~)
      (store '/apps/harness/' ~)
      (store '/harness' ~)
      (store '/harness/' ~)
  ==
::
++  on-save
  ^-  vase
  !>(state)
::
++  on-load
  |=  ole=vase
  ^-  (quip card _this)
  =/  old=state-0  !<(state-0 ole)
  :_  this(foot file-root, woot web-root, cash ~)
  %-  zing
  ^-  (list (list card))
  :~  ::  if the file root changed, set the new root up for tombstoning.
      ::
      ?:  =(foot.old file-root)  ~
      [(set-norm [our q.byk]:bowl file-root |)]~
    ::
      ::  always await next change on our file root
      ::
      :-  (read-next [our q.byk now]:bowl file-root)
      ::  always trigger clay tombstoning, for both old and new file roots.
      ::
      :-  [%pass /clay/tomb %arvo %c %tomb %pick ~]
      ::  always clear old cache entries.
      ::
      (turn ~(tap in cash.old) (curr store ~))
    ::
      ::  Clear known shell routes even when Eyre's cache survived without a
      ::  matching entry in our persisted cache index.
      ::
      :~  (store '/apps/harness' ~)
          (store '/apps/harness/' ~)
          (store '/harness' ~)
          (store '/harness/' ~)
      ==
    ::
      ::  if the file root changed, remove tombstoning from the old root.
      ::
      ?:  =(foot.old file-root)  ~
      [(set-norm [our q.byk]:bowl foot.old &)]~
    ::
      ::  Always rebind the web root on every on-load, like the api agent
      ::  does for /apps/harness/api. Survives vere restarts and agent
      ::  revives even when web-root is unchanged.
      ::
      ^-  (list card)
      =/  root-cards=(list card)
        ?:  =(woot.old web-root)
        ::  same root: unconditional rebind
          [[%pass /eyre/connect %arvo %e %connect [~ web-root] dap.bowl] ~]
        ::  web-root changed: disconnect the old, bind the new
        ::NOTE  re-bind first to avoid duct shenanigans.
        :~  [%pass /eyre/connect %arvo %e %connect [~ woot.old] dap.bowl]
            [%pass /eyre/connect %arvo %e %disconnect [~ woot.old]]
            [%pass /eyre/connect %arvo %e %connect [~ web-root] dap.bowl]
        ==
      (snoc root-cards [%pass /eyre/connect %arvo %e %connect [~ /harness] dap.bowl])
  ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ~|  mark=mark
  ?>  ?=(%handle-http-request mark)
  |^
  =/  [rid=@ta inbound=inbound-request:eyre]
    !<([@ta inbound-request:eyre] vase)
  =/  [cache=? payload=simple-payload:http]  (serve-request inbound)
  =/  path  /http-response/[rid]
  =/  replies=(list card)
    :~  [%give %fact ~[path] [%http-response-header !>(response-header.payload)]]
        [%give %fact ~[path] [%http-response-data !>(data.payload)]]
        [%give %kick ~[path] ~]
    ==
  ?.  cache  [replies this]
  :_  this(cash (~(put in cash) url.request.inbound))
  %+  snoc  replies
  (store url.request.inbound ~ auth=| %payload payload)
::
++  serve-request
  |=  inbound-request:eyre
  ^-  [cache=? payload=simple-payload:http]
  ::  Browsers fetch these PWA files without session cookies.
  ::
  =/  pwa-paths=(set @t)
    %-  ~(gas in *(set @t))
    :~  '/apps/harness/manifest.json'
        '/apps/harness/harness.svg'
        '/apps/harness/harness.png'
        '/apps/harness/app.js'
        '/apps/harness/app.css'
    ==
  ?.  ?|  authenticated
          (~(has in pwa-paths) url.request)
          (starts-with '/apps/harness/public/' url.request)
          =('/harness' url.request)
          =('/harness/' url.request)
      ==
    [| [403 ~] `(as-octs:mimes:html 'unauthenticated')]
  ?.  ?=(%'GET' method.request)
    [| [405 ~] `(as-octs:mimes:html 'read-only resource')]
  =+  ^-  [[ext=(unit @ta) site=(list @t)] args=(list [key=@t value=@t])]
    =-  (fall - [[~ ~] ~])
    (rush url.request ;~(plug apat:de-purl:html yque:de-purl:html))
  ::  Repository names may contain periods.  Public repository routes are
  ::  SPA shells, not static assets with the repository suffix as an
  ::  extension.
  ::
  =.  ext
    ?:  (starts-with '/apps/harness/public/' url.request)
      ~
    ext
  =/  request-root=(unit path)
    ?:  =(woot (scag (lent woot) site))  `woot
    ?:  =(/harness (scag 1 site))  `/harness
    ~
  ?~  request-root
    [| [500 ~] `(as-octs:mimes:html 'bad route')]
  ::  Cache versioned asset paths, but always read extensionless SPA shells
  ::  fresh.  The shell carries the current asset digest, so an Eyre cache
  ::  entry that survives invalidation can pin browsers to an old bundle.
  ::
  :-  ?=(^ ext)
  ?~  ext
    ::  serve index.html for extensionless requests (SPA fallback)
    =/  shell-path=path
      :*  (scot %p our.bowl)
          q.byk.bowl
          (scot %da now.bowl)
          (weld foot /index/html)
      ==
    ?.  .^(? %cu shell-path)
      ~&  [dap.bowl %not-found-extless]
      [[404 ~] `(as-octs:mimes:html 'not found')]
    =+  .^(file=^vase %cr shell-path)
    =+  ~|  [%no-mime-conversion %html]
        .^(=tube:clay %cc (scot %p our.bowl) q.byk.bowl (scot %da now.bowl) /html/mime)
    =+  !<(=mime (tube file))
    :_  `q.mime
    [200 ['content-type' 'text/html'] ['cache-control' 'no-cache'] ~]
  =/  =path
    :*  (scot %p our.bowl)
        q.byk.bowl
        (scot %da now.bowl)
        (weld foot (snoc (slag (lent u.request-root) site) u.ext))
    ==
  ?.  .^(? %cu path)
    ~&  [dap.bowl %not-found path=path]
    [[404 ~] `(as-octs:mimes:html 'not found')]
  =+  .^(file=^vase %cr path)
  ::  Clay supplies the mark-to-MIME conversion; a missing conversion fails
  ::  the request with the source extension in the error trace.
  =+  ~|  [%no-mime-conversion from=u.ext]
      .^(=tube:clay %cc (scot %p our.bowl) q.byk.bowl (scot %da now.bowl) /[u.ext]/mime)
  =+  !<(=mime (tube file))
  =/  content-type=@t  (rsh 3^1 (spat p.mime))
  =/  cache-control=@t
    ?+  u.ext  'max-age=3600'
      %css  'max-age=3600'
      %js   ?:  =('sw' (rear (slag (lent u.request-root) site)))
              'no-cache'
            'max-age=3600'
      %svg  'max-age=86400'
      %png  'max-age=86400'
      %jpg  'max-age=86400'
      %ico  'max-age=86400'
      %html  'no-cache'
      %json  'no-cache'
    ==
  :_  `q.mime
  [200 ['content-type' content-type] ['cache-control' cache-control] ~]
--
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?>  ?=([%http-response @ ~] path)
  [~ this]
::
++  on-arvo
  |=  [=wire sign=sign-arvo]
  ^-  (quip card _this)
  ~|  wire=wire
  ?+  wire  !!
      [%eyre %connect ~]
    ~|  sign=+<.sign
    ?>  ?=(%bound +<.sign)
    ~?  !accepted.sign  [dap.bowl %binding-rejected binding.sign]
    [~ this]
  ::
      [%eyre %cache ~]
    ~|  sign=+<.sign
    ~|  %did-not-expect-gift
    !!
  ::
      [%clay %next *]
    ::  ignore if it's for a previous file-root
    ::
    ?.  =(t.t.wire foot)  [~ this]
    ~|  sign=+<.sign
    ?>  ?=(%writ +<.sign)
    ::  request the next change, and clear the cache.
    ::  it will get refilled on first request for each file.
    ::
    :_  this(cash ~)
    :-  (read-next [our q.byk now]:bowl foot)
    (turn ~(tap in cash) (curr store ~))
  ==
::
++  on-leave  |=(* [~ this])
++  on-agent  |=(* [~ this])
++  on-peek   |=(* ~)
::
++  on-fail
  |=  [=term =tang]
  ^-  (quip card _this)
  %-  (slog (rap 3 dap.bowl ' +on-fail: ' term ~) tang)
  [~ this]
--
