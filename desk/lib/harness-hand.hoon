::  Pure binding, admission, and delivery bookkeeping. No transport or scheduler.
/-  h=harness, hh=harness-hand
|%
++  migrate
  |=  old=state-0:hh
  ^-  state:hh
  =/  controls=(map input-id:h control:hh)
    %-  ~(run by outbox.old)
    |=  pub=publication:hh
    ^-  control:hh
    [?:(=(%pending status.pub) 0 1) ~]
  [bindings.old observations.old queue.old active.old outbox.old controls ~ 1 ~]
++  terminal
  |=  status=delivery-state:hh
  |(=(%delivered status) =(%abandoned status))
++  generated
  |=  id=@t
  =('hand--' (end [3 6] id))
++  get-control
  |=  [db=state:hh id=input-id:h]
  ^-  control:hh
  (fall (~(get by controls.db) id) *control:hh)
++  input-id
  |=  [binding=@t event=@t]
  ^-  input-id:h
  (end [3 16] (shas %hand-input (jam [binding event])))
++  id-json
  |=  id=input-id:h
  ^-  json
  [%s (scot %uv id)]
++  admission-json
  |=  [id=input-id:h obs=observation:hh]
  ^-  json
  (pairs:enjs:format ~[['inputId' (id-json id)] ['phase' %s phase.obs] ['sourceEvent' %s event.obs]])
++  publication-json
  |=  [db=state:hh id=input-id:h pub=publication:hh]
  ^-  json
  %-  pairs:enjs:format
  :~  ['version' (numb:enjs:format 2)]
      ['attempt' (numb:enjs:format attempt:(get-control db id))]
      :-  'resolutions'
      :-  %a
      %+  turn  (flop resolutions:(get-control db id))
      |=  r=resolution:hh
      (pairs:enjs:format ~[['at' %s (scot %da at.r)] ['attempt' (numb:enjs:format attempt.r)] ['outcome' %s outcome.r] ['reason' %s reason.r]])
      ['effectId' (id-json id)]
      ['inputId' (id-json input.pub)]
      ['binding' %s binding.pub]
      ['hand' %s hand.pub]
      ['address' %s address.pub]
      ['sessionId' %s sid.pub]
      ['capability' %s 'publish']
      ['kind' %s kind.pub]
      ['text' %s body.pub]
      ['status' %s status.pub]
      ['worker' %s worker.pub]
      ['externalId' %s external.pub]
      :-  'receipts'
      :-  %a
      %+  turn  (flop receipts.pub)
      |=  r=receipt:hh
      (pairs:enjs:format ~[['at' %s (scot %da at.r)] ['status' %s status.r] ['worker' %s worker.r] ['externalId' %s external.r]])
  ==
++  outbox-json
  |=  [db=state:hh hand=@t]
  ^-  json
  :-  %a
  %+  murn  ~(tap by outbox.db)
  |=  [id=input-id:h pub=publication:hh]
  ^-  (unit json)
  ?.  =(hand hand.pub)  ~
  ?:  (terminal status.pub)  ~
  =/  cfg  (~(get by bindings.db) binding.pub)
  ?~  cfg  ~
  ?.  enabled.u.cfg  ~
  `(publication-json db id pub)
++  claim-json
  |=  [db=state:hh id=input-id:h pub=publication:hh acquired=?]
  ^-  json
  =/  jon  (publication-json db id pub)
  ?>  ?=(%o -.jon)
  [%o (~(put by p.jon) 'acquired' [%b acquired])]
++  status-json
  |=  [db=state:hh binding=@t]
  ^-  json
  =/  cfg  (~(get by bindings.db) binding)
  ?~  cfg  ~
  =/  inputs=(list json)
    %+  murn  ~(tap by observations.db)
    |=  [id=input-id:h obs=observation:hh]
    ^-  (unit json)
    ?.  =(binding binding.obs)  ~
    `(admission-json id obs)
  %-  pairs:enjs:format
  :~  ['binding' %s binding]
      ['hand' %s hand.u.cfg]
      ['address' %s address.u.cfg]
      ['sessionId' %s sid.u.cfg]
      ['enabled' %b enabled.u.cfg]
      ['actors' %a (turn actors.u.cfg |=(a=@t `json`[%s a]))]
      ['observations' %a inputs]
  ==
