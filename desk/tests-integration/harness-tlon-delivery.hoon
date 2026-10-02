::  Full adapter acknowledgement handling; emitted Messenger cards never run.
/-  t=harness-tlon, hh=harness-hand
/+  *test
/=  adapter  /app/harness-tlon
|%
++  acknowledge
  |=  [address=@t attempt=@ud rejected=?]
  ^-  [deliveries=(map @uv delivery:t) receipts=(list action:hh)]
  =/  bowl=bowl:gall  *bowl:gall
  =.  bowl  bowl(our ~zod, src ~zod, now ~2026.10.1)
  =/  saved=state-1:t  *state-1:t
  =.  saved
    saved(owner-initialized 1, enabled.policy |, deliveries (my ~[[0v1 [7 %send %uncertain 'external']]]))
  =/  ledger=state:hh  *state:hh
  =.  outbox.ledger
    (my ~[[0v1 [0v1 'binding' 'tlon' address 'conversation' %reply 'Hello' %claimed 'harness-tlon' 'external' ~]]])
  =/  attempt-gate
    |.
    =/  loaded  (~(on-load adapter bowl) !>(saved))
    =/  sign=sign:agent:gall  [%poke-ack ?:(rejected `~ ~)]
    =/  result
      (~(on-agent +.loaded bowl) /publish/0v1/(scot %ud attempt) sign)
    =/  retained  !<(state-1:t ~(on-save +.result bowl))
    =/  receipts
      %+  murn  -.result
      |=  card=card:agent:gall
      ^-  (unit action:hh)
      ?.  ?=([%pass * %agent * %poke %harness-hand *] card)  ~
      =/  [pass=* wire=* agent=* who=* poke=* mark=* data=vase]  card
      =/  request  !<(request:hh data)
      `act.request
    [deliveries.retained receipts]
  =/  checked
    %+  mink  [attempt-gate %9 2 %0 1]
    |=  [ref=* raw=*]
    ^-  (unit (unit noun))
    =/  path  ;;(path raw)
    ?:  (lien path |=(part=@ta =(%hand-state part)))  ``ledger
    ``%.n
  ?>  ?=(%0 -.checked)
  ;;([deliveries=(map @uv delivery:t) receipts=(list action:hh)] product.checked)
::
++  test-channel-ack-waits-for-host-confirmation
  =/  result  (acknowledge 'chat/~zod/channel' 7 |)
  ;:  weld
    (expect-eq !>(`delivery:t`[7 %send %uncertain 'external']) !>((~(got by deliveries.result) 0v1)))
    (expect-eq !>(~) !>(receipts.result))
  ==
::
++  test-dm-ack-and-rejection-record-only-the-current-attempt
  =/  accepted  (acknowledge 'dm/~nec' 7 |)
  =/  rejected  (acknowledge 'chat/~zod/channel' 7 &)
  =/  stale  (acknowledge 'dm/~nec' 6 |)
  ;:  weld
    (expect-eq !>(`delivery:t`[7 %receipt %delivered 'external']) !>((~(got by deliveries.accepted) 0v1)))
    (expect-eq !>(`delivery:t`[7 %receipt %failed 'external']) !>((~(got by deliveries.rejected) 0v1)))
    (expect-eq !>(`(list action:hh)`~[[%receipt-at 'tlon' 0v1 'harness-tlon' 7 %delivered 'external']]) !>(receipts.accepted))
    (expect-eq !>(`(list action:hh)`~[[%receipt-at 'tlon' 0v1 'harness-tlon' 7 %failed 'external']]) !>(receipts.rejected))
    (expect-eq !>(`delivery:t`[7 %send %uncertain 'external']) !>((~(got by deliveries.stale) 0v1)))
    (expect-eq !>(~) !>(receipts.stale))
  ==
--
