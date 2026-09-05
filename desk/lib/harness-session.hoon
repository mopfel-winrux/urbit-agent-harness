::  Pure session services: compose the head with the chosen budget policy and
::  JSON snapshot projection. Gall and the Grubbery verifier share these gates,
::  with no I/O authority or second scheduler.
/-  h=harness
/+  hl=harness, hp=harness-provider, hj=harness-json, failure=harness-failure, context=harness-context
|%
::  Keep provider byte accounting out of the semantic reducer. This gate is
::  evaluated only if replay says inference can run, preserving cheap polls.
++  next
  |=  [v=view:h skills=(map @t skill:h)]
  ^-  (unit step:h)
  ::  The current model's window determines the trigger, including after a
  ::  model switch. Idle polls and tool waits never evaluate the lazy estimate.
  (decide:hl v(max-context.config (input-budget:context max-context.config.v)) |=(~ (est-tokens:hp v skills)))
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
      %checkpoint-completed  &(?=(^ reply.i.prefix) ?=([~ %reply *] (outcome:hl (play:hl prefix))))
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
      ['memory' (memory-json:hj memory.v)]
      ['usage' (pairs:enjs:format ~[['prompt' (numb:enjs:format prompt.total.v)] ['completion' (numb:enjs:format completion.total.v)]])]
      ['compactionUsage' (pairs:enjs:format ~[['prompt' (numb:enjs:format prompt.compact-usage.v)] ['completion' (numb:enjs:format completion.compact-usage.v)]])]
      ['compactions' (numb:enjs:format (lent (skim log.ses |=(e=event:h |(?=(%compaction-completed -.e) ?=(%checkpoint-completed -.e))))))]
      :-  'origin'
      ?~  origin.v  ~
      (pairs:enjs:format ~[['sessionId' %s from.u.origin.v] ['eventCount' (numb:enjs:format at.u.origin.v)]])
      :-  'entries'
      ?:  ?&(?=(^ since) =(u.since revision))  ~
      (transcript-json:hj log.ses)
  ==
--
