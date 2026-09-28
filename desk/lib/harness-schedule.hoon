::  Transport-independent schedule validation and evidence projection.
::  No Gall effects or inference. The head commits each run before dispatch.
/-  c=harness-cron, h=harness, hh=harness-hand
/+  calendar=harness-cron, reminder=harness-reminder, hl=harness
|%
++  maintenance-needed
  |=  [jobs=(map @uv schedule:c) wake=(unit @da) now=@da changed=?]
  ^-  ?
  ?:  changed  &
  ::  An armed deadline includes the busy-job backoff; unrelated traffic must
  ::  not turn an overdue but busy job into continuous authority polling.
  ?^  wake  (lte u.wake now)
  ::  Reloads and consumed timer wakes must re-arm active jobs. Settled jobs
  ::  alone need no timer or read-triggered sweep; effects still authorize live.
  (lien ~(val by jobs) |=(job=schedule:c =(%active state.job)))
++  job-value
  |=  job=schedule:c
  ^-  job:c
  [kind.job timezone.job destination.job sid.job run-sid.job expression.job pattern.job prompt.job tools.job next.job remaining.job state.job reason.job last.job]
++  fingerprint
  |=  act=action:c
  ^-  @uvH
  (sham act)
++  create
  |=  [act=action:c source=binding:hh tools=(list tool-grant:h) now=@da]
  ^-  schedule:c
  ?>  ?=(%add -.act)
  ?>  enabled.source
  ?>  (lien actors.source |=(actor=@t =(actor actor.act)))
  =/  fields=job:c
    ?:  =(%reminder kind.act)
      =/  f=[at=@t destination=@t text=@t]
        ((ot:dejs:format ~[at+so:dejs:format destination+so:dejs:format text+so:dejs:format]) args.act)
      ?>  =(destination.f address.source)
      ?>  &((gth (met 3 text.f) 0) (lte (met 3 text.f) 4.096))
      =/  time  (parse:reminder at.f now)
      [%reminder timezone.time address.source sid.source '' at.f *pattern:c text.f tools at.time 1 %active '' ~]
    ?>  ?=(%o -.args.act)
    ?:  (~(has by p.args.act) 'at')
      =/  f=[at=@t prompt=@t]
        ((ot:dejs:format ~[at+so:dejs:format prompt+so:dejs:format]) args.act)
      ?>  &((gth (met 3 prompt.f) 0) (lte (met 3 prompt.f) 4.096))
      =/  time  (parse:reminder at.f now)
      [%prompt timezone.time address.source sid.source '' at.f *pattern:c prompt.f tools at.time 1 %active '' ~]
    =/  f=[schedule=@t timezone=@t prompt=@t runs=@t]
      ((ot:dejs:format ~[schedule+so:dejs:format timezone+so:dejs:format prompt+so:dejs:format runs+so:dejs:format]) args.act)
    ?>  =('UTC' timezone.f)
    ?>  &((gth (met 3 prompt.f) 0) (lte (met 3 prompt.f) 4.096))
    =/  runs  (number:calendar runs.f)
    ?>  &((gth runs 0) (lte runs 100))
    =/  pattern  (parse:calendar schedule.f)
    [%prompt 'UTC' address.source sid.source '' schedule.f pattern prompt.f tools (need (next:calendar pattern now)) runs %active '' ~]
  =.  run-sid.fields  (cat 3 'schedule-' (scot %uv id.act))
  [binding.act actor.act hand.source (fingerprint act) fields]
++  busy
  |=  [job=job:c db=state:hh]
  ^-  ?
  ::  Legacy transfer can precede its already-issued admission callback.
  ::  A reserved input without evidence must not be mistaken for idle work.
  ?:  ?&(?=(^ last.job) !(~(has by observations.db) u.last.job))  &
  ?|  (lien ~(val by observations.db) |=(o=observation:hh &(=(run-sid.job binding.o) ?=(?(%queued %running) phase.o))))
      (lien ~(val by outbox.db) |=(p=publication:hh &(=(run-sid.job sid.p) ?=(?(%pending %claimed %uncertain) status.p))))
  ==
++  accessible
  |=  [job=schedule:c owner=? binding=@t actor=@t]
  ^-  ?
  |(owner &(=(binding binding.job) =(actor actor.job)))
++  editable
  |=  [id=@uv job=schedule:c args=json now=@da]
  ^-  schedule:c
  ::  Creation validation keeps timing future-facing. Identity, grants and
  ::  admission history remain attached to the same conversation.
  =/  source=binding:hh  [hand.job destination.job sid.job ~[actor.job] &]
  =/  next  (create [%add id binding.job actor.job kind.job args] source tools.job now)
  next(run-sid run-sid.job, last last.job, fingerprint fingerprint.job)
