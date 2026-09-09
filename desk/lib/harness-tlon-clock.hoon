::  Maintenance and bounded Activity catch-up only. Publication retries never
::  create timers: native head invalidations and receipts drive delivery.
/-  t=harness-tlon
|%
++  deadline
  |=  [now=@da state=state:t]
  ^-  (unit @da)
  =/  times=(list @da)
    %+  weld
      ?:(enabled.policy.state (turn ~(val by computing.state) |=(lease=presence-lease:t (add at.lease ~s10))) ~)
      (murn ~(val by tool-receipts.state) |=(r=tool-receipt:t ?:(=(%sending stage.r) `(add at.r ~m1) ~)))
  =?  times  &(enabled.policy.state !watching.state)  [(add now ~s2) times]
  =?  times  &(enabled.policy.state catching-up.state)  [(add now ~s1) times]
  ?~  times  ~
  =/  earliest=@da
    =/  least  i.times
    =/  rest  t.times
    |-
    ?~  rest  least
    $(least (min least i.rest), rest t.rest)
  `(max (add now ~s1) earliest)
--
