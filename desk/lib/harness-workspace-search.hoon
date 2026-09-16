/-  w=harness-workspace, s=harness-workspace-search
/+  words=harness-corpus-index
|%
++  source
  |=  [db=state:w address=address:s]
  ^-  (unit (list @t))
  ?:  =(%artifact kind.key.address)
    =/  art  (~(get by artifacts.db) id.key.address)
    ?~  art  ~
    =/  revision  (~(get by revisions.u.art) revision.address)
    ?~  revision  ~
    =/  value  value.u.revision
    `[title.value body.value (turn sources.value |=(ref=source:w (cat 3 label.ref (cat 3 ' ' url.ref))))]
  ?:  =(%project kind.key.address)
    =/  project  (~(get by projects.db) id.key.address)
    ?~  project  ~
    `~[title.u.project description.u.project]
  =/  task  (~(get by tasks.db) id.key.address)
  ?~  task  ~
  `~[title.u.task description.u.task outcome.u.task]
++  fingerprint
  |=  [db=state:w address=address:s]
  ^-  (unit @uv)
  =/  value  (source db address)
  ?~(value ~ `(sham u.value))
++  queue
  |=  [idx=state:s address=address:s at=@da]
  ^-  state:s
  =?  back.idx  !(~(has by queued.idx) address)  [address back.idx]
  idx(queued (~(put by queued.idx) address at))
++  sync
  |=  [idx=state:s before=state:w after=state:w at=@da]
  ^-  state:s
  =?  before  |(!initialized.idx &(?=(~ documents.idx) ?=(~ queued.idx)))  *state:w
  =.  initialized.idx  &
  =.  idx
    %+  roll  ~(tap in (~(uni in ~(key by artifacts.before)) ~(key by artifacts.after)))
    |=  [id=@t out=_idx]
    =/  old  (~(get by artifacts.before) id)
    =/  new  (~(get by artifacts.after) id)
    =/  old-revs=(map @ud revision:w)  ?~(old ~ revisions.u.old)
    =/  new-revs=(map @ud revision:w)  ?~(new ~ revisions.u.new)
    ?:  =(old-revs new-revs)  out
    %+  roll  ~(tap in (~(uni in ~(key by old-revs)) ~(key by new-revs)))
    |=  [revision=@ud out=_out]
    =/  address=address:s  [[%artifact id] revision]
    ?:  =((fingerprint before address) (fingerprint after address))  out
    (queue out address at)
  =.  idx
    %+  roll  ~(tap in (~(uni in ~(key by projects.before)) ~(key by projects.after)))
    |=  [id=@t out=_idx]
    =/  address=address:s  [[%project id] 0]
    ?:  =((fingerprint before address) (fingerprint after address))  out
    (queue out address at)
  %+  roll  ~(tap in (~(uni in ~(key by tasks.before)) ~(key by tasks.after)))
  |=  [id=@t out=_idx]
  =/  address=address:s  [[%task id] 0]
  ?:  =((fingerprint before address) (fingerprint after address))  out
  (queue out address at)
++  remove
  |=  [idx=state:s address=address:s]
  ^-  state:s
  =/  old  (~(get by documents.idx) address)
  ?~  old  idx
  =.  documents.idx  (~(del by documents.idx) address)
  %+  roll  ~(tap in words.u.old)
  |=  [word=@t out=_idx]
  =/  matches  (~(got by terms.out) word)
  =/  versions  (~(got by matches) key.address)
  =.  versions  (~(del in versions) revision.address)
  =.  matches
    ?~  versions  (~(del by matches) key.address)
    (~(put by matches) key.address versions)
  ?^  matches  out(terms (~(put by terms.out) word matches))
  =/  prefix  (term-prefix:words word)
  =/  bucket  (~(del in (~(got by prefixes.out) prefix)) word)
  out(terms (~(del by terms.out) word), prefixes ?~(bucket (~(del by prefixes.out) prefix) (~(put by prefixes.out) prefix bucket)))