++  retryable
  |=  [job=job:c db=state:hh]
  ^-  ?
  ?.  ?&  =(%prompt kind.job)
          ?=(?(%active %complete) state.job)
          ?=(^ last.job)
      ==
    |
  =/  obs  (~(get by observations.db) u.last.job)
  =/  pub  (~(get by outbox.db) u.last.job)
  ?&  ?=(^ obs)
      =(run-sid.job binding.u.obs)
      =(%failed phase.u.obs)
      ?=(^ pub)
      =(%failure kind.u.pub)
      !(busy job db)
  ==
++  retry-session
  |=  [binding=@t ses=session:h]
  ^-  ?
  =/  v  (play:hl log.ses)
  ?.  &(?=(^ err.v) ?=(~ pending.v) =(~ wait.v) =(~ (open-calls:hl items.v)))  |
  =/  log  log.ses
  |-  ^-  ?
  ?~  log  |
  ?:  ?=(%input-admitted -.i.log)  |
  ?.  ?=(%input-received -.i.log)  $(log t.log)
  =/  source  source.input.i.log
  ?&(?=(%hand -.source) =(binding binding.source))
++  clearable
  |=  [job=job:c db=state:hh]
  ^-  ?
  ?.  |(=(%cancelled state.job) &(=(%complete state.job) =(0 remaining.job)))  |
  ?:  (busy job db)  |
  ?~  last.job  =(%cancelled state.job)
  =/  last  (~(get by observations.db) u.last.job)
  ?~  last  |
  =(run-sid.job binding.u.last)
++  advance
  |=  [job=schedule:c input=@uv now=@da]
  ^-  schedule:c
  ?>  &(=(%active state.job) (gth remaining.job 0))
  =.  job  job(remaining (dec remaining.job), last `input)
  ?:  =(0 remaining.job)  job(state %complete)
  =/  next  (next:calendar pattern.job now)
  ?~  next  job(state %complete)
  job(next (need next))
++  for-session
  |=  [jobs=(map @uv schedule:c) sid=@t]
  ^-  (unit schedule:c)
  =/  found  (skim ~(val by jobs) |=(job=schedule:c =(sid run-sid.job)))
  ?~(found ~ `i.found)
++  one-json
  |=  [id=@uv job=schedule:c db=state:hh]
  ^-  json
  =/  observation  ?~(last.job ~ (~(get by observations.db) u.last.job))
  =/  publication  ?~(last.job ~ (~(get by outbox.db) u.last.job))
  %-  pairs:enjs:format
  :~  ['id' %s (scot %uv id)]
      ['revision' %s (scot %uv (sham job))]
      ['sessionId' %s sid.job]
      ['runSessionId' %s run-sid.job]
      ['sourceBinding' %s binding.job]
      ['hand' %s hand.job]
      ['actor' %s actor.job]
      ['schedule' %s expression.job]
      ['kind' %s kind.job]
      ['timezone' %s timezone.job]
      ['destination' %s destination.job]
      ['prompt' %s prompt.job]
      ['next' %s (scot %da next.job)]
      ['remaining' (numb:enjs:format remaining.job)]
      ['state' %s state.job]
      ['reason' %s reason.job]
      ['lastInput' ?~(last.job ~ [%s (scot %uv u.last.job)])]
      ['execution' ?~(observation ~ [%s phase.u.observation])]
      ['delivery' ?~(publication ~ [%s status.u.publication])]
      ['evidenceAvailable' %b &]
      ['clearable' %b (clearable (job-value job) db)]
      ['retryable' %b (retryable (job-value job) db)]
  ==
++  list-json
  |=  [jobs=(map @uv schedule:c) db=state:hh binding=(unit @t)]
  ^-  json
  :-  %a
  %+  murn  ~(tap by jobs)
  |=  [id=@uv job=schedule:c]
  ^-  (unit json)
  ?.  ?~(binding & =(u.binding binding.job))  ~
  `(one-json id job db)
++  json-action
  |=  jon=json
  ^-  action:c
  =,  dejs:format
  =/  id  (cu |=(s=@t (need (slaw %uv s))) so)
  %.  jon
  %-  of
  :~  add+(ot ~[id+id binding+so actor+so kind+json-kind args+|=(a=json a)])
      list+(ot ~[binding+(mu so)])
      cancel+(ot ~[id+id])
      clear+(ot ~[id+id])
      edit+(ot ~[id+id revision+id args+|=(a=json a)])
      delete+(ot ~[id+id])
      retry+(ot ~[id+id input+id])
  ==
++  json-kind
  |=  jon=json
  ^-  ?(%prompt %reminder)
  =/  value  (so:dejs:format jon)
  ?>  ?=(?(%prompt %reminder) value)
  value
++  json-request
  =,  dejs:format
  ^-  $-(json request:c)
  (ot ~[id+so action+json-action])
--
