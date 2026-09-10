::  Prepared dispatch may reuse compiler work, never validation answers for
::  a different noun or mark. Broken extraction must still fail at use time.
/+  *test, marks
/=  noun-mark  /mar/noun
/=  ud-mark  /mar/ud
|%
++  test-mark-types-and-inputs-stay-independent
  =/  any  (build-marc:marks !>(noun-mark))
  =/  num  (build-marc:marks !>(ud-mark))
  =/  first  (vale:any [1 2])
  =/  second  (vale:num 42)
  =/  bad  (mole |.((vale:num [1 2])))
  =/  again  (vale:any [3 4])
  ;:  weld
    (expect-eq !>([1 2]) !>(q.first))
    (expect-eq !>(42) !>(q.second))
    (expect-eq !>([3 4]) !>(q.again))
    (expect-eq !>(~) !>(bad))
    (expect !>(!=(type:any type:num)))
    (expect-eq !>(p.first) !>(type:any))
    (expect-eq !>(p.second) !>(type:num))
  ==
++  test-broken-mark-extraction-stays-lazy
  =/  source
    |%
    ++  missing  0
    --
  =/  broken  (build-marc:marks !>(source))
  =/  result  (mole |.(vale:broken))
  (expect-eq !>(~) !>(result))
++  test-type-extraction-failure-does-not-discard-validator
  =/  source
    |_  value=*
    ++  grab
      |%
      ++  noun
        |=  data=*
        ?>  ?=(^ data)
        data
      --
    --
  =/  compiled  (build-marc:marks !>(source))
  =/  result  (vale:compiled [1 2])
  =/  bad-type  (mole |.(type:compiled))
  ;:  weld
    (expect-eq !>([1 2]) !>(q.result))
    (expect-eq !>(~) !>(bad-type))
  ==
--
