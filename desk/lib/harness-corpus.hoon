::  Incremental, disposable projection of the head's logs. No Gall, provider,
::  credential store or hand-specific reads. The head schedules +work only
::  while queued work exists; queries never rebuild or scan source text.
/-  h=harness, c=harness-corpus
/+  hl=harness, idx=harness-corpus-index
|%
++  enqueue
  |=  [db=state:c scope=scope:c]
  ^-  state:c
  ?:  (~(has in queued.db) scope)  db
  db(back [scope back.db], queued (~(put in queued.db) scope))
++  retire
  |=  [db=state:c sid=session-id:h]
  ^-  state:c
  =/  scope  (~(get by names.db) sid)
  ?~  scope  db
  =/  old  (~(got by scopes.db) u.scope)
  ::  Drop canonical records and authority immediately. Derived terms and
  ::  snippets remain inaccessible until a bounded rebuild reclaims them.
  %=  db
    names  (~(del by names.db) sid)
    scopes  (~(del by scopes.db) u.scope)
    queued  (~(del in queued.db) u.scope)
    count  (sub count.db count.old)
  ==
++  rename
  |=  [db=state:c from=session-id:h to=session-id:h]
  ^-  state:c
  =/  scope  (~(get by names.db) from)
  ?~  scope  db
  =/  old  (~(got by scopes.db) u.scope)
  db(names (~(put by (~(del by names.db) from)) to u.scope), scopes (~(put by scopes.db) u.scope old(sid to)))
::  Stop at the shared noun tail. Appending a normal turn does not traverse
::  the older conversation. A non-append replacement gets a new incarnation.
++  delta
  |=  [after=(list event:h) before=(list event:h)]
  ^-  (unit (list event:h))
  =|  out=(list event:h)
  |-  ^-  (unit (list event:h))
  ?:  =(after before)  `(flop out)
  ?~  after  ~
  $(after t.after, out [i.after out])
++  capture
  |=  [db=state:c sid=session-id:h log=(list event:h)]
  ^-  state:c
  =/  scope  (~(get by names.db) sid)
  ?~  scope
    =/  id=scope:c  +(next.db)
    =/  source  *conversation:c
    =.  source  source(sid sid, seen log, reverse log)
    =.  db  db(next id, names (~(put by names.db) sid id), scopes (~(put by scopes.db) id source))
    ?~  log  db
    (enqueue db id)
  =/  old  (~(got by scopes.db) u.scope)
  ?:  =(log seen.old)  db
  =/  added  (delta log seen.old)
  ?~  added  $(db (retire db sid))
  =.  old  old(seen log, incoming (weld u.added incoming.old))
  (enqueue db(scopes (~(put by scopes.db) u.scope old)) u.scope)
++  sync
  |=  [db=state:c sessions=(map session-id:h session:h)]
  ^-  state:c
  =/  prune
    |=  [sid=session-id:h db=state:c]
    ?:((~(has by sessions) sid) db (retire db sid))
  =.  db  (roll ~(tap in ~(key by names.db)) prune(db db))
  =/  collect
    |=  [[sid=session-id:h ses=session:h] db=state:c]
    (capture db sid log.ses)
  (roll ~(tap by sessions) collect(db db))
++  rebuild
  |=  [db=state:c epoch=@da]
  ^-  state:c
  =.  db  db(index *index:c, front ~, back ~, queued ~, count 0)
  =.  built-at.index.db  `epoch
  =/  collect
    |=  [[scope=scope:c old=conversation:c] db=state:c]
    =/  fresh  *conversation:c
    =.  fresh  fresh(sid sid.old, seen seen.old, reverse seen.old)
    (enqueue db(scopes (~(put by scopes.db) scope fresh)) scope)
  (roll ~(tap by scopes.db) collect(db db))
++  item-text
  |=  it=item:h
  ^-  @t
  ?-  -.it
    %user  body.it
    %tool  body.it
    %assistant
      %^  cat  3  body.it
      %+  rap  3
      %+  turn  calls.it
      |=  call=tool-call:h
      (rap 3 '\0aTool ' name.call ' (' id.call '): ' args.call ~)
  ==
