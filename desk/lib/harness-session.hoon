::  Pure session services: compose the head with the chosen budget policy and
::  JSON snapshot projection. Gall and the Grubbery verifier share these gates,
::  with no I/O authority or second scheduler.
/-  h=harness
/+  hl=harness, hp=harness-provider, hj=harness-json, failure=harness-failure
|%
::  Keep provider byte accounting out of the semantic reducer. This gate is
::  evaluated only if replay says inference can run, preserving cheap polls.
++  next
  |=  [v=view:h skills=(map @t skill:h)]
  ^-  (unit step:h)
  (decide:hl v |=(~ (est-tokens:hp v skills)))
++  inspect
  |=  [ses=session:h skills=(map @t skill:h)]
  ^-  [revision=@ud view=view:h next=(unit step:h)]
  =/  view  (play:hl log.ses)
  [(lent log.ses) view (next view skills)]
++  branch
  |=  [from=session-id:h ses=session:h at=@ud]
  ^-  (each session:h @t)
  ?.  &((gth at 0) (lte at (lent log.ses)))
    [%| 'Invalid branch point']
  ::  Retain the noun tail directly; no serialization or history rewriting.
  =/  prefix  (slag (sub (lent log.ses) at) log.ses)
  =/  complete=?
    ?~  prefix  |
    ?+  -.i.prefix  |
      %command-completed  &
      %llm-completed      ?=([%assistant * ~] item.i.prefix)
    ==
  ?.  complete  [%| 'Branch after a completed assistant reply']
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
      ['failure' ?~(err.v ~ (json:failure u.err.v))]
      ['model' %s model.config.v]
      ['usage' (pairs:enjs:format ~[['prompt' (numb:enjs:format prompt.total.v)] ['completion' (numb:enjs:format completion.total.v)]])]
      ['compactions' (numb:enjs:format (lent (skim log.ses |=(e=event:h ?=(%compaction-completed -.e)))))]
      :-  'origin'
      ?~  origin.v  ~
      (pairs:enjs:format ~[['sessionId' %s from.u.origin.v] ['eventCount' (numb:enjs:format at.u.origin.v)]])
      :-  'entries'
      ?:  ?&(?=(^ since) =(u.since revision))  ~
      (transcript-json:hj log.ses)
  ==
--
