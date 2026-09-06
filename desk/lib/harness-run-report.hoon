::  Bounded, redacted projection of one admitted input's existing event log.
::  No new run authority, transcript, provider secrets or effect execution.
/-  h=harness
/+  ht=harness-tools
|%
+$  call-state  ?(%unknown %completed %error %blocked %uncertain)
+$  call  [id=@t name=@t status=call-state]
+$  report  [calls=(list call) count=@ud truncated=?]
++  safe-name
  |=  name=@t
  ^-  @t
  ?:  =('current_time' name)  name
  ?~((tool-family:ht name) 'other_tool' name)
++  result-status
  |=  body=@t
  ^-  call-state
  ?:  =('uncertain:' (end 3^10 body))  %uncertain
  ?:  =('rejected:' (end 3^9 body))  %blocked
  ?:  |(=('error:' (end 3^6 body)) =('failed:' (end 3^7 body)))  %error
  %completed
++  collect
  |=  [log=(list event:h) id=input-id:h]
  ^-  (unit report)
  =/  segment=(list event:h)  ~
  =/  remaining=@ud  4.096
  =/  found
    |-  ^-  (unit (list event:h))
    ?:  |(=(0 remaining) ?=(~ log))  ~
    ?:  ?=(%input-received -.i.log)
      ?:  =(id id.input.i.log)  `segment
      $(log t.log, segment ~, remaining (dec remaining))
    $(log t.log, segment [i.log segment], remaining (dec remaining))
  ?~  found  ~
  %-  some
  %+  roll  u.found
  |:  [e=*event:h out=`report`[~ 0 |]]
  (step e out)
++  add-call
  |=  [c=tool-call:h out=report]
  ^-  report
  =.  count.out  +(count.out)
  ?:  (gte (lent calls.out) 64)  out(truncated &)
  out(calls [[id.c (safe-name name.c) %unknown] calls.out])
++  step
  |=  [e=event:h out=report]
  ^-  report
  ?:  ?=(%llm-completed -.e)
    ?.  ?=(%assistant -.item.e)  out
    %+  roll  calls.item.e
    |:  [c=*tool-call:h acc=out]
    (add-call c acc)
  ?.  ?=(%tool-completed -.e)  out
  =/  next
    =/  pending  calls.out
    |-  ^-  (list call)
    ?~  pending  ~
    ?:  &(=(id.i.pending call-id.e) =(%unknown status.i.pending))
      [i.pending(status (result-status body.e)) t.pending]
    [i.pending $(pending t.pending)]
  out(calls next)
--