++  event-record
  |=  [e=event:h before=view:h after=view:h source=(unit input-source:h) sent=@da author=@t]
  ^-  (unit record:c)
  =/  make
    |=  [kind=?(%message %context %tool %summary %note) role=@t body=@t]
    ^-  (unit record:c)
    ?:(=('' body) ~ `[kind role body source sent author])
  =/  item
    |=  it=item:h
    (make %message (scot %tas -.it) (item-text it))
  ?+  -.e  ~
    %input-admitted  (item item.e)
    %input-received  (item item.input.e)
    %context-received  (make %context 'context' body.e)
    %command-completed  (make %message 'assistant' body.e)
    %llm-completed  (item item.e)
    %tool-completed  (make %tool 'tool' (rap 3 name.e ' (' call-id.e '): ' body.e ~))
    %memory-set  (make %note 'note' (rap 3 name.e ': ' (fall body.e '[unpinned; earlier evidence retained]') ~))
    %compaction-completed  (make %summary 'summary' summary.e)
    %checkpoint-completed
      ?.  (~(has by nodes.lcm.after) revision.after)  ~
      (make %summary 'summary' summary.e)
    %cancelled
      =/  closed  (cancel-results:hl (flop items.before) reason.e)
      ?~  closed  ~
      (make %tool 'tool' (rap 3 (turn closed |=(it=item:h (cat 3 (item-text it) '\0a')))))
  ==
++  finish-work
  |=  [db=state:c scope=scope:c conv=conversation:c]
  ^-  state:c
  =.  db  db(scopes (~(put by scopes.db) scope conv))
  ?:  |(?=(^ reverse.conv) ?=(^ forward.conv) ?=(^ incoming.conv))
    (enqueue db scope)
  db
::  One wake has an event budget and a byte budget. A single oversized source
::  event is indexed on its own rather than truncated or silently omitted.
++  work
  |=  [db=state:c events=@ud bytes=@ud]
  ^-  state:c
  ?:  |(=(0 events) =(0 bytes))  db
  =?  db  ?=(~ front.db)
    db(front (flop back.db), back ~)
  =/  front  front.db
  ?~  front  db
  =/  scope  i.front
  =.  db  db(front t.front, queued (~(del in queued.db) scope))
  =/  found  (~(get by scopes.db) scope)
  ?~  found  db
  =/  conv  u.found
  =?  conv  &(?=(~ reverse.conv) ?=(~ forward.conv))
    conv(reverse incoming.conv, incoming ~)
  =/  remaining  events
  =/  left  bytes
  =/  reversing  ?=(^ reverse.conv)
  |-  ^-  state:c
  ?:  =(0 remaining)  (finish-work db scope conv)
  ?:  reversing
    =/  reverse  reverse.conv
    ?~  reverse  (finish-work db scope conv)
    $(conv conv(reverse t.reverse, forward [i.reverse forward.conv]), remaining (dec remaining))
  =/  forward  forward.conv
  ?~  forward  (finish-work db scope conv)
  =/  e  i.forward
  =/  after  (fold:hl e view.conv)
  =?  conv  ?=(%input-received -.e)
    conv(source `source.input.e, sent at.input.e, author ?~(actor.input.e '' (scot %p u.actor.input.e)))
  =/  record  (event-record e view.conv after source.conv sent.conv author.conv)
  =/  size  ?~(record 0 (met 3 body.u.record))
  ?:  &(!=(remaining events) (gth size left))  (finish-work db scope conv)
  =.  conv  conv(forward t.forward, view after)
  ?~  record  $(remaining (dec remaining))
  =/  ref=ref:c  [scope revision.after ~]
  =.  records.conv  (~(put by records.conv) revision.after u.record)
  =.  count.conv  +(count.conv)
  =.  index.db  (put-document:idx index.db ref sent.u.record author.u.record ~[body.u.record])
  =.  count.db  +(count.db)
  =.  left  (sub left (min left size))
  ?:  =(0 left)  (finish-work db scope conv)
  $(remaining (dec remaining))
--
