/-  t=harness-tlon, h=harness
/+  *test, trust=harness-peer-trust
|%
++  read
  |=  [present=? policy=policy:t siblings=?]
  ^-  [policy=policy:t siblings=?]
  =/  bowl=bowl:gall  *bowl:gall
  =.  our.bowl  ~zod
  =.  now.bowl  ~2026.9.8
  =/  attempt  |.(snapshot:~(. trust bowl))
  =/  out
    %+  mink  [attempt %9 2 %0 1]
    |=  [ref=* raw=*]
    ^-  (unit (unit noun))
    =/  path  ;;(path raw)
    ?:  =(%$ (rear path))  ``present
    ::  Any status/cron/ledger read fails the test instead of being stubbed.
    ?.  =(/peer-trust/noun (slag 4 path))  ~
    ``[policy siblings]
  ?>  ?=(%0 -.out)
  ;;([policy=policy:t siblings=?] product.out)
++  test-trust-read-does-not-render-adapter-status
  =/  policy=policy:t  [| `~nec (my ~[[~bud ~[%web]]]) &]
  (expect-eq !>([policy &]) !>((read & policy &)))
++  test-absent-adapter-grants-no-authority
  (expect-eq !>([[| ~ ~ &] |]) !>((read | [& `~nec ~ &] &)))
++  test-owner-and-sibling-revocations-are-read-live
  ;:  weld
    (expect-eq !>([[| `~nec ~ &] &]) !>((read & [| `~nec ~ &] &)))
    (expect-eq !>([[| ~ ~ &] |]) !>((read & [| ~ ~ &] |)))
  ==
--
