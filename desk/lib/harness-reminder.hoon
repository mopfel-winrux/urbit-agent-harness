::  One-shot civil time with an explicit UTC offset. No guessed timezone or
::  recurring local-time rule; ambiguous/missing offsets are rejected.
|%
++  parse
  |=  [text=@t now=@da]
  ^-  [at=@da timezone=@t]
  =/  size  (met 3 text)
  ?>  |(=(20 size) =(25 size))
  =/  part  |=([at=@ud len=@ud] (cut 3 [at len] text))
  ?>  ?&  =('-' (part 4 1))  =('-' (part 7 1))
          =('T' (part 10 1))  =(':' (part 13 1))  =(':' (part 16 1))
      ==
  =/  number
    |=  [at=@ud len=@ud]
    (need (rush (part at len) dem))
  =/  y  (number 0 4)
  =/  m  (number 5 2)
  =/  d  (number 8 2)
  =/  h  (number 11 2)
  =/  minute  (number 14 2)
  =/  s  (number 17 2)
  ?>  ?&((gte y 2.000) (lte y 9.999) (gte m 1) (lte m 12) (gte d 1) (lte d 31) (lth h 24) (lth minute 60) (lth s 60))
  =/  dt  (yore ~2000.1.1)
  =.  dt  dt(y y, m m, d.t d, h.t h, m.t minute, s.t s)
  =/  at  (year dt)
  ?>  =(dt (yore at))
  =/  zone  (part 19 (sub size 19))
  =/  offset=@dr
    ?:  =('Z' zone)  ~s0
    ?>  =(25 size)
    ?>  ?&(|(=('+' (part 19 1)) =('-' (part 19 1))) =(':' (part 22 1)) !=('-00:00' zone))
    =/  hours  (number 20 2)
    =/  minutes  (number 23 2)
    ?>  &((lte hours 14) (lth minutes 60))
    ?>  |((lth hours 14) =(minutes 0))
    (add (mul hours ~h1) (mul minutes ~m1))
  =.  at  ?:(=('-' (part 19 1)) (add at offset) (sub at offset))
  ?>  &((gth at now) (lte at (add now ~d365)))
  [at ?:(=('Z' zone) 'UTC' (cat 3 'UTC' zone))]
--