++  apply
  |=  [db=state:hh act=action:hh now=@da]
  ^-  (each [db=state:hh result=json] @t)
  ?-  -.act
      %register
    =/  id=@t  (cat 3 'hand--' (scot %ud next-binding.db))
    =.  next-binding.db  +(next-binding.db)
    ?:  |((~(has by bindings.db) id) (~(has in retired.db) id) (lien retirements.db |=(r=retirement:hh =(binding.r id))) (lien ~(val by observations.db) |=(obs=observation:hh =(binding.obs id))))
      $(db db)
    (bind-config db id config.act)
  ::
      %bind
    ?:  (generated id.act)  [%| 'The hand-- namespace is allocated by register']
    ?:  &(!(~(has by bindings.db) id.act) (gte (add ~(wyt in retired.db) ~(wyt by bindings.db)) 4.096))
      [%| 'Named binding identity capacity reached; use register']
    (bind-config db id.act config.act)
  ::
      %enable
    =/  cfg  (~(get by bindings.db) id.act)
    ?~  cfg  [%| 'Unknown binding']
    =.  bindings.db  (~(put by bindings.db) id.act u.cfg(enabled enabled.act))
    [%& db (status-json db id.act)]
  ::
      %remove
    =/  cfg  (~(get by bindings.db) id.act)
    ?~  cfg  [%| 'Unknown binding']
    ?:  (lien ~(val by observations.db) |=(obs=observation:hh =(binding.obs id.act)))
      [%| 'Export and retire a binding that has observations']
    =.  bindings.db  (~(del by bindings.db) id.act)
    =?  retired.db  !(generated id.act)  (~(put in retired.db) id.act)
    [%& db (pairs:enjs:format ~)]
  ::
      %observe
    =/  cfg  (~(get by bindings.db) binding.act)
    ?~  cfg  [%| 'Unknown binding']
    ?.  enabled.u.cfg  [%| 'Binding is disabled']
    ?.  (lien actors.u.cfg |=(actor=@t =(actor actor.act)))
      [%| 'Actor is not allowed by this binding']
    ?.  &(!=('' event.act) !=('' text.act) (lte (met 3 text.act) 65.536) (lte (met 3 event.act) 512))
      [%| 'Expected nonempty source event and text within admission limits']
    =/  id  (input-id binding.act event.act)
    =/  seen  (~(get by observations.db) id)
    ?^  seen
      ?.  &(=(actor.act actor.u.seen) =(text.act text.u.seen))
        [%| 'Source event already admitted with different content']
      [%& db (admission-json id u.seen)]
    ?:  (gte (lent queue.db) 128)  [%| 'Admission queue is full; retry the same source event later']
    =/  counts=[binding=@ud session=@ud]  (queued-counts db binding.act sid.u.cfg)
    ?:  |((gte binding.counts 8) (gte session.counts 16))
      [%| 'This binding or session has reached its waiting-work limit']
    ?:  (gte ~(wyt by observations.db) 2.048)
      [%| 'Hand ledger capacity reached; export and retire settled bindings']
    ?:  (gte (lent (skim ~(val by observations.db) |=(obs=observation:hh =(binding.obs binding.act)))) 256)
      [%| 'Binding ledger capacity reached; export and rotate its binding']
    =/  obs=observation:hh  [binding.act event.act actor.act text.act now %queued]
    =.  observations.db  (~(put by observations.db) id obs)
    =.  queue.db  (snoc queue.db id)
    [%& db (admission-json id obs)]
  ::
      %claim
    ?.  (lte (met 3 worker.act) 128)  [%| 'Worker identity exceeds its limit']
    =/  pub  (~(get by outbox.db) effect.act)
    ?~  pub  [%| 'Unknown effect']
    ?.  &(=(hand.act hand.u.pub) !=('' worker.act))  [%| 'Wrong hand or missing worker identity']
    =/  cfg  (~(get by bindings.db) binding.u.pub)
    ?.  ?&(?=(^ cfg) enabled.u.cfg)  [%| 'Binding is disabled']
    ?.  |(=(%pending status.u.pub) &(=(%claimed status.u.pub) =(worker.act worker.u.pub)))
      [%| 'Effect is not available to this worker']
    ?:  =(%claimed status.u.pub)  [%& db (claim-json db effect.act u.pub %.n)]
    =.  u.pub  u.pub(status %claimed, worker worker.act, receipts [[now %claimed worker.act ''] receipts.u.pub])
    =/  ctl  (get-control db effect.act)
    =.  controls.db  (~(put by controls.db) effect.act ctl(attempt +(attempt.ctl)))
    =.  outbox.db  (~(put by outbox.db) effect.act u.pub)
    [%& db (claim-json db effect.act u.pub %.y)]
  ::
      %receipt
    =/  ctl  (get-control db effect.act)
    ?.  =(1 attempt.ctl)  [%| 'An explicit attempt is required after recovery or retry']
    $(act [%receipt-at hand.act effect.act worker.act 1 status.act external.act])
  ::
      %receipt-at
    ?.  (lte (met 3 external.act) 2.048)  [%| 'External receipt exceeds its limit']
    =/  pub  (~(get by outbox.db) effect.act)
    ?~  pub  [%| 'Unknown effect']
    ?.  =(attempt.act attempt:(get-control db effect.act))  [%| 'Stale delivery attempt']
    ?.  &(=(hand.act hand.u.pub) !=('' worker.act) =(worker.act worker.u.pub))
      [%| 'Receipt does not match the claiming hand and worker']
    ?:  =(status.act status.u.pub)
      ?.  =(external.act external.u.pub)  [%| 'Conflicting receipt']
      [%& db (publication-json db effect.act u.pub)]
    ?.  ?=(?(%claimed %uncertain) status.u.pub)  [%| 'Effect cannot accept this receipt']
    =/  value=publication:hh  u.pub
    =.  value  value(status status.act, external external.act, receipts [[now status.act worker.act external.act] receipts.value])
    =.  outbox.db  (~(put by outbox.db) effect.act value)
    [%& db (publication-json db effect.act value)]
  ::
      %retry
    =/  pub  (~(get by outbox.db) effect.act)
    ?~  pub  [%| 'Unknown effect']
    ?.  &(=(hand.act hand.u.pub) =(%failed status.u.pub))
      [%| 'Only a confirmed failed delivery may be retried; reconcile uncertain outcomes first']
    ?:  (gte (lent receipts.u.pub) 96)  [%| 'Delivery retry budget exhausted; resolve or abandon the publication']
    =.  u.pub  u.pub(status %pending, worker '', external '', receipts [[now %pending '' ''] receipts.u.pub])
    =.  outbox.db  (~(put by outbox.db) effect.act u.pub)
    [%& db (publication-json db effect.act u.pub)]
  ::
      %status
    ?.  (~(has by bindings.db) binding.act)  [%| 'Unknown binding']
    [%& db (status-json db binding.act)]
  ::
      %outbox
    [%& db (outbox-json db hand.act)]
  ::
      %publications
    [%& db (publications-json db hand.act after.act limit.act)]
  ::
      %effect
    =/  pub  (~(get by outbox.db) effect.act)
    ?~  pub  [%| 'Unknown effect']
    ?.  =(hand.act hand.u.pub)  [%| 'Wrong hand']
    [%& db (publication-json db effect.act u.pub)]
  ::
      %resolve
    (resolve db act now)
  ::
      %health
    [%& db (health-json db hand.act now)]
  ::
      %archive
    (archive db binding.act)
  ::
      %records
    [%& db (records-json db binding.act after.act limit.act)]
  ::
      %retire
    (retire db binding.act digest.act location.act now)
  ==
