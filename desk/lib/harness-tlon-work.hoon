::  Owner-visible work is a bounded projection of admission and delivery,
::  never a second queue. Reading this page cannot start or retry any work.
/-  t=harness-tlon, hh=harness-hand
/+  p=harness-tlon-policy, hd=harness-hand, hp=harness-tlon-history-page
|%
+$  row  [at=@da key=@uv value=json]
++  phase
  |=  [obs=observation:hh pub=(unit publication:hh)]
  ^-  @t
  ?^  pub
    ?-  status.u.pub
      %pending    'completed'
      %claimed    'sending'
      %delivered  'delivered'
      %failed     'send-failed'
      %uncertain  'uncertain'
      %abandoned  'abandoned'
    ==
  ?-  phase.obs
    %queued     'received'
    %running    'working'
    %completed  'completed'
    %failed     'failed'
    %cancelled  'cancelled'
  ==
++  earlier
  |=  [a=[at=@da key=@uv] b=[at=@da key=@uv]]
  |((lth at.a at.b) &(=(at.a at.b) (lth key.a key.b)))
++  page
  |=  [state=state:t db=state:hh before=@t]
  ^-  json
  =/  cursor=(unit [at=@da key=@uv])
    ?:  =('' before)  ~
    ?>  (lte (met 3 before) 256)
    =/  parsed  ;;([%1 at=@da key=@uv] (cue (slav %uv before)))
    ?>  &((lte (met 0 at.parsed) 128) (lte (met 0 key.parsed) 256))
    `[at.parsed key.parsed]
  =/  rows=(list row)
    %+  murn  ~(tap by observations.db)
    |=  [id=@uv obs=observation:hh]
    ^-  (unit row)
    =/  cfg  (~(get by bindings.db) binding.obs)
    ?.  ?&(?=(^ cfg) =('tlon' hand.u.cfg))  ~
    =/  pub  (~(get by outbox.db) id)
    =/  route  (~(get by routes.state) sid.u.cfg)
    =/  current  ?&(?=(^ route) enabled.policy.state enabled.u.cfg =(%ready phase.u.route) =(binding.obs binding.u.route))
    :-  ~
    :*  at.obs  (sham [%input id])
      %-  pairs:enjs:format
      :~  ['kind' %s 'input']
          ['id' %s (scot %uv id)]
          ['at' %s (scot %da at.obs)]
          ['sessionId' %s sid.u.cfg]
          ['binding' %s binding.obs]
          ['actor' %s actor.obs]
          ['destination' %s address.u.cfg]
          ['text' %s (clip-text:hp text.obs 256)]
          ['reply' ?~(pub ~ [%s (clip-text:hp body.u.pub 512)])]
          ['status' %s (phase obs pub)]
          ['current' %b current]
          ['attempt' (numb:enjs:format attempt:(get-control:hd db id))]
          ['externalId' ?~(pub ~ [%s external.u.pub])]
          ['canRetry' %b ?~(pub | &(current =(%failed status.u.pub)))]
          ['canResolve' %b ?~(pub | !(terminal:hd status.u.pub))]
      ==
    ==
  =.  rows
    %+  weld  rows
    %+  turn  ~(tap by jobs.state)
    |=  [id=@uv job=job:t]
    ^-  row
    ::  Adapter jobs precede ledger admission. Their key and original text
    ::  remain available after an explicit setup/queue failure.
    :*  `@da`(dec (bex 128))  (sham [%admission id])
      %-  pairs:enjs:format
      :~  ['kind' %s 'admission']
          ['id' %s (scot %uv id)]
          ['sessionId' %s sid.job]
          ['actor' %s (scot %p actor.input.job)]
          ['destination' %s (address:p to.input.job)]
          ['text' %s (clip-text:hp text.input.job 256)]
          ['status' %s 'received']
          ['stage' %s stage.job]
          ['error' %s error.job]
          ['canRetry' %b &]
      ==
    ==
  =.  rows  (sort rows |=([a=row b=row] (earlier [at.b key.b] [at.a key.a])))
  ::  Put pre-admission work first without fabricating a timestamp. A stable
  ::  sort key of the maximal timestamp keeps its cursor distinct from history.
  =?  rows  ?=(^ cursor)
    (skim rows |=(r=row (earlier [at.r key.r] u.cursor)))
  =/  selected  (scag 16 rows)
  =/  next=(unit @t)
    ?.  (gth (lent rows) 16)  ~
    =/  last  (rear selected)
    `(scot %uv (jam [%1 at.last key.last]))
  (pairs:enjs:format ~[['records' %a (turn selected |=(r=row value.r))] ['next' ?~(next ~ [%s u.next])] ['limit' %n '16']])
--
