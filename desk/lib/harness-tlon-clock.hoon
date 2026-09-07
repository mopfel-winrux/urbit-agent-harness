::  Maintenance and bounded Activity catch-up only. Publication retries never
::  create timers: native head invalidations and receipts drive delivery.
/-  t=harness-tlon, cr=harness-cron
|%
++  deadline
  |=  [now=@da state=state:t]
  ^-  (unit @da)
  ?.  enabled.policy.state  ~
  =/  times=(list @da)
    %+  weld
      (turn ~(val by computing.state) |=(lease=presence-lease:t (add at.lease ~s10)))
    %+  weld
      (murn ~(val by tool-receipts.state) |=(r=tool-receipt:t ?:(=(%sending stage.r) `(add at.r ~m1) ~)))
    (murn ~(val by cron.state) |=(j=job:cr ?:(=(%active state.j) `next.j ~)))
  =?  times  !watching.state  [(add now ~s2) times]
  =?  times  catching-up.state  [(add now ~s1) times]
  ?~  times  ~
  =/  earliest=@da
    =/  least  i.times
    =/  rest  t.times
    |-
    ?~  rest  least
    $(least (min least i.rest), rest t.rest)
  `(max (add now ~s1) earliest)
--