++  bind-config
  |=  [db=state:hh id=@t cfg=binding:hh]
  ^-  (each [db=state:hh result=json] @t)
  ?.  &(!=('' id) !=('' hand.cfg) !=('' address.cfg) !=(~ actors.cfg))
    [%| 'Binding, hand, address, and an explicit actor allowlist are required']
  ?.  &((lte (met 3 id) 128) (lte (met 3 hand.cfg) 128) (lte (met 3 address.cfg) 2.048) (lte (lent actors.cfg) 128))
    [%| 'Binding metadata exceeds its limits']
  ?.  (levy actors.cfg |=(actor=@t (lte (met 3 actor) 512)))
    [%| 'Actor identity exceeds its limit']
  =/  existing  (~(get by bindings.db) id)
  ?^  existing
    ?.  =(u.existing cfg)  [%| 'Binding identities are immutable; use a new id']
    [%& db (status-json db id)]
  ?:  |((~(has in retired.db) id) (lien ~(val by observations.db) |=(obs=observation:hh =(binding.obs id))))
    [%| 'Retired binding ids cannot be reused']
  ?:  (gte ~(wyt by bindings.db) 256)  [%| 'Binding limit reached']
  =.  bindings.db  (~(put by bindings.db) id cfg)
  [%& db (status-json db id)]
