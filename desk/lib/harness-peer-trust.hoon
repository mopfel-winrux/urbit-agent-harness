::  Optional trust-source binding. The peer policy consumes ordinary grants,
::  not Tlon state. Read current trust so removing it leaves no stale grant.
/-  h=harness
/+  p=harness-tlon-policy
|_  =bowl:gall
++  grants
  ^-  (map @p peer-grant:h)
  =/  base  /(scot %p our.bowl)/harness-tlon/(scot %da now.bowl)
  ?.  .^(? %gu (weld base /$))  ~
  =/  status  .^(json %gx (weld base /status/json))
  =/  parsed
    %-  mole  |.
    ((ot:dejs:format ~[policy+json-policy:p]) status)
  ?~  parsed  ~
  (peer-grants:p u.parsed)
--
