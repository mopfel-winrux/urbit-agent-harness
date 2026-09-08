::  Optional trust-source binding. The peer policy consumes ordinary grants,
::  not Tlon state. Read current trust so removing it leaves no stale grant.
/-  h=harness, t=harness-tlon
/+  p=harness-tlon-policy
|_  =bowl:gall
++  grants
  ^-  (map @p peer-grant:h)
  =/  current  policy
  ?~  current  ~
  (peer-grants:p u.current)
++  owner
  ^-  (unit @p)
  =/  current  policy
  ?~  current  ~
  owner.u.current
++  siblings
  ^-  ?
  =/  base  /(scot %p our.bowl)/harness-tlon/(scot %da now.bowl)
  ?.  .^(? %gu (weld base /$))  |
  =/  status  .^(json %gx (weld base /status/json))
  =/  parsed
    %-  mole  |.
    ((ot:dejs:format ~[['siblingMoonOwners' bo:dejs:format]]) status)
  (fall parsed |)
++  policy
  ^-  (unit policy:t)
  =/  base  /(scot %p our.bowl)/harness-tlon/(scot %da now.bowl)
  ?.  .^(? %gu (weld base /$))  ~
  =/  status  .^(json %gx (weld base /status/json))
  =/  parsed
    %-  mole  |.
    ((ot:dejs:format ~[policy+json-policy:p]) status)
  parsed
--