++  queued-counts
  |=  [db=state:hh binding=@t sid=session-id:h]
  ^-  [binding=@ud session=@ud]
  %+  roll  queue.db
  |=  [id=input-id:h counts=[binding=@ud session=@ud]]
  =/  obs  (need (~(get by observations.db) id))
  =/  cfg  (need (~(get by bindings.db) binding.obs))
  [(add binding.counts ?:(=(binding binding.obs) 1 0)) (add session.counts ?:(=(sid sid.cfg) 1 0))]
++  resolve
  |=  [db=state:hh act=[%resolve hand=@t effect=input-id:h attempt=@ud status=?(%delivered %failed %uncertain %abandoned) external=@t reason=@t] now=@da]
  ^-  (each [db=state:hh result=json] @t)
  =/  pub  (~(get by outbox.db) effect.act)
  ?~  pub  [%| 'Unknown effect']
  =/  ctl  (get-control db effect.act)
  ?.  &(=(hand.act hand.u.pub) =(attempt.act attempt.ctl))
    [%| 'Wrong hand or stale recovery attempt']
  ?:  (terminal status.u.pub)  [%| 'Publication is already terminal']
  ?.  &(!=('' reason.act) (lte (met 3 reason.act) 1.024) (lte (met 3 external.act) 2.048))
    [%| 'A bounded, explicit recovery reason is required']
  ?:  &((gte (lent resolutions.ctl) 32) !=(%abandoned status.act))
    [%| 'Recovery budget exhausted; archive an explicit abandonment']
  =/  next=@ud  +(attempt.ctl)
  =.  controls.db
    (~(put by controls.db) effect.act [next [[now next status.act reason.act] resolutions.ctl]])
  =.  u.pub  u.pub(status status.act, worker '', external external.act, receipts [[now status.act '' external.act] receipts.u.pub])
  =.  outbox.db  (~(put by outbox.db) effect.act u.pub)
  [%& db (publication-json db effect.act u.pub)]
++  health-json
  |=  [db=state:hh hand=@t now=@da]
  ^-  json
  =/  claims=(list json)
    %+  murn  ~(tap by outbox.db)
    |=  [id=input-id:h pub=publication:hh]
    ^-  (unit json)
    ?.  &(=(hand hand.pub) |(=(%claimed status.pub) =(%uncertain status.pub)))  ~
    =/  age=@dr  ?~(receipts.pub ~s0 (sub now (min now at.i.receipts.pub)))
    `(pairs:enjs:format ~[['effectId' (id-json id)] ['binding' %s binding.pub] ['status' %s status.pub] ['worker' %s worker.pub] ['attempt' (numb:enjs:format attempt:(get-control db id))] ['ageSeconds' (numb:enjs:format (div age ~s1))] ['stale' %b (gte age ~m5)]])
  (pairs:enjs:format ~[['claims' %a claims] ['waiting' (numb:enjs:format (lent queue.db))] ['retainedObservations' (numb:enjs:format ~(wyt by observations.db))] ['queueLimit' (numb:enjs:format 128)] ['bindingQueueLimit' (numb:enjs:format 8)] ['sessionQueueLimit' (numb:enjs:format 16)] ['ledgerLimit' (numb:enjs:format 2.048)]])
++  binding-ids
  |=  [db=state:hh binding=@t]
  ^-  (list input-id:h)
  %-  sort
  :_  lth
  %+  murn  ~(tap by observations.db)
  |=  [id=input-id:h obs=observation:hh]
  ^-  (unit input-id:h)
  ?:(=(binding binding.obs) `id ~)
