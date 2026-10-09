::  Owner ACP memory management through the full head; cards stay local.
/-  *harness-store, ac=acp, m=harness-memory
/+  *test, j=harness-provider-wire, admin=harness-admin, mem=harness-memory,
    policy=harness-defaults
/=  head  /app/harness
|%
++  isolated
  |=  attempt=$-(* tang)
  =/  out  (mink [attempt %9 2 %0 1] |=([* *] ``%.n))
  ?>  ?=(%0 -.out)
  ;;(tang product.out)
++  response
  |=  cards=(list card:agent:gall)
  ^-  json
  ?~  cards  !!
  =/  card  i.cards
  ?:  ?=([%pass [%acp %send ~] %agent * %poke %acp-action-1 *] card)
    =/  [pass=* wire=* agent=* target=* poke=* mark=* data=vase]  card
    =/  action  !<(action:v1:ac data)
    ?>  ?=(%send -.action)
    (need (de:json:html payload.action))
  ?:  ?=([%pass [%admin %result ~] %agent * %poke %harness-admin-result *] card)
    =/  [pass=* wire=* agent=* target=* poke=* mark=* data=vase]  card
    =/  decoded  !<([@t @t] data)
    (need (de:json:html +.decoded))
  $(cards t.cards)
++  exercise
  |=  [connection=@t operation=@t]
  ^-  tang
  =/  =bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~zod, now ~2026.10.7)
  =/  saved=state-0  *state-0
  =.  saved  saved(defaults builtin-config:policy, local-mcp-seen 1)
  =/  =source:m  ['evidence' 0v1 7 now.bowl '~nec']
  =/  seeded  (save:mem knowledge.saved 'project' 0 [`'Keep the plan clear.' ~ | | source])
  ?>  ?=(%& -.seeded)
  =.  knowledge.saved  p.seeded
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  before  !<(state-0 ~(on-save +.loaded bowl))
  =/  params
    %-  pairs:enjs:format
    :~  ['name' %s 'project']  ['revision' %s '1']
        ['text' %s 'Use concrete examples.']  ['actor' %s '~nec']
        ['sessionId' %s 'forged']
    ==
  =/  frame
    %-  en:json:html
    %-  pairs:enjs:format
    :~  ['jsonrpc' %s '2.0']  ['id' %n '1']
        ['method' %s (cat 3 'harness/memory/' operation)]  ['params' params]
    ==
  =/  =update:v1:ac  [%messages connection %agent ~[[1 now.bowl frame]]]
  =/  handled  (~(on-agent +.loaded bowl) /acp/watch [%fact %acp-update-1 !>(update)])
  =/  after  !<(state-0 ~(on-save +.handled bowl))
  =/  reply  (response -.handled)
  =/  denied  ?=(^ (decode:admin connection))
  =/  write  &(!denied |(=('save' operation) =('forget' operation)))
  =/  record  (~(got by records.knowledge.after) 'project')
  ;:  weld
      (expect-eq !>(sessions.before) !>(sessions.after))
      (expect-eq !>(jobs.knowledge.before) !>(jobs.knowledge.after))
      (expect-eq !>(pending.knowledge.before) !>(pending.knowledge.after))
      ?:  write
        ;:  weld
            (expect-eq !>(2) !>(revision.record))
            (expect-eq !>('~zod') !>(actor.source.value.record))
            (expect-eq !>('') !>(sid.source.value.record))
            (expect-eq !>(?:(=('forget' operation) 1 0)) !>(barrier.knowledge.after))
        ==
      (expect-eq !>(knowledge.before) !>(knowledge.after))
      (expect-eq !>(denied) !>(?=(^ (get:j reply 'error'))))
      (expect-eq !>(!denied) !>(?=(^ (get:j reply 'result'))))
  ==
++  test-owner-list-is-read-only
  (isolated |=(ignored=* (exercise 'memory-owner-fixture' 'list')))
++  test-owner-save-uses-verified-attribution
  (isolated |=(ignored=* (exercise 'memory-owner-fixture' 'save')))
++  test-owner-forget-invalidates-capture
  (isolated |=(ignored=* (exercise 'memory-owner-fixture' 'forget')))
++  test-model-admin-cannot-browse-owner-memory
  (isolated |=(ignored=* (exercise (connection:admin ['model' 1 'tool']) 'list')))
++  test-model-admin-cannot-write-owner-memory
  (isolated |=(ignored=* (exercise (connection:admin ['model' 1 'tool']) 'save')))
++  dreaming-case
  |=  [connection=@t configure=? value=json]
  ^-  tang
  =/  =bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~zod, now ~2026.10.9)
  =/  saved=state-0  *state-0
  =.  saved  saved(defaults builtin-config:policy, local-mcp-seen 1)
  =/  seed
    %:  save:mem
      knowledge.saved
      'retained'
      0
      [`'Retain this saved fact.' ~ | & ['' 0v0 0 now.bowl '~zod']]
    ==
  ?>  ?=(%& -.seed)
  =.  knowledge.saved  p.seed
  =?  knowledge.saved  &(configure =([%b |] value))
    =/  job  *job:m
    =.  job  job(sid 'first', config builtin-config:policy)
    %=  knowledge.saved
      enabled.dreaming.maintenance  &
      due.dreaming.maintenance  `~2026.10.10
      pending  `[7 job builtin-config:policy 0 ~2026.10.9..00.02.00 ~]
      jobs  (my ~[[7 job]])
      head  7
      next  8
    ==
  =/  loaded  (~(on-load head bowl) !>(saved))
  =/  before  !<(state-0 ~(on-save +.loaded bowl))
  =/  params  (pairs:enjs:format ~[['enabled' value]])
  =/  frame
    %-  en:json:html
    %-  pairs:enjs:format
    :~  ['jsonrpc' %s '2.0']  ['id' %n '1']
        ['method' %s ?:(configure 'harness/memory/dreaming/configure' 'harness/memory/dreaming')]
        ['params' params]
    ==
  =/  =update:v1:ac  [%messages connection %agent ~[[1 now.bowl frame]]]
  =/  handled  (~(on-agent +.loaded bowl) /acp/watch [%fact %acp-update-1 !>(update)])
  =/  after  !<(state-0 ~(on-save +.handled bowl))
  =/  reply  (response -.handled)
  =/  denied  |(?=(^ (decode:admin connection)) &(configure !?=(%b -.value)))
  =/  enabled  &(!denied configure =([%b &] value))
  =/  restored  (~(on-load +.handled bowl) !>(after))
  =/  reloaded  !<(state-0 ~(on-save +.restored bowl))
  ;:  weld
      (expect-eq !>(sessions.before) !>(sessions.after))
      (expect-eq !>(records.knowledge.before) !>(records.knowledge.after))
      (expect-eq !>(enabled) !>(enabled.dreaming.maintenance.knowledge.after))
      (expect-eq !>(enabled) !>(enabled.dreaming.maintenance.knowledge.reloaded))
      (expect-eq !>(denied) !>(?=(^ (get:j reply 'error'))))
      (expect-eq !>(!denied) !>(?=(^ (get:j reply 'result'))))
      (expect-eq !>(?:(enabled `~2026.10.10 ~)) !>(wake.knowledge.after))
      (expect-eq !>(wake.knowledge.after) !>(wake.knowledge.reloaded))
      ?:  |(denied !configure)
        (expect-eq !>(knowledge.before) !>(knowledge.after))
      ~
  ==
++  test-owner-dreaming-read-is-read-only
  (isolated |=(ignored=* (dreaming-case 'owner' | [%b &])))
++  test-owner-enables-global-dreaming-with-a-persisted-daily-wake
  (isolated |=(ignored=* (dreaming-case 'owner' & [%b &])))
++  test-owner-can-disable-dreaming-without-removing-memories
  (isolated |=(ignored=* (dreaming-case 'owner' & [%b |])))
++  test-dreaming-rejects-nonboolean-values
  (isolated |=(ignored=* (dreaming-case 'owner' & [%s 'false'])))
++  test-model-admin-cannot-read-dreaming-settings
  (isolated |=(ignored=* (dreaming-case (connection:admin ['model' 1 'tool']) | [%b &])))
++  test-model-admin-cannot-enable-dreaming
  (isolated |=(ignored=* (dreaming-case (connection:admin ['model' 1 'tool']) & [%b &])))
--
