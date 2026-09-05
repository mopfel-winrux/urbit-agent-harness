::  The deterministic head: replay, transcript, continuation and loop guards.
::  This module depends only on the Harness noun vocabulary. It knows no JSON,
::  provider, credential, client, Gall bowl, or executor implementation.
::  +decide returns an intention; it never performs the intended operation.
::
/-  h=harness
|%
::  +play: fold the event log (newest first) into a view
::
++  play
  |=  log=(list event:h)
  ^-  view:h
  ::  Accumulate newest first, reversing once instead of copying every prefix.
  =/  reversed
    %+  roll  (flop log)
    |=  [e=event:h v=view:h]
    ^-  view:h
    ?-  -.e
      ::  Editing policy is not permission to restart a failed request.
      %config-replaced       v(config config.e)
      %input-admitted        v(items [item.e items.v], err ~, cancelled ~, compact-attempts 0)
      %input-received        v(items [item.input.e items.v], err ~, cancelled ~, compact-attempts 0)
      %command-completed    v(items [[%assistant body.e ~] items.v])
      %memory-set           v(memory ?~(body.e (~(del by memory.v) name.e) (~(put by memory.v) name.e u.body.e)))
      ::  A recorded request is an admitted continuation. Clearing the error
      ::  here also keeps already-recorded config/retry exchanges replayable.
      %llm-requested         v(pending `[req.e kind.e], err ~)
      %llm-failed            v(pending ~, compaction ~, err `err.e)
      %tool-requested        v(wait (~(put in wait.v) call-id.e))
      %retried               v(err ~, cancelled ~)
      %halted                v(pending ~, err `reason.e)
      %forked                v(pending ~, compaction ~, wait ~, cancelled ~, origin `[from.e at.e])
      %compaction-planned    v(pending `[req.e %compaction], compaction `plan.e, err ~, compact-attempts +(compact-attempts.v))
    ::  Results cannot revive a cancelled or superseded checkpoint, even when
    ::  replayed independently of Gall. The plan fixes the cut before dispatch.
        %checkpoint-completed
      ?.  =(pending.v `[req.e %compaction])  v
      ?~  compaction.v  v
      =/  p  u.compaction.v
      ?.  =(source.p (sham [summary.v (scag count.p (flop items.v))]))  v
      =/  tail=(list item:h)  (slag count.p (flop items.v))
      ::  A manual command's reply belongs at its admitted boundary. Native
      ::  input arriving during summary execution stays after it and still
      ::  needs inference; the acknowledgement must not swallow that input.
      =?  tail  ?=(^ reply.e)
        =/  at  (sub length.p count.p)
        (weld (scag at tail) [`item:h`[%assistant body.u.reply.e ~] (slag at tail)])
      %=  v
        pending  ~
        summary  `summary.e
        items  (flop tail)
        compaction  ~
        compact-usage  [(add prompt.compact-usage.v prompt.usage.e) (add completion.compact-usage.v completion.usage.e)]
        total  [(add prompt.total.v prompt.usage.e) (add completion.total.v completion.usage.e)]
      ==
        %compaction-failed
      ?.  =(pending.v `[req.e %compaction])  v
      %=  v
        pending  ~
        compaction  ~
        err  `err.e
        compact-usage  [(add prompt.compact-usage.v prompt.usage.e) (add completion.compact-usage.v completion.usage.e)]
        total  [(add prompt.total.v prompt.usage.e) (add completion.total.v completion.usage.e)]
      ==
    ::  Cancellation closes the provider exchange as well as the wait set.
    ::  These are cancellation receipts, never claims of external rollback.
    ::  Interpreting the event keeps existing logs intact and replayable.
    ::
        %cancelled
      %=  v
        pending    ~
        compaction  ~
        wait       ~
        cancelled  `reason.e
        items      (weld (flop (cancel-results (flop items.v) reason.e)) items.v)
      ==
    ::
        %tool-completed
      %=  v
        wait   (~(del in wait.v) call-id.e)
        items  [[%tool call-id.e name.e body.e] items.v]
      ==
    ::
        %llm-completed
      %=  v
        pending  ~
        items    [item.e items.v]
        total    :-  (add prompt.total.v prompt.usage.e)
                 (add completion.total.v completion.usage.e)
      ==
    ::
        %compaction-completed
      %=  v
        pending  ~
        summary  `summary.e
        items    (flop (retained (flop items.v)))
      ==
    ==
  reversed(items (flop items.reversed))
::  Classify a turn at the settlement boundary. Outstanding effects are not
::  terminal; an idle view without a final answer is not a successful reply.
::  Cancellation is replayed state, not the position of an event in the log:
::  a later config edit must not turn a cancelled turn into apparent success.
++  outcome
  |=  v=view:h
  ^-  (unit outcome:h)
  ?:  |(?=(^ pending.v) !=(~ wait.v))  ~
  ?^  cancelled.v  `[%cancelled u.cancelled.v]
  ?^  err.v  `[%failure u.err.v]
  =/  last=(unit item:h)  ?~(items.v ~ `(rear items.v))
  ?.  ?=([~ %assistant * ~] last)
    `[%failure 'Session ended without a response']
  `[%reply body.u.last]
::  The human transcript is independent of the provider's compacted context.
::  Event counts are stable message addresses within this session's history.
::
++  transcript
  |=  log=(list event:h)
  ^-  (list [at=@ud input-id=(unit input-id:h) =item:h])
  =/  events  (flop log)
  =/  at=@ud  0
  =|  rows=(list [at=@ud input-id=(unit input-id:h) =item:h])
  |-  ^-  (list [at=@ud input-id=(unit input-id:h) =item:h])
  ?~  events  (flop rows)
  =/  e  i.events
  ?:  ?=(%cancelled -.e)
    =/  before  (flop (turn rows |=([@ud (unit input-id:h) =item:h] item)))
    =/  closed  (cancel-results before reason.e)
    =/  added
      (turn closed |=(it=item:h [+(at) ~ it]))
    $(events t.events, at +(at), rows (weld (flop added) rows))
  =/  row=(unit [input-id=(unit input-id:h) =item:h])
    ?+  -.e  ~
      %input-admitted  `[~ item.e]
      %input-received  `[`id.input.e item.input.e]
      %command-completed  `[~ [%assistant body.e ~]]
      %checkpoint-completed  ?~(reply.e ~ `[~ [%assistant body.u.reply.e ~]])
      %llm-completed   `[~ item.e]
      %tool-completed  `[~ [%tool call-id.e name.e body.e]]
    ==
  ?~  row  $(events t.events, at +(at))
  $(events t.events, at +(at), rows [[+(at) u.row] rows])
++  transcript-items
  |=  log=(list event:h)
  (turn (transcript log) |=([@ud (unit input-id:h) =item:h] item))
::  +unanswered: trailing items with no assistant response yet
::
++  unanswered
  |=  items=(list item:h)
  ^-  (list item:h)
  %-  flop
  =/  rev  (flop items)
  |-  ^-  (list item:h)
  ?~  rev  ~
  ?:  ?=(%assistant -.i.rev)  ~
  [i.rev $(rev t.rev)]
::  +retained: what compaction keeps verbatim: the unanswered tail,
::  plus up to +keep-tail recent items, never splitting a tool flow
::
++  keep-tail  6
++  retained
  |=  items=(list item:h)
  ^-  (list item:h)
  =/  n  (lent items)
  =/  keep  (max (lent (unanswered items)) (min keep-tail n))
  |-  ^-  (list item:h)
  ?:  (gte keep n)  items
  =/  sl  (slag (sub n keep) items)
  ?:  ?=([[%tool *] *] sl)  $(keep +(keep))
  sl
::  +last-calls: the last assistant item's tool calls,
::  and the items that came after it
::
++  last-calls
  |=  items=(list item:h)
  ^-  [calls=(list tool-call:h) after=(list item:h)]
  =/  rev  (flop items)
  =|  after=(list item:h)
  |-  ^-  [calls=(list tool-call:h) after=(list item:h)]
  ?~  rev  [~ after]
  ?:  ?=(%assistant -.i.rev)
    [calls.i.rev after]
  $(rev t.rev, after [i.rev after])
::  Outstanding calls, including calls not yet dispatched. The same gate
::  determines execution and the terminal receipts produced by interruption.
++  open-calls
  |=  items=(list item:h)
  ^-  (list tool-call:h)
  =/  lc  (last-calls items)
  =/  done=(set @t)
    %-  ~(gas in *(set @t))
    %+  murn  after.lc
    |=(it=item:h ?:(?=(%tool -.it) `call-id.it ~))
  (skip calls.lc |=(c=tool-call:h (~(has in done) id.c)))
++  is-cancelled
  |=  body=@t
  =('cancelled: ' (end [3 11] body))
++  cancel-results
  |=  [items=(list item:h) reason=@t]
  ^-  (list item:h)
  %+  turn  (open-calls items)
  |=  c=tool-call:h
  :-  %tool
  :+  id.c  name.c
  %+  rap  3
  :~  'cancelled: '  reason
      '. No result was accepted. Execution may already have occurred; '
      'do not assume rollback or repeat the action without checking.'
  ==
::  loop-guard thresholds
::
++  max-fails  4    ::  consecutive failing tool results before halting
++  max-steps  24   ::  assistant turns since last input before halting
::  +is-error: does a tool result body read as an error, by convention?
::
++  is-error
  |=  body=@t
  ^-  ?
  ?|  =('error: ' (end [3 7] body))
      =('js error: ' (end [3 10] body))
      =('rejected: ' (end [3 10] body))
      =('peer error: ' (end [3 12] body))
  ==
::  +trailing-fails: length of the trailing run of failing tool
::  results (skipping the assistant turns between them)
::
++  trailing-fails
  |=  items=(list item:h)
  ^-  @ud
  =/  rev  (flop items)
  =|  n=@ud
  |-  ^-  @ud
  ?~  rev  n
  ?-  -.i.rev
    %assistant  $(rev t.rev)
    %user       n
    %tool       ?.((is-error body.i.rev) n $(rev t.rev, n +(n)))
  ==
::  +steps-since-input: assistant turns since the last admitted input
::  (a %user item; tool results do not count as input)
::
++  steps-since-input
  |=  items=(list item:h)
  ^-  @ud
  =/  rev  (flop items)
  =|  n=@ud
  |-  ^-  @ud
  ?~  rev  n
  ?:  ?=(%user -.i.rev)  n
  ?:  ?=(%assistant -.i.rev)  $(rev t.rev, n +(n))
  $(rev t.rev)
::  +decide: what happens next; ~ means idle.
::  The caller supplies a pure budget estimate. It is lazy so idle sessions
::  and outstanding tool work need not build a provider request just to decide
::  that nothing can run. A different encoding can supply a different estimate.
::
++  decide
  |=  [v=view:h budget=$-(~ @ud)]
  ^-  (unit step:h)
  ?^  cancelled.v  ~
  ?^  pending.v  ~
  ::  async tool results still in flight
  ::
  ?.  =(~ wait.v)  ~
  ::  a failure halts the loop; retry or new input clears it
  ::
  ?^  err.v  ~
  ?~  items.v  ~
  ::  outstanding tool calls from the last assistant turn
  ::
  =/  todo  (open-calls items.v)
  ?^  todo  `[%tools todo]
  =/  last=item:h  (rear items.v)
  ?:  ?=(%assistant -.last)  ~
  ::  loop guards: halt a stuck agent before it burns the budget.
  ::  a run of failing tool results means it is repeating a mistake;
  ::  too many turns since the last input means it is not converging.
  ::  either way, halt with a reason; a new input clears it and resumes
  ::
  =/  fails  (trailing-fails items.v)
  ?:  (gte fails max-fails)
    :-  ~
    :-  %halt
    %+  rap  3
    :~  'loop guard: '  (scot %ud fails)
        ' tool calls in a row failed. stopping so you can rethink or '
        'ask for help — send a new message to continue.'
    ==
  =/  since  (steps-since-input items.v)
  ?:  (gte since max-steps)
    :-  ~
    :-  %halt
    %+  rap  3
    :~  'loop guard: '  (scot %ud since)
        ' turns without resolving the request. stopping to avoid a '
        'runaway — send a new message to continue.'
    ==
  ?.  (gth (budget ~) max-context.config.v)
    `[%turn ~]
  ::  The planner either selects a bounded span or records a useful halt.
  ::  An oversized irreducible request must never be sent optimistically.
  `[%compact ~]
--