++  publications-json
  |=  [db=state:hh hand=@t after=(unit input-id:h) limit=@ud]
  ^-  json
  =/  ids=(list input-id:h)
    %-  sort
    :_  lth
    %+  murn  ~(tap by outbox.db)
    |=  [id=input-id:h pub=publication:hh]
    ^-  (unit input-id:h)
    ?.  &(=(hand hand.pub) !(terminal status.pub))  ~
    ?:  ?&(?=(^ after) (lte id u.after))  ~
    =/  cfg  (~(get by bindings.db) binding.pub)
    ?~  cfg  ~
    ?.  enabled.u.cfg  ~
    `id
  =/  page  (scag (min (max 1 (min 4 limit)) (lent ids)) ids)
  =/  records=(list json)
    (turn page |=(id=input-id:h (publication-json db id (need (~(get by outbox.db) id)))))
  (pairs:enjs:format ~[['records' %a records] ['next' ?:((gth (lent ids) (lent page)) (id-json (rear page)) ~)]])
++  archive-digest
  |=  [db=state:hh binding=@t]
  ^-  @uvH
  =/  records=(list noun)
    %+  turn  (binding-ids db binding)
    |=  id=input-id:h
    ^-  noun
    [id (~(get by observations.db) id) (~(get by outbox.db) id) (get-control db id)]
  (shas %hand-archive (jam [binding (~(get by bindings.db) binding) records]))
++  archive
  |=  [db=state:hh binding=@t]
  ^-  (each [db=state:hh result=json] @t)
  =/  cfg  (~(get by bindings.db) binding)
  ?:  ?&(?=(^ cfg) enabled.u.cfg)  [%| 'Disable the binding before exporting it']
  =/  ids  (binding-ids db binding)
  ?:  &(=(~ cfg) =(~ ids))  [%| 'Unknown binding']
  =/  working=?
    %+  lien  ids
    |=  id=input-id:h
    =/  obs  (need (~(get by observations.db) id))
    |(=(%queued phase.obs) =(%running phase.obs))
  ?:  working
    [%| 'Finish or cancel queued and active work before archiving']
  =/  unsettled=?
    %+  lien  ids
    |=  id=input-id:h
    =/  pub  (~(get by outbox.db) id)
    ?~  pub  %.n
    !(terminal status.u.pub)
  ?:  unsettled
    [%| 'Resolve every publication before archiving']
  [%& db (pairs:enjs:format ~[['binding' %s binding] ['digest' %s (scot %uv (archive-digest db binding))] ['records' (numb:enjs:format (lent ids))] ['config' (status-json db binding)]])]
++  records-json
  |=  [db=state:hh binding=@t after=(unit input-id:h) limit=@ud]
  ^-  json
  =/  ids  (skip (binding-ids db binding) |=(id=input-id:h ?~(after %.n (lte id u.after))))
  =/  page  (scag (min (max 1 (min 4 limit)) (lent ids)) ids)
  =/  records=(list json)
    %+  turn  page
    |=  id=input-id:h
    =/  obs  (need (~(get by observations.db) id))
    =/  pub  (~(get by outbox.db) id)
    (pairs:enjs:format ~[['inputId' (id-json id)] ['event' %s event.obs] ['actor' %s actor.obs] ['text' %s text.obs] ['at' %s (scot %da at.obs)] ['phase' %s phase.obs] ['publication' ?~(pub ~ (publication-json db id u.pub))]])
  (pairs:enjs:format ~[['digest' %s (scot %uv (archive-digest db binding))] ['records' %a records] ['next' ?:((gth (lent ids) (lent page)) (id-json (rear page)) ~)]])
++  retire
  |=  [db=state:hh binding=@t digest=@uvH location=@t now=@da]
  ^-  (each [db=state:hh result=json] @t)
  =/  prior  (skim retirements.db |=(r=retirement:hh &(=(binding binding.r) =(digest digest.r))))
  ?^  prior
    ?.  &(=(digest digest.i.prior) =(location location.i.prior))  [%| 'Conflicting retirement receipt']
    [%& db (pairs:enjs:format ~[['retired' %s binding] ['digest' %s (scot %uv digest)] ['location' %s location]])]
  =/  ready  (archive db binding)
  ?:  ?=(%| -.ready)  ready
  ?.  =(digest (archive-digest db binding))  [%| 'Archive changed; export it again before retiring']
  ?.  &(!=('' location) (lte (met 3 location) 2.048))  [%| 'An archive location is required']
  =/  ids  (binding-ids db binding)
  =.  db
    |-
    ?~  ids  db
    %=  $
      ids  t.ids
      db   db(observations (~(del by observations.db) i.ids), outbox (~(del by outbox.db) i.ids), controls (~(del by controls.db) i.ids))
    ==
  =.  bindings.db  (~(del by bindings.db) binding)
  =?  retired.db  !(generated binding)  (~(put in retired.db) binding)
  =.  retirements.db  [[binding digest location now] (scag (min 127 (lent retirements.db)) retirements.db)]
  [%& db (pairs:enjs:format ~[['retired' %s binding] ['digest' %s (scot %uv digest)] ['location' %s location]])]
++  next
  |=  [db=state:hh sid=session-id:h]
  ^-  (unit input-id:h)
  ?:  (~(has by active.db) sid)  ~
  =/  remaining  queue.db
  |-
  ?~  remaining  ~
  =/  obs  (~(get by observations.db) i.remaining)
  ?~  obs  $(remaining t.remaining)
  =/  cfg  (~(get by bindings.db) binding.u.obs)
  ?~  cfg  $(remaining t.remaining)
  ?.  &(enabled.u.cfg =(sid sid.u.cfg))  $(remaining t.remaining)
  `i.remaining
