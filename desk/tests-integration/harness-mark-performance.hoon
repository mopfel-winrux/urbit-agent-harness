::  Mark dispatch is pure in the compiled source, not in runtime state.
/+  *test, marks, tarball
/=  noun-mark  /mar/noun
|%
++  legacy-marc
  |=  cor=vase
  ^-  marc:tarball
  |%
  ++  type  p:(vale +6.q.cor)
  ++  vale  (build-vale:marks cor)
  ++  grow  (build-grow:marks cor)
  ++  grab  (build-grab:marks cor)
  --
++  run
  |=  marc=marc:tarball
  ^-  @ud
  =/  left=@ud  100
  =|  count=@ud
  |-  ^-  @ud
  ?:  =(0 left)  count
  =/  gat  (mule |.(vale.marc))
  =/  typ  (mule |.(type.marc))
  ?>  &(?=(%& -.gat) ?=(%& -.typ))
  =/  got=vase  (p.gat left)
  ?>  =(p.got p.typ)
  ?>  =(q.got left)
  $(left (dec left), count (add count left))
++  test-repeated-mark-dispatch
  =/  marc  (build-marc:marks !>(noun-mark))
  =/  legacy  (legacy-marc !>(noun-mark))
  =/  before
    ~>(%bout.[1 'perf-mark-legacy-dispatch-100'] (run legacy))
  =/  after
    ~>(%bout.[1 'perf-mark-prepared-dispatch-100'] (run marc))
  ;:  weld
    (expect-eq !>(5.050) !>(before))
    (expect-eq !>(before) !>(after))
  ==
--
