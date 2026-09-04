::  Versioned, transport-independent conversation hand boundary.
/-  h=harness
|%
+$  binding
  $:  hand=@t
      address=@t
      sid=session-id:h
      actors=(list @t)
      enabled=?
  ==
+$  phase  ?(%queued %running %completed %failed %cancelled)
+$  observation
  $:  binding=@t
      event=@t
      actor=@t
      text=@t
      at=@da
      phase=phase
  ==
+$  delivery-state  ?(%pending %claimed %delivered %failed %uncertain)
+$  receipt  [at=@da status=delivery-state worker=@t external=@t]
+$  publication
  $:  input=input-id:h
      binding=@t
      hand=@t
      address=@t
      sid=session-id:h
      kind=?(%reply %failure %cancelled)
      body=@t
      status=delivery-state
      worker=@t
      external=@t
      receipts=(list receipt)
  ==
+$  state
  $:  bindings=(map @t binding)
      observations=(map input-id:h observation)
      queue=(list input-id:h)
      active=(map session-id:h input-id:h)
      outbox=(map input-id:h publication)
  ==
+$  action
  $%  [%bind id=@t config=binding]
      [%enable id=@t enabled=?]
      [%remove id=@t]
      [%observe binding=@t event=@t actor=@t text=@t]
      [%claim hand=@t effect=input-id:h worker=@t]
      [%receipt hand=@t effect=input-id:h worker=@t status=?(%delivered %failed %uncertain) external=@t]
      [%retry hand=@t effect=input-id:h]
      [%status binding=@t]
      [%outbox hand=@t]
      [%effect hand=@t effect=input-id:h]
  ==
+$  request  [id=@t act=action]
--