++  start
  |=  [db=state:hh sid=session-id:h id=input-id:h]
  ^-  state:hh
  =/  obs  (need (~(get by observations.db) id))
  %=  db
    observations  (~(put by observations.db) id obs(phase %running))
    queue         (skip queue.db |=(i=input-id:h =(i id)))
    active        (~(put by active.db) sid id)
  ==
++  finish
  |=  [db=state:hh sid=session-id:h kind=?(%reply %failure %cancelled) body=@t]
  ^-  state:hh
  =/  id  (~(get by active.db) sid)
  ?~  id  db
  =/  obs  (need (~(get by observations.db) u.id))
  =/  cfg  (need (~(get by bindings.db) binding.obs))
  =/  phase=phase:hh  ?:(=(%reply kind) %completed ?:(=(%failure kind) %failed %cancelled))
  =/  pub=publication:hh  [u.id binding.obs hand.cfg address.cfg sid kind body %pending '' '' ~]
  %=  db
    observations  (~(put by observations.db) u.id obs(phase phase))
    active        (~(del by active.db) sid)
    outbox        (~(put by outbox.db) u.id pub)
  ==
++  cancel-queued
  |=  [db=state:hh sid=session-id:h]
  ^-  state:hh
  =/  waiting  queue.db
  |-
  ?~  waiting  db
  =/  id  i.waiting
  =/  obs  (need (~(get by observations.db) id))
  =/  cfg  (need (~(get by bindings.db) binding.obs))
  ?.  =(sid sid.cfg)  $(waiting t.waiting)
  =.  observations.db  (~(put by observations.db) id obs(phase %cancelled))
  =.  queue.db  (skip queue.db |=(i=input-id:h =(i id)))
  $(waiting t.waiting)
++  json-action
  |=  jon=json
  ^-  action:hh
  =,  dejs:format
  =/  id  (cu |=(s=@t (need (slaw %uv s))) so)
  %.  jon
  %-  of
  :~  bind+(ot ~[id+so config+(ot ~[hand+so address+so ['sessionId' so] actors+(ar so) enabled+bo])])
      register+(ot ~[config+(ot ~[hand+so address+so ['sessionId' so] actors+(ar so) enabled+bo])])
      enable+(ot ~[id+so enabled+bo])
      remove+(ot ~[id+so])
      observe+(ot ~[binding+so event+so actor+so text+so])
      claim+(ot ~[hand+so effect+id worker+so])
      receipt+(ot ~[hand+so effect+id worker+so status+json-receipt-status external+so])
      receipt-at+(ot ~[hand+so effect+id worker+so attempt+ni status+json-receipt-status external+so])
      resolve+(ot ~[hand+so effect+id attempt+ni status+json-resolution-status external+so reason+so])
      retry+(ot ~[hand+so effect+id])
      status+(ot ~[binding+so])
      outbox+(ot ~[hand+so])
      publications+(ot ~[hand+so after+(mu id) limit+ni])
      effect+(ot ~[hand+so effect+id])
      health+(ot ~[hand+so])
      archive+(ot ~[binding+so])
      records+(ot ~[binding+so after+(mu id) limit+ni])
      retire+(ot ~[binding+so digest+id location+so])
  ==
++  json-resolution-status
  |=  jon=json
  ^-  ?(%delivered %failed %uncertain %abandoned)
  =/  s  (so:dejs:format jon)
  ?>  ?=(?(%delivered %failed %uncertain %abandoned) s)
  s
++  json-receipt-status
  |=  jon=json
  ^-  ?(%delivered %failed %uncertain)
  =/  s  (so:dejs:format jon)
  ?>  ?=(?(%delivered %failed %uncertain) s)
  s
++  json-request
  =,  dejs:format
  ^-  $-(json request:hh)
  (ot ~[id+so action+json-action])
--
