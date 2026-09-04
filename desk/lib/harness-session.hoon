::  Transport-independent session operations. Both Gall and Grubbery hands
::  can use these gates without acquiring I/O authority or a second scheduler.
/-  h=harness
/+  hl=harness
|%
++  inspect
  |=  [ses=session:h skills=(map @t skill:h)]
  ^-  [revision=@ud view=view:h next=(unit step:h)]
  =/  view  (play:hl log.ses)
  [(lent log.ses) view (decide:hl view skills)]
++  branch
  |=  [from=session-id:h ses=session:h at=@ud]
  ^-  (each session:h @t)
  ?.  &((gth at 0) (lte at (lent log.ses)))
    [%| 'Invalid branch point']
  ::  Retain the noun tail directly; no serialization or history rewriting.
  =/  prefix  (slag (sub (lent log.ses) at) log.ses)
  ?.  ?=([[%llm-completed *] *] prefix)
    [%| 'Branch after a completed assistant reply']
  ?.  ?=([%assistant * ~] item.i.prefix)
    [%| 'Finish the tool exchange before branching']
  [%& [[%forked from at ~ ~] prefix] next-req.ses]
++  snapshot
  |=  [ses=session:h since=(unit @ud)]
  ^-  json
  =/  revision=@ud  (lent log.ses)
  =/  v  (play:hl log.ses)
  =/  phase=@t
    ?^  pending.v  ?:(=(%compaction kind.u.pending.v) 'compacting' 'thinking')
    ?:  !=(~ wait.v)  'tools'
    ?^  err.v  'error'
    'idle'
  %-  pairs:enjs:format
  :~  ['revision' (numb:enjs:format revision)]
      ['phase' %s phase]
      ['error' ?~(err.v ~ [%s u.err.v])]
      ['model' %s model.config.v]
      ['usage' (pairs:enjs:format ~[['prompt' (numb:enjs:format prompt.total.v)] ['completion' (numb:enjs:format completion.total.v)]])]
      ['compactions' (numb:enjs:format (lent (skim log.ses |=(e=event:h ?=(%compaction-completed -.e)))))]
      :-  'origin'
      ?~  origin.v  ~
      (pairs:enjs:format ~[['sessionId' %s from.u.origin.v] ['eventCount' (numb:enjs:format at.u.origin.v)]])
      :-  'entries'
      ?:  ?&(?=(^ since) =(u.since revision))  ~
      (transcript-json:hl log.ses)
  ==
--
