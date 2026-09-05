::  Pure context policy. No provider format, credentials, I/O or scheduler.
::  Encoders supply size estimates; this module chooses immutable source spans.
/-  h=harness
|%
::  Conservative policy, not catalog metadata or an exact tokenizer. Keep
::  response headroom separate from a 10% estimation margin. Small windows
::  scale down; unknown/zero windows cannot admit requests.
++  output-budget
  |=(window=@ud (min 4.096 (div window 4)))
++  input-budget
  |=  window=@ud
  (sub window (add (output-budget window) (div window 10)))
::  There is one model-relative trigger, not a second absolute context cap.
::  Compaction leaves a fraction of that budget as raw recent exchanges, so
::  the next request has room to grow instead of immediately compacting again.
++  tail-budget
  |=(window=@ud (div (input-budget window) 3))
++  source-hash
  |=  [v=view:h count=@ud]
  (sham [summary.v (scag count items.v)])
++  item-bytes
  |=  it=item:h
  ^-  @ud
  ?-  -.it
    %user  (met 3 body.it)
    %tool  (met 3 body.it)
    %assistant
      %+  add  (met 3 body.it)
      %+  roll  calls.it
      |=  [c=tool-call:h n=@ud]
      (add n (met 3 args.c))
  ==
::  Boundaries follow final assistant replies, never an unfinished tool group.
::  Keep the latest complete exchange and the current unanswered input. A
::  single enormous exchange is irreducible until artifact projection exists.
++  boundaries
  |=  items=(list item:h)
  =|  at=@ud
  =|  cuts=(list @ud)
  |-  ^-  (list @ud)
  ?~  items  (flop cuts)
  =?  cuts  ?=([%assistant * ~] i.items)
    [+(at) cuts]
  $(items t.items, at +(at))
::  Walk item sizes once to find the preferred retained-tail boundary. Do not
::  serialize every growing prefix or repeatedly scan every remaining suffix.
++  preferred
  |=  [items=(list item:h) cuts=(list @ud) target=@ud]
  ^-  @ud
  =/  sizes  (turn items item-bytes)
  =/  bytes  (roll sizes add)
  ::  An explicit compact on a short conversation should checkpoint its older
  ::  history, not spend inference on just the first (possibly tiny) exchange.
  ?:  (lte bytes (mul target 4))  (rear cuts)
  =|  at=@ud
  |-  ^-  @ud
  ?>  ?=(^ cuts)
  ?:  =(at i.cuts)
    ?:  |(=(~ t.cuts) (lte bytes (mul target 4)))  at
    $(cuts t.cuts)
  ?>  ?=(^ sizes)
  $(sizes t.sizes, bytes (sub bytes i.sizes), at +(at))
++  plan
  |=  $:  v=view:h
          through=@ud
          command=(unit input-id:h)
          estimate=$-(view:h @ud)
      ==
  ^-  (each compaction-plan:h @t)
  ?:  |(?=(^ pending.v) !=(~ wait.v))
    [%| 'Compaction waits for inference and tools to settle.']
  ?:  (gte compact-attempts.v 4)
    [%| 'Compaction attempt limit reached; change the model or reduce the request.']
  =/  cuts  (boundaries items.v)
  ?:  (lth (lent cuts) 2)
    [%| 'No completed historical exchange can be compacted while preserving the recent turn.']
  =.  cuts  (scag (dec (lent cuts)) cuts)
  =/  limit  (input-budget max-context.config.v)
  =/  goal  (preferred items.v cuts (tail-budget max-context.config.v))
  =.  cuts  (skim cuts |=(cut=@ud (lte cut goal)))
  ::  If the desired source prefix cannot fit, halve the number of complete
  ::  exchanges until it can. This is local planning, not provider retries.
  ::  It avoids a quadratic sequence of ever-larger request encodings.
  |-  ^-  (each compaction-plan:h @t)
  ?>  ?=(^ cuts)
  =/  count  (rear cuts)
  =/  size  (estimate v(items (scag count items.v)))
  ?:  (gth size limit)
    ?~  t.cuts
      [%| 'A complete historical exchange exceeds the compaction input budget.']
    $(cuts (scag (div (lent cuts) 2) `(list @ud)`cuts))
  [%& through count (lent items.v) (source-hash v count) size (output-budget max-context.config.v) url.config.v model.config.v command]
++  validate
  |=  [v=view:h p=compaction-plan:h stop=stop-reason:h it=item:h]
  ^-  (unit @t)
  ?.  =(source.p (source-hash v count.p))
    `'Compaction source coverage changed; the previous context was retained.'
  ?.  &(?=([%assistant * ~] it) =(%stop stop))
    `'Compaction did not return a complete summary; the previous context was retained.'
  ?:  |(=('' body.it) (levy (trip body.it) |=(c=@tD |(=(32 c) =(9 c) =(10 c) =(13 c)))))
    `'Compaction returned an empty summary; the previous context was retained.'
  ::  Reject expansion before the next decision, rather than looping on a
  ::  verbose summary. Request-level fit is checked again with the real codec.
  =/  before=@ud  ?~(summary.v 0 (met 3 u.summary.v))
  =.  before
    %+  roll  (scag count.p items.v)
    |=  [it=item:h bytes=@ud]
    (add bytes (item-bytes it))
  ?:  (gte (met 3 body.it) before)
    `'Compaction did not reduce the context; the previous context was retained.'
  ~
--