++  put
  |=  [idx=state:s address=address:s texts=(list @t) at=@da]
  ^-  state:s
  =.  idx  (remove idx address)
  =/  tokens  (tokenize:words texts)
  =.  documents.idx  (~(put by documents.idx) address [(sham texts) tokens at])
  %+  roll  ~(tap in tokens)
  |=  [word=@t out=_idx]
  =/  matches  (fall (~(get by terms.out) word) *matches:s)
  =/  versions  (fall (~(get by matches) key.address) *(set @ud))
  =.  matches  (~(put by matches) key.address (~(put in versions) revision.address))
  =/  prefix  (term-prefix:words word)
  =/  bucket  (fall (~(get by prefixes.out) prefix) *(set @t))
  out(terms (~(put by terms.out) word matches), prefixes (~(put by prefixes.out) prefix (~(put in bucket) word)))
++  work
  |=  [idx=state:s db=state:w limit=@ud budget=@ud]
  ^-  state:s
  ?:  |(=(0 limit) =(0 budget))  idx
  =?  idx  ?=(~ front.idx)  idx(front (flop back.idx), back ~)
  ?~  front.idx  idx
  =/  address  i.front.idx
  =/  at  (~(got by queued.idx) address)
  =/  saved=state:s  idx
  =/  next  saved(front t.front.idx, queued (~(del by queued.idx) address), epoch +(epoch.idx))
  =/  texts  (source db address)
  ?~  texts  $(idx (remove next address), limit (dec limit))
  =/  bytes  (roll u.texts |=([text=@t out=@ud] (add out (met 3 text))))
  =?  at  =(%artifact kind.key.address)
    at:(~(got by revisions:(~(got by artifacts.db) id.key.address)) revision.address)
  =?  at  =(%task kind.key.address)
    updated:(~(got by tasks.db) id.key.address)
  $(idx (put next address u.texts at), limit (dec limit), budget (sub budget (min budget bytes)))
++  alternatives
  |=  [idx=state:s needle=@t]
  ^-  (list @t)
  ?:  (~(has by terms.idx) needle)  ~[needle]
  ?:  (lth (met 3 needle) 2)  ~
  =/  bucket  (~(get by prefixes.idx) (term-prefix:words needle))
  ?~  bucket  ~
  %-  scag  :-  32
  %+  skim  (take-terms:words u.bucket 4.096)
  |=(word=@t |((prefix-match:words needle word) (one-edit:words needle word)))
++  union
  |=  [a=matches:s b=matches:s]
  ^-  matches:s
  %+  roll  ~(tap by b)
  |=  [[key=key:s versions=(set @ud)] out=_a]
  (~(put by out) key (~(uni in versions) (fall (~(get by out) key) *(set @ud))))
++  intersect
  |=  [a=matches:s b=matches:s]
  ^-  matches:s
  %+  roll  ~(tap by a)
  |=  [[key=key:s versions=(set @ud)] out=matches:s]
  =/  other  (~(get by b) key)
  ?~  other  out
  =/  shared  (~(int in versions) u.other)
  ?~  shared  out
  (~(put by out) key shared)
++  search
  |=  [idx=state:s query=@t]
  ^-  matches:s
  ?>  (lte (met 3 query) 512)
  =/  needles  ~(tap in (tokenize-text:words query))
  =/  result=(unit matches:s)  ~
  |-  ^-  matches:s
  ?~  needles  (fall result ~)
  =/  matches=matches:s
    %+  roll  (alternatives idx i.needles)
    |=  [word=@t out=matches:s]
    (union out (fall (~(get by terms.idx) word) *matches:s))
  =.  result  `?~(result matches (intersect u.result matches))
  ?:  ?=([~ ~] result)  ~
  $(needles t.needles)
++  live
  |=  [idx=state:s db=state:w address=address:s]
  ^-  ?
  =/  indexed  (~(get by documents.idx) address)
  ?~  indexed  |
  =(`signature.u.indexed (fingerprint db address))
--
