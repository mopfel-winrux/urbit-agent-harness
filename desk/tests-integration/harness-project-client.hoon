::  Full-agent HTTP routing and persistence, isolated from effect execution.
/-  *harness-store, ac=acp, n=tlon-notes
/+  *test, j=harness-workspace-json, admin=harness-admin
/=  head  /app/harness
/=  seed  /tests/harness-project-client
|%
++  isolated
  |=  attempt=$-(* tang)
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  ;;(tang product.out)
++  request
  |=  body=@t
  ^-  inbound-request:eyre
  [| | [%ipv4 .127.0.0.1] [%'POST' '/harness-project/read' ~[['authorization' (cat 3 'Bearer ' key:seed)]] `(as-octs:mimes:html body)]]
++  exercise
  |=  [req=inbound-request:eyre code=@ud now=@da]
  ^-  tang
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  ::  Public Eyre requests are not delivered as the owner.
  =.  src.bowl  ~nec
  =.  now.bowl  now
  =/  saved=state-28  *state-28
  =.  tlon-cron-imported.saved  &
  =.  workspace.saved  fixture:seed
  =.  project-clients.saved  issued:seed
  =.  book.workspace-notes.saved  `[~zod %fixture]
  =.  links.workspace-notes.saved  (my ~[['document' [42 ~ ~]] ['private' [100 ~ ~]] ['other-document' [99 ~ ~]]])
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  before  !<(state-28 ~(on-save +.loaded bowl))
  =/  response  (~(on-poke +.loaded bowl) %handle-http-request !>([`@ta`%client-fixture req]))
  =/  after  !<(state-28 ~(on-save +.response bowl))
  =/  headers
    %+  murn  -.response
    |=  card=card:agent:gall
    ?.  ?=([%give %fact * %http-response-header *] card)  ~
    =/  [give=* fact=* paths=* mark=* data=vase]  card
    `!<(response-header:http data)
  ?>  ?=(^ headers)
  ?>  =(1 (lent headers))
  =/  header  i.headers
  =/  bodies
    %+  murn  -.response
    |=  card=card:agent:gall
    ?.  ?=([%give %fact * %http-response-data *] card)  ~
    =/  [give=* fact=* paths=* mark=* data=vase]  card
    =/  body  (need !<((unit octs) data))
    `q.body
  ?>  ?=(^ bodies)
  =/  value  (need (de:json:html i.bodies))
  ;:  weld
    (expect-eq !>(code) !>(status-code.header))
    (expect !>(=(before after)))
    (expect !>((levy -.response |=(card=card:agent:gall ?=(%give -.card)))))
    (expect !>((lien headers.header |=([name=@t value=@t] &(=('cache-control' name) =('no-store' value))))))
    (expect !>(!(lien headers.header |=([name=@t value=@t] =('access-control-allow-origin' name)))))
    ?:  &(=(200 code) =('artifact' (string:j (need (de:json:html q:(need body.request.req))) 'action')))
      (expect-eq !>('Only the selected native note was read') !>((string:j (need (get:j value 'content')) 'body')))
    ~
  ==
++  test-http-read-does-not-change-any-durable-state-or-dispatch-effects
  (isolated |=(ignored=* (exercise (request '{"action":"project","args":{"id":"project"}}') 200 ~2026.9.14)))
++  test-http-foreign-project-and-task-are-unavailable
  %-  isolated  |=  ignored=*
  ;:  weld
    (exercise (request '{"action":"project","args":{"id":"other"}}') 404 ~2026.9.14)
    (exercise (request '{"action":"task","args":{"id":"other-task"}}') 404 ~2026.9.14)
  ==
++  test-http-writes-and-owner-surfaces-are-denied-before-effects
  %-  isolated  |=  ignored=*
  =/  actions  `(list @t)`~['member' 'client-create' 'task-update' 'publish' 'review' 'sessions' 'harness_admin' 'tlon']
  %-  zing
  %+  turn  actions
  |=  action=@t
  (exercise (request (en:json:html (pairs:enjs:format ~[['action' %s action] ['args' %o ~]]))) 403 ~2026.9.14)
++  test-http-cookie-is-not-client-authority-and-expiry-is-live
  %-  isolated  |=  ignored=*
  =/  req  (request '{"action":"help"}')
  ;:  weld
    (exercise req(header-list.request ~[['cookie' 'urbauth-~zod=not-a-project-key']]) 401 ~2026.9.14)
    (exercise req 401 ~2026.9.20)
    (exercise req(address [%ipv4 .10.0.0.1]) 403 ~2026.9.14)
    (exercise req(address [%ipv4 .10.0.0.1], secure &) 200 ~2026.9.14)
  ==
++  test-http-bounds-malformed-requests-and-exact-route
  %-  isolated  |=  ignored=*
  =/  req  (request '{"action":"help"}')
  ;:  weld
    (exercise (request '{not-json') 400 ~2026.9.14)
    (exercise (request '{"action":"help","args":[]}') 400 ~2026.9.14)
    (exercise req(method.request %'GET') 405 ~2026.9.14)
    (exercise req(url.request '/harness-project/read?key=forbidden') 404 ~2026.9.14)
    (exercise req(body.request `[8.193 'x']) 413 ~2026.9.14)
  ==
++  test-notes-reads-use-only-selected-native-identities
  =/  attempt  |=(ignored=* (exercise (request '{"action":"artifact","args":{"id":"document"}}') 200 ~2026.9.14))
  =/  out
    %+  mink  [attempt %9 2 %0 1]
    |=  [ref=* raw=*]
    ^-  (unit (unit noun))
    =/  path  ;;(path raw)
    ?:  ?=([%gu *] path)  ``%.n
    ?:  (lien path |=(part=@ta =(%notes-published part)))  ``~
    ?.  (lien path |=(part=@ta =('42' part)))  ~
    ?:  (lien path |=(part=@ta =(%note-history part)))  ``~
    ?.  (lien path |=(part=@ta =(%note part)))  ~
    =/  current=note:n  *note:n
    =.  id.current  42
    =.  title.current  'Native selected body'
    =.  body-md.current  'Only the selected native note was read'
    =.  revision.current  1
    ``current
  ?>  ?=(%0 -.out)
  ;;(tang product.out)
++  test-unavailable-native-notes-do-not-return-cached-bodies
  (isolated |=(ignored=* (exercise (request '{"action":"artifact","args":{"id":"document"}}') 503 ~2026.9.14)))
++  test-metadata-lists-succeed-without-native-body-scries
  ;:  weld
    (isolated |=(ignored=* (exercise (request '{"action":"artifacts"}') 200 ~2026.9.14)))
    (isolated |=(ignored=* (exercise (request '{"action":"proposals"}') 200 ~2026.9.14)))
  ==
++  credential-owner
  |=  connection=@t
  ^-  tang
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =.  src.bowl  ~zod
  =.  now.bowl  ~2026.9.14
  =/  saved=state-28  *state-28
  =.  tlon-cron-imported.saved  &
  =.  workspace.saved  fixture:seed
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  before  !<(state-28 ~(on-save +.loaded bowl))
  =/  params  (pairs:enjs:format ~[['action' %s 'client-create'] ['args' (args:seed 'new-key' key:seed 1)]])
  =/  frame  (en:json:html (pairs:enjs:format ~[['jsonrpc' %s '2.0'] ['id' %n '1'] ['method' %s 'harness/workspace'] ['params' params]]))
  =/  update=update:v1:ac  [%messages connection %agent ~[[1 now.bowl frame]]]
  =/  response  (~(on-agent +.loaded bowl) /acp/watch [%fact %acp-update-1 !>(update)])
  =/  after  !<(state-28 ~(on-save +.response bowl))
  =/  owner  ?=(~ (decode:admin connection))
  ;:  weld
    (expect-eq !>(?:(owner 1 0)) !>(~(wyt by project-clients.after)))
    (expect-eq !>(workspace-notes.before) !>(workspace-notes.after))
    (expect-eq !>(sessions.before) !>(sessions.after))
    (expect-eq !>(hands.before) !>(hands.after))
    (expect-eq !>(schedules.before) !>(schedules.after))
    (expect-eq !>(artifacts.workspace.before) !>(artifacts.workspace.after))
    (expect-eq !>(?:(owner +(writes.workspace.before) writes.workspace.before)) !>(writes.workspace.after))
  ==
++  test-owner-can-issue-without-native-document-effects
  (isolated |=(ignored=* (credential-owner 'owner-client-fixture')))
++  test-administration-tool-cannot-mint-project-credentials
  (isolated |=(ignored=* (credential-owner (connection:admin ['model-session' 1 'admin-call']))))
--
