::  Inspect full-agent ACP cards inside mink; never execute them or return
::  their large embedded vase types outside the sandbox.
/-  *harness-store, ac=acp
/+  *test, j=harness-workspace-json, admin=harness-admin
/=  head  /app/harness
|%
++  isolated
  |=  attempt=$-(* tang)
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  ;;(tang product.out)
++  exercise
  |=  connection=@t
  ^-  tang
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =.  src.bowl  ~zod
  =.  now.bowl  ~2026.9.12
  =/  saved=state-27  *state-27
  =.  tlon-cron-imported.saved  &
  =.  tasks.workspace.saved
    (my ~[['task' ['project' 'Read-only fixture' 'No effects' 1 %blocked ~ '' ~ now.bowl]]])
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  before  !<(state-27 ~(on-save +.loaded bowl))
  =/  frame=@t  '{"jsonrpc":"2.0","id":1,"method":"harness/inbox","params":{"state":"attention"}}'
  =/  update=update:v1:ac  [%messages connection %agent ~[[1 now.bowl frame]]]
  =/  read  (~(on-agent +.loaded bowl) /acp/watch [%fact %acp-update-1 !>(update)])
  =/  after  !<(state-27 ~(on-save +.read bowl))
  =/  payload=@t
    =/  cards  -.read
    |-  ^-  @t
    ?~  cards  !!
    =/  card  i.cards
    ?:  ?=([%pass [%acp %send ~] %agent * %poke %acp-action-1 *] card)
      =/  [pass=* wire=* agent=* target=* poke=* mark=* data=vase]  card
      =/  action  !<(action:v1:ac data)
      ?>  ?=(%send -.action)
      payload.action
    ?:  ?=([%pass [%admin %result ~] %agent * %poke %harness-admin-result *] card)
      =/  [pass=* wire=* agent=* target=* poke=* mark=* data=vase]  card
      =/  decoded  !<([@t @t] data)
      +.decoded
    $(cards t.cards)
  =/  response  (need (de:json:html payload))
  =/  result  (get:j response 'result')
  =/  denied  (get:j response 'error')
  ;:  weld
    (expect-eq !>(workspace.before) !>(workspace.after))
    (expect-eq !>(workspace-notes.before) !>(workspace-notes.after))
    (expect-eq !>(hands.before) !>(hands.after))
    (expect-eq !>(schedules.before) !>(schedules.after))
    (expect-eq !>(sessions.before) !>(sessions.after))
    (expect !>((lien -.read |=(c=card:agent:gall ?=([%pass [%acp %ack ~] %agent * %poke %acp-action-1 *] c)))))
    ?:  ?=(^ (decode:admin connection))
      (expect !>(&(?=(^ denied) ?=(~ result))))
    (expect !>(&(?=(^ result) ?=(~ denied))))
  ==
++  test-owner-read-is-projection-only
  (isolated |=(ignored=* (exercise 'inbox-owner-fixture')))
++  test-model-admin-cannot-read-owner-inbox
  (isolated |=(ignored=* (exercise (connection:admin ['model-session' 1 'admin-tool']))))
--
