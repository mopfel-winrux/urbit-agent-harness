::  Strict five-field UTC cron. Pure calendar logic, no timers or inference.
/-  c=harness-cron
|%
++  split
  |=  [text=@t delimiter=@t]
  ^-  (list @t)
  =/  chars  (trip text)
  =/  out=(list @t)  ~
  =/  part=tape  ~
  |-
  ?~  chars  (flop [(crip (flop part)) out])
  ?:  =(i.chars delimiter)
    $(chars t.chars, part ~, out [(crip (flop part)) out])
  $(chars t.chars, part [i.chars part])
++  number
  |=  txt=@t
  ^-  @ud
  ?>  &(!=('' txt) (lte (met 3 txt) 3))
  (need (rush txt dem))
++  field
  |=  [txt=@t lo=@ud hi=@ud]
  ^-  (set @ud)
  =/  entries  (split txt ',')
  ?>  (lte (lent entries) 60)
  %+  roll  entries
  |=  [entry=@t out=(set @ud)]
  =/  steps  (split entry '/')
  ?>  ?=(^ steps)
  ?>  |(=(1 (lent steps)) =(2 (lent steps)))
  =/  step=@ud  ?~(t.steps 1 (number i.t.steps))
  ?>  &((gth step 0) (lte step (add 1 (sub hi lo))))
  =/  range=[first=@ud last=@ud]
    ?:  =('*' i.steps)  [lo hi]
    =/  parts  (split i.steps '-')
    ?>  ?=(^ parts)
    ?>  |(=(1 (lent parts)) =(2 (lent parts)))
    =/  first  (number i.parts)
    =/  last  ?~(t.parts ?~(t.steps first hi) (number i.t.parts))
    [first last]
  ?>  &((gte first.range lo) (lte last.range hi) (lte first.range last.range))
  =/  at  first.range
  |-
  ?:  (gth at last.range)  out
  $(at (add at step), out (~(put in out) at))
++  parse
  |=  expr=@t
  ^-  pattern:c
  ?>  (lte (met 3 expr) 128)
  =/  fields  (skip (split expr ' ') |=(f=@t =('' f)))
  ?>  =(5 (lent fields))
  :*  (field (snag 0 fields) 0 59)
      (field (snag 1 fields) 0 23)
      (field (snag 2 fields) 1 31)
      (field (snag 3 fields) 1 12)
      (field (snag 4 fields) 0 6)
      =('*' (snag 2 fields))
      =('*' (snag 4 fields))
  ==
++  day-matches
  |=  [p=pattern:c day=@da]
  ^-  ?
  ?.  (gte day ~2000.1.1)  |
  =/  d  (yore day)
  ?.  (~(has in months.p) m.d)  |
  =/  dom  (~(has in days.p) d.t.d)
  =/  dow  (~(has in weekdays.p) (mod (add 6 (div (sub day ~2000.1.1) ~d1)) 7))
  ::  Traditional cron: restricted day-of-month and day-of-week are ORed.
  ?:  any-day.p  dow
  ?:  any-weekday.p  dom
  |(dom dow)
++  next
  |=  [p=pattern:c after=@da]
  ^-  (unit @da)
  ?.  (gte after ~2000.1.1)  ~
  =/  d  (yore after)
  =.  h.t.d  0
  =.  m.t.d  0
  =.  s.t.d  0
  =.  f.t.d  ~
  =/  day  (year d)
  =/  slots=(list @ud)
    %+  skim  (gulf 0 1.439)
    |=  minute=@ud
    &((~(has in hours.p) (div minute 60)) (~(has in minutes.p) (mod minute 60)))
  =/  tries  0
  |-
  ::  Day skipping bounds work even for impossible dates. Four years permit
  ::  ordinary leap-day schedules; no minute-by-minute year-long loop.
  ?:  =(1.461 tries)  ~
  =/  found=(unit @da)
    ?.  (day-matches p day)  ~
    =/  remaining  slots
    |-
    ?~  remaining  ~
    =/  at=@da  (add day (mul i.remaining ~m1))
    ?:  (gth at after)  `at
    $(remaining t.remaining)
  ?^  found  found
  $(tries +(tries), day (add day ~d1))
++  event
  |=  [id=@uv at=@da]
  ^-  @t
  (rap 3 'cron/' (scot %uv id) '/' (scot %da at) ~)
--
