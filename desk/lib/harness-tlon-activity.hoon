::  Forward, bounded traversal of the native Activity tree. Select first;
::  convert only selected events, never serialize/rebuild the whole feed.
/-  a=tlon-activity-ver, t=harness-tlon
|%
+$  row  [at=@da event=event:v10:a]
++  upgrade
  |=  [old=state-12:t now=@da]
  ^-  state:t
  ::  There was no durable cursor before this version. Start at migration,
  ::  preserving existing jobs, instead of re-answering older conversations.
  [%13 now | +.old]
++  newer
  |=  [tree=(tree row) after=@da limit=@ud]
  ^-  (list row)
  ?>  (lte limit 17)
  =/  out=[left=@ud rows=(list row)]  [limit ~]
  =.  out
    |-  ^+  out
    ?:  |(?=(~ tree) =(0 left.out))  out
    ?:  (lte at.n.tree after)  $(tree r.tree)
    =.  out  $(tree l.tree)
    ?:  =(0 left.out)  out
    =.  out  [(dec left.out) [n.tree rows.out]]
    $(tree r.tree)
  (flop rows.out)
++  supported
  |=  event=event:v10:a
  ^-  (unit incoming-event:v8:a)
  ::  New Activity variants do not silently become conversational input.
  (mole |.(;;(incoming-event:v8:a -.event)))
--
