::  Pure binding, admission, and delivery bookkeeping. No transport or scheduler.
/-  h=harness, hh=harness-hand
|%
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
  |=  [id=input-id:h pub=publication:hh]
  ^-  json
  %-  pairs:enjs:format
  :~  ['version' (numb:enjs:format 1)]
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
  ?:  =(%delivered status.pub)  ~
  =/  cfg  (~(get by bindings.db) binding.pub)
  ?~  cfg  ~
  ?.  enabled.u.cfg  ~
  `(publication-json id pub)
++  claim-json
  |=  [id=input-id:h pub=publication:hh acquired=?]
  ^-  json
  =/  jon  (publication-json id pub)
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
      %bind
    ?.  &(!=('' id.act) !=('' hand.config.act) !=('' address.config.act) !=(~ actors.config.act))
      [%| 'Binding, hand, address, and an explicit actor allowlist are required']
    =/  existing  (~(get by bindings.db) id.act)
    ?^  existing
      ?.  =(u.existing config.act)  [%| 'Binding identities are immutable; use a new id']
      [%& db (status-json db id.act)]
    ?:  (lien ~(val by observations.db) |=(obs=observation:hh =(binding.obs id.act)))
      [%| 'Retired binding ids cannot be reused']
    ?:  (gte (lent ~(tap by bindings.db)) 256)  [%| 'Binding limit reached']
    =.  bindings.db  (~(put by bindings.db) id.act config.act)
    [%& db (status-json db id.act)]
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
    ?:  (lien ~(val by observations.db) |=(obs=observation:hh &(=(binding.obs id.act) ?=(?(%queued %running) phase.obs))))
      [%| 'Binding still has work; cancel or finish it first']
    ?:  (lien ~(val by outbox.db) |=(pub=publication:hh &(=(binding.pub id.act) !=(%delivered status.pub))))
      [%| 'Binding has unsettled publications']
    =.  bindings.db  (~(del by bindings.db) id.act)
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
    =/  obs=observation:hh  [binding.act event.act actor.act text.act now %queued]
    =.  observations.db  (~(put by observations.db) id obs)
    =.  queue.db  (snoc queue.db id)
    [%& db (admission-json id obs)]
  ::
      %claim
    =/  pub  (~(get by outbox.db) effect.act)
    ?~  pub  [%| 'Unknown effect']
    ?.  &(=(hand.act hand.u.pub) !=('' worker.act))  [%| 'Wrong hand or missing worker identity']
    =/  cfg  (~(get by bindings.db) binding.u.pub)
    ?.  ?&(?=(^ cfg) enabled.u.cfg)  [%| 'Binding is disabled']
    ?.  |(=(%pending status.u.pub) &(=(%claimed status.u.pub) =(worker.act worker.u.pub)))
      [%| 'Effect is not available to this worker']
    ?:  =(%claimed status.u.pub)  [%& db (claim-json effect.act u.pub %.n)]
    =.  u.pub  u.pub(status %claimed, worker worker.act, receipts [[now %claimed worker.act ''] receipts.u.pub])
    =.  outbox.db  (~(put by outbox.db) effect.act u.pub)
    [%& db (claim-json effect.act u.pub %.y)]
  ::
      %receipt
    =/  pub  (~(get by outbox.db) effect.act)
    ?~  pub  [%| 'Unknown effect']
    ?.  &(=(hand.act hand.u.pub) !=('' worker.act) =(worker.act worker.u.pub))
      [%| 'Receipt does not match the claiming hand and worker']
    ?:  =(status.act status.u.pub)
      ?.  =(external.act external.u.pub)  [%| 'Conflicting receipt']
      [%& db (publication-json effect.act u.pub)]
    ?.  ?=(?(%claimed %uncertain) status.u.pub)  [%| 'Effect cannot accept this receipt']
    =/  value=publication:hh  u.pub
    =.  value  value(status status.act, external external.act, receipts [[now status.act worker.act external.act] receipts.value])
    =.  outbox.db  (~(put by outbox.db) effect.act value)
    [%& db (publication-json effect.act value)]
  ::
      %retry
    =/  pub  (~(get by outbox.db) effect.act)
    ?~  pub  [%| 'Unknown effect']
    ?.  &(=(hand.act hand.u.pub) =(%failed status.u.pub))
      [%| 'Only a confirmed failed delivery may be retried; reconcile uncertain outcomes first']
    =.  u.pub  u.pub(status %pending, worker '', external '', receipts [[now %pending '' ''] receipts.u.pub])
    =.  outbox.db  (~(put by outbox.db) effect.act u.pub)
    [%& db (publication-json effect.act u.pub)]
  ::
      %status
    ?.  (~(has by bindings.db) binding.act)  [%| 'Unknown binding']
    [%& db (status-json db binding.act)]
  ::
      %outbox
    [%& db (outbox-json db hand.act)]
  ::
      %effect
    =/  pub  (~(get by outbox.db) effect.act)
    ?~  pub  [%| 'Unknown effect']
    ?.  =(hand.act hand.u.pub)  [%| 'Wrong hand']
    [%& db (publication-json effect.act u.pub)]
  ==
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
      enable+(ot ~[id+so enabled+bo])
      remove+(ot ~[id+so])
      observe+(ot ~[binding+so event+so actor+so text+so])
      claim+(ot ~[hand+so effect+id worker+so])
      receipt+(ot ~[hand+so effect+id worker+so status+json-receipt-status external+so])
      retry+(ot ~[hand+so effect+id])
      status+(ot ~[binding+so])
      outbox+(ot ~[hand+so])
      effect+(ot ~[hand+so effect+id])
  ==
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
