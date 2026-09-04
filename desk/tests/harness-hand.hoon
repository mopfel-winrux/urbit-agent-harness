/-  h=harness, hh=harness-hand
/+  *test, hd=harness-hand
|%
++  seed
  ^-  state:hh
  =/  cfg=binding:hh  ['chat' 'opaque/thread' 'session' ~['alice'] %.y]
  =/  res  (apply:hd *state:hh [%bind 'binding' cfg] ~2000.1.1)
  ?>  ?=(%& -.res)
  db.p.res
++  admitted
  ^-  state:hh
  =/  res  (apply:hd seed [%observe 'binding' 'message-1' 'alice' 'Hello'] ~2000.1.1)
  ?>  ?=(%& -.res)
  db.p.res
++  id  (input-id:hd 'binding' 'message-1')
++  completed
  ^-  state:hh
  (finish:hd (start:hd admitted 'session' id) 'session' %reply 'The answer')
++  claimed
  ^-  state:hh
  =/  res  (apply:hd completed [%claim 'chat' id 'worker-1'] ~2000.1.1)
  ?>  ?=(%& -.res)
  db.p.res
++  test-deduplicates-source-events
  =/  res  (apply:hd admitted [%observe 'binding' 'message-1' 'alice' 'Hello'] ~2000.1.2)
  ?>  ?=(%& -.res)
  (expect-eq !>(admitted) !>(db.p.res))
++  test-rejects-conflicting-replays
  =/  res  (apply:hd admitted [%observe 'binding' 'message-1' 'alice' 'Different'] ~2000.1.1)
  (expect !>(?=(%| -.res)))
++  test-rejects-ungranted-actors
  =/  res  (apply:hd seed [%observe 'binding' 'message-1' 'mallory' 'Hello'] ~2000.1.1)
  (expect !>(?=(%| -.res)))
++  test-one-active-input-per-session
  =/  running  (start:hd admitted 'session' id)
  (expect !>(&(=(`id (next:hd admitted 'session')) =(~ (next:hd running 'session')) =(~ (next:hd admitted 'elsewhere')))))
++  test-reply-is-separate-from-delivery
  =/  db  completed
  =/  pub  (need (~(get by outbox.db) id))
  =/  obs  (need (~(get by observations.db) id))
  (expect !>(&(=(%completed phase.obs) =(%pending status.pub) =('The answer' body.pub) =('opaque/thread' address.pub) =(~ active.db))))
++  test-claim-is-exclusive
  =/  other  (apply:hd claimed [%claim 'chat' id 'worker-2'] ~2000.1.1)
  =/  again  (apply:hd claimed [%claim 'chat' id 'worker-1'] ~2000.1.2)
  ?>  ?=(%& -.again)
  (expect !>(&(?=(%| -.other) =(claimed db.p.again))))
++  test-receipts-are-idempotent-and-terminal
  =/  done  (apply:hd claimed [%receipt 'chat' id 'worker-1' %delivered 'external-1'] ~2000.1.1)
  ?>  ?=(%& -.done)
  =/  again  (apply:hd db.p.done [%receipt 'chat' id 'worker-1' %delivered 'external-1'] ~2000.1.2)
  ?>  ?=(%& -.again)
  =/  conflict  (apply:hd db.p.done [%receipt 'chat' id 'worker-1' %failed ''] ~2000.1.2)
  (expect !>(&(=(db.p.done db.p.again) ?=(%| -.conflict))))
++  test-uncertain-delivery-cannot-be-retried
  =/  unknown  (apply:hd claimed [%receipt 'chat' id 'worker-1' %uncertain ''] ~2000.1.1)
  ?>  ?=(%& -.unknown)
  =/  again  (apply:hd db.p.unknown [%retry 'chat' id] ~2000.1.2)
  (expect !>(?=(%| -.again)))
++  test-delivery-retry-does-not-requeue-inference
  =/  baseline  completed
  =/  failed  (apply:hd claimed [%receipt 'chat' id 'worker-1' %failed ''] ~2000.1.1)
  ?>  ?=(%& -.failed)
  =/  again  (apply:hd db.p.failed [%retry 'chat' id] ~2000.1.2)
  ?>  ?=(%& -.again)
  (expect !>(&(=(~ queue.db.p.again) =(~ active.db.p.again) =(observations.baseline observations.db.p.again))))
++  test-disable-hides-undelivered-output
  =/  disabled  (apply:hd completed [%enable 'binding' %.n] ~2000.1.1)
  ?>  ?=(%& -.disabled)
  (expect-eq !>(`json`[%a ~]) !>((outbox-json:hd db.p.disabled 'chat')))
++  test-cancel-removes-queued-work
  =/  cancelled  (cancel-queued:hd admitted 'session')
  =/  obs  (need (~(get by observations.cancelled) id))
  (expect !>(&(=(~ queue.cancelled) =(%cancelled phase.obs))))
++  test-source-ids-are-namespaced
  (expect !>(!=((input-id:hd 'binding' 'message-1') (input-id:hd 'elsewhere' 'message-1'))))
++  test-disabled-binding-cannot-claim
  =/  disabled  (apply:hd completed [%enable 'binding' %.n] ~2000.1.1)
  ?>  ?=(%& -.disabled)
  =/  res  (apply:hd db.p.disabled [%claim 'chat' id 'worker-1'] ~2000.1.1)
  (expect !>(?=(%| -.res)))
++  test-unsettled-bindings-cannot-be-removed
  =/  queued  (apply:hd admitted [%remove 'binding'] ~2000.1.1)
  =/  pending  (apply:hd completed [%remove 'binding'] ~2000.1.1)
  (expect !>(&(?=(%| -.queued) ?=(%| -.pending))))
++  test-binding-destination-is-immutable
  =/  cfg=binding:hh  ['chat' 'different/thread' 'session' ~['alice'] %.y]
  =/  res  (apply:hd seed [%bind 'binding' cfg] ~2000.1.1)
  (expect !>(?=(%| -.res)))
++  test-failed-work-still-has-a-publication
  =/  db  (finish:hd (start:hd admitted 'session' id) 'session' %failure 'Work failed.')
  =/  pub  (need (~(get by outbox.db) id))
  =/  obs  (need (~(get by observations.db) id))
  (expect !>(&(=(%failed phase.obs) =(%failure kind.pub) =(%pending status.pub))))
--
